package com.aam.carlauncher

import android.annotation.SuppressLint
import android.content.Context
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.location.OnNmeaMessageListener
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import io.flutter.plugin.common.EventChannel
import java.text.SimpleDateFormat
import java.util.*

/**
 * Fixes the XY Auto T100 RTC Reset Bug (where ACC power loss resets the clock to 2019/2020).
 * Extracts raw UTC satellite time directly from GPS constellation NMEA sentences ($GPRMC / $GPZDA).
 * Computes a monotonic offset and optionally attempts root system time sync.
 */
class GpsTimeSyncHelper(private val context: Context) : EventChannel.StreamHandler, LocationListener {

    companion object {
        private const val TAG = "GpsTimeSyncHelper"
    }

    private val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as? LocationManager
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private var nmeaListener: OnNmeaMessageListener? = null

    // Offsets & state
    @Volatile
    private var gpsTimeOffsetMs: Long = 0L // trueUtcMillis = SystemClock.elapsedRealtime() + gpsTimeOffsetMs

    @Volatile
    private var hasValidFix = false

    private var lastKnownLat = 25.4052 // Default: Ajman/Sharjah, UAE
    private var lastKnownLng = 55.5136
    private var lastSpeedKmh = 0.0
    private var lastBearing = 0.0

    private val rmcDateFormat = SimpleDateFormat("ddMMyyHHmmss", Locale.US).apply {
        timeZone = TimeZone.getTimeZone("UTC")
    }

    private val zdaDateFormat = SimpleDateFormat("ddMMyyyyHHmmss", Locale.US).apply {
        timeZone = TimeZone.getTimeZone("UTC")
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
        startGpsListening()
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
        stopGpsListening()
    }

    @SuppressLint("MissingPermission")
    fun startGpsListening() {
        if (locationManager == null) {
            Log.e(TAG, "LocationManager is null.")
            return
        }

        try {
            // Register standard location updates
            if (locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                locationManager.requestLocationUpdates(
                    LocationManager.GPS_PROVIDER,
                    1000L,
                    1.0f,
                    this,
                    Looper.getMainLooper()
                )
            }

            // Register NMEA listener for microsecond-accurate satellite timestamps
            nmeaListener = OnNmeaMessageListener { message, timestamp ->
                parseNmeaMessage(message)
            }
            locationManager.addNmeaListener(nmeaListener!!, Handler(Looper.getMainLooper()))
            Log.i(TAG, "GPS Satellite listener and NMEA stream registered.")
        } catch (e: SecurityException) {
            Log.e(TAG, "GPS permissions not granted: ${e.message}")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting GPS listener: ${e.message}")
        }
    }

    fun stopGpsListening() {
        try {
            locationManager?.removeUpdates(this)
            nmeaListener?.let {
                locationManager?.removeNmeaListener(it)
            }
        } catch (ignored: Exception) {}
    }

    private fun parseNmeaMessage(nmea: String) {
        if (!nmea.startsWith("$")) return
        val tokens = nmea.split(",")
        if (tokens.isEmpty()) return

        val sentenceType = tokens[0]

        // Parse $GPRMC or $GNRMC (Recommended Minimum Specific GPS/TRANSIT Data)
        // Format: $GPRMC,hhmmss.ss,A,lat,N,lon,E,speed,course,ddmmyy,...
        if (sentenceType.endsWith("RMC") && tokens.size >= 10) {
            val status = tokens[2]
            if (status == "A") { // "A" = Data Valid
                val timeStr = tokens[1].split(".")[0]
                val dateStr = tokens[9]
                if (timeStr.length == 6 && dateStr.length == 6) {
                    try {
                        val combined = dateStr + timeStr
                        val parsedDate = rmcDateFormat.parse(combined)
                        if (parsedDate != null) {
                            applySatelliteTimeSync(parsedDate.time, "NMEA-RMC")
                        }
                    } catch (e: Exception) {
                        Log.w(TAG, "Failed to parse RMC timestamp: ${e.message}")
                    }
                }
            }
        }

        // Parse $GPZDA or $GNZDA (UTC Time and Date)
        // Format: $GPZDA,hhmmss.ss,dd,mm,yyyy,...
        if (sentenceType.endsWith("ZDA") && tokens.size >= 5) {
            val timeStr = tokens[1].split(".")[0]
            val day = tokens[2]
            val month = tokens[3]
            val year = tokens[4]
            if (timeStr.length == 6 && day.isNotEmpty() && month.isNotEmpty() && year.isNotEmpty()) {
                try {
                    val combined = String.format("%02d%02d%s%s", day.toInt(), month.toInt(), year, timeStr)
                    val parsedDate = zdaDateFormat.parse(combined)
                    if (parsedDate != null) {
                        applySatelliteTimeSync(parsedDate.time, "NMEA-ZDA")
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "Failed to parse ZDA timestamp: ${e.message}")
                }
            }
        }
    }

    override fun onLocationChanged(location: Location) {
        lastKnownLat = location.latitude
        lastKnownLng = location.longitude
        lastSpeedKmh = location.speed * 3.6
        lastBearing = location.bearing.toDouble()

        // Location.time provides the UTC timestamp from satellite
        if (location.time > 1600000000000L) { // Post 2020 check
            applySatelliteTimeSync(location.time, "LocationFix")
        }

        dispatchGpsStatus()
    }

    private fun applySatelliteTimeSync(satelliteUtcMillis: Long, source: String) {
        val nowElapsed = SystemClock.elapsedRealtime()
        gpsTimeOffsetMs = satelliteUtcMillis - nowElapsed
        hasValidFix = true

        Log.i(TAG, "GPS Satellite Lock acquired via $source! Accurate UTC: $satelliteUtcMillis, Monotonic Offset: $gpsTimeOffsetMs ms")

        // Try to update system clock if root or system permission available on the head unit
        tryRootSystemClockSync(satelliteUtcMillis)

        dispatchGpsStatus()
    }

    private fun tryRootSystemClockSync(utcMillis: Long) {
        // Many Android head-units (including XY Auto T100) run eng/userdebug builds with root access
        try {
            val seconds = utcMillis / 1000L
            val p = Runtime.getRuntime().exec(arrayOf("su", "-c", "date @$seconds && am broadcast -a android.intent.action.TIME_SET"))
            p.waitFor()
            Log.i(TAG, "Attempted root system clock update to seconds: $seconds")
        } catch (ignored: Exception) {
            // Non-root environment; Flutter app still operates with perfect accuracy via monotonic offset!
        }
    }

    private fun dispatchGpsStatus() {
        val accurateUtcMillis = SystemClock.elapsedRealtime() + gpsTimeOffsetMs
        val data = mapOf(
            "utcMillis" to accurateUtcMillis,
            "timeOffsetMs" to gpsTimeOffsetMs,
            "hasValidFix" to hasValidFix,
            "latitude" to lastKnownLat,
            "longitude" to lastKnownLng,
            "speedKmh" to lastSpeedKmh,
            "bearing" to lastBearing
        )
        mainHandler.post {
            eventSink?.success(data)
        }
    }

    fun getCurrentAccurateUtcMillis(): Long {
        return if (hasValidFix) {
            SystemClock.elapsedRealtime() + gpsTimeOffsetMs
        } else {
            System.currentTimeMillis()
        }
    }

    fun getLastCoordinates(): Pair<Double, Double> {
        return Pair(lastKnownLat, lastKnownLng)
    }

    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
    override fun onProviderEnabled(provider: String) {}
    override fun onProviderDisabled(provider: String) {}
}

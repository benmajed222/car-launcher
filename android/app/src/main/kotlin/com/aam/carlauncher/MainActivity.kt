package com.aam.carlauncher

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Main Android Activity for AAM Cockpit Automotive Car Launcher.
 * Features: Apple CarPlay integration, OBD-II telemetry, GPS clock sync,
 * Google Maps CarPlay navigation intents, Wi-Fi/BT quick controls,
 * System Volume control, Screen Brightness / Dimming, and Adhan audio.
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL_CARPLAY = "car_launcher/carplay"
        private const val CHANNEL_OBD_CONTROL = "car_launcher/obd_control"
        private const val CHANNEL_OBD_STREAM = "car_launcher/obd_stream"
        private const val CHANNEL_GPS_TIME = "car_launcher/gps_time"
        private const val CHANNEL_SYSTEM = "car_launcher/system"
    }

    private lateinit var carPlayHelper: CarPlayLauncherHelper
    private lateinit var obdService: ObdBluetoothService
    private lateinit var gpsTimeHelper: GpsTimeSyncHelper
    private lateinit var audioManager: AudioManager
    private var adhanPlayer: MediaPlayer? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        carPlayHelper = CarPlayLauncherHelper(this)
        obdService = ObdBluetoothService(this)
        gpsTimeHelper = GpsTimeSyncHelper(this)
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val binaryMessenger = flutterEngine.dartExecutor.binaryMessenger

        // 1. CarPlay & Navigation Bridge
        MethodChannel(binaryMessenger, CHANNEL_CARPLAY).setMethodCallHandler { call, result ->
            when (call.method) {
                "detectCarPlay" -> {
                    result.success(carPlayHelper.detectInstalledCarPlayApp())
                }
                "getAllLinkApps" -> {
                    result.success(carPlayHelper.getAllInstalledLinkApps())
                }
                "launchCarPlay" -> {
                    val targetPackage = call.argument<String?>("targetPackage")
                    val success = carPlayHelper.launchCarPlayApp(targetPackage)
                    result.success(success)
                }
                "isPackageInstalled" -> {
                    val pkg = call.argument<String>("packageName") ?: ""
                    result.success(carPlayHelper.isPackageInstalled(pkg))
                }
                "navigateCarPlayMaps" -> {
                    val lat = call.argument<Double>("lat") ?: 25.1972
                    val lng = call.argument<Double>("lng") ?: 55.2744
                    val label = call.argument<String>("label") ?: "Destination"
                    val success = navigateViaGoogleMaps(lat, lng, label)
                    result.success(success)
                }
                else -> result.notImplemented()
            }
        }

        // 2. OBD-II Control & Query Bridge
        MethodChannel(binaryMessenger, CHANNEL_OBD_CONTROL).setMethodCallHandler { call, result ->
            when (call.method) {
                "configureObd" -> {
                    val mode = call.argument<String>("mode") ?: "bluetooth"
                    val address = call.argument<String?>("address")
                    val port = call.argument<Int>("port") ?: 35000
                    obdService.configure(mode, address, port)
                    result.success(true)
                }
                "getPairedDevices" -> {
                    result.success(obdService.getPairedBluetoothDevices())
                }
                "sendRawCommand" -> {
                    val cmd = call.argument<String>("command") ?: ""
                    val response = obdService.executeRawCommandPublic(cmd)
                    result.success(response)
                }
                "reconnectObd" -> {
                    obdService.stopService()
                    obdService.startService()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // 3. OBD-II Live Stream (EventChannel)
        EventChannel(binaryMessenger, CHANNEL_OBD_STREAM).setStreamHandler(obdService)

        // 4. GPS Satellite Time Sync (EventChannel)
        EventChannel(binaryMessenger, CHANNEL_GPS_TIME).setStreamHandler(gpsTimeHelper)

        // 5. System Utilities (Volume, Brightness, Wi-Fi, Bluetooth, Apps, Adhan)
        MethodChannel(binaryMessenger, CHANNEL_SYSTEM).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAllInstalledApps" -> {
                    result.success(getInstalledLauncherApps())
                }
                "launchApp" -> {
                    val pkg = call.argument<String>("packageName")
                    if (pkg != null) {
                        val launchIntent = packageManager.getLaunchIntentForPackage(pkg)
                        if (launchIntent != null) {
                            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(launchIntent)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Package name is null", null)
                    }
                }
                "getVolume" -> {
                    val current = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
                    val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                    result.success(if (max > 0) current.toDouble() / max else 0.5)
                }
                "setVolume" -> {
                    val level = call.argument<Double>("level") ?: 0.5
                    val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                    val target = (level * max).toInt().coerceIn(0, max)
                    audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, target, 0)
                    result.success(true)
                }
                "setScreenBrightness" -> {
                    val brightness = (call.argument<Double>("brightness") ?: 1.0).toFloat().coerceIn(0.05f, 1.0f)
                    val layoutParams = window.attributes
                    layoutParams.screenBrightness = brightness
                    window.attributes = layoutParams
                    result.success(true)
                }
                "openSystemSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_SETTINGS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "openWifiSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_WIFI_SETTINGS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "openBluetoothSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_BLUETOOTH_SETTINGS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "playAdhanSound" -> {
                    playAdhanAudio()
                    result.success(true)
                }
                "stopAdhanSound" -> {
                    stopAdhanAudio()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun navigateViaGoogleMaps(lat: Double, lng: Double, label: String): Boolean {
        try {
            val gmmIntentUri = Uri.parse("google.navigation:q=$lat,$lng&mode=d")
            val mapIntent = Intent(Intent.ACTION_VIEW, gmmIntentUri).apply {
                setPackage("com.google.android.apps.maps")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            if (mapIntent.resolveActivity(packageManager) != null) {
                startActivity(mapIntent)
                return true
            }

            return carPlayHelper.launchCarPlayApp(null)
        } catch (e: Exception) {
            return carPlayHelper.launchCarPlayApp(null)
        }
    }

    private fun playAdhanAudio() {
        stopAdhanAudio()
        try {
            val notificationUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)

            adhanPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .build()
                )
                setDataSource(applicationContext, notificationUri)
                prepare()
                start()
            }
        } catch (ignored: Exception) {}
    }

    private fun stopAdhanAudio() {
        try {
            adhanPlayer?.stop()
            adhanPlayer?.release()
        } catch (ignored: Exception) {}
        adhanPlayer = null
    }

    private fun getInstalledLauncherApps(): List<Map<String, String>> {
        val pm = packageManager
        val intent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        val apps = pm.queryIntentActivities(intent, 0)
        val result = mutableListOf<Map<String, String>>()

        for (resolveInfo in apps) {
            val pkg = resolveInfo.activityInfo.packageName
            if (pkg == packageName) continue

            val label = resolveInfo.loadLabel(pm).toString()
            result.add(
                mapOf(
                    "packageName" to pkg,
                    "appName" to label
                )
            )
        }
        result.sortBy { it["appName"]?.lowercase() }
        return result
    }

    override fun onDestroy() {
        super.onDestroy()
        stopAdhanAudio()
        obdService.stopService()
        gpsTimeHelper.stopGpsListening()
    }
}

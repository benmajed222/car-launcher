package com.aam.carlauncher

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.*
import java.io.BufferedReader
import java.io.InputStream
import java.io.InputStreamReader
import java.io.OutputStream
import java.net.InetSocketAddress
import java.net.Socket
import java.util.UUID

/**
 * High-performance, resilient OBD-II (ELM327) telemetry client.
 * Connects via Classic Bluetooth SPP, BLE or Wi-Fi TCP Sockets.
 * Optimized for ISO 15765-4 CAN (11-bit 500kbps) on the 2012 Honda Accord.
 */
class ObdBluetoothService(private val context: Context) : EventChannel.StreamHandler {

    companion object {
        private const val TAG = "ObdBluetoothService"
        // Standard Serial Port Profile (SPP) UUID
        private val SPP_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
        private const val DEFAULT_WIFI_IP = "192.168.0.10"
        private const val DEFAULT_WIFI_PORT = 35000
    }

    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var connectionJob: Job? = null

    @Volatile
    private var isRunning = false

    @Volatile
    private var isConnected = false

    // Bluetooth resources
    private var bluetoothSocket: BluetoothSocket? = null
    private var wifiSocket: Socket? = null
    private var inputStream: InputStream? = null
    private var outputStream: OutputStream? = null

    // Configuration
    private var connectionMode = "bluetooth" // "bluetooth" or "wifi"
    private var targetDeviceAddress: String? = null
    private var wifiHost: String = DEFAULT_WIFI_IP
    private var wifiPort: Int = DEFAULT_WIFI_PORT

    // Telemetry cache
    private var lastSpeed = 0
    private var lastRpm = 0
    private var lastCoolant = 85
    private var lastVoltage = 13.8
    private var lastIntakeTemp = 35
    private var lastThrottle = 0

    fun configure(mode: String, addressOrHost: String?, port: Int = DEFAULT_WIFI_PORT) {
        connectionMode = mode
        if (mode == "wifi") {
            wifiHost = addressOrHost ?: DEFAULT_WIFI_IP
            wifiPort = port
        } else {
            targetDeviceAddress = addressOrHost
        }
    }

    fun startService() {
        if (isRunning) return
        isRunning = true
        startConnectionLoop()
    }

    fun stopService() {
        isRunning = false
        connectionJob?.cancel()
        disconnectCurrentSocket()
        notifyStatus(false, "Disconnected")
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
        startService()
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
        stopService()
    }

    private fun startConnectionLoop() {
        connectionJob?.cancel()
        connectionJob = serviceScope.launch {
            while (isRunning && isActive) {
                if (!isConnected) {
                    notifyStatus(false, "Connecting to OBD adapter ($connectionMode)...")
                    val connected = if (connectionMode == "wifi") {
                        connectWifi()
                    } else {
                        connectBluetooth()
                    }

                    if (connected) {
                        isConnected = true
                        notifyStatus(true, "Connected & Initializing ELM327...")
                        if (initializeElm327()) {
                            notifyStatus(true, "Online - Telemetry Streaming")
                            pollPidsLoop()
                        } else {
                            Log.w(TAG, "ELM327 initialization failed. Reconnecting in 3s...")
                            disconnectCurrentSocket()
                        }
                    } else {
                        Log.w(TAG, "Socket connection failed. Retrying in 4s...")
                    }
                }
                delay(4000)
            }
        }
    }

    private fun connectBluetooth(): Boolean {
        val btAdapter = BluetoothAdapter.getDefaultAdapter() ?: return false
        if (!btAdapter.isEnabled) return false

        try {
            val device: BluetoothDevice? = if (!targetDeviceAddress.isNullOrEmpty()) {
                btAdapter.getRemoteDevice(targetDeviceAddress)
            } else {
                // Auto-detect paired OBD adapter
                btAdapter.bondedDevices.firstOrNull { d ->
                    val name = (d.name ?: "").uppercase()
                    name.contains("OBD") || name.contains("ELM") || name.contains("VGATE") || name.contains("LINK")
                }
            }

            if (device == null) {
                Log.w(TAG, "No paired OBD-II device found.")
                return false
            }

            btAdapter.cancelDiscovery()
            val socket = device.createRfcommSocketToServiceRecord(SPP_UUID)
            socket.connect()

            bluetoothSocket = socket
            inputStream = socket.inputStream
            outputStream = socket.outputStream
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Bluetooth connection error: ${e.message}")
            disconnectCurrentSocket()
            return false
        }
    }

    private fun connectWifi(): Boolean {
        try {
            val socket = Socket()
            socket.connect(InetSocketAddress(wifiHost, wifiPort), 4000)
            wifiSocket = socket
            inputStream = socket.getInputStream()
            outputStream = socket.getOutputStream()
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Wi-Fi socket connection error: ${e.message}")
            disconnectCurrentSocket()
            return false
        }
    }

    private suspend fun initializeElm327(): Boolean {
        return withContext(Dispatchers.IO) {
            try {
                // Flush buffer
                clearInputBuffer()

                // Initialization AT commands for ELM327
                sendRawCommandInternal("ATZ")   // Reset
                delay(800)
                sendRawCommandInternal("ATE0")  // Echo Off
                delay(100)
                sendRawCommandInternal("ATL0")  // Linefeeds Off
                delay(100)
                sendRawCommandInternal("ATS0")  // Spaces Off
                delay(100)
                sendRawCommandInternal("ATH0")  // Headers Off
                delay(100)
                // Set protocol to ISO 15765-4 CAN (11-bit 500k) for 2012 Accord (ATSP6) or Auto (ATSP0)
                sendRawCommandInternal("ATSP0")
                delay(200)

                // Verify communication with voltage query
                val voltResp = sendRawCommandInternal("ATRV")
                Log.i(TAG, "ELM327 initialized. Initial Battery Voltage: $voltResp")
                true
            } catch (e: Exception) {
                Log.e(TAG, "Initialization failed: ${e.message}")
                false
            }
        }
    }

    private suspend fun pollPidsLoop() {
        var cycleCounter = 0
        while (isRunning && isConnected) {
            try {
                // High frequency PID: Speed (010D) & RPM (010C) - polled every ~250ms
                val speedRaw = sendRawCommandInternal("010D")
                parseSpeed(speedRaw)

                val rpmRaw = sendRawCommandInternal("010C")
                parseRpm(rpmRaw)

                // Medium frequency PID: Coolant (0105) & Voltage (ATRV) - polled every ~1.5s
                if (cycleCounter % 4 == 0) {
                    val coolantRaw = sendRawCommandInternal("0105")
                    parseCoolant(coolantRaw)

                    val voltRaw = sendRawCommandInternal("ATRV")
                    parseVoltage(voltRaw)
                }

                // Low frequency PID: Intake Air Temp (010F) & Throttle (0111) - polled every ~3s
                if (cycleCounter % 8 == 0) {
                    val intakeRaw = sendRawCommandInternal("010F")
                    parseIntakeTemp(intakeRaw)

                    val throttleRaw = sendRawCommandInternal("0111")
                    parseThrottle(throttleRaw)
                }

                cycleCounter++
                emitTelemetry()
                delay(250)
            } catch (e: Exception) {
                Log.e(TAG, "PID poll error: ${e.message}")
                isConnected = false
                disconnectCurrentSocket()
                break
            }
        }
    }

    @Synchronized
    private fun sendRawCommandInternal(command: String): String {
        val out = outputStream ?: throw IllegalStateException("OutputStream is null")
        val input = inputStream ?: throw IllegalStateException("InputStream is null")

        val cmdFormatted = (command.trim() + "\r").toByteArray(Charsets.US_ASCII)
        out.write(cmdFormatted)
        out.flush()

        val sb = StringBuilder()
        val buffer = ByteArray(256)
        val startTime = System.currentTimeMillis()

        while (System.currentTimeMillis() - startTime < 1200) {
            if (input.available() > 0) {
                val len = input.read(buffer)
                if (len > 0) {
                    val chunk = String(buffer, 0, len, Charsets.US_ASCII)
                    sb.append(chunk)
                    if (sb.contains(">")) {
                        break
                    }
                }
            } else {
                Thread.sleep(15)
            }
        }
        return sb.toString().replace(">", "").replace("\r", " ").replace("\n", " ").trim()
    }

    fun executeRawCommandPublic(cmd: String): String {
        return try {
            if (!isConnected) return "Error: Not connected to OBD adapter"
            sendRawCommandInternal(cmd)
        } catch (e: Exception) {
            "Error: ${e.message}"
        }
    }

    private fun parseSpeed(raw: String) {
        val clean = raw.replace(" ", "").uppercase()
        val index = clean.indexOf("410D")
        if (index != -1 && clean.length >= index + 6) {
            val hex = clean.substring(index + 4, index + 6)
            try {
                lastSpeed = hex.toInt(16)
            } catch (ignored: Exception) {}
        }
    }

    private fun parseRpm(raw: String) {
        val clean = raw.replace(" ", "").uppercase()
        val index = clean.indexOf("410C")
        if (index != -1 && clean.length >= index + 8) {
            val hexA = clean.substring(index + 4, index + 6)
            val hexB = clean.substring(index + 6, index + 8)
            try {
                val a = hexA.toInt(16)
                val b = hexB.toInt(16)
                lastRpm = ((a * 256) + b) / 4
            } catch (ignored: Exception) {}
        }
    }

    private fun parseCoolant(raw: String) {
        val clean = raw.replace(" ", "").uppercase()
        val index = clean.indexOf("4105")
        if (index != -1 && clean.length >= index + 6) {
            val hex = clean.substring(index + 4, index + 6)
            try {
                lastCoolant = hex.toInt(16) - 40
            } catch (ignored: Exception) {}
        }
    }

    private fun parseVoltage(raw: String) {
        val clean = raw.replace("V", "").trim()
        val parts = clean.split(" ")
        for (p in parts) {
            try {
                val v = p.toDouble()
                if (v in 5.0..20.0) {
                    lastVoltage = v
                    break
                }
            } catch (ignored: Exception) {}
        }
    }

    private fun parseIntakeTemp(raw: String) {
        val clean = raw.replace(" ", "").uppercase()
        val index = clean.indexOf("410F")
        if (index != -1 && clean.length >= index + 6) {
            val hex = clean.substring(index + 4, index + 6)
            try {
                lastIntakeTemp = hex.toInt(16) - 40
            } catch (ignored: Exception) {}
        }
    }

    private fun parseThrottle(raw: String) {
        val clean = raw.replace(" ", "").uppercase()
        val index = clean.indexOf("4111")
        if (index != -1 && clean.length >= index + 6) {
            val hex = clean.substring(index + 4, index + 6)
            try {
                val a = hex.toInt(16)
                lastThrottle = (a * 100) / 255
            } catch (ignored: Exception) {}
        }
    }

    private fun emitTelemetry() {
        val data = mapOf(
            "speed" to lastSpeed,
            "rpm" to lastRpm,
            "coolantTemp" to lastCoolant,
            "voltage" to lastVoltage,
            "intakeTemp" to lastIntakeTemp,
            "throttle" to lastThrottle,
            "isConnected" to true,
            "statusMessage" to "Active"
        )
        mainHandler.post {
            eventSink?.success(data)
        }
    }

    private fun notifyStatus(connected: Boolean, message: String) {
        val data = mapOf(
            "speed" to lastSpeed,
            "rpm" to lastRpm,
            "coolantTemp" to lastCoolant,
            "voltage" to lastVoltage,
            "intakeTemp" to lastIntakeTemp,
            "throttle" to lastThrottle,
            "isConnected" to connected,
            "statusMessage" to message
        )
        mainHandler.post {
            eventSink?.success(data)
        }
    }

    private fun clearInputBuffer() {
        try {
            while ((inputStream?.available() ?: 0) > 0) {
                inputStream?.read()
            }
        } catch (ignored: Exception) {}
    }

    private fun disconnectCurrentSocket() {
        isConnected = false
        try {
            inputStream?.close()
            outputStream?.close()
            bluetoothSocket?.close()
            wifiSocket?.close()
        } catch (ignored: Exception) {}
        inputStream = null
        outputStream = null
        bluetoothSocket = null
        wifiSocket = null
    }

    fun getPairedBluetoothDevices(): List<Map<String, String>> {
        val btAdapter = BluetoothAdapter.getDefaultAdapter() ?: return emptyList()
        if (!btAdapter.isEnabled) return emptyList()

        return btAdapter.bondedDevices.map { device ->
            mapOf(
                "name" to (device.name ?: "Unknown Device"),
                "address" to device.address
            )
        }
    }
}

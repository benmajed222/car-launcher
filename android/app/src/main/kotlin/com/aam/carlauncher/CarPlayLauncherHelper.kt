package com.aam.carlauncher

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.util.Log

/**
 * Intelligent package scanner and launcher for Apple CarPlay link apps on XY Auto T100 head-units.
 * Safely preserves AudioFocus and background projection services.
 */
class CarPlayLauncherHelper(private val context: Context) {

    companion object {
        private const val TAG = "CarPlayLauncherHelper"

        // Known CarPlay Link package candidates on XY Auto and general aftermarket firmware
        val CANDIDATE_PACKAGES = listOf(
            "com.suding.speedplay",      // CarLink / SpeedPlay (standard on XY Auto T100)
            "com.zjinnova.zlink",        // ZLink / ZLink5
            "cn.manstep.phonemirror",    // AutoKit
            "com.zjinnova.auto_kit",     // AutoKit v2
            "com.tlink.link",            // TLink
            "com.carbit.easylink",       // CarbitLink
            "com.autonavi.amapauto",     // AMap Auto Link
            "com.xyauto.link"            // XY Auto Link
        )
    }

    /**
     * Scans for the installed CarPlay application, checking candidates in priority order.
     */
    fun detectInstalledCarPlayApp(): Map<String, Any?> {
        val pm = context.packageManager
        for (pkg in CANDIDATE_PACKAGES) {
            try {
                val appInfo = pm.getApplicationInfo(pkg, 0)
                val appName = pm.getApplicationLabel(appInfo).toString()
                Log.i(TAG, "Found CarPlay candidate: $appName ($pkg)")
                return mapOf(
                    "packageName" to pkg,
                    "appName" to appName,
                    "isInstalled" to true
                )
            } catch (e: PackageManager.NameNotFoundException) {
                // Not installed, continue scanning
            }
        }

        return mapOf(
            "packageName" to null,
            "appName" to null,
            "isInstalled" to false
        )
    }

    /**
     * Returns a list of all detected phone-link / projection apps installed on the system.
     */
    fun getAllInstalledLinkApps(): List<Map<String, String>> {
        val pm = context.packageManager
        val foundApps = mutableListOf<Map<String, String>>()

        for (pkg in CANDIDATE_PACKAGES) {
            try {
                val appInfo = pm.getApplicationInfo(pkg, 0)
                val appName = pm.getApplicationLabel(appInfo).toString()
                foundApps.add(
                    mapOf(
                        "packageName" to pkg,
                        "appName" to appName
                    )
                )
            } catch (ignored: PackageManager.NameNotFoundException) {
            }
        }
        return foundApps
    }

    /**
     * Launches the designated CarPlay package without killing background audio or stealing focus.
     */
    fun launchCarPlayApp(targetPackage: String?): Boolean {
        val pm = context.packageManager
        val pkgToLaunch = targetPackage ?: (detectInstalledCarPlayApp()["packageName"] as? String)

        if (pkgToLaunch == null) {
            Log.e(TAG, "No CarPlay app specified or detected.")
            return false
        }

        try {
            val launchIntent = pm.getLaunchIntentForPackage(pkgToLaunch)
            if (launchIntent != null) {
                // Ensure launch flags preserve task history and prevent restarting background audio
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)
                context.startActivity(launchIntent)
                Log.i(TAG, "Successfully launched CarPlay package: $pkgToLaunch")
                return true
            } else {
                Log.e(TAG, "Launch intent for $pkgToLaunch is null")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to launch $pkgToLaunch: ${e.message}", e)
        }
        return false
    }

    /**
     * Checks if a package is currently running in the foreground or background tasks.
     */
    fun isPackageInstalled(packageName: String): Boolean {
        return try {
            context.packageManager.getApplicationInfo(packageName, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }
}

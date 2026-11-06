package com.asec.app

import android.app.Activity
import android.content.pm.ApplicationInfo
import android.os.Build
import android.os.Bundle
import android.os.Debug
import android.provider.Settings
import android.view.WindowManager
import java.io.File
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// FLAG_SECURE: Android refuses screenshots of this window, screen
/// recordings and casting show it as black, and the recent-apps thumbnail is
/// blank. Set before the first frame so nothing is ever captured unprotected.
///
/// The super admin can lift it from Settings → Control centre → "Block
/// screenshots": Dart calls `asec/screen_protection` → `setEnabled(bool)`
/// (lib/core/settings/screen_protection.dart).
///
/// SCREEN CAPTURE ALERTS: on Android 14+ a screenshot, and on Android 15+ a
/// screen recording that shows this app, is reported to Dart as
/// `captured("screenshot" | "recording")` on the same channel; Dart saves it
/// for the admin (lib/features/admin/a2_members/data/device_security.dart).
class MainActivity : FlutterActivity() {
  private var channel: MethodChannel? = null

  // Kept as Any so older Android versions never load these API 34/35 types.
  private var screenshotCallback: Any? = null
  private var recordingCallback: Any? = null

  private fun report(type: String) {
    runOnUiThread { channel?.invokeMethod("captured", type) }
  }

  override fun onStart() {
    super.onStart()
    if (Build.VERSION.SDK_INT >= 34 && screenshotCallback == null) {
      try {
        val cb = Activity.ScreenCaptureCallback { report("screenshot") }
        registerScreenCaptureCallback(mainExecutor, cb)
        screenshotCallback = cb
      } catch (_: Throwable) {}
    }
    if (Build.VERSION.SDK_INT >= 35 && recordingCallback == null) {
      try {
        val rc = java.util.function.Consumer<Int> { state ->
          if (state == WindowManager.SCREEN_RECORDING_STATE_VISIBLE) report("recording")
        }
        val now = windowManager.addScreenRecordingCallback(mainExecutor, rc)
        recordingCallback = rc
        if (now == WindowManager.SCREEN_RECORDING_STATE_VISIBLE) report("recording")
      } catch (_: Throwable) {}
    }
  }

  override fun onStop() {
    if (Build.VERSION.SDK_INT >= 34) {
      (screenshotCallback as? Activity.ScreenCaptureCallback)?.let {
        try { unregisterScreenCaptureCallback(it) } catch (_: Throwable) {}
      }
      screenshotCallback = null
    }
    if (Build.VERSION.SDK_INT >= 35) {
      @Suppress("UNCHECKED_CAST")
      (recordingCallback as? java.util.function.Consumer<Int>)?.let {
        try { windowManager.removeScreenRecordingCallback(it) } catch (_: Throwable) {}
      }
      recordingCallback = null
    }
    super.onStop()
  }

  override fun onCreate(savedInstanceState: Bundle?) {
    window.setFlags(
      WindowManager.LayoutParams.FLAG_SECURE,
      WindowManager.LayoutParams.FLAG_SECURE,
    )
    super.onCreate(savedInstanceState)
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "asec/screen_protection")
    channel = ch
    ch.setMethodCallHandler { call, result ->
        if (call.method == "setEnabled") {
          val on = call.arguments as? Boolean ?: true
          runOnUiThread {
            if (on) {
              window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
            } else {
              window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            }
          }
          result.success(null)
        } else if (call.method == "stableId") {
          // lib/.../device_identity.dart — ANDROID_ID stays the same for this
          // app on this phone after an uninstall / reinstall (Android 8+), so
          // a reinstall is not "another device".
          val id = try {
            Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
          } catch (_: Throwable) { null }
          result.success(id)
        } else if (call.method == "integrity") {
          // lib/core/settings/app_integrity.dart — a release build refuses
          // to run while any of these is found.
          result.success(integrityIssues())
        } else {
          result.notImplemented()
        }
      }
  }

  /// What makes this device unsafe for the lessons: developer options, USB
  /// debugging, an attached debugger, a debuggable (re-signed) build, root,
  /// or a hooking framework (Frida / Xposed).
  private fun integrityIssues(): List<String> {
    val issues = mutableListOf<String>()
    val cr = contentResolver
    try {
      if (Settings.Global.getInt(cr, Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0) != 0) {
        issues.add("developer_options")
      }
      if (Settings.Global.getInt(cr, Settings.Global.ADB_ENABLED, 0) != 0) {
        issues.add("usb_debugging")
      }
    } catch (_: Throwable) {}
    if (Debug.isDebuggerConnected() || Debug.waitingForDebugger()) issues.add("debugger")
    if ((applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0) issues.add("debuggable")

    val rootPaths = listOf(
      "/system/bin/su", "/system/xbin/su", "/sbin/su", "/su/bin/su",
      "/data/local/su", "/data/local/xbin/su", "/data/local/bin/su",
      "/system/sd/xbin/su", "/system/app/Superuser.apk", "/data/adb/magisk",
      "/sbin/.magisk", "/system/bin/.ext/su",
    )
    if (rootPaths.any { File(it).exists() } || (Build.TAGS?.contains("test-keys") == true)) {
      issues.add("root")
    }

    val hookPaths = listOf("/data/local/tmp/frida-server", "/data/local/tmp/re.frida.server")
    var hooked = hookPaths.any { File(it).exists() }
    try {
      Class.forName("de.robv.android.xposed.XposedBridge")
      hooked = true
    } catch (_: Throwable) {}
    try {
      File("/proc/self/maps").useLines { lines ->
        if (lines.any { it.contains("frida", true) || it.contains("xposed", true) || it.contains("lsposed", true) }) {
          hooked = true
        }
      }
    } catch (_: Throwable) {}
    if (hooked) issues.add("hooking")
    return issues.distinct()
  }
}

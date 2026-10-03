package com.thomasgrsst.ciguard

import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.os.Build
import android.os.PersistableBundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ciguard/secure").setMethodCallHandler { call, result ->
            val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            when (call.method) {
                "setSecure" -> {
                    if (call.arguments as? Boolean != false) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                }
                "copy" -> {
                    val clip = ClipData.newPlainText("CiGuard", call.arguments as? String ?: "")
                    // Masque le contenu dans l'aperçu du presse-papiers d'Android 13+.
                    clip.description.extras = PersistableBundle().apply {
                        if (Build.VERSION.SDK_INT >= 33) {
                            putBoolean(ClipDescription.EXTRA_IS_SENSITIVE, true)
                        } else {
                            putBoolean("android.content.extra.IS_SENSITIVE", true)
                        }
                    }
                    clipboard.setPrimaryClip(clip)
                    result.success(null)
                }
                "clearClipboard" -> {
                    if (Build.VERSION.SDK_INT >= 28) {
                        clipboard.clearPrimaryClip()
                    } else {
                        clipboard.setPrimaryClip(ClipData.newPlainText("", ""))
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}

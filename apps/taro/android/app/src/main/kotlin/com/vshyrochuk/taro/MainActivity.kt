package com.vshyrochuk.taro

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // UrlLauncher.openAppSettings (S22 notifications): the app details
        // screen, where notifications are turned back on.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "taro/app_settings")
            .setMethodCallHandler { call, result ->
                if (call.method != "open") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val intent = Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.fromParts("package", packageName, null),
                ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                result.success(
                    try {
                        startActivity(intent)
                        true
                    } catch (_: Exception) {
                        false
                    },
                )
            }
    }
}

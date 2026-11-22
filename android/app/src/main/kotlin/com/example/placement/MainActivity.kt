package com.channeli.img.placementonline

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "channeli/app_info")
            .setMethodCallHandler { call, result ->
                if (call.method == "version") {
                    result.success(packageManager.getPackageInfo(packageName, 0).versionName)
                } else {
                    result.notImplemented()
                }
            }
        NoticeNotifications.createChannel(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "placement_v2/notifications")
            .setMethodCallHandler { call, result ->
                if (call.method == "show") {
                    NoticeNotifications.show(this, call.argument<String>("title"), call.argument<String>("body"))
                    result.success(null)
                } else result.notImplemented()
            }
    }
}
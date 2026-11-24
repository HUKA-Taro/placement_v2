package com.channeli.img.placementonline

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val policyCache = getSharedPreferences("app_version_policy", MODE_PRIVATE)
        MethodChannel(messenger, "channeli/app_info").setMethodCallHandler { call, result ->
            when (call.method) {
                "androidIdHash" -> {
                    val androidId = Settings.Secure.getString(
                        contentResolver, Settings.Secure.ANDROID_ID
                    )
                    val hash = androidId?.let { value ->
                        java.security.MessageDigest.getInstance("SHA-256")
                            .digest(value.toByteArray(Charsets.UTF_8))
                            .joinToString("") { byte -> "%02x".format(byte.toInt() and 0xff) }
                    }
                    result.success(hash)
                }
                "version" -> result.success(packageManager.getPackageInfo(packageName, 0).versionName)
                "buildNumber" -> {
                    val info = packageManager.getPackageInfo(packageName, 0)
                    @Suppress("DEPRECATION")
                    val number = if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()
                    result.success(number)
                }
                "readVersionPolicy" -> result.success(policyCache.getString("policy", null))
                "writeVersionPolicy" -> {
                    policyCache.edit().putString("policy", call.argument<String>("policy")).apply()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        NoticeNotifications.createChannel(this)
        MethodChannel(messenger, "placement_v2/notifications").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "allowed" -> result.success(NotificationManagerCompat.from(this).areNotificationsEnabled())
                    "openSettings" -> {
                        val settings = if (Build.VERSION.SDK_INT >= 26) {
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                        } else {
                            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                Uri.fromParts("package", packageName, null))
                        }
                        startActivity(settings)
                        result.success(null)
                    }
                    "show" -> {
                        if (!NotificationManagerCompat.from(this).areNotificationsEnabled()) {
                            result.error("permission_denied", "Enable notifications in Android settings.", null)
                        } else {
                            NoticeNotifications.show(this, call.argument<String>("title"), call.argument<String>("body"))
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            } catch (error: Exception) {
                result.error("notifications_unavailable", "Could not complete the notification action.", null)
            }
        }
    }
}

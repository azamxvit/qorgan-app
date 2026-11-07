package kz.qorgan.qorgan_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings

class MainActivity : FlutterActivity() {
    private val permissionHistory by lazy {
        getSharedPreferences("qorgan_permission_requests", MODE_PRIVATE)
    }

    private fun canRequest(permission: String, key: String): Boolean =
        checkSelfPermission(permission) != PackageManager.PERMISSION_GRANTED &&
            (!permissionHistory.getBoolean(key, false) ||
                shouldShowRequestPermissionRationale(permission))

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kz.qorgan/protection")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "smsGranted" -> result.success(checkSelfPermission(Manifest.permission.RECEIVE_SMS) == PackageManager.PERMISSION_GRANTED)
                    "canRequestSms" -> result.success(canRequest(Manifest.permission.RECEIVE_SMS, "sms"))
                    "canRequestNotifications" -> result.success(
                        Build.VERSION.SDK_INT >= 33 && canRequest(Manifest.permission.POST_NOTIFICATIONS, "notifications")
                    )
                    "noteSmsRequested" -> {
                        permissionHistory.edit().putBoolean("sms", true).apply()
                        result.success(null)
                    }
                    "noteNotificationsRequested" -> {
                        permissionHistory.edit().putBoolean("notifications", true).apply()
                        result.success(null)
                    }
                    "openSettings" -> {
                        startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName")))
                        result.success(null)
                    }
                    "openNotificationSettings" -> {
                        val intent = if (Build.VERSION.SDK_INT >= 26) {
                            Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS)
                                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                                .putExtra(Settings.EXTRA_CHANNEL_ID, "qorgan_sms_warnings")
                        } else {
                            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))
                        }
                        startActivity(intent)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}

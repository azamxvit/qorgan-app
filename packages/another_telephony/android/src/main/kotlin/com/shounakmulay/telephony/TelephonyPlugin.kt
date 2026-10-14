// Adapted from another_telephony 0.4.1. MIT, Copyright (c) 2020 Shounak Mulay.
package com.shounakmulay.telephony
import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import com.shounakmulay.telephony.sms.IncomingSmsHandler
import com.shounakmulay.telephony.sms.IncomingSmsReceiver
import com.shounakmulay.telephony.utils.Constants
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class TelephonyPlugin : FlutterPlugin, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private var binding: ActivityPluginBinding? = null
    private var permissionResult: MethodChannel.Result? = null
    private var foregroundReady = false
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, Constants.CHANNEL_SMS)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "sdkInt" -> result.success(Build.VERSION.SDK_INT)
                "startBackgroundService" -> {
                    try {
                        val setup = call.argument<Number>("setupHandle")!!.toLong()
                        val background = call.argument<Number>("backgroundHandle")!!.toLong()
                        IncomingSmsHandler.setBackgroundSetupHandle(context, setup)
                        IncomingSmsHandler.setBackgroundMessageHandle(context, background)
                        check(context.getSharedPreferences(Constants.SHARED_PREFERENCES_NAME, Context.MODE_PRIVATE)
                            .edit().putBoolean(Constants.SHARED_PREFS_DISABLE_BACKGROUND_EXE, false).commit())
                        foregroundReady = true
                        if (activity != null) IncomingSmsReceiver.foregroundSmsChannel = channel
                        result.success(null)
                    } catch (_: Exception) { result.error("registration_failed", "Cannot register SMS callback", null) }
                }
                "requestSmsPermissions" -> {
                    if (context.checkSelfPermission(Manifest.permission.RECEIVE_SMS) == PackageManager.PERMISSION_GRANTED) result.success(true)
                    else if (activity == null || permissionResult != null) result.success(false)
                    else {
                        permissionResult = result
                        activity!!.requestPermissions(arrayOf(Manifest.permission.RECEIVE_SMS), 7301)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.binding = binding
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
        if (foregroundReady) IncomingSmsReceiver.foregroundSmsChannel = channel
    }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        if (requestCode != 7301) return false
        permissionResult?.success(grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED)
        permissionResult = null
        return true
    }
    override fun onDetachedFromActivity() {
        binding?.removeRequestPermissionsResultListener(this)
        binding = null
        activity = null
        if (IncomingSmsReceiver.foregroundSmsChannel === channel) IncomingSmsReceiver.foregroundSmsChannel = null
        permissionResult?.success(false)
        permissionResult = null
    }
    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = onAttachedToActivity(binding)
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        if (IncomingSmsReceiver.foregroundSmsChannel === channel) IncomingSmsReceiver.foregroundSmsChannel = null
        channel.setMethodCallHandler(null)
    }
}

// Adapted from another_telephony 0.4.1, MIT, Copyright (c) 2020 Shounak Mulay.
// Qorgan: hold broadcast until Dart completion; preserve multipart whitespace;
// prevent concurrent cold engine starts; persist callback registration synchronously.
package com.shounakmulay.telephony.sms

import android.app.ActivityManager
import android.app.KeyguardManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.provider.Telephony
import android.telephony.SmsMessage
import com.shounakmulay.telephony.utils.Constants
import com.shounakmulay.telephony.utils.Constants.HANDLE
import com.shounakmulay.telephony.utils.Constants.HANDLE_BACKGROUND_MESSAGE
import com.shounakmulay.telephony.utils.Constants.MESSAGE
import com.shounakmulay.telephony.utils.Constants.MESSAGE_BODY
import com.shounakmulay.telephony.utils.Constants.ON_MESSAGE
import com.shounakmulay.telephony.utils.Constants.ORIGINATING_ADDRESS
import com.shounakmulay.telephony.utils.Constants.SERVICE_CENTER_ADDRESS
import com.shounakmulay.telephony.utils.Constants.SHARED_PREFERENCES_NAME
import com.shounakmulay.telephony.utils.Constants.SHARED_PREFS_BACKGROUND_MESSAGE_HANDLE
import com.shounakmulay.telephony.utils.Constants.SHARED_PREFS_BACKGROUND_SETUP_HANDLE
import com.shounakmulay.telephony.utils.Constants.SHARED_PREFS_DISABLE_BACKGROUND_EXE
import com.shounakmulay.telephony.utils.Constants.STATUS
import com.shounakmulay.telephony.utils.Constants.TIMESTAMP
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation
import java.util.concurrent.atomic.AtomicBoolean

class IncomingSmsReceiver : BroadcastReceiver() {
    companion object { var foregroundSmsChannel: MethodChannel? = null }
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return
        ContextHolder.applicationContext = context.applicationContext
        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            .groupBy { it.originatingAddress }.values
        if (messages.isEmpty()) return
        val pending = goAsync()
        val handler = Handler(Looper.getMainLooper())
        val finished = AtomicBoolean(false)
        var remaining = messages.size
        val timeout = Runnable { if (finished.compareAndSet(false, true)) pending.finish() }
        handler.postDelayed(timeout, 9000)
        val done = {
            remaining -= 1
            if (remaining == 0 && finished.compareAndSet(false, true)) {
                handler.removeCallbacks(timeout)
                pending.finish()
            }
            Unit
        }
        messages.forEach { parts ->
            val message = parts.first().toMap()
            message[MESSAGE_BODY] = parts.joinToString("") { it.messageBody.orEmpty() }
            val channel = foregroundSmsChannel
            if (channel != null && IncomingSmsHandler.isApplicationForeground(context)) {
                channel.invokeMethod(ON_MESSAGE, mapOf(MESSAGE to message), completion(done))
            } else {
                IncomingSmsHandler.enqueue(context.applicationContext, message, done)
            }
        }
    }
}

private fun completion(done: () -> Unit) = object : MethodChannel.Result {
    override fun success(result: Any?) = done()
    override fun error(code: String, message: String?, details: Any?) = done()
    override fun notImplemented() = done()
}

fun SmsMessage.toMap(): HashMap<String, Any?> = hashMapOf(
    MESSAGE_BODY to messageBody, TIMESTAMP to timestampMillis.toString(),
    ORIGINATING_ADDRESS to originatingAddress, STATUS to status.toString(),
    SERVICE_CENTER_ADDRESS to serviceCenterAddress
)

object IncomingSmsHandler : MethodChannel.MethodCallHandler {
    private data class Delivery(val message: HashMap<String, Any?>, val done: () -> Unit)
    private val queue = mutableListOf<Delivery>()
    private var engine: FlutterEngine? = null
    private var channel: MethodChannel? = null
    private var ready = false
    private var starting = false
    private var appContext: Context? = null

    fun enqueue(context: Context, message: HashMap<String, Any?>, done: () -> Unit) {
        val prefs = context.getSharedPreferences(SHARED_PREFERENCES_NAME, Context.MODE_PRIVATE)
        val setup = prefs.getLong(SHARED_PREFS_BACKGROUND_SETUP_HANDLE, 0)
        if (prefs.getBoolean(SHARED_PREFS_DISABLE_BACKGROUND_EXE, false) || setup == 0L) {
            done(); return
        }
        appContext = context
        val delivery = Delivery(message, done)
        if (ready) { deliver(delivery); return }
        queue.add(delivery)
        if (starting) return
        starting = true
        try {
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(context)
            loader.ensureInitializationComplete(context, null)
            val callback = FlutterCallbackInformation.lookupCallbackInformation(setup)
                ?: throw IllegalStateException("SMS callback unavailable")
            engine = FlutterEngine(context)
            channel = MethodChannel(engine!!.dartExecutor, Constants.CHANNEL_SMS_BACKGROUND)
            channel!!.setMethodCallHandler(this)
            engine!!.dartExecutor.executeDartCallback(DartExecutor.DartCallback(context.assets, loader.findAppBundlePath(), callback))
        } catch (_: Exception) {
            starting = false
            queue.toList().forEach { it.done() }
            queue.clear()
        }
    }
    private fun deliver(delivery: Delivery) {
        val context = appContext ?: run { delivery.done(); return }
        val handle = context.getSharedPreferences(SHARED_PREFERENCES_NAME, Context.MODE_PRIVATE)
            .getLong(SHARED_PREFS_BACKGROUND_MESSAGE_HANDLE, 0)
        channel!!.invokeMethod(HANDLE_BACKGROUND_MESSAGE, mapOf(HANDLE to handle, MESSAGE to delivery.message), completion(delivery.done))
    }
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "backgroundServiceInitialized") {
            ready = true
            starting = false
            queue.toList().forEach { deliver(it) }
            queue.clear()
            result.success(null)
        } else result.notImplemented()
    }
    fun onChannelInitialized(context: Context) {
        appContext = context.applicationContext
        ready = true
        starting = false
        queue.toList().forEach { deliver(it) }
        queue.clear()
    }
    fun setBackgroundMessageHandle(context: Context, handle: Long) {
        check(context.getSharedPreferences(SHARED_PREFERENCES_NAME, Context.MODE_PRIVATE)
            .edit().putLong(SHARED_PREFS_BACKGROUND_MESSAGE_HANDLE, handle).commit())
    }
    fun setBackgroundSetupHandle(context: Context, handle: Long) {
        check(context.getSharedPreferences(SHARED_PREFERENCES_NAME, Context.MODE_PRIVATE)
            .edit().putLong(SHARED_PREFS_BACKGROUND_SETUP_HANDLE, handle).commit())
    }
    fun isApplicationForeground(context: Context): Boolean {
        if ((context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager).isKeyguardLocked) return false
        return (context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager)
            .runningAppProcesses?.any { it.pid == Process.myPid() && it.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND } == true
    }
}

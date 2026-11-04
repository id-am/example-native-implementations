package com.example.call_state

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.telephony.PhoneStateListener
import android.telephony.TelephonyCallback
import android.telephony.TelephonyManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class CallStatePlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var telephonyManager: TelephonyManager? = null

    private var modernCallback: TelephonyCallback? = null
    @Suppress("DEPRECATION")
    private var legacyListener: PhoneStateListener? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
        methodChannel = MethodChannel(binding.binaryMessenger, "call_state/methods")
        methodChannel.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, "call_state/events")
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        stopListening()
    }

    private fun hasPermission(): Boolean =
        ContextCompat.checkSelfPermission(context, Manifest.permission.READ_PHONE_STATE) ==
            PackageManager.PERMISSION_GRANTED

    private fun map(state: Int): String = when (state) {
        TelephonyManager.CALL_STATE_RINGING -> "ringing"
        TelephonyManager.CALL_STATE_OFFHOOK -> "active"
        else -> "idle"
    }

    @Suppress("DEPRECATION")
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getCallStatus" -> {
                val tm = telephonyManager
                if (tm == null) {
                    result.error("unavailable", "Telephony service not available", null)
                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !hasPermission()) {
                    result.error("permission_denied", "READ_PHONE_STATE not granted", null)
                } else {
                    result.success(map(tm.callState))
                }
            }
            else -> result.notImplemented()
        }
    }

    @Suppress("DEPRECATION")
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        val tm = telephonyManager
        if (events == null) return
        if (tm == null) {
            events.error("unavailable", "Telephony service not available", null)
            return
        }
        if (!hasPermission()) {
            events.error("permission_denied", "READ_PHONE_STATE not granted", null)
            return
        }
        stopListening()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val cb = object : TelephonyCallback(), TelephonyCallback.CallStateListener {
                override fun onCallStateChanged(state: Int) {
                    events.success(map(state))
                }
            }
            modernCallback = cb
            tm.registerTelephonyCallback(ContextCompat.getMainExecutor(context), cb)
        } else {
            // PhoneStateListener must be created on a thread with a Looper.
            mainHandler.post {
                val l = object : PhoneStateListener() {
                    @Deprecated("Deprecated in Java")
                    override fun onCallStateChanged(state: Int, phoneNumber: String?) {
                        events.success(map(state))
                    }
                }
                legacyListener = l
                tm.listen(l, PhoneStateListener.LISTEN_CALL_STATE)
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        stopListening()
    }

    @Suppress("DEPRECATION")
    private fun stopListening() {
        val tm = telephonyManager ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            modernCallback?.let { tm.unregisterTelephonyCallback(it) }
            modernCallback = null
        } else {
            legacyListener?.let { l -> mainHandler.post { tm.listen(l, PhoneStateListener.LISTEN_NONE) } }
            legacyListener = null
        }
    }
}

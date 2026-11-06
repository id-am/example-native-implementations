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

/**
 * Conecta los canales de Flutter con el estado de llamadas de Android.
 *
 * El paquete admite Android 5.0 (API 21) en adelante. Desde Android 12 (API 31)
 * usa [TelephonyCallback]; en Android 5.0-11 (API 21-30) conserva
 * [PhoneStateListener] como alternativa compatible.
 */
class CallStatePlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var telephonyManager: TelephonyManager? = null

    private var modernCallback: TelephonyCallback? = null
    // PhoneStateListener se deprecó en Android 12 (API 31); se necesita para API 21-30.
    @Suppress("DEPRECATION")
    private var legacyListener: PhoneStateListener? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    /** Guarda el contexto y registra los canales de métodos y eventos de Flutter. */
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
        methodChannel = MethodChannel(binding.binaryMessenger, "call_state/methods")
        methodChannel.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, "call_state/events")
        eventChannel.setStreamHandler(this)
    }

    /** Desregistra los canales y detiene cualquier escucha de estado activa. */
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        stopListening()
    }

    /** Indica si la aplicación tiene concedido el permiso para leer el estado telefónico. */
    private fun hasPermission(): Boolean =
        ContextCompat.checkSelfPermission(context, Manifest.permission.READ_PHONE_STATE) ==
            PackageManager.PERMISSION_GRANTED

    /** Convierte los estados de Android a los valores de estado publicados por el paquete. */
    private fun map(state: Int): String = when (state) {
        TelephonyManager.CALL_STATE_RINGING -> "ringing"
        TelephonyManager.CALL_STATE_OFFHOOK -> "active"
        TelephonyManager.CALL_STATE_IDLE -> "idle"
        else -> "idle"
    }

    /**
     * Atiende las llamadas al canal de métodos; por ahora, obtiene el estado actual.
     *
     * [TelephonyManager.callState] está deprecado desde Android 12 (API 31), pero se
     * conserva aquí para consultar el estado actual en todas las versiones admitidas.
     */
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

    /**
     * Inicia la escucha al suscribirse al canal de eventos y publica cambios de estado.
     *
     * Requiere READ_PHONE_STATE. Usa [TelephonyCallback] desde API 31 y la API
     * deprecada [PhoneStateListener] en API 21-30.
     */
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
        // Registra el callback o listener adecuado según la versión de Android.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val cb = object : TelephonyCallback(), TelephonyCallback.CallStateListener {
                /** Publica en el canal cada cambio de estado notificado por Android. */
                override fun onCallStateChanged(state: Int) {
                    events.success(map(state))
                }
            }
            modernCallback = cb
            tm.registerTelephonyCallback(ContextCompat.getMainExecutor(context), cb)
        } else {
            // PhoneStateListener crea un listener que debe ejecutarse en un hilo con un Looper.
            mainHandler.post {
                val l = object : PhoneStateListener() {
                    /** Publica en el canal cada cambio de estado notificado por Android. */
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

    /** Detiene la escucha cuando Flutter cancela la suscripción al canal de eventos. */
    override fun onCancel(arguments: Any?) {
        stopListening()
    }

    /**
     * Desregistra el callback o listener activo y limpia su referencia.
     *
     * [PhoneStateListener] y [TelephonyManager.listen] están deprecados desde
     * Android 12 (API 31); se usan solo en la rama para Android 5.0-11 (API 21-30).
     */
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

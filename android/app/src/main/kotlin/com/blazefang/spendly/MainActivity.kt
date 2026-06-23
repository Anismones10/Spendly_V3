package com.blazefang.spendly

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private val CHANNEL = "com.blazefang.spendly/biometric"
    private val WIDGET_CHANNEL = "com.blazefang.spendly/widget"

    // Holds the action extracted from the launching/new intent until
    // the Flutter engine is ready to receive it via MethodChannel.
    private var pendingWidgetAction: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // IMPORTANT: do NOT touch flutterEngine here — it does not exist yet.
        // Just capture the action; it will be sent once configureFlutterEngine runs.
        pendingWidgetAction = extractAction(intent)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Biometric channel
        val helper = BiometricHelper(this)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkAvailable" -> helper.checkAvailable(result)
                "authenticate" -> {
                    val title = call.argument<String>("title") ?: "Verify Identity"
                    helper.authenticate(title, result)
                }
                else -> result.notImplemented()
            }
        }

        // Engine is ready now — flush any pending widget action
        pendingWidgetAction?.let { action ->
            Log.d("SpendlyWidget", "Sending pending action (cold start): $action")
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
                .invokeMethod("onWidgetAction", action)
            pendingWidgetAction = null
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        // Activity (and its Flutter engine) already exists on warm start — safe to send now
        val action = extractAction(intent) ?: return
        Log.d("SpendlyWidget", "onNewIntent action (warm start): $action")
        try {
            MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
                .invokeMethod("onWidgetAction", action)
        } catch (e: Exception) {
            Log.e("SpendlyWidget", "Failed to send widget action", e)
        }
    }

    private fun extractAction(intent: Intent?): String? {
        val action = intent?.getStringExtra("widget_action") ?: return null
        if (action == "open") return null
        return action
    }
}
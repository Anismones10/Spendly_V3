package com.example.expense_tracker

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private val CHANNEL = "com.example.expense_tracker/biometric"
    private val WIDGET_CHANNEL = "com.example.expense_tracker/widget"

    private var pendingWidgetAction: String? = null

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

        // Send any pending widget action now that Flutter engine is ready
        pendingWidgetAction?.let { action ->
            Log.d("SpendlyWidget", "Sending pending action: $action")
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
                .invokeMethod("onWidgetAction", action)
            pendingWidgetAction = null
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleWidgetIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleWidgetIntent(intent)
    }

    private fun handleWidgetIntent(intent: Intent?) {
        val action = intent?.getStringExtra("widget_action") ?: return
        if (action == "open") return // plain open — do nothing extra
        Log.d("SpendlyWidget", "handleWidgetIntent action: $action")

        val engine = flutterEngine
        if (engine != null) {
            MethodChannel(engine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
                .invokeMethod("onWidgetAction", action)
        } else {
            // Engine not ready (cold start) — store and send in configureFlutterEngine
            pendingWidgetAction = action
        }
    }
}

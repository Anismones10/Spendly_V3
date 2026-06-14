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

    // Store action from cold-start intent until Flutter engine is ready
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

        // Flutter engine is now ready — send any pending widget action
        pendingWidgetAction?.let { action ->
            Log.d("SpendlyWidget", "Sending pending action to Flutter: $action")
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
                .invokeMethod("onWidgetAction", action)
            pendingWidgetAction = null
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        extractWidgetAction(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        // Engine is already running on warm start — send immediately
        val action = getSpendlyAction(intent) ?: return
        Log.d("SpendlyWidget", "onNewIntent action: $action")
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, WIDGET_CHANNEL).invokeMethod("onWidgetAction", action)
        }
    }

    private fun extractWidgetAction(intent: Intent?) {
        val action = getSpendlyAction(intent) ?: return
        Log.d("SpendlyWidget", "onCreate action: $action (engine ready: ${flutterEngine != null})")
        val engine = flutterEngine
        if (engine != null) {
            MethodChannel(engine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
                .invokeMethod("onWidgetAction", action)
        } else {
            // Engine not ready yet — store and send in configureFlutterEngine
            pendingWidgetAction = action
        }
    }

    private fun getSpendlyAction(intent: Intent?): String? {
        val uri = intent?.data ?: return null
        if (uri.scheme != "spendly") return null
        return uri.host
    }
}

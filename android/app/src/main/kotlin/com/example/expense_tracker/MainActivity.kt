package com.example.expense_tracker

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    // This is the "bridge" name — must match the Dart side exactly
    private val CHANNEL = "com.example.expense_tracker/biometric"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val helper = BiometricHelper(this)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkAvailable" -> helper.checkAvailable(result)
                "authenticate"   -> {
                    val title = call.argument<String>("title") ?: "Verify Identity"
                    helper.authenticate(title, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    // Forward new intents (e.g. widget deep links: spendly://add_expense)
    // to Flutter so home_widget's widgetClicked stream picks them up
    // even when MainActivity already exists (singleTop launch mode).
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
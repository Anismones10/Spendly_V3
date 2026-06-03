package com.example.expense_tracker

import androidx.biometric.BiometricManager
import androidx.biometric.BiometricManager.Authenticators.BIOMETRIC_WEAK
import androidx.biometric.BiometricManager.Authenticators.DEVICE_CREDENTIAL
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import io.flutter.plugin.common.MethodChannel

class BiometricHelper(private val activity: FragmentActivity) {

    // Check if any biometric is available on this device
    fun checkAvailable(result: MethodChannel.Result) {
        val manager = BiometricManager.from(activity)
        val available = manager.canAuthenticate(BIOMETRIC_WEAK or DEVICE_CREDENTIAL) ==
                BiometricManager.BIOMETRIC_SUCCESS
        result.success(available)
    }

    // Show the biometric prompt — works with weak face, strong face, fingerprint
    fun authenticate(title: String, result: MethodChannel.Result) {
        val executor = ContextCompat.getMainExecutor(activity)

        val callback = object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(
                r: BiometricPrompt.AuthenticationResult
            ) {
                result.success("success")
            }

            override fun onAuthenticationFailed() {
                // User tried but failed — let them try again, don't close
            }

            override fun onAuthenticationError(
                errorCode: Int, errString: CharSequence
            ) {
                // User cancelled or too many attempts
                result.success("cancelled")
            }
        }

        val prompt = BiometricPrompt(activity, executor, callback)

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle(title)
            .setSubtitle("Use biometric to access Spendly")
            // BIOMETRIC_WEAK = accepts ALL face types + fingerprint on all phones
            .setAllowedAuthenticators(BIOMETRIC_WEAK or DEVICE_CREDENTIAL)
            .build()

        activity.runOnUiThread {
            prompt.authenticate(promptInfo)
        }
    }
}

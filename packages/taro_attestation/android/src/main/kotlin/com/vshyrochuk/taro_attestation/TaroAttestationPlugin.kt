package com.vshyrochuk.taro_attestation

import android.content.Context
import com.google.android.play.core.integrity.IntegrityManagerFactory
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Android side of `taro_attestation` (02 AR9, §6.4; RC87): the Play Integrity
 * Standard API (`prepareStandard`, `requestStandardToken`) and
 * `Settings.Secure.ANDROID_ID` (`androidId`). The iOS methods answer
 * `notImplemented`, which the Dart side maps to `unsupported`.
 *
 * Errors are `Result.error(code)` with a code of [AttestationErrors]. Token
 * values and the ANDROID_ID are never put into an error message.
 */
class TaroAttestationPlugin
    @JvmOverloads
    constructor(
        private val integrityFactory: (Context) -> IntegrityProvider = ::playIntegrity,
        private val androidIdFactory: (Context) -> AndroidIdProvider = ::secureSettings,
    ) : FlutterPlugin,
        MethodCallHandler {
        private var channel: MethodChannel? = null
        private var integrity: IntegrityProvider? = null
        private var androidId: AndroidIdProvider? = null

        override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
            integrity = integrityFactory(binding.applicationContext)
            androidId = androidIdFactory(binding.applicationContext)
            channel =
                MethodChannel(binding.binaryMessenger, CHANNEL).also {
                    it.setMethodCallHandler(this)
                }
        }

        override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
            channel?.setMethodCallHandler(null)
            channel = null
            integrity = null
            androidId = null
        }

        override fun onMethodCall(
            call: MethodCall,
            result: Result,
        ) {
            val integrity = integrity
            val androidId = androidId
            if (integrity == null || androidId == null) {
                return result.error(AttestationErrors.UNSUPPORTED, "plugin is not attached", null)
            }
            when (call.method) {
                // The Standard API exists on every supported OS version;
                // prepareStandard proves that Play can serve it.
                "isSupported" -> result.success(true)
                "prepareStandard" -> prepare(integrity, call, result)
                "requestStandardToken" -> request(integrity, call, result)
                "androidId" -> result.success(androidId.androidId())
                else -> result.notImplemented()
            }
        }

        private fun prepare(
            integrity: IntegrityProvider,
            call: MethodCall,
            result: Result,
        ) {
            val number =
                call.argument<Number>("cloudProjectNumber")?.toLong()
                    ?: return result.error(AttestationErrors.REJECTED, "cloudProjectNumber is missing", null)
            integrity.prepare(number) { error ->
                if (error == null) result.success(null) else fail(result, error)
            }
        }

        private fun request(
            integrity: IntegrityProvider,
            call: MethodCall,
            result: Result,
        ) {
            val requestHash =
                call.argument<String>("requestHash")
                    ?: return result.error(AttestationErrors.REJECTED, "requestHash is missing", null)
            integrity.request(requestHash) { token ->
                token.fold(onSuccess = result::success, onFailure = { fail(result, it) })
            }
        }

        private fun fail(
            result: Result,
            error: Throwable,
        ) {
            result.error(AttestationErrors.codeOf(error), AttestationErrors.messageOf(error), null)
        }

        companion object {
            /** The method channel shared with the Dart side and iOS. */
            const val CHANNEL = "taro_attestation"

            internal fun playIntegrity(context: Context): IntegrityProvider =
                PlayIntegrityProvider(IntegrityManagerFactory.createStandard(context))

            internal fun secureSettings(context: Context): AndroidIdProvider =
                SecureSettingsAndroidIdProvider(context.contentResolver)
        }
    }

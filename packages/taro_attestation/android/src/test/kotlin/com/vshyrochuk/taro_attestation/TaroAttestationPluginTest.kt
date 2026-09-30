package com.vshyrochuk.taro_attestation

import android.content.ContentResolver
import android.content.Context
import com.google.android.play.core.integrity.model.StandardIntegrityErrorCode
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.ArgumentMatchers.any
import org.mockito.ArgumentMatchers.eq
import org.mockito.ArgumentMatchers.isNull
import org.mockito.Mockito.mock
import org.mockito.Mockito.verify
import org.mockito.Mockito.verifyNoInteractions
import org.mockito.Mockito.`when`
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertSame

/*
 * JVM unit tests of the Kotlin plugin code, measured with JaCoCo as the
 * coverage unit taro_attestation_android (06 §5.2, RC40). Run them with
 * `tools/ci/native_coverage_android.sh` or `./gradlew :taro_attestation:jacocoTestReport`
 * in `example/android/`.
 */

/** Scripted [IntegrityProvider]: answers with [prepareError] and [token]. */
private class FakeIntegrity : IntegrityProvider {
    var prepareError: Throwable? = null
    var token: Result<String> = Result.success("pi-token")
    val prepared = mutableListOf<Long>()
    val requested = mutableListOf<String>()

    override fun prepare(
        cloudProjectNumber: Long,
        done: (Throwable?) -> Unit,
    ) {
        prepared += cloudProjectNumber
        done(prepareError)
    }

    override fun request(
        requestHash: String,
        done: (Result<String>) -> Unit,
    ) {
        requested += requestHash
        done(token)
    }
}

internal class TaroAttestationPluginTest {
    private lateinit var integrity: FakeIntegrity
    private var androidIdValue: String? = "9774d56d682e549c"
    private lateinit var plugin: TaroAttestationPlugin
    private lateinit var binding: FlutterPlugin.FlutterPluginBinding
    private lateinit var messenger: BinaryMessenger
    private lateinit var context: Context
    private lateinit var result: MethodChannel.Result

    @BeforeTest
    fun setUp() {
        integrity = FakeIntegrity()
        context = mock(Context::class.java)
        messenger = mock(BinaryMessenger::class.java)
        binding = mock(FlutterPlugin.FlutterPluginBinding::class.java)
        `when`(binding.binaryMessenger).thenReturn(messenger)
        `when`(binding.applicationContext).thenReturn(context)
        result = mock(MethodChannel.Result::class.java)
        plugin =
            TaroAttestationPlugin(
                integrityFactory = { ctx ->
                    assertSame(context, ctx)
                    integrity
                },
                androidIdFactory = { ctx ->
                    assertSame(context, ctx)
                    AndroidIdProvider { androidIdValue }
                },
            )
        plugin.onAttachedToEngine(binding)
    }

    private fun call(
        method: String,
        arguments: Map<String, Any?>? = null,
    ) = plugin.onMethodCall(MethodCall(method, arguments), result)

    @Test
    fun attachAndDetach_registerAndClearTheChannelHandler() {
        verify(messenger).setMessageHandler(eq("taro_attestation"), any())
        plugin.onDetachedFromEngine(binding)
        verify(messenger).setMessageHandler(eq("taro_attestation"), isNull())
    }

    @Test
    fun detached_answersUnsupported() {
        plugin.onDetachedFromEngine(binding)
        call("isSupported")
        verify(result).error("unsupported", "plugin is not attached", null)
    }

    @Test
    fun detachWithoutAttach_isHarmless() {
        TaroAttestationPlugin().onDetachedFromEngine(binding)
    }

    @Test
    fun isSupported_isTrue() {
        call("isSupported")
        verify(result).success(true)
    }

    @Test
    fun prepareStandard_passesTheProjectNumber() {
        call("prepareStandard", mapOf("cloudProjectNumber" to 123456789012L))
        assertEquals(listOf(123456789012L), integrity.prepared)
        verify(result).success(null)
    }

    @Test
    fun prepareStandard_acceptsAnIntNumber() {
        call("prepareStandard", mapOf("cloudProjectNumber" to 42))
        assertEquals(listOf(42L), integrity.prepared)
    }

    @Test
    fun prepareStandard_withoutNumber_isRejected() {
        call("prepareStandard", mapOf<String, Any?>())
        verify(result).error("rejected", "cloudProjectNumber is missing", null)
        assertEquals(emptyList(), integrity.prepared)
    }

    @Test
    fun prepareStandard_failure_mapsTheErrorCode() {
        integrity.prepareError = integrityError(StandardIntegrityErrorCode.PLAY_SERVICES_NOT_FOUND)
        call("prepareStandard", mapOf("cloudProjectNumber" to 1L))
        verify(result).error("unsupported", "StandardIntegrityException(-6)", null)
    }

    @Test
    fun requestStandardToken_returnsTheToken() {
        call("requestStandardToken", mapOf("requestHash" to "abc_-"))
        assertEquals(listOf("abc_-"), integrity.requested)
        verify(result).success("pi-token")
    }

    @Test
    fun requestStandardToken_withoutHash_isRejected() {
        call("requestStandardToken", mapOf<String, Any?>())
        verify(result).error("rejected", "requestHash is missing", null)
    }

    @Test
    fun requestStandardToken_failures_mapToTheirKinds() {
        val cases =
            listOf(
                integrityError(StandardIntegrityErrorCode.TOO_MANY_REQUESTS) to "quota",
                integrityError(StandardIntegrityErrorCode.APP_UID_MISMATCH) to "rejected",
                integrityError(StandardIntegrityErrorCode.NETWORK_ERROR) to "transient",
                integrityError(StandardIntegrityErrorCode.API_NOT_AVAILABLE) to "unsupported",
                NotPreparedException() to "transient",
            )
        for ((error, code) in cases) {
            val result = mock(MethodChannel.Result::class.java)
            integrity.token = Result.failure(error)
            plugin.onMethodCall(MethodCall("requestStandardToken", mapOf("requestHash" to "h")), result)
            verify(result).error(eq(code), any(), isNull())
        }
    }

    @Test
    fun androidId_returnsTheValueOrNull() {
        call("androidId")
        verify(result).success("9774d56d682e549c")
        androidIdValue = null
        val second = mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(MethodCall("androidId", null), second)
        verify(second).success(null)
    }

    @Test
    fun iosAndUnknownMethods_areNotImplemented() {
        for (method in listOf("generateKey", "attestKey", "generateAssertion", "deviceCheckToken", "unknown")) {
            val result = mock(MethodChannel.Result::class.java)
            plugin.onMethodCall(MethodCall(method, null), result)
            verify(result).notImplemented()
        }
    }

    @Test
    fun defaultFactories_buildThePlayAndSettingsProviders() {
        val resolver = mock(ContentResolver::class.java)
        val appContext = mock(Context::class.java)
        `when`(appContext.contentResolver).thenReturn(resolver)
        `when`(appContext.applicationContext).thenReturn(appContext)
        assertIs<SecureSettingsAndroidIdProvider>(TaroAttestationPlugin.secureSettings(appContext))
        verifyNoInteractions(resolver)
        assertIs<PlayIntegrityProvider>(TaroAttestationPlugin.playIntegrity(appContext))
    }
}

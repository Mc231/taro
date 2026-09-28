package com.vshyrochuk.taro_attestation

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.ArgumentMatchers.any
import org.mockito.ArgumentMatchers.eq
import org.mockito.ArgumentMatchers.isNull
import org.mockito.Mockito
import kotlin.test.Test

/*
 * JVM unit tests of the Kotlin plugin code, measured with JaCoCo as the
 * coverage unit taro_attestation_android (06 §5.2, RC40). Run them with
 * `tools/ci/native_coverage_android.sh` or `./gradlew :taro_attestation:jacocoTestReport`
 * in `example/android/`.
 */

internal class TaroAttestationPluginTest {
    @Test
    fun onMethodCall_getPlatformVersion_returnsExpectedValue() {
        val plugin = TaroAttestationPlugin()

        val call = MethodCall("getPlatformVersion", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).success("Android " + android.os.Build.VERSION.RELEASE)
    }

    @Test
    fun onMethodCall_unknownMethod_isNotImplemented() {
        val plugin = TaroAttestationPlugin()

        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(MethodCall("unknownMethod", null), mockResult)

        Mockito.verify(mockResult).notImplemented()
    }

    @Test
    fun attachAndDetach_registerAndClearTheChannelHandler() {
        val plugin = TaroAttestationPlugin()
        val messenger = Mockito.mock(BinaryMessenger::class.java)
        val binding = Mockito.mock(FlutterPlugin.FlutterPluginBinding::class.java)
        Mockito.`when`(binding.binaryMessenger).thenReturn(messenger)

        plugin.onAttachedToEngine(binding)
        Mockito.verify(messenger).setMessageHandler(eq("taro_attestation"), any())

        plugin.onDetachedFromEngine(binding)
        Mockito.verify(messenger).setMessageHandler(eq("taro_attestation"), isNull())
    }
}

package com.vshyrochuk.taro_attestation

import android.content.ContentResolver
import org.mockito.Mockito.mock
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertSame

internal class AndroidIdProviderTest {
    private val resolver = mock(ContentResolver::class.java)

    @Test
    fun readsAndroidIdFromSecureSettings() {
        val reads = mutableListOf<Pair<ContentResolver, String>>()
        val provider =
            SecureSettingsAndroidIdProvider(resolver) { r, key ->
                reads += r to key
                "9774d56d682e549c"
            }
        assertEquals("9774d56d682e549c", provider.androidId())
        assertSame(resolver, reads.single().first)
        assertEquals("android_id", reads.single().second)
    }

    @Test
    fun missingOrBlankIsNull() {
        assertNull(SecureSettingsAndroidIdProvider(resolver) { _, _ -> null }.androidId())
        assertNull(SecureSettingsAndroidIdProvider(resolver) { _, _ -> "  " }.androidId())
    }

    @Test
    fun defaultReaderIsSettingsSecure() {
        // Constructing with the default reader must not touch the OS.
        SecureSettingsAndroidIdProvider(resolver)
    }
}

package com.vshyrochuk.taro_attestation

import android.content.ContentResolver
import android.provider.Settings

/** `Settings.Secure.ANDROID_ID` (03 §3.7); the raw value never leaves the device. */
fun interface AndroidIdProvider {
    /** The ANDROID_ID, or `null` when the OS reports none. */
    fun androidId(): String?
}

/** [AndroidIdProvider] over the secure settings of [resolver]; [read] is `Settings.Secure.getString`. */
class SecureSettingsAndroidIdProvider(
    private val resolver: ContentResolver,
    private val read: (ContentResolver, String) -> String? = Settings.Secure::getString,
) : AndroidIdProvider {
    override fun androidId(): String? = read(resolver, Settings.Secure.ANDROID_ID)?.takeIf { it.isNotBlank() }
}

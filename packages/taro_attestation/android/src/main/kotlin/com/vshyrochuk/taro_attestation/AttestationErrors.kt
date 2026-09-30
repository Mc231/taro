package com.vshyrochuk.taro_attestation

import com.google.android.play.core.integrity.StandardIntegrityException
import com.google.android.play.core.integrity.model.StandardIntegrityErrorCode

/**
 * The channel error codes, one per Dart `AttestationErrorKind` (02 §6.4):
 * the Dart side parses `PlatformException.code` by name.
 */
internal object AttestationErrors {
    const val UNSUPPORTED = "unsupported"
    const val KEY_INVALIDATED = "keyInvalidated"
    const val REJECTED = "rejected"
    const val QUOTA = "quota"
    const val TRANSIENT = "transient"

    /** The code of a Play Integrity failure [error]; anything else is transient. */
    fun codeOf(error: Throwable): String =
        if (error is StandardIntegrityException) codeOf(error.errorCode) else TRANSIENT

    /** A message for [error] that names its type and Play error code, never a token. */
    fun messageOf(error: Throwable): String =
        if (error is StandardIntegrityException) {
            "StandardIntegrityException(${error.errorCode})"
        } else {
            error.javaClass.simpleName
        }

    /**
     * The code of a `StandardIntegrityErrorCode`:
     * - no Play Store / Play services, or outdated ones: [UNSUPPORTED];
     * - a wrong app identity, cloud project number or request hash: [REJECTED];
     * - `TOO_MANY_REQUESTS`: [QUOTA];
     * - network, server, binding, provider and internal errors: [TRANSIENT].
     */
    fun codeOf(errorCode: Int): String =
        when (errorCode) {
            StandardIntegrityErrorCode.API_NOT_AVAILABLE,
            StandardIntegrityErrorCode.PLAY_STORE_NOT_FOUND,
            StandardIntegrityErrorCode.PLAY_SERVICES_NOT_FOUND,
            StandardIntegrityErrorCode.PLAY_STORE_VERSION_OUTDATED,
            StandardIntegrityErrorCode.PLAY_SERVICES_VERSION_OUTDATED,
            -> UNSUPPORTED

            StandardIntegrityErrorCode.APP_NOT_INSTALLED,
            StandardIntegrityErrorCode.APP_UID_MISMATCH,
            StandardIntegrityErrorCode.CLOUD_PROJECT_NUMBER_IS_INVALID,
            StandardIntegrityErrorCode.REQUEST_HASH_TOO_LONG,
            -> REJECTED

            StandardIntegrityErrorCode.TOO_MANY_REQUESTS -> QUOTA

            else -> TRANSIENT
        }
}

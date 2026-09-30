package com.vshyrochuk.taro_attestation

import com.google.android.play.core.integrity.model.StandardIntegrityErrorCode
import kotlin.test.Test
import kotlin.test.assertEquals

internal class AttestationErrorsTest {
    @Test
    fun everyStandardErrorCode_mapsToItsKind() {
        val expected =
            mapOf(
                StandardIntegrityErrorCode.API_NOT_AVAILABLE to "unsupported",
                StandardIntegrityErrorCode.PLAY_STORE_NOT_FOUND to "unsupported",
                StandardIntegrityErrorCode.PLAY_SERVICES_NOT_FOUND to "unsupported",
                StandardIntegrityErrorCode.PLAY_STORE_VERSION_OUTDATED to "unsupported",
                StandardIntegrityErrorCode.PLAY_SERVICES_VERSION_OUTDATED to "unsupported",
                StandardIntegrityErrorCode.APP_NOT_INSTALLED to "rejected",
                StandardIntegrityErrorCode.APP_UID_MISMATCH to "rejected",
                StandardIntegrityErrorCode.CLOUD_PROJECT_NUMBER_IS_INVALID to "rejected",
                StandardIntegrityErrorCode.REQUEST_HASH_TOO_LONG to "rejected",
                StandardIntegrityErrorCode.TOO_MANY_REQUESTS to "quota",
                StandardIntegrityErrorCode.NETWORK_ERROR to "transient",
                StandardIntegrityErrorCode.CANNOT_BIND_TO_SERVICE to "transient",
                StandardIntegrityErrorCode.GOOGLE_SERVER_UNAVAILABLE to "transient",
                StandardIntegrityErrorCode.CLIENT_TRANSIENT_ERROR to "transient",
                StandardIntegrityErrorCode.INTEGRITY_TOKEN_PROVIDER_INVALID to "transient",
                StandardIntegrityErrorCode.INTERNAL_ERROR to "transient",
                StandardIntegrityErrorCode.NO_ERROR to "transient",
            )
        for ((code, kind) in expected) {
            assertEquals(kind, AttestationErrors.codeOf(code), "code $code")
            assertEquals(kind, AttestationErrors.codeOf(integrityError(code)), "exception $code")
        }
    }

    @Test
    fun anyOtherThrowable_isTransient() {
        assertEquals("transient", AttestationErrors.codeOf(IllegalStateException("x")))
        assertEquals("transient", AttestationErrors.codeOf(NotPreparedException()))
    }

    @Test
    fun messages_nameTheTypeAndCode() {
        assertEquals(
            "StandardIntegrityException(-8)",
            AttestationErrors.messageOf(integrityError(StandardIntegrityErrorCode.TOO_MANY_REQUESTS)),
        )
        assertEquals("NotPreparedException", AttestationErrors.messageOf(NotPreparedException()))
    }
}

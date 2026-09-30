package com.vshyrochuk.taro_attestation

import com.google.android.play.core.integrity.StandardIntegrityManager
import com.google.android.play.core.integrity.StandardIntegrityManager.StandardIntegrityToken
import com.google.android.play.core.integrity.StandardIntegrityManager.StandardIntegrityTokenProvider
import com.google.android.play.core.integrity.StandardIntegrityManager.StandardIntegrityTokenRequest
import com.google.android.play.core.integrity.model.StandardIntegrityErrorCode
import org.mockito.ArgumentCaptor
import org.mockito.ArgumentMatchers.any
import org.mockito.Mockito.mock
import org.mockito.Mockito.times
import org.mockito.Mockito.verify
import org.mockito.Mockito.`when`
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertSame

internal class PlayIntegrityProviderTest {
    private lateinit var manager: StandardIntegrityManager
    private lateinit var tokenProvider: StandardIntegrityTokenProvider
    private lateinit var subject: PlayIntegrityProvider

    @BeforeTest
    fun setUp() {
        manager = mock(StandardIntegrityManager::class.java)
        tokenProvider = mock(StandardIntegrityTokenProvider::class.java)
        subject = PlayIntegrityProvider(manager)
    }

    private fun token(value: String): StandardIntegrityToken {
        val token = mock(StandardIntegrityToken::class.java)
        `when`(token.token()).thenReturn(value)
        return token
    }

    private fun prepareSucceeds() {
        val task = finishedTask(tokenProvider)
        `when`(manager.prepareIntegrityToken(any())).thenReturn(task)
    }

    private fun prepare(): Throwable? {
        var outcome: Throwable? = IllegalStateException("not called")
        subject.prepare(123L) { outcome = it }
        return outcome
    }

    private fun request(hash: String = "hash"): Result<String>? {
        var outcome: Result<String>? = null
        subject.request(hash) { outcome = it }
        return outcome
    }

    @Test
    fun prepare_success_reportsNoError() {
        prepareSucceeds()
        assertNull(prepare())
        verify(manager).prepareIntegrityToken(any())
    }

    @Test
    fun prepare_failure_reportsTheError() {
        val error = integrityError(StandardIntegrityErrorCode.PLAY_STORE_NOT_FOUND)
        val task = finishedTask<StandardIntegrityTokenProvider>(error = error)
        `when`(manager.prepareIntegrityToken(any())).thenReturn(task)
        assertSame(error, prepare())
        // Still unprepared: a request fails without calling Play.
        assertIs<NotPreparedException>(request()!!.exceptionOrNull())
    }

    @Test
    fun prepare_cancelled_isAnError() {
        val task = finishedTask<StandardIntegrityTokenProvider>(successful = false)
        `when`(manager.prepareIntegrityToken(any())).thenReturn(task)
        assertIs<IllegalStateException>(prepare())
    }

    @Test
    fun request_beforePrepare_isNotPrepared() {
        assertIs<NotPreparedException>(request()!!.exceptionOrNull())
    }

    @Test
    fun request_returnsTheTokenForTheHash() {
        prepareSucceeds()
        prepare()
        val task = finishedTask(token("pi-token"))
        `when`(tokenProvider.request(any())).thenReturn(task)

        assertEquals("pi-token", request("abc_-")!!.getOrThrow())

        val captor = ArgumentCaptor.forClass(StandardIntegrityTokenRequest::class.java)
        verify(tokenProvider).request(captor.capture())
        assertEquals("abc_-", captor.value.requestHash())
    }

    @Test
    fun request_failure_isReturned() {
        prepareSucceeds()
        prepare()
        val error = integrityError(StandardIntegrityErrorCode.NETWORK_ERROR)
        val task = finishedTask<StandardIntegrityToken>(error = error)
        `when`(tokenProvider.request(any())).thenReturn(task)
        assertSame(error, request()!!.exceptionOrNull())
    }

    @Test
    fun request_invalidProvider_preparesAgainAndRetriesOnce() {
        prepareSucceeds()
        prepare()
        val invalid = integrityError(StandardIntegrityErrorCode.INTEGRITY_TOKEN_PROVIDER_INVALID)
        val failed = finishedTask<StandardIntegrityToken>(error = invalid)
        val fresh = finishedTask(token("fresh"))
        `when`(tokenProvider.request(any())).thenReturn(failed).thenReturn(fresh)

        assertEquals("fresh", request()!!.getOrThrow())
        verify(manager, times(2)).prepareIntegrityToken(any())
        verify(tokenProvider, times(2)).request(any())
    }

    @Test
    fun request_invalidProviderTwice_givesUp() {
        prepareSucceeds()
        prepare()
        val invalid = integrityError(StandardIntegrityErrorCode.INTEGRITY_TOKEN_PROVIDER_INVALID)
        val failed = finishedTask<StandardIntegrityToken>(error = invalid)
        `when`(tokenProvider.request(any())).thenReturn(failed)

        assertSame(invalid, request()!!.exceptionOrNull())
        verify(tokenProvider, times(2)).request(any())
    }

    @Test
    fun request_invalidProvider_failedPrepare_returnsThePrepareError() {
        val prepareError = integrityError(StandardIntegrityErrorCode.NETWORK_ERROR)
        val prepared = finishedTask(tokenProvider)
        val notPrepared = finishedTask<StandardIntegrityTokenProvider>(error = prepareError)
        `when`(manager.prepareIntegrityToken(any())).thenReturn(prepared).thenReturn(notPrepared)
        prepare()
        val invalid = integrityError(StandardIntegrityErrorCode.INTEGRITY_TOKEN_PROVIDER_INVALID)
        val failed = finishedTask<StandardIntegrityToken>(error = invalid)
        `when`(tokenProvider.request(any())).thenReturn(failed)

        assertSame(prepareError, request()!!.exceptionOrNull())
        // The invalid provider was dropped.
        assertIs<NotPreparedException>(request()!!.exceptionOrNull())
    }
}

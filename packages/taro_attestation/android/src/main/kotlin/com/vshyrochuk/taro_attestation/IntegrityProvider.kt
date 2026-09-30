package com.vshyrochuk.taro_attestation

import com.google.android.gms.tasks.Task
import com.google.android.play.core.integrity.StandardIntegrityException
import com.google.android.play.core.integrity.StandardIntegrityManager
import com.google.android.play.core.integrity.StandardIntegrityManager.PrepareIntegrityTokenRequest
import com.google.android.play.core.integrity.StandardIntegrityManager.StandardIntegrityTokenProvider
import com.google.android.play.core.integrity.StandardIntegrityManager.StandardIntegrityTokenRequest
import com.google.android.play.core.integrity.model.StandardIntegrityErrorCode

/** The Play Integrity Standard API as the plugin uses it (RC87; no Classic API). */
interface IntegrityProvider {
    /** Warms up a token provider for [cloudProjectNumber]; [done] gets `null` or the error. */
    fun prepare(cloudProjectNumber: Long, done: (Throwable?) -> Unit)

    /** A token bound to [requestHash]; [done] gets the token or the error. */
    fun request(requestHash: String, done: (Result<String>) -> Unit)
}

/** Raised by [PlayIntegrityProvider.request] before a successful [IntegrityProvider.prepare]. */
class NotPreparedException : IllegalStateException("prepareStandard has not succeeded")

/**
 * [IntegrityProvider] over a [StandardIntegrityManager]. Keeps the prepared
 * token provider; a provider that Play reports invalid
 * (`INTEGRITY_TOKEN_PROVIDER_INVALID`) is prepared again once and the
 * request retried.
 */
class PlayIntegrityProvider(private val manager: StandardIntegrityManager) : IntegrityProvider {
    private var tokenProvider: StandardIntegrityTokenProvider? = null
    private var cloudProjectNumber: Long? = null

    override fun prepare(cloudProjectNumber: Long, done: (Throwable?) -> Unit) {
        val request = PrepareIntegrityTokenRequest.builder().setCloudProjectNumber(cloudProjectNumber).build()
        complete(manager.prepareIntegrityToken(request)) { result ->
            result.onSuccess {
                tokenProvider = it
                this.cloudProjectNumber = cloudProjectNumber
            }
            done(result.exceptionOrNull())
        }
    }

    override fun request(requestHash: String, done: (Result<String>) -> Unit) {
        request(requestHash, retry = true, done)
    }

    private fun request(requestHash: String, retry: Boolean, done: (Result<String>) -> Unit) {
        val provider = tokenProvider ?: return done(Result.failure(NotPreparedException()))
        val request = StandardIntegrityTokenRequest.builder().setRequestHash(requestHash).build()
        complete(provider.request(request)) { result ->
            val error = result.exceptionOrNull()
            val number = cloudProjectNumber
            if (retry && number != null && isProviderInvalid(error)) {
                tokenProvider = null
                prepare(number) { prepareError ->
                    if (prepareError == null) {
                        request(requestHash, retry = false, done)
                    } else {
                        done(Result.failure(prepareError))
                    }
                }
            } else {
                done(result.map { it.token() })
            }
        }
    }

    private fun isProviderInvalid(error: Throwable?): Boolean =
        error is StandardIntegrityException &&
            error.errorCode == StandardIntegrityErrorCode.INTEGRITY_TOKEN_PROVIDER_INVALID

    private fun <T> complete(task: Task<T>, done: (Result<T>) -> Unit) {
        task.addOnCompleteListener { finished ->
            val error = finished.exception
            done(
                when {
                    error != null -> Result.failure(error)
                    finished.isSuccessful -> Result.success(finished.result)
                    else -> Result.failure(IllegalStateException("task cancelled"))
                },
            )
        }
    }
}

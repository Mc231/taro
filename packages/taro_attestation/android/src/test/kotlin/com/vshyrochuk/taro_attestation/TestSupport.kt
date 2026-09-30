package com.vshyrochuk.taro_attestation

import com.google.android.gms.tasks.OnCompleteListener
import com.google.android.gms.tasks.Task
import com.google.android.play.core.integrity.StandardIntegrityException
import org.mockito.ArgumentMatchers.any
import org.mockito.Mockito.doAnswer
import org.mockito.Mockito.mock
import org.mockito.Mockito.`when`

/** A finished [Task]: [result] on success, or [error]; `successful = false` without an error = cancelled. */
@Suppress("UNCHECKED_CAST")
internal fun <T> finishedTask(
    result: T? = null,
    error: Exception? = null,
    successful: Boolean = error == null,
): Task<T> {
    val task = mock(Task::class.java) as Task<T>
    `when`(task.exception).thenReturn(error)
    `when`(task.isSuccessful).thenReturn(successful)
    `when`(task.result).thenReturn(result)
    doAnswer { invocation ->
        invocation.getArgument<OnCompleteListener<T>>(0).onComplete(task)
        task
    }.`when`(task).addOnCompleteListener(anyNonNull<OnCompleteListener<T>>())
    return task
}

/** `ArgumentMatchers.any()` for a non-null Kotlin parameter type. */
@Suppress("UNCHECKED_CAST")
internal fun <T> anyNonNull(): T {
    any<T>()
    return null as T
}

/** A Play Integrity failure with [errorCode] (its constructor is not public). */
internal fun integrityError(errorCode: Int): StandardIntegrityException {
    val error = mock(StandardIntegrityException::class.java)
    `when`(error.errorCode).thenReturn(errorCode)
    return error
}

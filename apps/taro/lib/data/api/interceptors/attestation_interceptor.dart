import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:taro/data/api/request_context.dart';
import 'package:taro_core/taro_core.dart';

/// Third in the chain (02 §6.3, 03 §3.4): `X-Taro-Attestation` on the four
/// **attest** routes (RC11, RC50). The header is `aa1.<assertion>` (iOS) or
/// `pi1.<token>` (Android) over [clientDataHash], or `none` on a device
/// without platform attestation (low trust). A failed assertion stops the
/// request with its [AttestationFailure] (e.g. `keyInvalidated` →
/// re-registration, 02 §6.4).
final class AttestationInterceptor extends Interceptor {
  /// Creates the interceptor.
  AttestationInterceptor(this._attestation);

  final AttestationService _attestation;

  /// The `none` header of an unsupported device.
  static const String none = 'none';

  /// `SHA256(method ‖ path ‖ SHA256(body) ‖ Idempotency-Key)` (03 §3.4):
  /// UTF-8 method (upper case) and path, the raw 32-byte body hash, and the
  /// UTF-8 key (empty when absent). Mirrors the Worker's
  /// `callClientDataHash`.
  static List<int> clientDataHash({
    required String method,
    required String path,
    required List<int> body,
    String? idempotencyKey,
  }) => sha256.convert([
    ...utf8.encode(method.toUpperCase()),
    ...utf8.encode(path),
    ...sha256.convert(body).bytes,
    ...utf8.encode(idempotencyKey ?? ''),
  ]).bytes;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!(options.endpoint?.attested ?? false)) return handler.next(options);
    if (!_attestation.isSupported) {
      options.headers[TaroHeaders.attestation] = none;
      return handler.next(options);
    }
    final data = options.data;
    final hash = clientDataHash(
      method: options.method,
      path: options.uri.path,
      body: data is Uint8List ? data : const <int>[],
      idempotencyKey: options.idempotencyKey,
    );
    switch (await _attestation.assert_(clientDataHash: hash)) {
      case Ok(:final value):
        options.headers[TaroHeaders.attestation] = value.header;
        handler.next(options);
      case Err(:final failure):
        handler.reject(failureException(options, failure));
    }
  }
}

/// The `taro_core` test kit (Phase 4.5, QA16): one Riverpod-free fake per
/// port, the determinism helpers and the builders.
///
/// Imported only from `test/` and `integration_test/` (the app imports it
/// by relative path, 02 §2.1); never from any `lib/`.
library;

export 'builders/builders.dart';
export 'capturing_logger.dart';
export 'fake_behaviour.dart';
export 'fake_clock.dart';
export 'journal_fakes.dart';
export 'platform_fakes.dart';
export 'random_sources.dart';
export 'sequential_id_generator.dart';
export 'storage_fakes.dart';
export 'store_fakes.dart';
export 'worker_fakes.dart';

/// Taro domain layer: models, ports, use cases and pure logic.
///
/// Pure Dart: no Flutter, no I/O (02 §2.1). This barrel exports only the
/// per-area sub-barrels; each area owns its own barrel file.
library;

export 'src/analytics/analytics.dart';
export 'src/logic/logic.dart';
export 'src/model/models.dart';
export 'src/ports/ports.dart';
export 'src/result/result_barrel.dart';
export 'src/usecases/usecases.dart';

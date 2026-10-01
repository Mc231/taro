import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// The normalized slot layouts of [spread] in draw order (01 §10.2), for
/// `SpreadCanvas` and `SpreadDiagram`.
List<SpreadSlotLayout> spreadSlotLayouts(SpreadDefinition spread) {
  final positions = [...spread.positions]
    ..sort((a, b) => a.order.compareTo(b.order));
  return [
    for (final p in positions)
      SpreadSlotLayout(
        x: p.x.clamp(0, 1).toDouble(),
        y: p.y.clamp(0, 1).toDouble(),
        rotationDeg: p.rotationDeg,
      ),
  ];
}

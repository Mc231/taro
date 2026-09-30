import 'dart:io';

import 'package:taro_dart_tools/gen_state_inventory.dart';

/// Writes `docs/design/STATE_INVENTORY.md` (Phase 13 Sprint 13.4).
void main(List<String> args) {
  exitCode = genStateInventory(args);
}

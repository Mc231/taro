import 'package:logging/logging.dart';

/// The console sink is the one place allowed to print (import_rules.yaml).
void attachConsoleSink(Logger root) {
  root.onRecord.listen((record) => print('${record.level}: ${record.message}'));
}

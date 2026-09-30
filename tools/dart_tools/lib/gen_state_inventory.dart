/// Generator of `docs/design/STATE_INVENTORY.md` (Phase 13 Sprint 13.4):
/// screen → route → states → ★ golden flag → banner allowed, built from the
/// sealed state unions of the screen controllers and GLOSSARY §10. It is
/// the input of Phase 14 (Claude Design handoff).
library;

import 'dart:io';

import 'package:taro_dart_tools/gen_coverage_all.dart' show findRepoRoot;
import 'package:taro_dart_tools/src/state_inventory/inventory.dart';
import 'package:taro_dart_tools/src/state_inventory/screens.dart';

export 'src/state_inventory/inventory.dart';
export 'src/state_inventory/screens.dart';

/// Repo-relative path of the generated document.
const stateInventoryPath = 'docs/design/STATE_INVENTORY.md';

/// The command that regenerates the document (quoted in its header).
const stateInventoryCommand =
    'dart run tools/dart_tools/bin/gen_state_inventory.dart';

const _usage =
    '''
Usage: $stateInventoryCommand [options]

Writes $stateInventoryPath from the sealed state unions in
apps/taro/lib/features/** and the screen table of GLOSSARY §10.

Options:
  --repo-root <dir>   Repository root (default: nearest ancestor with docs/specs).
  --check             Fail (exit 1) when the document is missing or stale
                      instead of writing it.
  -h, --help          Show this help.''';

/// Runs the generator with command-line [args] and returns the exit code
/// (0 ok, 1 failure or stale, 64 usage error). Messages go to [out] and
/// [err]; [cwd] is where the repository root search starts.
int genStateInventory(
  List<String> args, {
  StringSink? out,
  StringSink? err,
  Directory? cwd,
}) {
  final stdoutSink = out ?? stdout;
  final stderrSink = err ?? stderr;
  String? repoRoot;
  var check = false;
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '-h' || arg == '--help') {
      stdoutSink.writeln(_usage);
      return 0;
    } else if (arg == '--check') {
      check = true;
    } else if (arg == '--repo-root' && i + 1 < args.length) {
      repoRoot = args[++i];
    } else if (arg.startsWith('--repo-root=')) {
      repoRoot = arg.substring('--repo-root='.length);
    } else {
      stderrSink
        ..writeln('gen_state_inventory: unexpected argument "$arg"')
        ..writeln(_usage);
      return 64;
    }
  }
  final root = repoRoot != null
      ? Directory(repoRoot).absolute
      : findRepoRoot(cwd ?? Directory.current);
  if (root == null || !root.existsSync()) {
    stderrSink.writeln(
      'gen_state_inventory: no repository root (docs/specs) found; '
      'pass --repo-root',
    );
    return 1;
  }
  final String document;
  try {
    document = buildStateInventory(root);
  } on InventoryException catch (e) {
    stderrSink
      ..writeln('gen_state_inventory: the screen map is stale:')
      ..writeln(e.message);
    return 1;
  }
  final target = File('${root.path}/$stateInventoryPath');
  if (check) {
    final current = target.existsSync() ? target.readAsStringSync() : null;
    if (current != document) {
      stderrSink.writeln(
        'gen_state_inventory: $stateInventoryPath is stale; '
        'run $stateInventoryCommand',
      );
      return 1;
    }
    stdoutSink.writeln('gen_state_inventory: OK ($stateInventoryPath)');
    return 0;
  }
  target
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(document);
  stdoutSink.writeln('gen_state_inventory: wrote $stateInventoryPath');
  return 0;
}

/// The document for the repository at [root] (throws
/// [InventoryException] on a stale mapping or a missing input).
String buildStateInventory(Directory root) {
  final glossaryFile = File('${root.path}/docs/specs/GLOSSARY.md');
  if (!glossaryFile.existsSync()) {
    throw const InventoryException('docs/specs/GLOSSARY.md is missing');
  }
  final features = Directory('${root.path}/apps/taro/lib/features');
  if (!features.existsSync()) {
    throw const InventoryException('apps/taro/lib/features is missing');
  }
  final files =
      features
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (f) =>
                f.path.endsWith('.dart') &&
                !f.path.endsWith('.freezed.dart') &&
                !f.path.endsWith('.g.dart'),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final sources = {
    for (final f in files)
      f.path.substring(root.path.length + 1).replaceAll(r'\', '/'): f
          .readAsStringSync(),
  };
  final unions = parseUnions(sources);
  final screens = resolve(
    kScreens,
    unions,
    parseGlossaryScreens(glossaryFile.readAsStringSync()),
  );
  return render(screens, unions, command: stateInventoryCommand);
}

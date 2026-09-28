/// Import-graph gate for the packages and the app folders (02 AR2, §2.1,
/// §11; 06 §6.2; RC95).
///
/// Checks, reporting `file:line`:
/// * the package table: `taro_core` (pure Dart: no Flutter, I/O, Riverpod or
///   taro package), `taro_ui` (no `taro_core`, app or Riverpod),
///   `taro_attestation` (no taro package); any other package under `apps/`
///   or `packages/` is unknown (3 packages + the app);
/// * no `lib/src` import across packages (only barrels are public) and no
///   relative import that leaves a package;
/// * the `apps/taro/lib` folder table (`features/`, `data/`,
///   `data/content/`, `services/`, `services/presentation/`, `l10n/`,
///   `app_state/`, `common/`; `bootstrap/`, `di/`, `routing/`, `lifecycle/`
///   and root files are unrestricted);
/// * tests: `apps/taro/test/**` may import `packages/taro_core/test/fakes/`,
///   `packages/taro_core/test/contracts/` and `packages/taro_ui/test/helpers/`
///   by relative path; no other relative import may leave a package;
/// * non-directional layout APIs in `lib/` (`EdgeInsets.only`/`Positioned`
///   with `left:`/`right:`, `Alignment.centerLeft|Right`,
///   `TextAlign.left|right`), generated files excepted.
library;

import 'dart:io';

import 'package:taro_dart_tools/src/architecture/scanner.dart';

export 'src/architecture/dart_source.dart';
export 'src/architecture/rules.dart';
export 'src/architecture/scanner.dart';

const _usage = '''
Usage: dart run tools/dart_tools/bin/check_architecture.dart [options]

Checks the import graph of every package and of apps/taro/lib against
02_ARCHITECTURE.md §2.1 and flags non-directional layout APIs (§11).

Options:
  --repo-root <dir>   Repository root (default: nearest ancestor of the
                      current directory holding docs/specs).
  -h, --help          Show this help.''';

/// The nearest ancestor of [start] (inclusive) that contains `docs/specs`.
Directory? findTaroRoot(Directory start) {
  var current = start.absolute;
  while (true) {
    if (Directory('${current.path}/docs/specs').existsSync()) return current;
    final parent = current.parent;
    if (parent.path == current.path) return null;
    current = parent;
  }
}

/// Runs the check with command-line [args]; returns 0 (clean), 1
/// (violations or no repository) or 64 (usage error).
int checkArchitecture(
  List<String> args, {
  StringSink? out,
  StringSink? err,
  Directory? cwd,
}) {
  final stdoutSink = out ?? stdout;
  final stderrSink = err ?? stderr;
  String? repoRoot;
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '-h' || arg == '--help') {
      stdoutSink.writeln(_usage);
      return 0;
    } else if (arg == '--repo-root' && i + 1 < args.length) {
      repoRoot = args[++i];
    } else if (arg.startsWith('--repo-root=')) {
      repoRoot = arg.substring('--repo-root='.length);
    } else {
      stderrSink
        ..writeln('check_architecture: unexpected argument "$arg"')
        ..writeln(_usage);
      return 64;
    }
  }
  final root = repoRoot != null
      ? Directory(repoRoot).absolute
      : findTaroRoot(cwd ?? Directory.current);
  if (root == null || !root.existsSync()) {
    stderrSink.writeln(
      'check_architecture: no repository root (docs/specs) found; '
      'pass --repo-root',
    );
    return 1;
  }
  final result = ArchitectureScanner(root).scan();
  result.violations.forEach(stdoutSink.writeln);
  if (result.violations.isNotEmpty) {
    stdoutSink.writeln(
      'check_architecture: FAILED (${result.violations.length} violation(s) '
      'in ${result.filesScanned} file(s))',
    );
    return 1;
  }
  stdoutSink.writeln(
    'check_architecture: OK (${result.filesScanned} file(s))',
  );
  return 0;
}

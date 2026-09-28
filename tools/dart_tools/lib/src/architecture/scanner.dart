/// Walks the workspace, resolves every directive and applies the rules.
library;

import 'dart:io';

import 'package:taro_dart_tools/src/architecture/dart_source.dart';
import 'package:taro_dart_tools/src/architecture/rules.dart';

/// One rule violation, printed as `path:line: [rule] message`.
class Violation implements Comparable<Violation> {
  /// Creates a violation.
  const Violation(this.path, this.line, this.rule, this.message);

  /// Repo-relative POSIX path.
  final String path;

  /// 1-based line (0 when the whole file is concerned).
  final int line;

  /// Short rule id.
  final String rule;

  /// Human-readable explanation.
  final String message;

  @override
  int compareTo(Violation other) {
    final byPath = path.compareTo(other.path);
    if (byPath != 0) return byPath;
    final byLine = line.compareTo(other.line);
    return byLine != 0 ? byLine : message.compareTo(other.message);
  }

  @override
  String toString() => '${line > 0 ? '$path:$line' : path}: [$rule] $message';
}

/// A workspace package: its pubspec name and repo-relative directory.
class Package {
  /// Creates a package.
  const Package(this.name, this.dir);

  /// `name:` from its pubspec.
  final String name;

  /// Repo-relative POSIX directory, e.g. `packages/taro_core`.
  final String dir;
}

/// Result of a scan.
class ScanResult {
  /// Creates a result.
  const ScanResult(this.violations, this.filesScanned);

  /// Sorted violations.
  final List<Violation> violations;

  /// Number of Dart files read.
  final int filesScanned;
}

final _pubspecName = RegExp(r'^name:\s*([A-Za-z0-9_]+)', multiLine: true);

/// Normalises a POSIX path with `.` and `..` segments.
String normalizePath(String path) {
  final out = <String>[];
  for (final part in path.split('/')) {
    if (part.isEmpty || part == '.') continue;
    if (part == '..') {
      if (out.isNotEmpty && out.last != '..') {
        out.removeLast();
      } else {
        out.add('..');
      }
    } else {
      out.add(part);
    }
  }
  return out.join('/');
}

String _dirname(String path) {
  final index = path.lastIndexOf('/');
  return index < 0 ? '' : path.substring(0, index);
}

/// The directive target, classified.
class Target {
  const Target._(this.package, this.path, {this.dartLibrary});

  /// A `dart:` library.
  const Target.dart(String library) : this._(null, null, dartLibrary: library);

  /// `package` is the package name (workspace or external); `path` is the
  /// repo-relative file for workspace targets.
  const Target.package(String? package, String? path) : this._(package, path);

  /// Package name, or `null` for a relative path outside every package.
  final String? package;

  /// Repo-relative path for workspace files, else `null`.
  final String? path;

  /// `dart:x` for SDK libraries.
  final String? dartLibrary;
}

/// Reads the workspace under [root] and applies 02 §2.1 and §11.
class ArchitectureScanner {
  /// Creates a scanner for the repository at [root].
  ArchitectureScanner(this.root);

  /// Repository root.
  final Directory root;

  final List<Violation> _violations = [];
  late final List<Package> _packages;
  var _files = 0;

  /// Runs every rule and returns the sorted violations.
  ScanResult scan() {
    _packages = _discoverPackages();
    for (final package in _packages) {
      if (!taroPackages.contains(package.name)) {
        _violations.add(
          Violation(
            '${package.dir}/pubspec.yaml',
            0,
            'unknown-package',
            'package ${package.name} is not in the 02 §2.1 table '
                '(3 packages + the app, RC95)',
          ),
        );
        continue;
      }
      for (final file in _dartFiles('${package.dir}/lib')) {
        _checkLibFile(package, file);
      }
      for (final folder in ['test', 'integration_test']) {
        for (final file in _dartFiles('${package.dir}/$folder')) {
          _checkTestFile(package, file);
        }
      }
    }
    _violations.sort();
    return ScanResult(List.unmodifiable(_violations), _files);
  }

  List<Package> _discoverPackages() {
    final packages = <Package>[];
    for (final parent in ['apps', 'packages']) {
      final dir = Directory('${root.path}/$parent');
      if (!dir.existsSync()) continue;
      final children = dir.listSync().whereType<Directory>().toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      for (final child in children) {
        final pubspec = File('${child.path}/pubspec.yaml');
        if (!pubspec.existsSync()) continue;
        final match = _pubspecName.firstMatch(pubspec.readAsStringSync());
        final name = match?.group(1) ?? _basename(child.path);
        packages.add(Package(name, '$parent/${_basename(child.path)}'));
      }
    }
    return packages;
  }

  String _basename(String path) => path.split(Platform.pathSeparator).last;

  Iterable<String> _dartFiles(String relativeDir) sync* {
    final dir = Directory('${root.path}/$relativeDir');
    if (!dir.existsSync()) return;
    final files =
        dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .map((f) => f.path.substring(root.path.length + 1))
            .map((p) => p.replaceAll(Platform.pathSeparator, '/'))
            .toList()
          ..sort();
    yield* files;
  }

  Package? _packageNamed(String name) {
    for (final package in _packages) {
      if (package.name == name) return package;
    }
    return null;
  }

  Package? _packageContaining(String path) {
    for (final package in _packages) {
      if (path.startsWith('${package.dir}/')) return package;
    }
    return null;
  }

  Target? _resolve(String fromFile, String uri) {
    if (uri.startsWith('dart:')) return Target.dart(uri.split('/').first);
    if (uri.startsWith('package:')) {
      final rest = uri.substring('package:'.length);
      final slash = rest.indexOf('/');
      final name = slash < 0 ? rest : rest.substring(0, slash);
      final local = _packageNamed(name);
      final path = local == null || slash < 0
          ? null
          : '${local.dir}/lib/${rest.substring(slash + 1)}';
      return Target.package(name, path == null ? null : normalizePath(path));
    }
    if (uri.contains(':')) return null; // other schemes (e.g. data:)
    final path = normalizePath('${_dirname(fromFile)}/$uri');
    return Target.package(_packageContaining(path)?.name, path);
  }

  List<Directive> _read(String file) {
    _files++;
    return parseDirectives(File('${root.path}/$file').readAsStringSync());
  }

  void _add(String file, int line, String rule, String message) =>
      _violations.add(Violation(file, line, rule, message));

  void _checkLibFile(Package package, String file) {
    final source = File('${root.path}/$file').readAsStringSync();
    final directives = _read(file);
    final isApp = package.name == 'taro';
    final libRoot = '${package.dir}/lib/';
    final libPath = file.substring(libRoot.length);
    final zone = isApp ? zoneOf(libPath) : null;

    for (final directive in directives) {
      final target = _resolve(file, directive.uri);
      if (target == null) continue;
      final line = directive.line;
      final library = target.dartLibrary;
      if (library != null) {
        final why = packageRuleViolation(package.name, library);
        if (why != null) _add(file, line, 'package-dependency', why);
        continue;
      }
      final relative = !directive.uri.startsWith('package:');
      final targetPackage = target.package;
      final targetPath = target.path;
      if (relative && targetPackage != package.name) {
        _add(
          file,
          line,
          'relative-cross-package',
          'relative import ${directive.uri} leaves ${package.dir}/',
        );
        continue;
      }
      if (targetPackage == null) continue;
      if (targetPackage != package.name) {
        _checkCrossPackage(file, line, target);
        final why =
            packageRuleViolation(package.name, targetPackage) ??
            folderPackageViolation(zone, targetPackage);
        if (why != null) _add(file, line, 'package-dependency', why);
        continue;
      }
      if (targetPath == null) continue;
      if (!targetPath.startsWith(libRoot)) {
        _add(
          file,
          line,
          'outside-lib',
          'lib/ file imports ${directive.uri}, outside lib/',
        );
        continue;
      }
      if (isApp) {
        final why = folderRuleViolation(
          libPath,
          targetPath.substring(libRoot.length),
        );
        if (why != null) _add(file, line, 'folder-dependency', why);
      }
    }

    if (!_isGenerated(file)) {
      for (final use in findLayoutUses(source)) {
        _add(
          file,
          use.line,
          'non-directional',
          '${use.api} is not RTL-safe; use the Directional/start/end form '
              '(02 §11)',
        );
      }
    }
  }

  bool _isGenerated(String file) =>
      file.contains('/generated/') ||
      file.endsWith('.g.dart') ||
      file.endsWith('.freezed.dart');

  void _checkCrossPackage(String file, int line, Target target) {
    final targetPackage = _packageNamed(target.package!);
    final path = target.path;
    if (targetPackage == null || path == null) return;
    if (path.startsWith('${targetPackage.dir}/lib/src/')) {
      _add(
        file,
        line,
        'lib-src',
        'imports ${targetPackage.name} lib/src; use the package barrel',
      );
    }
  }

  void _checkTestFile(Package package, String file) {
    for (final directive in _read(file)) {
      final target = _resolve(file, directive.uri);
      if (target == null || target.dartLibrary != null) continue;
      final targetPackage = target.package;
      final path = target.path;
      final relative = !directive.uri.startsWith('package:');
      if (relative) {
        if (path != null && path.startsWith('${package.dir}/')) continue;
        final allowed =
            package.name == 'taro' &&
            path != null &&
            appTestHelperFolders.any(path.startsWith);
        if (!allowed) {
          _add(
            file,
            directive.line,
            'test-cross-package',
            'relative import ${directive.uri} leaves ${package.dir}/ '
                '(apps/taro/test may reach only taro_core test/fakes, '
                'test/contracts and taro_ui test/helpers)',
          );
        }
        continue;
      }
      if (targetPackage == null || targetPackage == package.name) continue;
      _checkCrossPackage(file, directive.line, target);
      final why = packageRuleViolation(package.name, targetPackage);
      if (why != null && taroPackages.contains(targetPackage)) {
        _add(file, directive.line, 'package-dependency', why);
      }
    }
  }
}

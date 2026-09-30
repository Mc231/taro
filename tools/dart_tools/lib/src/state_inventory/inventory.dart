/// Parsing and rendering of `docs/design/STATE_INVENTORY.md`.
library;

import 'package:taro_dart_tools/src/state_inventory/screens.dart';

/// One case of a sealed state union (`const factory Union.name(`).
final class UnionCase {
  /// Creates a case.
  const UnionCase(this.name, this.doc);

  /// The factory name (the state name).
  final String name;

  /// The factory's doc comment, whitespace-collapsed (may be empty).
  final String doc;
}

/// A `@freezed sealed class` with its factory cases, in source order.
final class StateUnion {
  /// Creates a union.
  const StateUnion(this.name, this.path, this.cases);

  /// The class name.
  final String name;

  /// Repo-relative path of the declaring file.
  final String path;

  /// The cases.
  final List<UnionCase> cases;
}

/// A screen row of GLOSSARY §10.
final class GlossaryScreen {
  /// Creates a row.
  const GlossaryScreen(this.id, this.name, this.route, this.banner);

  /// `S01` … `S33`.
  final String id;

  /// The screen name.
  final String name;

  /// The route (markdown, as written in the glossary).
  final String route;

  /// The banner screen ID, or `null` when the screen never has a banner.
  final String? banner;
}

/// The inventory could not be built (a stale mapping or a missing input).
final class InventoryException implements Exception {
  /// Creates the exception.
  const InventoryException(this.message);

  /// What is wrong.
  final String message;

  @override
  String toString() => message;
}

final RegExp _sealed = RegExp(r'^sealed class (\w+)', multiLine: true);
final RegExp _factory = RegExp(r'const factory (\w+)\.(\w+)\(');

/// The sealed unions declared in [sources] (repo-relative path → source).
Map<String, StateUnion> parseUnions(Map<String, String> sources) {
  final unions = <String, StateUnion>{};
  for (final MapEntry(key: path, value: source) in sources.entries) {
    final names = {for (final m in _sealed.allMatches(source)) m.group(1)!};
    if (names.isEmpty) continue;
    final cases = <String, List<UnionCase>>{for (final n in names) n: []};
    final lines = source.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final match = _factory.firstMatch(lines[i]);
      if (match == null) continue;
      final list = cases[match.group(1)];
      if (list == null) continue;
      list.add(UnionCase(match.group(2)!, _docAbove(lines, i)));
    }
    for (final name in names) {
      unions[name] = StateUnion(name, path, cases[name]!);
    }
  }
  return unions;
}

String _docAbove(List<String> lines, int index) {
  final doc = <String>[];
  for (var i = index - 1; i >= 0; i--) {
    final line = lines[i].trim();
    if (!line.startsWith('///')) break;
    doc.insert(0, line.substring(3).trim());
  }
  return doc.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

final RegExp _screenRow = RegExp(
  r'^\| (S\d\d) \| (.+?) \| (.+?) \| .+? \| (.+?) \|\s*$',
  multiLine: true,
);

/// The screen rows of GLOSSARY §10 ([glossary] is the whole file).
Map<String, GlossaryScreen> parseGlossaryScreens(String glossary) {
  final start = glossary.indexOf(RegExp(r'^## 10\. ', multiLine: true));
  if (start < 0) {
    throw const InventoryException('GLOSSARY.md has no "## 10." section');
  }
  final end = glossary.indexOf(RegExp(r'^## 11\. ', multiLine: true), start);
  final section = glossary.substring(start, end < 0 ? glossary.length : end);
  return {
    for (final m in _screenRow.allMatches(section))
      m.group(1)!: GlossaryScreen(
        m.group(1)!,
        m.group(2)!.trim(),
        m.group(3)!.trim(),
        _banner(m.group(4)!.trim()),
      ),
  };
}

String? _banner(String cell) {
  final match = RegExp('`([a-z_]+)`').firstMatch(cell);
  return match?.group(1);
}

/// The states of one screen, resolved against the parsed unions.
final class ScreenStates {
  /// Creates the resolution.
  const ScreenStates(this.spec, this.glossary, this.rows);

  /// The mapping.
  final ScreenSpec spec;

  /// The glossary row.
  final GlossaryScreen glossary;

  /// Every state row, in order.
  final List<StateRow> rows;

  /// The ★ state names.
  List<String> get starred => [
    for (final r in rows)
      if (r.starred) r.name,
  ];
}

/// One row of a screen's state table.
final class StateRow {
  /// Creates a row.
  const StateRow(this.name, this.union, this.doc, {required this.starred});

  /// The state name.
  final String name;

  /// The union it belongs to; `null` for a 01 §8.3 state that is not a
  /// union case.
  final String? union;

  /// Its description.
  final String doc;

  /// Whether it gets a golden at phone and tablet width.
  final bool starred;
}

/// Resolves every screen of [screens] against [unions] and [glossary];
/// throws [InventoryException] listing every stale mapping.
List<ScreenStates> resolve(
  List<ScreenSpec> screens,
  Map<String, StateUnion> unions,
  Map<String, GlossaryScreen> glossary,
) {
  final problems = <String>[];
  final result = <ScreenStates>[];
  for (final spec in screens) {
    final row = glossary[spec.id];
    if (row == null) {
      problems.add('${spec.id}: not in GLOSSARY §10');
      continue;
    }
    final rows = <StateRow>[];
    for (final (index, name) in spec.unions.indexed) {
      final union = unions[name];
      if (union == null) {
        problems.add('${spec.id}: union $name not found in apps/taro/lib');
        continue;
      }
      final primary = index == 0;
      final names = {for (final c in union.cases) c.name};
      if (primary) {
        for (final state in {...spec.only, ...spec.starred}) {
          if (!names.contains(state)) {
            problems.add('${spec.id}: $name has no state "$state"');
          }
        }
      }
      for (final c in union.cases) {
        if (primary && spec.only.isNotEmpty && !spec.only.contains(c.name)) {
          continue;
        }
        rows.add(
          StateRow(
            c.name,
            name,
            c.doc,
            starred: primary && spec.starred.contains(c.name),
          ),
        );
      }
    }
    for (final other in spec.other) {
      rows.add(
        StateRow(
          other,
          null,
          '',
          starred: spec.otherStarred.contains(other),
        ),
      );
    }
    result.add(ScreenStates(spec, row, rows));
  }
  if (problems.isNotEmpty) {
    throw InventoryException(problems.join('\n'));
  }
  return result;
}

String _summaryState(StateRow r, {required String? primary}) {
  final name = r.union == primary ? r.name : '${r.union}.${r.name}';
  return '`$name`${r.starred ? '★' : ''}';
}

String _cell(String text) => text.replaceAll('|', r'\|');

/// The markdown document.
String render(
  List<ScreenStates> screens,
  Map<String, StateUnion> unions, {
  required String command,
}) {
  final b = StringBuffer()
    ..writeln('# State inventory (S01–S33)')
    ..writeln()
    ..writeln(
      '> Generated by `$command` from the sealed state unions of the '
      'screen controllers (`apps/taro/lib/features/**`) and GLOSSARY §10. '
      'Do not edit by hand: change the controllers or '
      '`tools/dart_tools/lib/src/state_inventory/screens.dart` and '
      're-run it (`--check` fails when this file is stale). Input of '
      'Phase 14 (Claude Design handoff).',
    )
    ..writeln()
    ..writeln(
      '★ = golden at phone **and** tablet width, light + dark (01 §8.3, '
      'RC24). Banner = the `kBannerAllowList` screen ID (01 PR13, RC18); '
      'every other screen never shows a banner. States without a union are '
      '01 §8.3 states carried as view flags, widget states or redirects.',
    )
    ..writeln()
    ..writeln('## Summary')
    ..writeln()
    ..writeln('| Screen | Route | States | ★ golden | Banner |')
    ..writeln('|---|---|---|---|---|');
  for (final s in screens) {
    final g = s.glossary;
    final primary = s.spec.unions.isEmpty ? null : s.spec.unions.first;
    final states = [
      for (final r in s.rows)
        if (r.union != null) _summaryState(r, primary: primary),
    ];
    final starred = [
      for (final r in s.rows)
        if (r.starred) r.union == null ? r.name : '`${r.name}`',
    ];
    b.writeln(
      '| ${g.id} ${_cell(g.name)} | ${_cell(g.route)} | '
      '${states.isEmpty ? '—' : states.join(', ')} | '
      '${starred.isEmpty ? '—' : _cell(starred.join(', '))} | '
      '${g.banner == null ? '—' : '✅ `${g.banner}`'} |',
    );
  }
  for (final s in screens) {
    final g = s.glossary;
    b
      ..writeln()
      ..writeln('## ${g.id} · ${g.name}')
      ..writeln()
      ..write(
        'Route ${g.route} · Banner '
        '${g.banner == null ? 'none' : '✅ `${g.banner}`'}',
      );
    if (s.spec.unions.isNotEmpty) {
      final sources = [
        for (final name in s.spec.unions) '`$name` (`${unions[name]!.path}`)',
      ];
      b.write(' · Unions: ${sources.join(', ')}');
    }
    b
      ..writeln()
      ..writeln()
      ..writeln('| State | ★ | Union | Description |')
      ..writeln('|---|---|---|---|');
    for (final r in s.rows) {
      b.writeln(
        '| ${r.union == null ? _cell(r.name) : '`${r.name}`'} | '
        '${r.starred ? '★' : ''} | '
        '${r.union == null ? '— (01 §8.3)' : '`${r.union}`'} | '
        '${_cell(r.doc)} |',
      );
    }
  }
  final mapped = {for (final s in screens) ...s.spec.unions};
  final unmapped =
      unions.values
          .where(
            (u) =>
                !mapped.contains(u.name) &&
                u.path.contains('/features/') &&
                u.cases.isNotEmpty,
          )
          .toList()
        ..sort((a, c) => a.name.compareTo(c.name));
  if (unmapped.isNotEmpty) {
    b
      ..writeln()
      ..writeln('## Other sealed unions in `features/` (not screen states)')
      ..writeln()
      ..writeln('| Union | File | Cases |')
      ..writeln('|---|---|---|');
    for (final u in unmapped) {
      b.writeln(
        '| `${u.name}` | `${u.path}` | '
        '${u.cases.map((c) => '`${c.name}`').join(', ')} |',
      );
    }
  }
  return b.toString();
}

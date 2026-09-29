/// `tools/content translate` (01 §11 step 4): machine-translates en cards,
/// spread texts and articles into one locale through a [ClaudeClient], and
/// writes YAML/Markdown with `sourceHash` and `reviewStatus: machine`.
library;

import 'dart:convert';
import 'dart:io';

import 'package:taro_dart_tools/src/content/banned.dart';
import 'package:taro_dart_tools/src/content/claude_client.dart';
import 'package:taro_dart_tools/src/content/common.dart';
import 'package:taro_dart_tools/src/content/ids.dart';
import 'package:taro_dart_tools/src/content/source.dart';
import 'package:taro_dart_tools/src/content/validator.dart';
import 'package:taro_dart_tools/src/content/yaml_writer.dart';

/// Human names of the locales, for the prompt.
const Map<String, String> kLocaleNames = {
  'ar': 'Arabic (Modern Standard Arabic)',
  'de': 'German (informal "du")',
  'es': 'Spanish',
  'fr': 'French',
  'it': 'Italian',
  'ja': 'Japanese (polite form)',
  'ko': 'Korean (polite form)',
  'nl': 'Dutch',
  'pt': 'Portuguese',
  'tr': 'Turkish',
  'uk': 'Ukrainian',
};

/// The parts `translate` can produce.
enum TranslatePart {
  /// `<locale>/cards/<cardId>.yaml`.
  cards,

  /// `<locale>/spreads.yaml`.
  spreads,

  /// `<locale>/articles/{about,faq}.md`.
  articles,
}

/// Options of one run.
final class TranslateOptions {
  /// Creates options.
  const TranslateOptions({
    required this.locale,
    required this.parts,
    this.cards,
    this.force = false,
    this.dryRun = false,
    this.model = kDefaultTranslateModel,
    this.allowUnreviewedGlossary = false,
  });

  /// Target locale (not `en`).
  final String locale;

  /// What to translate.
  final Set<TranslatePart> parts;

  /// Card IDs to consider; `null` = all 78.
  final List<String>? cards;

  /// Re-translate current translations too.
  final bool force;

  /// Print the plan only (no API call, no key needed).
  final bool dryRun;

  /// Claude model ID.
  final String model;

  /// Skip the "glossary reviewed" gate (01 §11 step 2).
  final bool allowUnreviewedGlossary;
}

/// One unit of work.
final class TranslateJob {
  /// Creates a job.
  const TranslateJob(this.part, this.id, this.status, this.path);

  /// Cards, spreads or articles.
  final TranslatePart part;

  /// Card or article ID (`spreads` for the spreads file).
  final String id;

  /// `missing`, `stale` or `current` (with `--force`).
  final String status;

  /// Repository-relative output path.
  final String path;
}

Map<String, Object?> _m(Object? v) => v! as Map<String, Object?>;

/// Translates per [options]; returns the exit code.
Future<int> translate(
  Directory root,
  TranslateOptions options, {
  required ClaudeClient? Function() client,
  required BannedPhrases banned,
  required DateTime today,
  required StringSink out,
  required StringSink err,
}) async {
  final locale = options.locale;
  final source = ContentSource.load(root);
  final result = validate(source, banned, ValidateOptions(today: today));
  final blocking = result.errors
      .where(
        (i) =>
            i.path.startsWith('$kSourceDir/en/') ||
            i.path == '$kSourceDir/glossary.yaml' ||
            i.path == '$kSourceDir/deck.yaml',
      )
      .toList();
  if (blocking.isNotEmpty) {
    blocking.take(20).forEach(err.writeln);
    err.writeln(
      'translate: fix the ${blocking.length} en/glossary error(s) first '
      '(tools/content/validate)',
    );
    return 1;
  }
  final glossary = _m(source.glossary);
  final review = _m(glossary['review']);
  if (review[locale] != 'reviewed' && !options.allowUnreviewedGlossary) {
    err.writeln(
      'translate: glossary.yaml review.$locale is "${review[locale]}"; the '
      'glossary must be reviewed before translation (01 §11 step 2). Use '
      '--allow-unreviewed-glossary for a draft run.',
    );
    return 1;
  }
  final jobs = planJobs(source, options);
  if (jobs.isEmpty) {
    out.writeln('translate $locale: nothing to do (all current)');
    return 0;
  }
  for (final job in jobs) {
    out.writeln('translate $locale: ${job.path} (${job.status})');
  }
  if (options.dryRun) {
    out.writeln('translate $locale: dry run, ${jobs.length} file(s) planned');
    return 0;
  }
  final claude = client();
  if (claude == null) {
    err.writeln('translate: ANTHROPIC_API_KEY is not set');
    return 1;
  }
  final prompt = _SystemPrompt(root, source, banned, locale);
  for (final job in jobs) {
    try {
      final content = switch (job.part) {
        TranslatePart.cards => await _card(
          claude,
          options,
          prompt,
          source,
          job.id,
        ),
        TranslatePart.spreads => await _spreads(
          claude,
          options,
          prompt,
          source,
        ),
        TranslatePart.articles => await _article(
          claude,
          options,
          prompt,
          source,
          job.id,
        ),
      };
      File('${root.path}/${job.path}')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(content);
      out.writeln('translate $locale: wrote ${job.path}');
    } on ClaudeException catch (e) {
      err.writeln('translate: ${job.path}: ${e.message}');
      return 1;
    }
  }
  final after = validate(
    ContentSource.load(root),
    banned,
    ValidateOptions(today: today),
  );
  final written = {for (final j in jobs) j.path};
  final problems = after.errors.where((i) => written.contains(i.path)).toList()
    ..forEach(err.writeln);
  if (problems.isNotEmpty) {
    err.writeln(
      'translate $locale: ${problems.length} validation error(s) in the '
      'written files; fix them before review',
    );
    return 1;
  }
  out.writeln('translate $locale: ${jobs.length} file(s) written, valid');
  return 0;
}

/// The jobs of [options] against [source] (missing and stale files, plus
/// current ones with `--force`).
List<TranslateJob> planJobs(ContentSource source, TranslateOptions options) {
  final locale = options.locale;
  final jobs = <TranslateJob>[];
  String? status(Object? front, String current) {
    if (front == null) return 'missing';
    final hash = front is Map ? front['sourceHash'] : null;
    if (hash != current) return 'stale';
    return options.force ? 'current' : null;
  }

  if (options.parts.contains(TranslatePart.cards)) {
    for (final id in options.cards ?? kCardIds) {
      final hash = cardSourceHash(_m(source.cards[kSourceLocale]![id]));
      final s = status(source.cards[locale]?[id], hash);
      if (s != null) {
        jobs.add(
          TranslateJob(
            TranslatePart.cards,
            id,
            s,
            '$kSourceDir/$locale/cards/$id.yaml',
          ),
        );
      }
    }
  }
  if (options.parts.contains(TranslatePart.spreads)) {
    final hash = spreadsSourceHash(_m(source.spreads[kSourceLocale]));
    final s = status(source.spreads[locale], hash);
    if (s != null) {
      jobs.add(
        TranslateJob(
          TranslatePart.spreads,
          'spreads',
          s,
          '$kSourceDir/$locale/spreads.yaml',
        ),
      );
    }
  }
  if (options.parts.contains(TranslatePart.articles)) {
    for (final id in kArticleIds) {
      final en = source.articles[kSourceLocale]![id]!;
      final s = status(
        source.articles[locale]?[id]?.frontMatter,
        articleSourceHash(en.body),
      );
      if (s != null) {
        jobs.add(
          TranslateJob(
            TranslatePart.articles,
            id,
            s,
            '$kSourceDir/$locale/articles/$id.md',
          ),
        );
      }
    }
  }
  return jobs;
}

final class _SystemPrompt {
  _SystemPrompt(this.root, this.source, this.banned, this.locale);

  final Directory root;
  final ContentSource source;
  final BannedPhrases banned;
  final String locale;

  String build(String task) {
    final glossary = _m(source.glossary);
    final names = StringBuffer();
    for (final section in ['cards', 'suits', 'arcana', 'positions', 'terms']) {
      for (final v in _m(glossary[section]).values) {
        final map = _m(v);
        if (map[locale] != null) {
          names.writeln('- ${map['en']} → ${map[locale]}');
        }
      }
    }
    final styleFile = File('${root.path}/$kStyleGuidePath');
    final style = styleFile.existsSync() ? styleFile.readAsStringSync() : '';
    return '''
You translate content of Taro, a reflective tarot journal app, from English into ${kLocaleNames[locale]} (locale "$locale"). $task

Rules:
- Reflection voice only: invite the reader to consider and notice; never predict, promise or claim certainty; no fear, fate or doom; no medical, legal, financial, pregnancy or religious claims. "Future" and "outcome" mean where things may be heading if nothing changes.
- Address the reader as a gender-neutral "you" in the locale's register.
- Keep the meaning, tone, structure and paragraph breaks of the English text. Do not add or drop ideas.
- Card and spread texts are plain text: no Markdown, HTML or emoji.
- Use these glossary terms exactly:
$names- Never use these banned words or phrases (or close variants): ${banned.phrasesFor(locale).join(', ')}.
- Answer with the JSON object the schema describes and nothing else.

Style guide:
$style''';
  }
}

String _header(TranslateOptions options) =>
    'Machine translation by tools/content/translate (${options.model}); '
    'reviewStatus: machine until a native reviewer edits it.';

Map<String, Object?> _stringSchema() => {'type': 'string'};

Map<String, Object?> _objectSchema(Map<String, Object?> properties) => {
  'type': 'object',
  'additionalProperties': false,
  'required': properties.keys.toList(),
  'properties': properties,
};

/// The answer schema of a card translation.
Map<String, Object?> cardAnswerSchema() {
  final list = {'type': 'array', 'items': _stringSchema()};
  return _objectSchema({
    'name': _stringSchema(),
    'keywordsUpright': list,
    'keywordsReversed': list,
    'shortUpright': _stringSchema(),
    'shortReversed': _stringSchema(),
    'meaningUpright': _stringSchema(),
    'meaningReversed': _stringSchema(),
    'aspects': _objectSchema({for (final k in kAspectKeys) k: _stringSchema()}),
    'reflectionQuestions': list,
    'imageryNote': _stringSchema(),
  });
}

Object? _trim(Object? v) => switch (v) {
  final String s => s.trim(),
  final List<Object?> l => [for (final e in l) _trim(e)],
  final Map<String, Object?> m => {
    for (final e in m.entries) e.key: _trim(e.value),
  },
  _ => v,
};

Future<String> _card(
  ClaudeClient claude,
  TranslateOptions options,
  _SystemPrompt prompt,
  ContentSource source,
  String id,
) async {
  final en = _m(source.cards[kSourceLocale]![id]);
  final name = _m(_m(_m(source.glossary)['cards'])[id])[options.locale];
  final answer = await claude.complete(
    ClaudeRequest(
      model: options.model,
      system: prompt.build(
        'Translate one tarot card text. Keep 3–6 keywords of at most 24 '
        'characters each, short texts under 160 characters, exactly 3 '
        'reflection questions under 120 characters, and long texts about '
        'as long as the English.',
      ),
      user: const JsonEncoder.withIndent('  ').convert({
        'cardId': id,
        for (final k in kCardTextKeys) k: en[k],
      }),
      schema: cardAnswerSchema(),
    ),
  );
  final card = _m(_trim(answer));
  return toYaml(
    {
      'cardId': id,
      'reviewStatus': 'machine',
      'sourceHash': cardSourceHash(en),
      for (final k in kCardTextKeys)
        k: k == 'name' && name != null ? name : card[k],
    },
    header: [_header(options)],
  );
}

Future<String> _spreads(
  ClaudeClient claude,
  TranslateOptions options,
  _SystemPrompt prompt,
  ContentSource source,
) async {
  final en = _m(source.spreads[kSourceLocale]);
  final whenToUse = {
    for (final s in en['spreads']! as List)
      '${_m(s)['id']}': _m(s)['whenToUse'],
  };
  final answer = await claude.complete(
    ClaudeRequest(
      model: options.model,
      system: prompt.build(
        'Translate the "when to use" text of each tarot spread; keep the '
        'spread IDs as keys.',
      ),
      user: const JsonEncoder.withIndent(
        '  ',
      ).convert({'whenToUse': whenToUse}),
      schema: _objectSchema({
        'whenToUse': _objectSchema({
          for (final id in kSpreadPositions.keys) id: _stringSchema(),
        }),
      }),
    ),
  );
  final texts = _m(_m(_trim(answer))['whenToUse']);
  return toYaml(
    {
      'reviewStatus': 'machine',
      'sourceHash': spreadsSourceHash(en),
      'whenToUse': {for (final id in kSpreadPositions.keys) id: texts[id]},
    },
    header: [_header(options)],
  );
}

Future<String> _article(
  ClaudeClient claude,
  TranslateOptions options,
  _SystemPrompt prompt,
  ContentSource source,
  String id,
) async {
  final en = source.articles[kSourceLocale]![id]!;
  final answer = await claude.complete(
    ClaudeRequest(
      model: options.model,
      system: prompt.build(
        'Translate one Learn article written in Markdown. Keep the Markdown '
        'structure (headings, lists, links, bold) and the URLs unchanged; no '
        'raw HTML. The first line stays a level-1 heading.',
      ),
      user: en.body,
      schema: _objectSchema({'markdown': _stringSchema()}),
    ),
  );
  final markdown = '${_m(_trim(answer))['markdown']}';
  return '---\n'
      'reviewStatus: machine\n'
      'sourceHash: ${articleSourceHash(en.body)}\n'
      '---\n'
      '$markdown\n';
}

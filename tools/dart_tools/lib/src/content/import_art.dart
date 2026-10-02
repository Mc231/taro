/// `tools/content/import_art`: imports the D15 deck art (Phase 18 Sprint 18.1;
/// 01 §16, 02 §17, 05 §6.1).
///
/// Input: a folder with one image per art key, named `<cardId>.<ext>` for the
/// 78 cards and `back.<ext>` for the card back (`ext` = png, jpg, jpeg or
/// webp). Every file is checked (complete set, no strays, decodable, aspect
/// ratio = the `size.card.aspectRatio` token within a tolerance, wide enough
/// for @3x), centre-cropped to the exact ratio, resized and encoded as lossy
/// WebP with `cwebp` (libwebp; `brew install webp`). The quality steps down
/// from [kArtQualities] until the @3x file fits [kArtBudgetBytes].
///
/// Output under `apps/taro/assets/deck/art/<artSet>/`:
/// * `<artKey>.webp`: the @2x pixels as the main asset (no 1x file is
///   shipped; Flutter picks the main entry up to 2.0 dpr),
/// * `3.0x/<artKey>.webp`: the @3x variant,
/// * `art_manifest.json`: sizes, qualities and the `cacheWidth` hints per
///   card size token (decode width = min(token width × dpr, @3x width)).
///
/// `artKey` = card ID, `card_back` for the back (as in the placeholder set).
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:taro_dart_tools/src/content/common.dart';
import 'package:taro_dart_tools/src/content/ids.dart';
import 'package:taro_dart_tools/src/content/placeholder_art.dart';

/// The design tokens file (`size.card.*`).
const String kTokensPath = 'docs/design/taro.tokens.json';

/// The app pubspec whose `flutter.assets` lists the art folder.
const String kAppPubspecPath = 'apps/taro/pubspec.yaml';

/// `deck.yaml` (its `artSet` selects the bundled art).
const String kDeckYamlPath = '$kSourceDir/deck.yaml';

/// The manifest written next to the art.
const String kArtManifestName = 'art_manifest.json';

/// The folder of the @3x variants inside an art set.
const String kArt3xDir = '3.0x';

/// Byte budget per card file (@3x and @2x): 150 KB (02 §17, the stricter
/// of 01 §16 and 02 §17).
const int kArtBudgetBytes = 150 * 1000;

/// Default @3x width in pixels: 3 × `size.card.lg` (220).
const int kDefaultArtWidth3x = 660;

/// Default relative tolerance of the source aspect ratio.
const double kDefaultAspectTolerance = 0.02;

/// WebP qualities tried in order until the @3x file fits the budget.
const List<int> kArtQualities = [90, 85, 80, 75, 70, 65, 60];

/// The device pixel ratios the `cacheWidth` hints are given for.
const List<int> kHintDprs = [2, 3];

/// Source image extensions.
const List<String> kArtSourceExtensions = ['png', 'jpg', 'jpeg', 'webp'];

/// The source file stem of the card back.
const String kSourceBackStem = 'back';

/// Repository-relative folder of [artSet].
String artSetDir(String artSet) => '$kAppDeckDir/art/$artSet';

/// The main (@2x) asset of [artKey] in [artSet].
String artMainPath(String artSet, String artKey) =>
    '${artSetDir(artSet)}/$artKey.webp';

/// The @3x variant of [artKey] in [artSet].
String art3xPath(String artSet, String artKey) =>
    '${artSetDir(artSet)}/$kArt3xDir/$artKey.webp';

/// An encoder failure (missing binary, non-zero exit).
final class ArtEncoderException implements Exception {
  /// Creates the exception.
  const ArtEncoderException(this.message);

  /// What went wrong.
  final String message;

  @override
  String toString() => message;
}

/// Encodes an image as WebP at a quality (0–100).
abstract interface class ArtEncoder {
  /// The encoder and its version, for the manifest; throws
  /// [ArtEncoderException] when the encoder is unavailable.
  String describe();

  /// [image] as WebP at [quality].
  Uint8List encode(img.Image image, {required int quality});
}

/// Runs a process synchronously (`Process.runSync`; injected by tests).
typedef RunProcess =
    ProcessResult Function(String executable, List<String> arguments);

/// The production encoder: libwebp's `cwebp` (macOS: `brew install webp`;
/// Linux: the `webp` package).
final class CwebpEncoder implements ArtEncoder {
  /// Creates the encoder for [executable].
  CwebpEncoder({this.executable = 'cwebp', RunProcess? run})
    : _run = run ?? Process.runSync;

  /// The `cwebp` binary.
  final String executable;
  final RunProcess _run;

  ProcessResult _exec(List<String> args) {
    try {
      return _run(executable, args);
    } on ProcessException catch (e) {
      throw ArtEncoderException(
        '$executable not runnable (${e.message}); install libwebp '
        '(brew install webp) or pass --cwebp',
      );
    }
  }

  @override
  String describe() {
    final result = _exec(['-version']);
    if (result.exitCode != 0) {
      throw ArtEncoderException(
        '$executable -version exited ${result.exitCode}',
      );
    }
    return 'cwebp ${'${result.stdout}'.trim()}';
  }

  @override
  Uint8List encode(img.Image image, {required int quality}) {
    final dir = Directory.systemTemp.createTempSync('taro_cwebp_');
    try {
      final input = File('${dir.path}/in.png')
        ..writeAsBytesSync(img.encodePng(image, level: 1));
      final output = File('${dir.path}/out.webp');
      final result = _exec([
        '-quiet',
        '-q',
        '$quality',
        '-m',
        '6',
        '-sharp_yuv',
        '-metadata',
        'none',
        input.path,
        '-o',
        output.path,
      ]);
      if (result.exitCode != 0 || !output.existsSync()) {
        throw ArtEncoderException(
          '$executable exited ${result.exitCode}: ${'${result.stderr}'.trim()}',
        );
      }
      return output.readAsBytesSync();
    } finally {
      dir.deleteSync(recursive: true);
    }
  }
}

/// The `size.card` tokens: the aspect ratio and the card widths by name.
typedef CardSizeTokens = ({double aspectRatio, Map<String, int> widths});

/// Reads `size.card.*` from [kTokensPath] under [root].
CardSizeTokens readCardSizeTokens(Directory root) {
  final Object? doc;
  try {
    doc = jsonDecode(File('${root.path}/$kTokensPath').readAsStringSync());
  } on FileSystemException catch (e) {
    throw ContentFormatException(kTokensPath, e.message);
  } on FormatException catch (e) {
    throw ContentFormatException(kTokensPath, e.message);
  }
  final size = doc is Map ? doc['size'] : null;
  final card = size is Map ? size['card'] : null;
  if (card is! Map) {
    throw const ContentFormatException(kTokensPath, 'no size.card group');
  }
  double? number(Object? token) {
    final value = token is Map ? token[r'$value'] : null;
    return value is num
        ? value.toDouble()
        : double.tryParse('$value'.replaceAll('px', ''));
  }

  final aspect = number(card['aspectRatio']);
  if (aspect == null || aspect <= 0) {
    throw const ContentFormatException(
      kTokensPath,
      'size.card.aspectRatio is not a positive number',
    );
  }
  final widths = <String, int>{
    for (final MapEntry(:key, :value) in card.entries)
      if (key != 'aspectRatio' && number(value) != null)
        '$key': number(value)!.round(),
  };
  return (aspectRatio: aspect, widths: widths);
}

/// Options of one import.
final class ArtImportOptions {
  /// Creates the options.
  const ArtImportOptions({
    required this.artSet,
    required this.aspectRatio,
    this.cardWidths = const {},
    this.width3x = kDefaultArtWidth3x,
    this.aspectTolerance = kDefaultAspectTolerance,
    this.budgetBytes = kArtBudgetBytes,
    this.qualities = kArtQualities,
  });

  /// The art set key (snake_case, not `placeholder`).
  final String artSet;

  /// Width / height (`size.card.aspectRatio`).
  final double aspectRatio;

  /// Card widths in logical pixels by token name (`size.card.*`).
  final Map<String, int> cardWidths;

  /// Output width @3x in pixels.
  final int width3x;

  /// Accepted relative deviation of the source ratio.
  final double aspectTolerance;

  /// Byte budget per file.
  final int budgetBytes;

  /// Qualities tried in order.
  final List<int> qualities;

  /// The @3x size.
  (int, int) get size3x => (width3x, (width3x / aspectRatio).round());

  /// The @2x size.
  (int, int) get size2x {
    final w = (width3x * 2 / 3).round();
    return (w, (w / aspectRatio).round());
  }
}

/// The result of planning an import: files to write or the problems found.
final class ArtImport {
  /// Creates the result.
  const ArtImport(this.files, this.errors);

  /// Repository-relative path → bytes (art and manifest).
  final Map<String, Uint8List> files;

  /// One line per problem; nothing is written when non-empty.
  final List<String> errors;
}

/// The art key of a source file stem, or null when it is not one.
String? artKeyOfStem(String stem) => stem == kSourceBackStem
    ? kCardBackKey
    : (kCardIds.contains(stem) ? stem : null);

/// Finds the source image of every art key in [source]; problems go to
/// [errors].
Map<String, File> scanArtSource(Directory source, List<String> errors) {
  if (!source.existsSync()) {
    errors.add('${source.path}: source folder does not exist');
    return const {};
  }
  final found = <String, File>{};
  final entries = source.listSync().whereType<File>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in entries) {
    final name = file.uri.pathSegments.last;
    if (name.startsWith('.')) continue;
    final dot = name.lastIndexOf('.');
    final stem = dot < 0 ? name : name.substring(0, dot);
    final ext = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
    final key = artKeyOfStem(stem);
    if (key == null || !kArtSourceExtensions.contains(ext)) {
      errors.add(
        '$name: not a card ID or "$kSourceBackStem" with '
        '${kArtSourceExtensions.join('/')}',
      );
      continue;
    }
    if (found.containsKey(key)) {
      errors.add('$name: second file for $key');
      continue;
    }
    found[key] = file;
  }
  for (final key in placeholderArtKeys()) {
    if (!found.containsKey(key)) {
      final stem = key == kCardBackKey ? kSourceBackStem : key;
      errors.add('$stem: missing');
    }
  }
  return found;
}

/// Whether [width] × [height] is within [tolerance] of [aspect].
bool aspectMatches(int width, int height, double aspect, double tolerance) =>
    height > 0 && ((width / height) - aspect).abs() / aspect <= tolerance;

/// [image] centre-cropped to [aspect] (width / height).
img.Image cropToAspect(img.Image image, double aspect) {
  final w = image.width;
  final h = image.height;
  if (w / h > aspect) {
    final cw = math.min(w, (h * aspect).round());
    return img.copyCrop(image, x: (w - cw) ~/ 2, y: 0, width: cw, height: h);
  }
  final ch = math.min(h, (w / aspect).round());
  return img.copyCrop(image, x: 0, y: (h - ch) ~/ 2, width: w, height: ch);
}

/// `cacheWidth` hints: token name → dpr → decode width (≤ @3x width).
Map<String, Map<String, int>> cacheWidthHints(ArtImportOptions options) => {
  for (final MapEntry(:key, :value) in options.cardWidths.entries)
    key: {
      for (final dpr in kHintDprs)
        '$dpr': math.min(value * dpr, options.width3x),
    },
};

/// Plans the import of [source] with [encoder]: validates every file first,
/// then converts. Writes nothing.
ArtImport planArtImport(
  Directory source,
  ArtImportOptions options,
  ArtEncoder encoder, {
  void Function(String line)? log,
}) {
  final errors = <String>[];
  final String encoderName;
  try {
    encoderName = encoder.describe();
  } on ArtEncoderException catch (e) {
    return ArtImport(const {}, ['encoder: $e']);
  }
  final sources = scanArtSource(source, errors);
  final (w3, h3) = options.size3x;
  final (w2, h2) = options.size2x;
  final images = <String, img.Image>{};
  for (final MapEntry(:key, value: file) in sources.entries) {
    final name = file.uri.pathSegments.last;
    final image = img.decodeNamedImage(file.path, file.readAsBytesSync());
    if (image == null) {
      errors.add('$name: not a decodable image');
      continue;
    }
    if (!aspectMatches(
      image.width,
      image.height,
      options.aspectRatio,
      options.aspectTolerance,
    )) {
      errors.add(
        '$name: ${image.width}×${image.height} is not '
        'size.card.aspectRatio ${options.aspectRatio} '
        '(±${(options.aspectTolerance * 100).toStringAsFixed(1)} %)',
      );
      continue;
    }
    if (image.width < w3) {
      errors.add('$name: ${image.width} px wide; @3x needs at least $w3 px');
      continue;
    }
    images[key] = image;
  }
  if (errors.isNotEmpty) return ArtImport(const {}, errors);

  final files = <String, Uint8List>{};
  final records = <String, Object?>{};
  var total = 0;
  for (final key in placeholderArtKeys()) {
    final cropped = cropToAspect(images[key]!, options.aspectRatio);
    final x3 = img.copyResize(
      cropped,
      width: w3,
      height: h3,
      interpolation: img.Interpolation.average,
    );
    final x2 = img.copyResize(
      cropped,
      width: w2,
      height: h2,
      interpolation: img.Interpolation.average,
    );
    Uint8List? bytes3;
    Uint8List? bytes2;
    var quality = options.qualities.first;
    for (final q in options.qualities) {
      quality = q;
      bytes3 = encoder.encode(x3, quality: q);
      if (bytes3.length <= options.budgetBytes) break;
    }
    if (bytes3!.length > options.budgetBytes) {
      errors.add(
        '$key: @3x is ${bytes3.length} bytes at quality $quality '
        '(budget ${options.budgetBytes})',
      );
      continue;
    }
    bytes2 = encoder.encode(x2, quality: quality);
    files[artMainPath(options.artSet, key)] = bytes2;
    files[art3xPath(options.artSet, key)] = bytes3;
    total += bytes2.length + bytes3.length;
    records[key] = {
      'quality': quality,
      'bytes2x': bytes2.length,
      'bytes3x': bytes3.length,
    };
    log?.call(
      '$key: q$quality, @2x ${bytes2.length} B, @3x ${bytes3.length} B',
    );
  }
  if (errors.isNotEmpty) return ArtImport(const {}, errors);
  files['${artSetDir(options.artSet)}/$kArtManifestName'] = utf8.encode(
    canonicalJson({
      'artSet': options.artSet,
      'aspectRatio': options.aspectRatio,
      'budgetBytes': options.budgetBytes,
      'encoder': encoderName,
      'densities': {
        '2x': {'width': w2, 'height': h2, 'path': '<artKey>.webp'},
        '3x': {'width': w3, 'height': h3, 'path': '$kArt3xDir/<artKey>.webp'},
      },
      'cacheWidth': cacheWidthHints(options),
      'files': records,
      'totalBytes': total,
    }),
  );
  return ArtImport(files, const []);
}

/// Every file currently under the folder of [artSet] (repository-relative).
List<String> listArtSet(Directory root, String artSet) {
  final dir = Directory('${root.path}/${artSetDir(artSet)}');
  if (!dir.existsSync()) return [];
  final prefix = '${root.path}/';
  return [
    for (final f in dir.listSync(recursive: true).whereType<File>())
      f.path.substring(prefix.length),
  ]..sort();
}

/// [yaml] (`deck.yaml`) with its top-level `artSet` set to [artSet];
/// comments and other keys are kept.
String withArtSet(String yaml, String artSet) {
  final line = RegExp(r'^artSet:.*$', multiLine: true);
  return line.hasMatch(yaml)
      ? yaml.replaceFirst(line, 'artSet: $artSet')
      : '${yaml.endsWith('\n') || yaml.isEmpty ? yaml : '$yaml\n'}'
            'artSet: $artSet\n';
}

/// [pubspec] with `- assets/deck/art/<artSet>/` under `flutter.assets`
/// (after the last art entry); unchanged when present.
String withArtAsset(String pubspec, String artSet) {
  final entry = 'assets/deck/art/$artSet/';
  final lines = pubspec.split('\n');
  if (lines.any((l) => l.trim() == '- $entry')) return pubspec;
  final last = lines.lastIndexWhere(
    (l) => l.trimLeft().startsWith('- assets/deck/art/'),
  );
  if (last < 0) {
    throw const ContentFormatException(
      kAppPubspecPath,
      'no "- assets/deck/art/" entry to add the art set after',
    );
  }
  final indent = lines[last].substring(
    0,
    lines[last].length - lines[last].trimLeft().length,
  );
  lines.insert(last + 1, '$indent- $entry');
  return lines.join('\n');
}

/// Checks the bundled [artSet]: the 79 main files exist, nothing else but
/// the manifest and `3.0x/`, each file within [budgetBytes], and (not for
/// the placeholder set) every @3x variant exists with [aspectRatio].
List<String> checkArtSet(
  Directory root,
  String artSet, {
  required double aspectRatio,
  double aspectTolerance = kDefaultAspectTolerance,
  int budgetBytes = kArtBudgetBytes,
}) {
  final problems = <String>[];
  final dir = artSetDir(artSet);
  final present = listArtSet(root, artSet).toSet();
  if (present.isEmpty) return ['$dir: no art (run tools/content/import_art)'];
  final strict = artSet != kPlaceholderArtSet;
  final expected = <String>{'$dir/$kArtManifestName'};
  for (final key in placeholderArtKeys()) {
    final paths = [
      artMainPath(artSet, key),
      if (strict) art3xPath(artSet, key),
    ];
    for (final path in paths) {
      expected.add(path);
      final file = File('${root.path}/$path');
      if (!file.existsSync()) {
        problems.add('$path: missing');
        continue;
      }
      final bytes = file.readAsBytesSync();
      if (bytes.length > budgetBytes) {
        problems.add('$path: ${bytes.length} bytes > budget $budgetBytes');
      }
      if (!strict) continue;
      final info = img.WebPDecoder().startDecode(bytes);
      if (info == null) {
        problems.add('$path: not a WebP file');
      } else if (!aspectMatches(
        info.width,
        info.height,
        aspectRatio,
        aspectTolerance,
      )) {
        problems.add('$path: ${info.width}×${info.height} is not $aspectRatio');
      }
    }
  }
  if (strict && !present.contains('$dir/$kArtManifestName')) {
    problems.add('$dir/$kArtManifestName: missing');
  }
  for (final path in present.difference(expected)) {
    problems.add('$path: not part of the art set');
  }
  final pubspec = File('${root.path}/$kAppPubspecPath');
  if (pubspec.existsSync() &&
      !pubspec.readAsStringSync().contains('- assets/deck/art/$artSet/')) {
    problems.add('$kAppPubspecPath: no "- assets/deck/art/$artSet/" entry');
  }
  return problems..sort();
}

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:taro_ui/taro_ui.dart';

/// Placeholder card art for deck tests and goldens: a painted card face
/// (field, frame and a suit glyph) that resolves synchronously, so goldens
/// never race the image decoder. `taro_ui` takes art as an
/// `ImageProvider`; the app passes its bundled `assets/deck/art/*`.
@immutable
class PlaceholderArt extends ImageProvider<PlaceholderArt> {
  /// Creates art for [glyph]; [width] × [height] device pixels.
  const PlaceholderArt({
    this.glyph = TaroIcons.cup,
    this.width = 116,
    this.height = 200,
  });

  /// The glyph painted in the middle (makes a reversed card visible).
  final TaroIcons glyph;

  /// Pixel width.
  final int width;

  /// Pixel height.
  final int height;

  static final Map<PlaceholderArt, ui.Image> _cache = {};

  ui.Image _render() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(width.toDouble(), height.toDouble());
    const colors = TaroColorTokens.light;
    canvas
      ..drawRect(Offset.zero & size, Paint()..color = colors.bg.surface)
      ..drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height / 3),
        Paint()..color = colors.accent.subtle,
      );
    final glyphSize = size.width / 2;
    canvas
      ..save()
      ..translate(size.width / 4, size.height / 2 - glyphSize / 2);
    TaroGlyphPainter(
      glyph,
      color: colors.suit.cups,
    ).paint(canvas, Size.square(glyphSize));
    canvas.restore();
    final picture = recorder.endRecording();
    final image = picture.toImageSync(width, height);
    picture.dispose();
    return image;
  }

  @override
  Future<PlaceholderArt> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    PlaceholderArt key,
    ImageDecoderCallback decode,
  ) {
    final image = _cache.putIfAbsent(key, key._render);
    return OneFrameImageStreamCompleter(
      SynchronousFuture(ImageInfo(image: image.clone())),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PlaceholderArt &&
      other.glyph == glyph &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(glyph, width, height);
}

/// An image that never finishes loading (the art-loading skeleton state).
class PendingArt extends ImageProvider<PendingArt> {
  /// Creates the provider.
  const PendingArt();

  @override
  Future<PendingArt> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(PendingArt key, ImageDecoderCallback decode) =>
      _PendingCompleter();
}

class _PendingCompleter extends ImageStreamCompleter {}

/// An image that fails to load (the art error state).
class BrokenArt extends ImageProvider<BrokenArt> {
  /// Creates the provider.
  const BrokenArt();

  @override
  Future<BrokenArt> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(BrokenArt key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(
        Future<ImageInfo>.error(StateError('broken art')),
      );
}

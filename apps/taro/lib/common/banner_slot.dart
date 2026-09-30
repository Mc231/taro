import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;
import 'package:taro/app_state/consent_controller.dart';
import 'package:taro/app_state/entitlement_controller.dart';
import 'package:taro/app_state/remote_config_controller.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// The number of completed AI readings on this device (Classic, pending,
/// failed and refused readings do not count): the
/// `ads.bannerMinCompletedReadings` input of [BannerPolicy] (04 §8).
final StreamProvider<int> completedAiReadingsProvider = StreamProvider(
  (ref) => ref
      .watch(journalRepositoryProvider)
      .watchAll(query: const JournalQuery(includeDailyCards: false))
      .map(
        (items) => items
            .where(
              (item) =>
                  item is JournalReadingItem &&
                  item.reading.status is ReadingStatusComplete,
            )
            .length,
      ),
);

/// Whether a screen's banner may show now (`BannerPolicy.shouldShow` over
/// the remote config, the Remove Banner Ads entitlement, UMP's
/// `canRequestAds` and the completed AI readings; RC18).
final ProviderFamily<bool, BannerScreen> bannerVisibleProvider =
    Provider.family<bool, BannerScreen>((
      ref,
      screen,
    ) {
      final completed = ref.watch(completedAiReadingsProvider).value;
      if (completed == null) return false;
      return BannerPolicy.shouldShow(
        screen.id,
        config: ref.watch(remoteConfigProvider),
        entitlement: ref.watch(entitlementProvider),
        canRequestAds: ref.watch(consentProvider).ads.canRequestAds,
        completedReadings: completed,
      );
    });

/// The bottom banner of a `kBannerAllowList` screen (S05 `home`, S14
/// `journal_list`, S16 `learn_library`; 01 PR13, 04 §8, RC18, RC59).
///
/// Place it **outside** the scroll view, below the content and above the
/// tab bar. The ad comes from the `BannerSlotView` port in `di/`; it is
/// zero-sized until an ad has loaded, and then sits in its own
/// `color.ad.container` band with `space.adGap` (≥ 16 dp) above and below.
/// When the policy says no, or the ad fails, the slot and both gaps
/// collapse to nothing (no empty box).
class BannerSlot extends ConsumerWidget {
  /// Creates the slot for [screen].
  const BannerSlot(this.screen, {super.key});

  /// The banner screen ID.
  final BannerScreen screen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(bannerVisibleProvider(screen));
    if (!visible) return const SizedBox.shrink();
    final tokens = context.tokens;
    final view = ref.watch(bannerSlotViewProvider);
    return Semantics(
      container: true,
      label: TaroLocalizations.of(context).commonAdSemantics,
      child: AdGapFrame(
        gap: tokens.space.adGap,
        color: tokens.color.ad.container,
        child: view.build(screen, visible: true),
      ),
    );
  }
}

/// Adds [gap] above and below [child] and paints [color] behind it, but
/// only while [child] has a height: a zero-height child (an ad that has not
/// loaded, or failed) makes the whole frame zero-sized.
class AdGapFrame extends SingleChildRenderObjectWidget {
  /// Creates the frame.
  const AdGapFrame({
    required this.gap,
    required this.color,
    super.child,
    super.key,
  });

  /// The vertical gap on each side (`space.adGap`).
  final double gap;

  /// The band colour behind the child (`color.ad.container`).
  final Color color;

  @override
  RenderAdGapFrame createRenderObject(BuildContext context) =>
      RenderAdGapFrame(gap: gap, color: color);

  @override
  void updateRenderObject(BuildContext context, RenderAdGapFrame renderObject) {
    renderObject
      ..gap = gap
      ..color = color;
  }
}

/// The render object of [AdGapFrame].
class RenderAdGapFrame extends RenderShiftedBox {
  /// Creates the render object.
  RenderAdGapFrame({required double gap, required Color color})
    : _gap = gap,
      _color = color,
      super(null);

  double _gap;
  Color _color;

  /// The vertical gap on each side.
  double get gap => _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  /// The band colour.
  Color get color => _color;
  set color(Color value) {
    if (value == _color) return;
    _color = value;
    markNeedsPaint();
  }

  bool get _collapsed => child == null || child!.size.height <= 0;

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(
      constraints.loosen().deflate(EdgeInsets.symmetric(vertical: _gap)),
      parentUsesSize: true,
    );
    final data = child.parentData! as BoxParentData;
    if (child.size.height <= 0) {
      data.offset = Offset.zero;
      size = constraints.constrain(Size.zero);
      return;
    }
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : child.size.width;
    size = constraints.constrain(Size(width, child.size.height + 2 * _gap));
    data.offset = Offset((size.width - child.size.width) / 2, _gap);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_collapsed) return;
    final band = Rect.fromLTWH(
      offset.dx,
      offset.dy + _gap,
      size.width,
      child!.size.height,
    );
    context.canvas.drawRect(band, Paint()..color = _color);
    super.paint(context, offset);
  }
}

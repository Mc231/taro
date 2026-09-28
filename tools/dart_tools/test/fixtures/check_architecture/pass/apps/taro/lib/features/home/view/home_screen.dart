import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/app_state/balance_controller.dart';
import 'package:taro/common/balance_chip.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/home/controller/home_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';
import '../controller/home_controller.dart'
    if (dart.library.io) '../controller/home_controller.dart';

// EdgeInsets.only(left: 8) in a comment is fine.
/* Alignment.centerLeft in a block /* nested */ comment is fine. */
const label = 'TextAlign.left inside a string is fine';
final a = EdgeInsetsDirectional.only(start: 8);
final b = EdgeInsets.only(top: 8, bottom: foo(left: 1));
final c = AlignmentDirectional.centerStart;
final d = TextAlign.start;
final e = Positioned.fill(child: x);
final f = PositionedDirectional(start: 0, child: x);
final g = Positioned(top: 0, child: x);
final h = r'raw \ string';
final i = '''triple
EdgeInsets.only(left: 1)
''';
final j = "escaped \" quote";

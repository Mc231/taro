import 'package:flutter/widgets.dart';

/// Text scale above which rows stack their side-by-side parts (value,
/// actions) under the text so nothing is squeezed or clipped (01 §12, the
/// same 1.5× threshold as the spread reflow). Internal to `taro_ui`.
const double kTaroRowReflowTextScale = 1.5;

/// Whether the ambient text scale is above [kTaroRowReflowTextScale].
bool taroShouldReflow(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(1) > kTaroRowReflowTextScale;

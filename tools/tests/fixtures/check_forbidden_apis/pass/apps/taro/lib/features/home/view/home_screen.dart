import 'package:flutter/widgets.dart';
import 'package:taro_ui/taro_ui.dart';

// DateTime.now() and print() in a comment are not code.
/* Random() in a block comment /* nested */ is ignored too. */
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    const note = 'print(DateTime.now()) inside a string is text';
    final raw = r'Color(0xFF000000) and fontSize: 12 in a raw string';
    final multi = '''
      EdgeInsets.only(left: 8) in a triple-quoted string
    ''';
    return Stack(
      children: [
        Positioned(top: 0, child: Tile(left: note, right: raw)),
        PositionedDirectional(start: 8, child: Text('$label $multi')),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(label, textAlign: TextAlign.start),
          ),
        ),
        Padding(padding: EdgeInsets.only(top: taroSpace.md)),
      ],
    );
  }
}

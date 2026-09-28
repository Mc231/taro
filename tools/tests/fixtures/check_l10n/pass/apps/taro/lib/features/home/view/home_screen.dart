import 'package:flutter/widgets.dart';

// Text('Hello in a comment') is not code.
Widget home(TaroLocalizations l10n, int count, String name) => Column(
  children: [
    Text(l10n.greeting(name)),
    Text('$count'),
    Text('${count + 1}'),
    Text('42 / 78'),
    Tooltip(message: name, child: Text(name)),
    Semantics(label: l10n.appTitle, child: const SizedBox()),
    Text('$name'),
  ],
);

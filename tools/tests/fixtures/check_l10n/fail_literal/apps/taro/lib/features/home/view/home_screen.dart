import 'package:flutter/widgets.dart';

Widget home() => Column(
  children: [
    Text('Hello there'),
    IconButton(tooltip: "Close", onPressed: null, icon: const SizedBox()),
    Chip(label: 'Daily card'),
  ],
);

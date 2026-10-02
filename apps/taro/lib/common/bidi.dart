/// [text] in a left-to-right isolate (U+2066 … U+2069): file names, e-mail
/// addresses, IDs and URLs keep their order inside RTL text.
String ltrIsolate(String text) => '\u2066$text\u2069';

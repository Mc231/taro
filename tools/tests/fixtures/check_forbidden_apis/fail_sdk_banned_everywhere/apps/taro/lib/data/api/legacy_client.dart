import 'package:http/http.dart' as http;

Future<void> ping() => http.get(Uri.parse('https://example.com'));

import 'dart:convert';
import 'dart:io';

/// Reads `config/<name>.json` relative to the package root (the test cwd).
Map<String, Object?> readConfigFile(String name) {
  final file = File('config/$name.json');
  return (jsonDecode(file.readAsStringSync()) as Map).cast<String, Object?>();
}

/// Flavor config file names (02 §15).
const configNames = ['dev', 'staging', 'prod'];

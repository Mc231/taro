import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taro_attestation/taro_attestation.dart';

void main() => runApp(ExampleApp(plugin: TaroAttestation()));

class ExampleApp extends StatefulWidget {
  const ExampleApp({required this.plugin, super.key});

  final TaroAttestation plugin;

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    _load().ignore();
  }

  Future<void> _load() async {
    String version;
    try {
      version = await widget.plugin.getPlatformVersion() ?? 'Unknown';
    } on PlatformException {
      version = 'Failed to get platform version.';
    }
    if (!mounted) return;
    setState(() => _platformVersion = version);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('taro_attestation example')),
        body: Center(child: Text('Running on: $_platformVersion')),
      ),
    );
  }
}

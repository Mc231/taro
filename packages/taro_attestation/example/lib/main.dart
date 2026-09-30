import 'package:flutter/material.dart';
import 'package:taro_attestation/taro_attestation.dart';

void main() => runApp(const ExampleApp(plugin: TaroAttestation()));

/// Host app of the plugin's native tests: shows whether platform
/// attestation is available on this device.
class ExampleApp extends StatefulWidget {
  /// An app over [plugin].
  const ExampleApp({required this.plugin, super.key});

  /// The plugin under test.
  final TaroAttestation plugin;

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  String _status = 'Checking…';

  @override
  void initState() {
    super.initState();
    _load().ignore();
  }

  Future<void> _load() async {
    String status;
    try {
      status = await widget.plugin.isSupported() ? 'supported' : 'unsupported';
    } on TaroAttestationException catch (e) {
      status = 'error: ${e.kind.name}';
    }
    if (!mounted) return;
    setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('taro_attestation example')),
        body: Center(child: Text('Attestation: $_status')),
      ),
    );
  }
}

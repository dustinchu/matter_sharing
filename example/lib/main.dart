import 'package:flutter/material.dart';
import 'package:matter_sharing/matter_sharing.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Matter Sharing Example',
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _payload = 'MT:Y.K90AFN00KA0648G00';
  static const _discriminator = 3840;
  static const _passcode = 20202021;

  String _status = '';
  bool _loading = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _status = '';
    });
    try {
      await action();
      setState(() => _status = 'Success');
    } on MatterSharingException catch (e) {
      setState(() => _status = 'Error [${e.code.name}]: ${e.message}'
          '${e.details != null ? '\ndetails: ${e.details}' : ''}');
    } catch (e) {
      setState(() => _status = 'Unexpected error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matter Sharing Example')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _loading
                  ? null
                  : () => _run(
                        () => MatterSharing.shareToAppleHome(
                          onboardingPayload: _payload,
                        ),
                      ),
              child: const Text('Share to Apple Home'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading
                  ? null
                  : () => _run(
                        () => MatterSharing.shareToGoogleHome(
                          onboardingPayload: _payload,
                          discriminator: _discriminator,
                          passcode: _passcode,
                        ),
                      ),
              child: const Text('Share to Google Home'),
            ),
            const SizedBox(height: 24),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_status.isNotEmpty)
              Text(_status, style: const TextStyle(fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }
}

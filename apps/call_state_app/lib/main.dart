import 'dart:async';

import 'package:call_state/call_state.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Call State',
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const HomePage(),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CallStatus? _status;
  String? _error;
  StreamSubscription<CallStatus>? _subscription;

  Future<void> _check() async {
    try {
      final status = await CallState.instance.getCallStatus();
      setState(() {
        _status = status;
        _error = null;
      });
    } on CallStateException catch (e) {
      setState(() => _error = e.toString());
    }
  }

  void _toggleSubscription() {
    if (_subscription != null) {
      _subscription!.cancel();
      setState(() => _subscription = null);
      return;
    }
    setState(() {
      _subscription = CallState.instance.onCallStatusChanged.listen(
        (callStatus) => setState(() {
          _status = callStatus;
          _error = null;
        }),
        onError: (Object e) => setState(() {
          _error = e.toString();
          _subscription = null;
        }),
      );
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listening = _subscription != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Call State')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Status: ${_status?.name ?? 'unknown'}',
                style: Theme.of(context).textTheme.headlineSmall),
            Text('In call: ${_status?.isInCall ?? false}'),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _check, child: const Text('Check now')),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _toggleSubscription,
              child: Text(listening ? 'Stop listening' : 'Start listening'),
            ),
          ],
        ),
      ),
    );
  }
}

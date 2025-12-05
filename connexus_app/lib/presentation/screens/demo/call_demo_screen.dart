import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_router.dart';
import '../../providers/call_provider.dart';

/// Demo screen to test incoming call functionality.
class CallDemoScreen extends StatelessWidget {
  const CallDemoScreen({super.key});

  void _simulateIncomingCall(BuildContext context) {
    final callProvider = context.read<CallProvider>();

    // Simulate an incoming call (known contact).
    callProvider.handleIncomingCall(
      callId: 'demo-call-${DateTime.now().millisecondsSinceEpoch}',
      callerNumber: '14155551234',
      callerName: 'John Smith',
      callerPhotoUrl: null,
    );

    Navigator.of(context).pushNamed(
      AppRouter.incomingCall,
      arguments: callProvider.currentCall,
    );
  }

  void _simulateUnknownCaller(BuildContext context) {
    final callProvider = context.read<CallProvider>();

    // Simulate an incoming call (unknown contact).
    callProvider.handleIncomingCall(
      callId: 'demo-call-${DateTime.now().millisecondsSinceEpoch}',
      callerNumber: '18005551234',
    );

    Navigator.of(context).pushNamed(
      AppRouter.incomingCall,
      arguments: callProvider.currentCall,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.phone_callback),
              label: const Text('Simulate Incoming Call (Known)'),
              onPressed: () => _simulateIncomingCall(context),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.phone),
              label: const Text('Simulate Incoming Call (Unknown)'),
              onPressed: () => _simulateUnknownCaller(context),
            ),
          ],
        ),
      ),
    );
  }
}

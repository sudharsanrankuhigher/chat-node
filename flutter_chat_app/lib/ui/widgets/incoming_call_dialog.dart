import 'package:flutter/material.dart';

class IncomingCallDialog extends StatelessWidget {
  const IncomingCallDialog({
    super.key,
    required this.callerId,
    required this.onAccept,
    required this.onReject,
  });

  final String callerId;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Incoming call'),
      content: Text('User $callerId is calling you.'),
      actions: <Widget>[
        TextButton(
          onPressed: onReject,
          child: const Text('Reject'),
        ),
        FilledButton(
          onPressed: onAccept,
          child: const Text('Accept'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class IncomingCallDialog extends StatelessWidget {
  const IncomingCallDialog({
    super.key,
    required this.callerName,
    required this.callType,
    required this.onAccept,
    required this.onReject,
  });

  final String callerName;
  final String callType;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Incoming call'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(callerName),
          const SizedBox(height: 8),
          Text('${callType[0].toUpperCase()}${callType.substring(1)} call'),
        ],
      ),
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

import 'package:flutter/material.dart';

import '../../core/models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
  });

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Card(
          color: isMine ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: <Widget>[
                Text(message.message),
                const SizedBox(height: 6),
                Text(
                  _formatTime(message.timestamp),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

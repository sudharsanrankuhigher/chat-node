import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../models/call_signal.dart';
import '../../../models/chat_message.dart';
import '../../../viewmodels/chat_viewmodel.dart';
import '../../widgets/incoming_call_dialog.dart';
import '../../widgets/message_bubble.dart';
import '../call/call_view.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final ScrollController _scrollController = ScrollController();
  bool _isShowingIncomingDialog = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ChatViewModel>.reactive(
      viewModelBuilder: ChatViewModel.new,
      onViewModelReady: (ChatViewModel viewModel) => viewModel.initialise(),
      builder: (BuildContext context, ChatViewModel viewModel, Widget? child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
          _showIncomingCallDialogIfNeeded(viewModel);
        });

        final List<ChatMessage> messages = viewModel.conversationMessages;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Stacked Chat'),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.circle,
                      size: 12,
                      color: viewModel.isConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(viewModel.isConnected ? 'Connected' : 'Offline'),
                  ],
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      TextField(
                        controller: viewModel.currentUserController,
                        decoration: const InputDecoration(
                          labelText: 'Your user ID',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: viewModel.peerUserController,
                              decoration: const InputDecoration(
                                labelText: 'Chat / call user ID',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed:
                                viewModel.isConnected ? viewModel.disconnect : viewModel.connect,
                            child: Text(viewModel.isConnected ? 'Disconnect' : 'Connect'),
                          ),
                        ],
                      ),
                      if (viewModel.errorText != null) ...<Widget>[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            viewModel.errorText!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: viewModel.onlineUsers
                        .where((String userId) => userId != viewModel.currentUserId)
                        .map(
                          (String userId) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(userId),
                              selected: userId == viewModel.selectedPeerUserId,
                              onSelected: (_) => viewModel.selectPeer(userId),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF2F7F5),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: messages.length,
                      itemBuilder: (BuildContext context, int index) {
                        final ChatMessage message = messages[index];
                        return MessageBubble(
                          message: message,
                          isMine: message.senderId == viewModel.currentUserId,
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: viewModel.messageController,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Type a message',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: viewModel.selectedPeerUserId.isEmpty ||
                                viewModel.currentUserId.isEmpty
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => CallView(
                                      currentUserId: viewModel.currentUserId,
                                      peerUserId: viewModel.selectedPeerUserId,
                                      isIncoming: false,
                                      autoStart: true,
                                    ),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.video_call),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: viewModel.sendMessage,
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _showIncomingCallDialogIfNeeded(ChatViewModel viewModel) {
    final CallSignal? signal = viewModel.pendingIncomingCall;
    if (signal == null || _isShowingIncomingDialog || !mounted) {
      return;
    }

    _isShowingIncomingDialog = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return IncomingCallDialog(
          callerId: signal.from,
          onReject: () async {
            Navigator.of(dialogContext).pop();
            await viewModel.rejectIncomingCall();
          },
          onAccept: () {
            final CallSignal? accepted = viewModel.takeIncomingCall();
            Navigator.of(dialogContext).pop();

            if (accepted == null) {
              return;
            }

            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CallView(
                  currentUserId: viewModel.currentUserId,
                  peerUserId: accepted.from,
                  isIncoming: true,
                  remoteOffer: accepted.description,
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _isShowingIncomingDialog = false;
    });
  }
}

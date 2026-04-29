import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../core/models/user_profile.dart';
import '../../widgets/message_bubble.dart';
import '../call/call_view.dart';
import 'chat_viewmodel.dart';

class ChatView extends StatefulWidget {
  const ChatView({
    super.key,
    required this.currentUser,
    required this.peerUser,
  });

  final UserProfile currentUser;
  final UserProfile peerUser;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ChatViewModel>.reactive(
      viewModelBuilder: () => ChatViewModel(peerUser: widget.peerUser),
      onViewModelReady: (ChatViewModel viewModel) => viewModel.initialise(),
      builder: (BuildContext context, ChatViewModel viewModel, Widget? child) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(widget.peerUser.displayName),
                Text(
                  viewModel.isPeerOnline ? 'Online' : 'Offline',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            actions: <Widget>[
              IconButton(
                onPressed: () => _openCall(context, isVideoCall: false),
                icon: const Icon(Icons.call),
              ),
              IconButton(
                onPressed: () => _openCall(context, isVideoCall: true),
                icon: const Icon(Icons.videocam),
              ),
            ],
          ),
          body: Column(
            children: <Widget>[
              if (viewModel.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    viewModel.errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              Expanded(
                child: viewModel.isBusy
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: viewModel.messages.length,
                        itemBuilder: (BuildContext context, int index) {
                          final message = viewModel.messages[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: MessageBubble(
                              message: message,
                              isMine: message.senderId == widget.currentUser.id,
                            ),
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: viewModel.messageController,
                          minLines: 1,
                          maxLines: 4,
                          onChanged: (_) => viewModel.onComposerChanged(),
                          decoration: const InputDecoration(
                            hintText: 'Type a message',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filled(
                        onPressed: viewModel.canSend ? viewModel.sendMessage : null,
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openCall(BuildContext context, {required bool isVideoCall}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CallView(
          currentUser: widget.currentUser,
          peerUser: widget.peerUser,
          isIncoming: false,
          isVideoCall: isVideoCall,
          autoStart: true,
        ),
      ),
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../core/models/chat_message.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/socket_service.dart';
import '../../../app/app.locator.dart';

class ChatViewModel extends ReactiveViewModel {
  ChatViewModel({required this.peerUser});

  final UserProfile peerUser;
  final ApiService _apiService = locator<ApiService>();
  final SessionService _sessionService = locator<SessionService>();
  final SocketService _socketService = locator<SocketService>();

  final TextEditingController messageController = TextEditingController();
  final List<ChatMessage> _messages = <ChatMessage>[];
  StreamSubscription<ChatMessage>? _messageSubscription;
  bool _initialized = false;
  String? _errorMessage;

  @override
  List<ListenableServiceMixin> get listenableServices =>
      <ListenableServiceMixin>[_sessionService, _socketService];

  UserProfile? get currentUser => _sessionService.currentUser;
  List<ChatMessage> get messages => List<ChatMessage>.unmodifiable(_messages);
  String? get errorMessage => _errorMessage;
  bool get isPeerOnline => _socketService.onlineUsers.contains(peerUser.id);
  bool get canSend =>
      currentUser != null && messageController.text.trim().isNotEmpty && _socketService.isConnected;

  Future<void> initialise() async {
    if (_initialized) {
      return;
    }

    _initialized = true;
    _messageSubscription = _socketService.messages.listen(_handleIncomingMessage);
    await runBusyFuture(_loadHistory());
  }

  Future<void> sendMessage() async {
    final UserProfile? me = currentUser;
    final String trimmedMessage = messageController.text.trim();
    if (me == null || trimmedMessage.isEmpty) {
      return;
    }

    final ChatMessage outgoingMessage = ChatMessage(
      id: '',
      senderId: me.id,
      receiverId: peerUser.id,
      message: trimmedMessage,
      timestamp: DateTime.now(),
    );

    _messages.add(outgoingMessage);
    _sortMessages();
    messageController.clear();
    notifyListeners();

    _socketService.sendMessage(
      senderId: me.id,
      receiverId: peerUser.id,
      message: trimmedMessage,
    );
  }

  void onComposerChanged() {
    notifyListeners();
  }

  Future<void> _loadHistory() async {
    try {
      _errorMessage = null;
      final List<ChatMessage> history = await _apiService.getChatHistory(peerUser.id);
      _messages
        ..clear()
        ..addAll(history);
      _sortMessages();
    } catch (error) {
      _errorMessage = error.toString();
    }

    notifyListeners();
  }

  void _handleIncomingMessage(ChatMessage message) {
    final String? myUserId = currentUser?.id;
    if (myUserId == null) {
      return;
    }

    final bool isCurrentConversation =
        (message.senderId == myUserId && message.receiverId == peerUser.id) ||
        (message.senderId == peerUser.id && message.receiverId == myUserId);

    if (!isCurrentConversation) {
      return;
    }

    _messages.add(message);
    _sortMessages();
    notifyListeners();
  }

  void _sortMessages() {
    _messages.sort(
      (ChatMessage a, ChatMessage b) => a.timestamp.compareTo(b.timestamp),
    );
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    messageController.dispose();
    super.dispose();
  }
}

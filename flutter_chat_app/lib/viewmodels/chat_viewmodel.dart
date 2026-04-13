import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../app/app.locator.dart';
import '../models/call_signal.dart';
import '../models/chat_message.dart';
import '../services/call_service.dart';
import '../services/socket_service.dart';

class ChatViewModel extends ReactiveViewModel {
  final SocketService _socketService = locator<SocketService>();
  final CallService _callService = locator<CallService>();

  final TextEditingController currentUserController = TextEditingController();
  final TextEditingController peerUserController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  final List<ChatMessage> _messages = <ChatMessage>[];

  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<CallSignal>? _incomingCallSubscription;
  bool _initialized = false;
  CallSignal? _pendingIncomingCall;

  @override
  List<ListenableServiceMixin> get listenableServices =>
      <ListenableServiceMixin>[_socketService, _callService];

  List<ChatMessage> get conversationMessages {
    final String currentUserId = this.currentUserId;
    final String peerUserId = selectedPeerUserId;

    return _messages.where((ChatMessage message) {
      final bool isConversationA =
          message.senderId == currentUserId && message.receiverId == peerUserId;
      final bool isConversationB =
          message.senderId == peerUserId && message.receiverId == currentUserId;
      return isConversationA || isConversationB;
    }).toList()
      ..sort(
          (ChatMessage a, ChatMessage b) => a.timestamp.compareTo(b.timestamp));
  }

  List<String> get onlineUsers => _socketService.onlineUsers;
  bool get isConnected => _socketService.isConnected;
  String get currentUserId => currentUserController.text.trim();
  String get selectedPeerUserId => peerUserController.text.trim();
  String? get errorText => _socketService.lastError;
  CallSignal? get pendingIncomingCall => _pendingIncomingCall;

  void initialise() {
    if (_initialized) {
      return;
    }

    _initialized = true;
    _messageSubscription =
        _socketService.messages.listen((ChatMessage message) {
      _messages.add(message);
      notifyListeners();
    });

    _incomingCallSubscription =
        _socketService.incomingCalls.listen((CallSignal signal) {
      _pendingIncomingCall = signal;
      notifyListeners();
    });
  }

  Future<void> connect() async {
    if (currentUserId.isEmpty) {
      return;
    }

    await _socketService.connect(currentUserId);
    notifyListeners();
  }

  void disconnect() {
    _socketService.disconnect();
    notifyListeners();
  }

  void selectPeer(String userId) {
    peerUserController.text = userId;
    notifyListeners();
  }

  void sendMessage() {
    if (currentUserId.isEmpty ||
        selectedPeerUserId.isEmpty ||
        messageController.text.trim().isEmpty) {
      return;
    }

    final ChatMessage newMessage = ChatMessage(
      senderId: currentUserId,
      receiverId: selectedPeerUserId,
      message: messageController.text.trim(),
      timestamp: DateTime.now(),
    );

    _messages.add(newMessage);
    _socketService.sendMessage(
      senderId: currentUserId,
      receiverId: selectedPeerUserId,
      message: newMessage.message,
    );

    messageController.clear();
    notifyListeners();
  }

  CallSignal? takeIncomingCall() {
    final CallSignal? signal = _pendingIncomingCall;
    _pendingIncomingCall = null;
    notifyListeners();
    return signal;
  }

  Future<void> rejectIncomingCall() async {
    final CallSignal? signal = takeIncomingCall();
    if (signal == null || currentUserId.isEmpty) {
      return;
    }

    _socketService.endCall(from: currentUserId, to: signal.from);
    await _callService.endCurrentCall();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _incomingCallSubscription?.cancel();
    currentUserController.dispose();
    peerUserController.dispose();
    messageController.dispose();
    super.dispose();
  }
}

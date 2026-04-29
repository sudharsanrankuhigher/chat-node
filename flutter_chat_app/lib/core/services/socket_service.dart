import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:stacked/stacked.dart';

import '../models/call_signal.dart';
import '../models/chat_message.dart';
import '../models/ice_candidate_model.dart';
import '../utils/app_constants.dart';

class SocketService with ListenableServiceMixin {
  SocketService() {
    listenToReactiveValues(<ReactiveValue<dynamic>>[
      _isConnected,
      _connectedUserId,
      _lastError,
      _onlineUsers,
    ]);
  }

  io.Socket? _socket;
  final ReactiveValue<bool> _isConnected = ReactiveValue<bool>(false);
  final ReactiveValue<String?> _connectedUserId = ReactiveValue<String?>(null);
  final ReactiveValue<String?> _lastError = ReactiveValue<String?>(null);
  final ReactiveValue<List<String>> _onlineUsers =
      ReactiveValue<List<String>>(<String>[]);

  final StreamController<ChatMessage> _messageController =
      StreamController<ChatMessage>.broadcast();
  final StreamController<CallSignal> _incomingCallController =
      StreamController<CallSignal>.broadcast();
  final StreamController<CallSignal> _callAcceptedController =
      StreamController<CallSignal>.broadcast();
  final StreamController<Map<String, dynamic>> _callEndedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<IceCandidateModel> _iceCandidateController =
      StreamController<IceCandidateModel>.broadcast();

  bool get isConnected => _isConnected.value;
  String? get currentUserId => _connectedUserId.value;
  String? get lastError => _lastError.value;
  List<String> get onlineUsers => List<String>.unmodifiable(_onlineUsers.value);

  Stream<ChatMessage> get messages => _messageController.stream;
  Stream<CallSignal> get incomingCalls => _incomingCallController.stream;
  Stream<CallSignal> get acceptedCalls => _callAcceptedController.stream;
  Stream<Map<String, dynamic>> get callEnded => _callEndedController.stream;
  Stream<IceCandidateModel> get iceCandidates => _iceCandidateController.stream;

  Future<void> connect(String userId) async {
    final String normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return;
    }

    if (isConnected && currentUserId == normalizedUserId) {
      return;
    }

    disconnect();

    _connectedUserId.value = normalizedUserId;
    _lastError.value = null;

    _socket = io.io(
      AppConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(<String>['websocket'])
          .disableAutoConnect()
          .setQuery(<String, dynamic>{'userId': normalizedUserId})
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected.value = true;
      _lastError.value = null;
      _socket!.emit('register_user', normalizedUserId);
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      _isConnected.value = false;
      notifyListeners();
    });

    _socket!.onConnectError((dynamic error) {
      _lastError.value = error.toString();
      _isConnected.value = false;
      notifyListeners();
    });

    _socket!.on('receive_message', (dynamic data) {
      if (data is Map) {
        _messageController.add(
          ChatMessage.fromJson(Map<String, dynamic>.from(data)),
        );
      }
    });

    _socket!.on('incoming_call', (dynamic data) {
      if (data is Map) {
        _incomingCallController.add(
          CallSignal.fromMap(Map<String, dynamic>.from(data)),
        );
      }
    });

    _socket!.on('call_accepted', (dynamic data) {
      if (data is Map) {
        _callAcceptedController.add(
          CallSignal.fromMap(Map<String, dynamic>.from(data)),
        );
      }
    });

    _socket!.on('call_ended', (dynamic data) {
      if (data is Map) {
        _callEndedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('ice_candidate', (dynamic data) {
      if (data is Map) {
        _iceCandidateController.add(
          IceCandidateModel.fromMap(Map<String, dynamic>.from(data)),
        );
      }
    });

    _socket!.on('online_users', (dynamic data) {
      if (data is List) {
        _onlineUsers.value = data.map((dynamic user) => user.toString()).toList();
        notifyListeners();
      }
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _isConnected.value = false;
    _connectedUserId.value = null;
    _onlineUsers.value = <String>[];
    notifyListeners();
  }

  void sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
  }) {
    _socket?.emit('send_message', <String, dynamic>{
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
    });
  }

  void callUser({
    required String from,
    required String to,
    required Map<String, dynamic> offer,
    required String callType,
  }) {
    _socket?.emit('call_user', <String, dynamic>{
      'from': from,
      'to': to,
      'offer': offer,
      'callType': callType,
    });
  }

  void answerCall({
    required String from,
    required String to,
    required Map<String, dynamic> answer,
  }) {
    _socket?.emit('answer_call', <String, dynamic>{
      'from': from,
      'to': to,
      'answer': answer,
    });
  }

  void endCall({
    required String from,
    required String to,
  }) {
    _socket?.emit('end_call', <String, dynamic>{
      'from': from,
      'to': to,
    });
  }

  void sendIceCandidate({
    required String from,
    required String to,
    required Map<String, dynamic> candidate,
  }) {
    _socket?.emit('ice_candidate', <String, dynamic>{
      'from': from,
      'to': to,
      'candidate': candidate,
    });
  }
}

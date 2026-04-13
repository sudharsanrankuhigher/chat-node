import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:stacked/stacked.dart';

import '../app/app.locator.dart';
import '../models/call_signal.dart';
import '../models/call_state.dart';
import '../models/ice_candidate_model.dart';
import '../services/call_service.dart';
import '../services/socket_service.dart';

class CallViewModel extends ReactiveViewModel {
  CallViewModel({
    required this.currentUserId,
    required this.peerUserId,
    required this.isIncoming,
    this.remoteOffer,
    this.autoStart = false,
  });

  final String currentUserId;
  final String peerUserId;
  final bool isIncoming;
  final bool autoStart;
  final Map<String, dynamic>? remoteOffer;

  final SocketService _socketService = locator<SocketService>();
  final CallService _callService = locator<CallService>();

  StreamSubscription<CallSignal>? _acceptedSubscription;
  StreamSubscription<dynamic>? _endSubscription;
  StreamSubscription<dynamic>? _iceSubscription;
  bool _initialized = false;
  bool _callStarted = false;
  bool _shouldClose = false;

  @override
  List<ListenableServiceMixin> get listenableServices =>
      <ListenableServiceMixin>[_socketService, _callService];

  RTCVideoRenderer get localRenderer => _callService.localRenderer;
  RTCVideoRenderer get remoteRenderer => _callService.remoteRenderer;
  CallState get callState => _callService.callState;
  bool get isMuted => _callService.isMuted;
  bool get renderersReady => _callService.renderersReady;
  bool get shouldClose => _shouldClose;

  Future<void> initialise() async {
    if (_initialized) {
      return;
    }

    _initialized = true;
    setBusy(true);

    await _callService.prepareForCall(
      currentUserId: currentUserId,
      peerUserId: peerUserId,
    );

    if (isIncoming) {
      _callService.markIncomingRinging();
    }

    _acceptedSubscription =
        _socketService.acceptedCalls.listen((CallSignal signal) async {
      if (signal.from != peerUserId && signal.to != peerUserId) {
        return;
      }

      await _callService.setRemoteAnswer(signal.description);
      notifyListeners();
    });

    _iceSubscription =
        _socketService.iceCandidates.listen((IceCandidateModel signal) async {
      if (signal.from != peerUserId && signal.to != peerUserId) {
        return;
      }

      await _callService.addIceCandidate(signal.candidate);
      notifyListeners();
    });

    _endSubscription = _socketService.callEnded.listen((dynamic payload) async {
      final String from = (payload['from'] ?? '').toString();
      final String to = (payload['to'] ?? '').toString();

      final bool isCurrentCall =
          (from == peerUserId && to == currentUserId) ||
          (from == currentUserId && to == peerUserId);

      if (!isCurrentCall) {
        return;
      }

      _shouldClose = true;
      await _callService.endCurrentCall();
      notifyListeners();
    });

    if (autoStart && !isIncoming) {
      await startCall();
    }

    setBusy(false);
  }

  Future<void> startCall() async {
    if (_callStarted) {
      return;
    }

    _callStarted = true;
    final Map<String, dynamic> offer = await _callService.createOffer();
    _socketService.callUser(from: currentUserId, to: peerUserId, offer: offer);
    notifyListeners();
  }

  Future<void> acceptCall() async {
    if (remoteOffer == null) {
      return;
    }

    final Map<String, dynamic> answer = await _callService.acceptOffer(remoteOffer!);
    _socketService.answerCall(from: currentUserId, to: peerUserId, answer: answer);
    notifyListeners();
  }

  Future<void> rejectCall() async {
    _socketService.endCall(from: currentUserId, to: peerUserId);
    _shouldClose = true;
    await _callService.endCurrentCall();
    notifyListeners();
  }

  Future<void> endCall() async {
    _socketService.endCall(from: currentUserId, to: peerUserId);
    _shouldClose = true;
    await _callService.endCurrentCall();
    notifyListeners();
  }

  Future<void> toggleMute() => _callService.toggleMute();

  Future<void> switchCamera() => _callService.switchCamera();

  @override
  void dispose() {
    _acceptedSubscription?.cancel();
    _iceSubscription?.cancel();
    _endSubscription?.cancel();
    super.dispose();
  }
}

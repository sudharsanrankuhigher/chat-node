import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:stacked/stacked.dart';

import '../../../core/models/call_signal.dart';
import '../../../core/models/call_state.dart';
import '../../../core/models/ice_candidate_model.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/services/call_service.dart';
import '../../../core/services/socket_service.dart';
import '../../../app/app.locator.dart';

class CallViewModel extends ReactiveViewModel {
  CallViewModel({
    required this.currentUser,
    required this.peerUser,
    required this.isIncoming,
    required this.isVideoCall,
    this.remoteOffer,
    this.autoStart = false,
  });

  final UserProfile currentUser;
  final UserProfile peerUser;
  final bool isIncoming;
  final bool isVideoCall;
  final bool autoStart;
  final Map<String, dynamic>? remoteOffer;

  final SocketService _socketService = locator<SocketService>();
  final CallService _callService = locator<CallService>();

  StreamSubscription<CallSignal>? _acceptedSubscription;
  StreamSubscription<Map<String, dynamic>>? _endSubscription;
  StreamSubscription<IceCandidateModel>? _iceSubscription;
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
      currentUserId: currentUser.id,
      peerUserId: peerUser.id,
      videoEnabled: isVideoCall,
    );

    if (isIncoming) {
      _callService.markIncomingRinging();
    }

    _acceptedSubscription =
        _socketService.acceptedCalls.listen((CallSignal signal) async {
      if (signal.from != peerUser.id || signal.to != currentUser.id) {
        return;
      }

      await _callService.setRemoteAnswer(signal.description);
      notifyListeners();
    });

    _iceSubscription =
        _socketService.iceCandidates.listen((IceCandidateModel signal) async {
      final bool isCurrentCall =
          (signal.from == peerUser.id && signal.to == currentUser.id) ||
          (signal.from == currentUser.id && signal.to == peerUser.id);
      if (!isCurrentCall) {
        return;
      }

      await _callService.addIceCandidate(signal.candidate);
      notifyListeners();
    });

    _endSubscription = _socketService.callEnded.listen((Map<String, dynamic> payload) async {
      final String from = (payload['from'] ?? '').toString();
      final String to = (payload['to'] ?? '').toString();
      final bool isCurrentCall =
          (from == peerUser.id && to == currentUser.id) ||
          (from == currentUser.id && to == peerUser.id);

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
    _socketService.callUser(
      from: currentUser.id,
      to: peerUser.id,
      offer: offer,
      callType: isVideoCall ? 'video' : 'audio',
    );
    notifyListeners();
  }

  Future<void> acceptCall() async {
    if (remoteOffer == null) {
      return;
    }

    final Map<String, dynamic> answer = await _callService.acceptOffer(remoteOffer!);
    _socketService.answerCall(
      from: currentUser.id,
      to: peerUser.id,
      answer: answer,
    );
    notifyListeners();
  }

  Future<void> rejectCall() async {
    _socketService.endCall(from: currentUser.id, to: peerUser.id);
    _shouldClose = true;
    await _callService.endCurrentCall();
    notifyListeners();
  }

  Future<void> endCall() async {
    _socketService.endCall(from: currentUser.id, to: peerUser.id);
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

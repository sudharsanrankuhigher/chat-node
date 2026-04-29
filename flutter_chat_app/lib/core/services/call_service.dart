import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:stacked/stacked.dart';

import '../models/call_state.dart';
import 'socket_service.dart';

class CallService with ListenableServiceMixin {
  CallService(this._socketService);

  final SocketService _socketService;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  CallState _callState = CallState.idle;
  String? _currentUserId;
  String? _peerUserId;
  bool _isMuted = false;
  bool _isVideoCall = true;
  bool _renderersReady = false;

  CallState get callState => _callState;
  bool get isMuted => _isMuted;
  bool get isVideoCall => _isVideoCall;
  bool get renderersReady => _renderersReady;

  Future<void> initializeRenderers() async {
    if (_renderersReady) {
      return;
    }

    await localRenderer.initialize();
    await remoteRenderer.initialize();
    _renderersReady = true;
  }

  Future<void> prepareForCall({
    required String currentUserId,
    required String peerUserId,
    required bool videoEnabled,
  }) async {
    _currentUserId = currentUserId;
    _peerUserId = peerUserId;
    _isVideoCall = videoEnabled;

    await initializeRenderers();
    await _disposePeerConnection();
    await _disposeStreams();
    await _ensureLocalMedia(videoEnabled: videoEnabled);
    await _createPeerConnection();

    _callState = CallState.idle;
    _isMuted = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> createOffer() async {
    if (_peerConnection == null) {
      throw StateError('Peer connection is not initialized.');
    }

    _callState = CallState.connecting;
    notifyListeners();

    final RTCSessionDescription offer = await _peerConnection!.createOffer(
      <String, dynamic>{
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': _isVideoCall ? 1 : 0,
      },
    );
    await _peerConnection!.setLocalDescription(offer);

    return <String, dynamic>{
      'sdp': offer.sdp,
      'type': offer.type,
    };
  }

  Future<Map<String, dynamic>> acceptOffer(Map<String, dynamic> offer) async {
    if (_peerConnection == null) {
      throw StateError('Peer connection is not initialized.');
    }

    _callState = CallState.connecting;
    notifyListeners();

    final RTCSessionDescription remoteOffer = RTCSessionDescription(
      offer['sdp']?.toString(),
      offer['type']?.toString(),
    );

    await _peerConnection!.setRemoteDescription(remoteOffer);

    final RTCSessionDescription answer = await _peerConnection!.createAnswer(
      <String, dynamic>{
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': _isVideoCall ? 1 : 0,
      },
    );
    await _peerConnection!.setLocalDescription(answer);

    return <String, dynamic>{
      'sdp': answer.sdp,
      'type': answer.type,
    };
  }

  Future<void> setRemoteAnswer(Map<String, dynamic> answer) async {
    if (_peerConnection == null) {
      return;
    }

    final RTCSessionDescription remoteAnswer = RTCSessionDescription(
      answer['sdp']?.toString(),
      answer['type']?.toString(),
    );

    await _peerConnection!.setRemoteDescription(remoteAnswer);
    _callState = CallState.connected;
    notifyListeners();
  }

  Future<void> addIceCandidate(Map<String, dynamic> candidate) async {
    if (_peerConnection == null) {
      return;
    }

    final dynamic rawIndex = candidate['sdpMLineIndex'];
    final int? index = rawIndex is int ? rawIndex : int.tryParse('$rawIndex');

    await _peerConnection!.addCandidate(
      RTCIceCandidate(
        candidate['candidate']?.toString(),
        candidate['sdpMid']?.toString(),
        index,
      ),
    );
  }

  void markIncomingRinging() {
    _callState = CallState.ringing;
    notifyListeners();
  }

  Future<void> toggleMute() async {
    if (_localStream == null) {
      return;
    }

    _isMuted = !_isMuted;
    for (final MediaStreamTrack track in _localStream!.getAudioTracks()) {
      track.enabled = !_isMuted;
    }

    notifyListeners();
  }

  Future<void> switchCamera() async {
    if (!_isVideoCall) {
      return;
    }

    final List<MediaStreamTrack> videoTracks =
        _localStream?.getVideoTracks() ?? <MediaStreamTrack>[];
    if (videoTracks.isEmpty) {
      return;
    }

    await Helper.switchCamera(videoTracks.first);
  }

  Future<void> endCurrentCall() async {
    _callState = CallState.ended;
    notifyListeners();
    await _disposePeerConnection();
    await _disposeStreams();
    _callState = CallState.idle;
    notifyListeners();
  }

  Future<void> _ensureLocalMedia({required bool videoEnabled}) async {
    _localStream = await navigator.mediaDevices.getUserMedia(
      <String, dynamic>{
        'audio': true,
        'video': videoEnabled ? <String, dynamic>{'facingMode': 'user'} : false,
      },
    );

    localRenderer.srcObject = _localStream;
  }

  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection(
      <String, dynamic>{
        'iceServers': <Map<String, dynamic>>[
          <String, dynamic>{'urls': 'stun:stun.l.google.com:19302'},
          <String, dynamic>{'urls': 'stun:stun1.l.google.com:19302'},
        ],
      },
      <String, dynamic>{},
    );

    for (final MediaStreamTrack track in _localStream!.getTracks()) {
      await _peerConnection!.addTrack(track, _localStream!);
    }

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (_currentUserId == null || _peerUserId == null || candidate.candidate == null) {
        return;
      }

      _socketService.sendIceCandidate(
        from: _currentUserId!,
        to: _peerUserId!,
        candidate: <String, dynamic>{
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      );
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _callState = CallState.connected;
        notifyListeners();
      }
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isEmpty) {
        return;
      }

      _remoteStream = event.streams.first;
      remoteRenderer.srcObject = _remoteStream;
      _callState = CallState.connected;
      notifyListeners();
    };
  }

  Future<void> _disposePeerConnection() async {
    await _peerConnection?.close();
    _peerConnection = null;
    remoteRenderer.srcObject = null;
  }

  Future<void> _disposeStreams() async {
    for (final MediaStreamTrack track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      track.stop();
    }
    for (final MediaStreamTrack track in _remoteStream?.getTracks() ?? <MediaStreamTrack>[]) {
      track.stop();
    }

    await _localStream?.dispose();
    await _remoteStream?.dispose();
    _localStream = null;
    _remoteStream = null;
    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;
  }
}

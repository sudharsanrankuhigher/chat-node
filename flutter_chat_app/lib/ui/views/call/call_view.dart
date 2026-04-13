import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:stacked/stacked.dart';

import '../../../models/call_state.dart';
import '../../../viewmodels/call_viewmodel.dart';

class CallView extends StatefulWidget {
  const CallView({
    super.key,
    required this.currentUserId,
    required this.peerUserId,
    required this.isIncoming,
    this.remoteOffer,
    this.autoStart = false,
  });

  final String currentUserId;
  final String peerUserId;
  final bool isIncoming;
  final Map<String, dynamic>? remoteOffer;
  final bool autoStart;

  @override
  State<CallView> createState() => _CallViewState();
}

class _CallViewState extends State<CallView> {
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<CallViewModel>.reactive(
      viewModelBuilder: () => CallViewModel(
        currentUserId: widget.currentUserId,
        peerUserId: widget.peerUserId,
        isIncoming: widget.isIncoming,
        remoteOffer: widget.remoteOffer,
        autoStart: widget.autoStart,
      ),
      onViewModelReady: (CallViewModel viewModel) => viewModel.initialise(),
      builder: (BuildContext context, CallViewModel viewModel, Widget? child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (viewModel.shouldClose && mounted) {
            Navigator.of(context).maybePop();
          }
        });

        return WillPopScope(
          onWillPop: () async {
            if (viewModel.callState != CallState.idle) {
              await viewModel.endCall();
            }
            return true;
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text('Call with ${widget.peerUserId}'),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: viewModel.renderersReady
                          ? Stack(
                              children: <Widget>[
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: RTCVideoView(
                                      viewModel.remoteRenderer,
                                      objectFit: RTCVideoViewObjectFit
                                          .RTCVideoViewObjectFitCover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 16,
                                  top: 16,
                                  width: 120,
                                  height: 180,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black87,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: RTCVideoView(
                                      viewModel.localRenderer,
                                      mirror: true,
                                      objectFit: RTCVideoViewObjectFit
                                          .RTCVideoViewObjectFitCover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 16,
                                  right: 16,
                                  bottom: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      _statusText(viewModel.callState),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const Center(child: CircularProgressIndicator()),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: <Widget>[
                        FilledButton.icon(
                          onPressed: !widget.isIncoming && !widget.autoStart
                              ? viewModel.startCall
                              : null,
                          icon: const Icon(Icons.call),
                          label: const Text('Call'),
                        ),
                        FilledButton.icon(
                          onPressed: widget.isIncoming &&
                                  viewModel.callState == CallState.ringing
                              ? viewModel.acceptCall
                              : null,
                          icon: const Icon(Icons.call_received),
                          label: const Text('Accept'),
                        ),
                        OutlinedButton.icon(
                          onPressed: widget.isIncoming &&
                                  viewModel.callState == CallState.ringing
                              ? viewModel.rejectCall
                              : null,
                          icon: const Icon(Icons.call_end),
                          label: const Text('Reject'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: viewModel.callState != CallState.idle
                              ? viewModel.endCall
                              : null,
                          icon: const Icon(Icons.call_end),
                          label: const Text('End call'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: viewModel.toggleMute,
                          icon: Icon(
                            viewModel.isMuted ? Icons.mic_off : Icons.mic,
                          ),
                          label: Text(viewModel.isMuted ? 'Unmute' : 'Mute'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: viewModel.switchCamera,
                          icon: const Icon(Icons.cameraswitch),
                          label: const Text('Switch camera'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _statusText(CallState state) {
    switch (state) {
      case CallState.idle:
        return 'Ready';
      case CallState.ringing:
        return 'Incoming call';
      case CallState.connecting:
        return 'Connecting...';
      case CallState.connected:
        return 'Connected';
      case CallState.ended:
        return 'Call ended';
    }
  }
}

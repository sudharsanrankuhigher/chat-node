import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:stacked/stacked.dart';

import '../../../core/models/call_state.dart';
import '../../../core/models/user_profile.dart';
import 'call_viewmodel.dart';

class CallView extends StatelessWidget {
  const CallView({
    super.key,
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

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<CallViewModel>.reactive(
      viewModelBuilder: () => CallViewModel(
        currentUser: currentUser,
        peerUser: peerUser,
        isIncoming: isIncoming,
        isVideoCall: isVideoCall,
        remoteOffer: remoteOffer,
        autoStart: autoStart,
      ),
      onViewModelReady: (CallViewModel viewModel) => viewModel.initialise(),
      builder: (BuildContext context, CallViewModel viewModel, Widget? child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (viewModel.shouldClose && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });

        return Scaffold(
          appBar: AppBar(
            title: Text('${isVideoCall ? 'Video' : 'Audio'} call'),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  Text(
                    peerUser.displayName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(_labelForState(viewModel.callState)),
                  const SizedBox(height: 24),
                  Expanded(
                    child: isVideoCall
                        ? _VideoLayout(viewModel: viewModel, peerUser: peerUser)
                        : _AudioLayout(peerUser: peerUser),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: _buildControls(viewModel),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildControls(CallViewModel viewModel) {
    if (isIncoming && viewModel.callState == CallState.ringing) {
      return <Widget>[
        FilledButton(
          onPressed: viewModel.acceptCall,
          child: const Text('Accept'),
        ),
        OutlinedButton(
          onPressed: viewModel.rejectCall,
          child: const Text('Reject'),
        ),
      ];
    }

    return <Widget>[
      FilledButton.tonal(
        onPressed: viewModel.toggleMute,
        child: Text(viewModel.isMuted ? 'Unmute' : 'Mute'),
      ),
      if (isVideoCall)
        FilledButton.tonal(
          onPressed: viewModel.switchCamera,
          child: const Text('Switch camera'),
        ),
      FilledButton(
        onPressed: viewModel.endCall,
        child: const Text('End call'),
      ),
    ];
  }

  String _labelForState(CallState state) {
    switch (state) {
      case CallState.idle:
        return isIncoming ? 'Incoming call' : 'Preparing call';
      case CallState.ringing:
        return 'Ringing';
      case CallState.connecting:
        return 'Connecting';
      case CallState.connected:
        return 'Connected';
      case CallState.ended:
        return 'Call ended';
    }
  }
}

class _VideoLayout extends StatelessWidget {
  const _VideoLayout({
    required this.viewModel,
    required this.peerUser,
  });

  final CallViewModel viewModel;
  final UserProfile peerUser;

  @override
  Widget build(BuildContext context) {
    if (!viewModel.renderersReady) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: <Widget>[
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: RTCVideoView(viewModel.remoteRenderer, mirror: false),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: RTCVideoView(viewModel.localRenderer, mirror: true),
          ),
        ),
      ],
    );
  }
}

class _AudioLayout extends StatelessWidget {
  const _AudioLayout({required this.peerUser});

  final UserProfile peerUser;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircleAvatar(
        radius: 64,
        child: Text(
          peerUser.displayName.isEmpty ? '?' : peerUser.displayName[0].toUpperCase(),
          style: Theme.of(context).textTheme.displaySmall,
        ),
      ),
    );
  }
}

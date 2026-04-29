import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../app/app.locator.dart';
import '../../core/models/call_signal.dart';
import '../../core/models/user_profile.dart';
import '../../core/services/session_service.dart';
import '../../core/services/socket_service.dart';
import '../views/call/call_view.dart';
import 'incoming_call_dialog.dart';

class GlobalCallListener extends StatefulWidget {
  const GlobalCallListener({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<GlobalCallListener> createState() => _GlobalCallListenerState();
}

class _GlobalCallListenerState extends State<GlobalCallListener> {
  final SocketService _socketService = locator<SocketService>();
  final SessionService _sessionService = locator<SessionService>();
  StreamSubscription<CallSignal>? _subscription;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    _subscription = _socketService.incomingCalls.listen(_handleIncomingCall);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _handleIncomingCall(CallSignal signal) async {
    if (_dialogOpen) {
      return;
    }

    final BuildContext? context = StackedService.navigatorKey?.currentContext;
    final UserProfile? currentUser = _sessionService.currentUser;
    if (context == null || currentUser == null) {
      return;
    }

    final UserProfile peerUser =
        _sessionService.userById(signal.from) ?? UserProfile.fallback(signal.from);

    _dialogOpen = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return IncomingCallDialog(
          callerName: peerUser.displayName,
          callType: signal.callType,
          onReject: () {
            Navigator.of(dialogContext).pop();
            _socketService.endCall(from: currentUser.id, to: peerUser.id);
          },
          onAccept: () {
            Navigator.of(dialogContext).pop();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CallView(
                  currentUser: currentUser,
                  peerUser: peerUser,
                  isIncoming: true,
                  isVideoCall: signal.callType != 'audio',
                  remoteOffer: signal.description,
                ),
              ),
            );
          },
        );
      },
    );

    _dialogOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

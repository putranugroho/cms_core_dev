import 'dart:async';

import 'package:flutter/material.dart';

class AutoLogoutWrapper extends StatefulWidget {
  final Widget child;
  final Duration idleDuration;
  final VoidCallback onIdleTimeout;
  final VoidCallback? onActivity;

  const AutoLogoutWrapper({
    super.key,
    required this.child,
    required this.idleDuration,
    required this.onIdleTimeout,
    this.onActivity,
  });

  @override
  State<AutoLogoutWrapper> createState() => _AutoLogoutWrapperState();
}

class _AutoLogoutWrapperState extends State<AutoLogoutWrapper> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void didUpdateWidget(covariant AutoLogoutWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.idleDuration != widget.idleDuration) {
      _resetTimer();
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(widget.idleDuration, widget.onIdleTimeout);
  }

  void _handleActivity() {
    widget.onActivity?.call();
    _resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _handleActivity(),
      onPointerMove: (_) => _handleActivity(),
      onPointerSignal: (_) => _handleActivity(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (_) {
          _handleActivity();
          return false;
        },
        child: widget.child,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:collection';

// Define a global key for ScaffoldMessenger
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class SnackbarManager {
  SnackbarManager._privateConstructor();

  static final SnackbarManager _instance = SnackbarManager._privateConstructor();

  factory SnackbarManager() {
    return _instance;
  }

  final Queue<String> _messageQueue = Queue<String>();
  bool _isShowing = false;

  void showSnackBar(String message) {
    _messageQueue.add(message);
    if (!_isShowing) {
      _showNextSnackBar();
    }
  }

  void _showNextSnackBar() {
    if (_messageQueue.isEmpty) {
      _isShowing = false;
      return;
    }

    _isShowing = true;
    final message = _messageQueue.removeFirst();

    final snackBar = SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      elevation: 6.0,
      duration: Duration(seconds: 4),
    );

    rootScaffoldMessengerKey.currentState?.showSnackBar(snackBar).closed.then((_) {
      Future.delayed(Duration(seconds: 1), () {
        _showNextSnackBar();
      });
    });
  }
}
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:collection';

class SnackbarManager {
  SnackbarManager._privateConstructor();

  static final SnackbarManager _instance = SnackbarManager._privateConstructor();

  factory SnackbarManager() {
    return _instance;
  }

  final Queue<String> _messageQueue = Queue<String>();
  bool _isShowing = false;

  void showSnackBar(BuildContext context, String message) {
    _messageQueue.add(message);
    if (!_isShowing) {
      _showNextSnackBar(context);
    }
  }

  void _showNextSnackBar(BuildContext context) {
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

    ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((_) {
      Future.delayed(Duration(seconds: 1), () {
        _showNextSnackBar(context);
      });
    });
  }
}
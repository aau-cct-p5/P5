// ActivityRecognitionManager handles activity recognition logic

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart'
    as fr;
import 'permissions/activity.dart'; // Import the new activity permission file
import 'package:connectivity_plus/connectivity_plus.dart';

class ActivityRecognitionManager {
  bool isCycling = false;
  fr.ActivityType currentActivity = fr.ActivityType.UNKNOWN;
  StreamSubscription<fr.Activity>? activitySubscription;
  Function(bool) onCyclingStatusChanged; // Callback to notify when cycling status changes
  Function(fr.ActivityType) onActivityChanged; // Callback to notify activity changes

  BuildContext context;
  Function() startDataCollectionCallback;
  Function() stopDataCollectionCallback;
  Function() sendDataToServerCallback;

  ActivityRecognitionManager({
    required this.context,
    required this.onCyclingStatusChanged,
    required this.onActivityChanged,
    required this.startDataCollectionCallback,
    required this.stopDataCollectionCallback,
    required this.sendDataToServerCallback,
  });

  void subscribeActivityStream() async {
    bool hasPermission = await checkAndRequestActivityPermission(); // Use the new method
    if (hasPermission) {
      activitySubscription = fr
          .FlutterActivityRecognition.instance.activityStream
          .listen(onActivityChange, onError: onActivityError);
    } else {
      developer.log('Activity recognition permission not granted.');
    }
  }

  void onActivityChange(fr.Activity activity) {
    // Use alias
    currentActivity = activity.type;
    onActivityChanged(currentActivity);

    if (activity.type == fr.ActivityType.ON_BICYCLE) {
      // Use alias
      if (!isCycling) {
        isCycling = true;
        onCyclingStatusChanged(isCycling);
        startDataCollectionCallback();
        developer
            .log('Cycling detected. Data collection started automatically.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Cycling started. Data collection initiated.')),
        ); // Add SnackBar for cycling start
      }
    } else {
      if (isCycling) {
        isCycling = false;
        onCyclingStatusChanged(isCycling);
        stopDataCollectionCallback();
        developer
            .log('Cycling stopped. Data collection stopped automatically.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Cycling stopped. Data collection halted.')),
        ); // Add SnackBar for cycling stop
        checkIfConnected();
      } else {
        developer.log('Activity detected: $currentActivity');
      }
    }
  }

  Future<void> checkIfConnected() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi) {
      developer.log('Connected, sending data...');
      sendDataToServerCallback();
    } else {
      developer.log('Not connected to wifi, trying again later...');
    }
  }

  void onActivityError(dynamic error) {
    developer.log('Activity recognition error: $error');
  }

  void dispose() {
    activitySubscription?.cancel();
  }
}


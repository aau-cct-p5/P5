// ActivityRecognitionManager handles activity recognition logic

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart'
    as fr;
import 'permissions/activity.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'app.dart';

class ActivityRecognitionManager {
  bool isCycling = false;
  fr.ActivityType currentActivity = fr.ActivityType.UNKNOWN;
  StreamSubscription<fr.Activity>? activitySubscription;
  Function(bool)
      onCyclingStatusChanged; // Callback to notify when cycling status changes
  Function(fr.ActivityType)
      onActivityChanged; // Callback to notify activity changes

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
    if (!isAutoDataCollection)
      return; // Only subscribe if auto data collection is enabled
    bool hasPermission =
        await checkAndRequestActivityPermission(); // Use the new method
    if (hasPermission) {
      activitySubscription = fr
          .FlutterActivityRecognition.instance.activityStream
          .listen(onActivityChange, onError: onActivityError);
    } else {
      developer.log('Activity recognition permission not granted.');
    }
  }

  void unsubscribeActivityStream() {
    activitySubscription?.cancel();
    activitySubscription = null;
  }

  void onActivityChange(fr.Activity activity) {
    if (!isAutoDataCollection)
      return; // Ignore if auto data collection is disabled

    currentActivity = activity.type;
    onActivityChanged(currentActivity);

    if (activity.type == fr.ActivityType.ON_BICYCLE) {
      if (!isCycling) {
        isCycling = true;
        onCyclingStatusChanged(isCycling);
        startDataCollectionCallback(); // Start data collection based on activity
        // Update the global flag
        isCollectingData = true;
        developer
            .log('Cycling detected. Data collection started automatically.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Cycling started. Data collection initiated.')),
        );
      }
    } else {
      if (isCycling) {
        isCycling = false;
        onCyclingStatusChanged(isCycling);
        stopDataCollectionCallback(); // Stop data collection based on activity
        // Update the global flag
        isCollectingData = false;
        developer
            .log('Cycling stopped. Data collection stopped automatically.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Cycling stopped. Data collection halted.')),
        );
      } else {
        developer.log('Activity detected: $currentActivity');
      }
    }
  }

  void onActivityError(dynamic error) {
    developer.log('Activity recognition error: $error');
  }

  void dispose() {
    activitySubscription?.cancel();
  }
}

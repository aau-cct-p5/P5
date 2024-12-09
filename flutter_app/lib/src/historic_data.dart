import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';

/// Represents historical sensor data including timestamp, position, and sensor events.
/// Automatically calculates the root mean square of acceleration from accelerometer events.
class HistoricData {
  final DateTime timestamp;
  final Position position;
  final UserAccelerometerEvent userAccelerometerEvent; // UserAccelerometerEvent filters out gravity
  final GyroscopeEvent gyroscopeEvent;
  final double rmsAcceleration;
  final String surfaceType;

  HistoricData({
    required this.timestamp,
    required this.position,
    required this.userAccelerometerEvent,
    required this.gyroscopeEvent,
    this.surfaceType = 'none',
  }) : rmsAcceleration = sqrt(
          userAccelerometerEvent.x * userAccelerometerEvent.x +
              userAccelerometerEvent.y * userAccelerometerEvent.y +
              userAccelerometerEvent.z * userAccelerometerEvent.z,
        );
}

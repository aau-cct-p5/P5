import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';

/// Represents historical sensor data including timestamp, position, and sensor events.
/// Automatically calculates the root mean square of acceleration from accelerometer events.
class HistoricData {
  final DateTime timestamp;
  final Position position;
  final AccelerometerEvent accelerometerEvent;
  final GyroscopeEvent gyroscopeEvent;
  final double rmsAcceleration;

  HistoricData({
    required this.timestamp,
    required this.position,
    required this.accelerometerEvent,
    required this.gyroscopeEvent,
  }) : rmsAcceleration = sqrt(
          accelerometerEvent.x * accelerometerEvent.x +
              accelerometerEvent.y * accelerometerEvent.y +
              accelerometerEvent.z * accelerometerEvent.z,
        );
}

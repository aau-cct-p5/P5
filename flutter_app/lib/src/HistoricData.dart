import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

class HistoricData {
  final DateTime timestamp;
  final Position position;
  final AccelerometerEvent accelerometerEvent;
  final GyroscopeEvent gyroscopeEvent;

  HistoricData({
    required this.timestamp,
    required this.position,
    required this.accelerometerEvent,
    required this.gyroscopeEvent,
  });
}

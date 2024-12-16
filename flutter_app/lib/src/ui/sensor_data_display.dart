import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Widget to display sensor data from a stream.
class SensorDataDisplay<T> extends StatelessWidget {
  final Stream<T> stream;
  final String waitingText;

  /// Constructs a SensorDataDisplay with the provided stream and waiting text.
  const SensorDataDisplay({
    Key? key,
    required this.stream,
    required this.waitingText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // StreamBuilder listens to the sensor data stream and builds UI accordingly
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final event = snapshot.data!;
          if (event is UserAccelerometerEvent) {
            return _buildSensorRows(event.x, event.y, event.z);
          } else if (event is GyroscopeEvent) {
            return _buildSensorRows(event.x, event.y, event.z);
          } else {
            return const Text('Unknown data type');
          }
        } else {
          return Text(waitingText);
        }
      },
    );
  }

  /// Builds rows to display X, Y, Z sensor values.
  Widget _buildSensorRows(double x, double y, double z) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRow('X:', x),
        _buildRow('Y:', y),
        _buildRow('Z:', z),
      ],
    );
  }

  /// Builds a single row with a label and its corresponding value.
  Widget _buildRow(String label, double value) {
    return Row(
      children: [
        const SizedBox(width: 150, child: Text('')),
        Text('$label $value'),
      ],
    );
  }
}

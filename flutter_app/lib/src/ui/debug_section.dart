import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../data_collection/data_collection_manager.dart';
import '../activity_recognition_manager.dart';
import 'sensor_data_display.dart';

/// Widget to display debugging information including GPS, sensor data, and activities.
class DebugSection extends StatelessWidget {
  final Position? currentPosition;
  final DataCollectionManager dataCollectionManager;
  final ActivityRecognitionManager activityRecognitionManager;
  final VoidCallback toggleDataCollection;
  final VoidCallback toggleManualDataCollection;
  final VoidCallback toggleAutoDataCollection;
  final Future<String> Function() sendDataToServer;

  /// Constructs DebugSection with current position, data managers, and callbacks.
  const DebugSection({
    Key? key,
    required this.currentPosition,
    required this.dataCollectionManager,
    required this.activityRecognitionManager,
    required this.toggleDataCollection,
    required this.toggleManualDataCollection,
    required this.toggleAutoDataCollection,
    required this.sendDataToServer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Main column layout for debugging information
    return Column(
      children: [
        const Text('GPS Data:'),
        if (currentPosition != null) ...[
          Text('Lat: ${currentPosition!.latitude}'),
          Text('Lon: ${currentPosition!.longitude}'),
        ],
        const SizedBox(height: 20),
        // Display data collection statistics
        Text(
            'Samples in Memory: ${dataCollectionManager.tempHistoricData.length}'),
        Text('Written Samples: ${dataCollectionManager.writtenSamples}'),
        const SizedBox(height: 20),
        const Text('Current Activity:'),
        Text(activityRecognitionManager.currentActivity.toString()),
        const SizedBox(height: 20),
        const Text('Accelerometer Data:'),
        // Display accelerometer sensor data
        SensorDataDisplay<UserAccelerometerEvent>(
          stream: userAccelerometerEvents,
          waitingText: 'Waiting for accelerometer data...',
        ),
        const SizedBox(height: 20),
        const Text('Gyroscope Data:'),
        // Display gyroscope sensor data
        SensorDataDisplay<GyroscopeEvent>(
          stream: gyroscopeEvents,
          waitingText: 'Waiting for gyroscope data...',
        ),
        const SizedBox(height: 20),
        const Text('Historic Data:'),
        // List of historic collected data samples
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: dataCollectionManager.tempHistoricData.length,
          itemBuilder: (context, index) {
            final data = dataCollectionManager.tempHistoricData[index];
            return ListTile(
              title: Text(
                  'Time: ${data.timestamp}, Lat: ${data.position.latitude}, Lon: ${data.position.longitude}'),
              subtitle: Text(
                  'Acc: X=${data.userAccelerometerEvent.x}, Y=${data.userAccelerometerEvent.y}, Z=${data.userAccelerometerEvent.z}\n'
                  'Gyro: X=${data.gyroscopeEvent.x}, Y=${data.gyroscopeEvent.y}, Z=${data.gyroscopeEvent.z}'),
            );
          },
        ),
      ],
    );
  }
}

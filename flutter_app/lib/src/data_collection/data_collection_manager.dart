import 'package:flutter_app/src/data_collection/collect_data.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'dart:async';
import 'dart:isolate'; // Import for multithreading
import '../historic_data.dart';
import 'dart:developer' as developer;
import '../app.dart';

class DataCollectionManager {
  bool _isCollectingData = false;
  int _writtenSamples = 0;
  final List<HistoricData> _tempHistoricData = [];

  Timer? _writeTimer;
  Timer? _samplingTimer;
  Position? _currentPosition;
  UserAccelerometerEvent? _userAccelerometerEvent;
  GyroscopeEvent? _gyroscopeEvent;

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  final Function(int) onWrittenSamplesUpdated;
  final Function() onDataUpdated;
  final Function() getCurrentSurfaceType;

  int _samplesInLastInterval = 0;
  Timer? _samplingRateTimer;

  // Ports for communicating with I/O isolate
  SendPort? _ioSendPort;
  late ReceivePort _ioReceivePort;

  DataCollectionManager({
    required this.onWrittenSamplesUpdated,
    required this.onDataUpdated,
    required this.getCurrentSurfaceType,
  });

  /// Start a persistent isolate for I/O operations.
  Future<void> _startIOIsolate() async {
    _ioReceivePort = ReceivePort();
    await Isolate.spawn(_ioIsolateEntry, _ioReceivePort.sendPort);
    _ioSendPort = await _ioReceivePort.first; // Wait for isolate to send back its SendPort
  }

  /// The entry point for the I/O isolate. 
  /// It sets up a ReceivePort to listen for incoming data batches and writes them to the file.
  static Future<void> _ioIsolateEntry(SendPort mainSendPort) async {
    final receivePort = ReceivePort();
    // Send the sendPort for this isolate back to main isolate
    mainSendPort.send(receivePort.sendPort);

    // Listen for incoming messages (data to write)
    await for (final message in receivePort) {
      if (message is List<HistoricData>) {
        // Write data to file
        try {
          final file = await getLocalFile();
          await writeDataToFile(message, file.path);
        } catch (e) {
          developer.log('IO isolate error writing data: $e');
        }
      } else if (message == 'close') {
        break;
      }
    }
  }

  Future<void> startDataCollection() async {
    developer.log('Starting data collection...');
    await _startIOIsolate(); // Start the I/O isolate first

    _isCollectingData = true;
    _positionSubscription = _listenToLocationChanges();
    _accelerometerSubscription = _listenToAccelerometer();
    _gyroscopeSubscription = _listenToGyroscope();

    // Write every 5 seconds
    _writeTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      _appendHistoricDataToFile();
    });

    // Sample every 20ms regardless of changes
    _samplingTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      _saveHistoricData();
    });

    // Start a timer to log sampling rate every 10 seconds
    _samplingRateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      final double avgRate = _samplesInLastInterval / 10.0;
      developer.log('Average sampling rate over last 10s: $avgRate samples/s');
      _samplesInLastInterval = 0;
    });
  }

  void startAutoDataCollection() {
    isAutoDataCollection = true;
  }

  void stopAutoDataCollection() {
    isAutoDataCollection = false;
  }

  void stopDataCollection() {
    _isCollectingData = false;
    _positionSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _writeTimer?.cancel();
    _samplingTimer?.cancel();
    _samplingRateTimer?.cancel();

    // Notify IO isolate to close if desired
    _ioSendPort?.send('close');
  }

  StreamSubscription<Position> _listenToLocationChanges() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      ),
    ).listen((Position position) {
      _currentPosition = position;
      onDataUpdated();
    });
  }

  StreamSubscription<UserAccelerometerEvent> _listenToAccelerometer() {
    return userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      _userAccelerometerEvent = event;
      onDataUpdated();
    });
  }

  StreamSubscription<GyroscopeEvent> _listenToGyroscope() {
    return gyroscopeEvents.listen((GyroscopeEvent event) {
      _gyroscopeEvent = event;
      onDataUpdated();
    });
  }

  Future<void> _saveHistoricData() async {
    if (!_isCollectingData) return;
    // Create a new data point with the latest known values
    final data = HistoricData(
      timestamp: DateTime.now(),
      position: _currentPosition!,
      userAccelerometerEvent: _userAccelerometerEvent!,
      gyroscopeEvent: _gyroscopeEvent!,
      surfaceType: getCurrentSurfaceType(),
    );

    _tempHistoricData.add(data);
    _samplesInLastInterval += 1;
  }

  Future<void> _appendHistoricDataToFile() async {
    if (_tempHistoricData.isEmpty) {
      return;
    }

    // Send the data to the I/O isolate to handle writing.
    final dataToAppend = List<HistoricData>.from(_tempHistoricData);
    _tempHistoricData.clear();
    _ioSendPort?.send(dataToAppend);
  }

  Future<void> dispose() async {
    _positionSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _writeTimer?.cancel();
    _samplingTimer?.cancel();
    _samplingRateTimer?.cancel();

    // Close the IO isolate
    _ioSendPort?.send('close');
  }


  bool get isCollectingData => _isCollectingData;

  set isCollectingData(bool value) {
    _isCollectingData = value;
  }

  int get writtenSamples => _writtenSamples;
  List<HistoricData> get tempHistoricData => _tempHistoricData;
  Position? get currentPosition => _currentPosition;
}

import 'package:flutter/services.dart';
import 'package:flutter_app/src/data_collection/collect_data.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'dart:async';
import 'dart:isolate';
import '../historic_data.dart';
import 'dart:developer' as developer;
import '../app.dart';

// Manages the collection of sensor and location data
class DataCollectionManager {
  bool _isCollectingData = false; // Indicates if data collection is active
  int _writtenSamples = 0; // Number of samples written
  final List<HistoricData> _tempHistoricData = []; // Temporary storage for data

  Timer? _writeTimer; // Timer for periodic file writing
  Timer? _samplingTimer; // Timer for data sampling
  Position? _currentPosition; // Current GPS position
  UserAccelerometerEvent? _userAccelerometerEvent; // Latest accelerometer event
  GyroscopeEvent? _gyroscopeEvent; // Latest gyroscope event

  StreamSubscription<Position>?
      _positionSubscription; // Subscription to location changes
  StreamSubscription<UserAccelerometerEvent>?
      _accelerometerSubscription; // Subscription to accelerometer events
  StreamSubscription<GyroscopeEvent>?
      _gyroscopeSubscription; // Subscription to gyroscope events

  final Function(int)
      onWrittenSamplesUpdated; // Callback for written samples update
  final Function() onDataUpdated; // Callback for data updates
  final Function()
      getCurrentSurfaceType; // Callback to get current surface type

  int _samplesInLastInterval = 0; // Samples counted in the last interval
  Timer? _samplingRateTimer; // Timer for logging sampling rate

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
    var rootIsolateToken = RootIsolateToken.instance!;
    await Isolate.spawn(
      _ioIsolateEntry,
      [_ioReceivePort.sendPort, rootIsolateToken], // Pass the token
    );
    _ioSendPort = await _ioReceivePort
        .first; // Wait for isolate to send back its SendPort
  }

  /// The entry point for the I/O isolate.
  /// It sets up a ReceivePort to listen for incoming data batches and writes them to the file.
  static Future<void> _ioIsolateEntry(List<dynamic> args) async {
    SendPort mainSendPort = args[0];
    RootIsolateToken rootIsolateToken = args[1];

    BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);

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

  /// Starts the data collection process.
  Future<void> startDataCollection() async {
    developer.log('Starting data collection...');
    await _startIOIsolate();

    _isCollectingData = true;
    _positionSubscription = _listenToLocationChanges();
    _accelerometerSubscription = _listenToAccelerometer();
    _gyroscopeSubscription = _listenToGyroscope();

    // Write data to file every 10 seconds
    _writeTimer = Timer.periodic(const Duration(seconds: 10), (Timer timer) {
      _appendHistoricDataToFile();
    });

    // Sample data every 4ms regardless of changes
    _samplingTimer = Timer.periodic(const Duration(milliseconds: 4), (timer) {
      _saveHistoricData();
    });

    // Start a timer to log sampling rate every 10 seconds
    _samplingRateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      final double avgRate = _samplesInLastInterval / 10.0;
      developer.log('Average sampling rate over last 10s: $avgRate samples/s');
      _samplesInLastInterval = 0;
    });
  }

  /// Enables automatic data collection mode.
  void startAutoDataCollection() {
    isAutoDataCollection = true;
  }

  /// Disables automatic data collection mode.
  void stopAutoDataCollection() {
    isAutoDataCollection = false;
  }

  /// Stops the data collection process and cleans up resources.
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

  // Subscribes to location changes using Geolocator
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

  // Subscribes to accelerometer events
  StreamSubscription<UserAccelerometerEvent> _listenToAccelerometer() {
    return userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      _userAccelerometerEvent = event;
      onDataUpdated();
    });
  }

  // Subscribes to gyroscope events
  StreamSubscription<GyroscopeEvent> _listenToGyroscope() {
    return gyroscopeEvents.listen((GyroscopeEvent event) {
      _gyroscopeEvent = event;
      onDataUpdated();
    });
  }

  /// Saves the latest sensor and location data into temporary storage.
  Future<void> _saveHistoricData() async {
    if (!_isCollectingData ||
        _currentPosition == null ||
        _userAccelerometerEvent == null ||
        _gyroscopeEvent == null) return;
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

  /// Appends the collected historic data to the file via the I/O isolate.
  Future<void> _appendHistoricDataToFile() async {
    if (_tempHistoricData.isEmpty) {
      return;
    }

    // Send the data to the I/O isolate to handle writing.
    final dataToAppend = List<HistoricData>.from(_tempHistoricData);
    _tempHistoricData.clear();
    _ioSendPort?.send(dataToAppend);
  }

  /// Disposes of all resources and stops data collection.
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

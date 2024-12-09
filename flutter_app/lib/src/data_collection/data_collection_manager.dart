/// Manages the data collection process, including listening to sensor streams,
/// collecting data, and writing it to a file using multithreading to avoid blocking the UI.
///
/// This class handles the collection of GPS positions, accelerometer, and gyroscope data.
/// It uses isolates to offload heavy tasks like writing data to a file, ensuring that
/// the main thread remains responsive. It provides methods to start and stop data collection,
/// and periodically writes the collected data to a file. It also provides callbacks to update the UI
/// when data is updated or when the number of written samples changes.

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
  /// Indicates whether data collection is currently active.
  bool _isCollectingData = false;

  /// The total number of samples that have been written to the file.
  int _writtenSamples = 0;

  /// A temporary list to store collected data before writing to file.
  final List<HistoricData> _tempHistoricData = [];

  /// Timer to throttle data saving to prevent excessive writes.
  Timer? _throttleTimer;

  /// Timer to schedule periodic data writing to file.
  Timer? _writeTimer;

  /// The current GPS position.
  Position? _currentPosition;

  /// The latest user accelerometer event.
  UserAccelerometerEvent? _userAccelerometerEvent;

  /// The latest gyroscope event.
  GyroscopeEvent? _gyroscopeEvent;

  /// Subscription to the GPS position stream.
  StreamSubscription<Position>? _positionSubscription;

  /// Subscription to the user accelerometer stream.
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;

  /// Subscription to the gyroscope stream.
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  /// Callback function to update the written samples count in the UI.
  final Function(int) onWrittenSamplesUpdated;

  /// Callback function to notify the UI that new data is available.
  final Function() onDataUpdated;

  /// Function to get the current surface type, used when saving data.
  final Function() getCurrentSurfaceType;

  /// Creates a new [DataCollectionManager].
  ///
  /// The [onWrittenSamplesUpdated] callback is called whenever the number of
  /// written samples changes, so the UI can be updated.
  ///
  /// The [onDataUpdated] callback is called whenever new data is available,
  /// so the UI can be refreshed.
  ///
  /// The [getCurrentSurfaceType] function is used to get the current surface
  /// type when saving data.
  DataCollectionManager({
    required this.onWrittenSamplesUpdated,
    required this.onDataUpdated,
    required this.getCurrentSurfaceType,
  });

  /// Starts the data collection process.
  ///
  /// Begins listening to the GPS position, accelerometer, and gyroscope streams.
  /// Also starts a timer to periodically write collected data to a file.
  Future<void> startDataCollection() async {
    developer.log('Starting data collection...');
    _isCollectingData = true;
    _positionSubscription = _listenToLocationChanges();
    _accelerometerSubscription = _listenToAccelerometer();
    _gyroscopeSubscription = _listenToGyroscope();
    _writeTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      developer.log('Times up, appending data to file.');
      _appendHistoricDataToFile();
    });
  }

  void startAutoDataCollection() {
    isAutoDataCollection = true; // Update the global variable
    // Do not start data collection here
  }

  // Add method to stop automatic data collection
  void stopAutoDataCollection() {
    isAutoDataCollection = false; // Update the global variable
    // Do not stop data collection here
  }

  /// Stops the data collection process.
  ///
  /// Cancels all active subscriptions and timers.
  void stopDataCollection() {
    _isCollectingData = false;
    _positionSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _writeTimer?.cancel();
    _throttleTimer?.cancel();
  }

  /// Listens to GPS position changes and updates the current position.
  ///
  /// Returns a [StreamSubscription] that can be cancelled when no longer needed.
  StreamSubscription<Position> _listenToLocationChanges() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      ),
    ).listen((Position position) {
      developer
          .log('New position: ${position.latitude}, ${position.longitude}');
      _currentPosition = position;
      onDataUpdated();
      _throttleSaveHistoricData();
    });
  }

  /// Listens to user accelerometer events and updates the latest event.
  ///
  /// Returns a [StreamSubscription] that can be cancelled when no longer needed.
  StreamSubscription<UserAccelerometerEvent> _listenToAccelerometer() {
    return userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      _userAccelerometerEvent = event;
      onDataUpdated();
      _throttleSaveHistoricData();
    });
  }

  /// Listens to gyroscope events and updates the latest event.
  ///
  /// Returns a [StreamSubscription] that can be cancelled when no longer needed.
  StreamSubscription<GyroscopeEvent> _listenToGyroscope() {
    return gyroscopeEvents.listen((GyroscopeEvent event) {
      _gyroscopeEvent = event;
      onDataUpdated();
      _throttleSaveHistoricData();
    });
  }

  /// Throttles the saving of historic data to prevent excessive writes.
  ///
  /// Uses a [Timer] to delay the call to [_saveHistoricData] by a short duration.
  void _throttleSaveHistoricData() {
    if (!_isCollectingData) return;
    if (_throttleTimer?.isActive ?? false) return;

    _throttleTimer = Timer(const Duration(milliseconds: 5), () {
      _saveHistoricData();
    });
  }

  /// Saves the current sensor data as a [HistoricData] object.
  ///
  /// Collects the current position, accelerometer event, and gyroscope event,
  /// and adds them to the [_tempHistoricData] list.
  Future<void> _saveHistoricData() async {
    if (_userAccelerometerEvent != null && _gyroscopeEvent != null) {
      final position = _currentPosition ??
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best,
          );
      _currentPosition = position;

      final data = HistoricData(
        timestamp: DateTime.now(),
        position: position,
        userAccelerometerEvent: _userAccelerometerEvent!,
        gyroscopeEvent: _gyroscopeEvent!,
        surfaceType: getCurrentSurfaceType(), // Include surfaceType
      );
      _tempHistoricData.add(data);
      _writtenSamples += 1;
      onWrittenSamplesUpdated(_writtenSamples);
    }
  }

  /// Appends the collected data to the local file using an isolate to avoid blocking.
  ///
  /// Offloads the file writing operation to a separate isolate.
  Future<void> _appendHistoricDataToFile() async {
    if (_tempHistoricData.isEmpty) {
      developer.log('No data to append');
      return;
    }

    try {
      final List<HistoricData> dataToAppend = List.from(_tempHistoricData);
      final String filePath = (await getLocalFile()).path; // Obtain file path

      // Create a ReceivePort to receive messages from the isolate
      final ReceivePort receivePort = ReceivePort();

      // Spawn an isolate to handle file writing, passing filePath
      await Isolate.spawn<List<dynamic>>(
        _writeDataIsolate,
        [dataToAppend, filePath, receivePort.sendPort],
      );

      // Wait for the isolate to signal completion
      await receivePort.first;

      developer.log('All temporary historic data written to file successfully');

      // Clear the temporary list after writing
      _tempHistoricData.clear();
    } catch (e) {
      developer.log('Error writing temporary historic data to file: $e');
    }
  }

  /// Isolate entry point for writing data to a file.
  ///
  /// Receives a list containing the data to write, the file path, and a [SendPort] to communicate back.
  static Future<void> _writeDataIsolate(List<dynamic> args) async {
    final List<HistoricData> dataToAppend = args[0];
    final String filePath = args[1]; // Receive file path
    final SendPort sendPort = args[2];
    developer.log('Writing data to file in isolate...');
    developer.log('Number of data entries to write: ${dataToAppend.length}');
    try {
      await writeDataToFile(dataToAppend, filePath); // Pass file path
      developer.log('All data written to file successfully');
    } catch (e) {
      developer.log('Error in isolate while writing data: $e');
    }

    // Signal that the operation is complete
    sendPort.send(null);
  }

  /// Disposes of resources used by this manager.
  ///
  /// Cancels all active subscriptions and timers.
  Future<void> dispose() async {
    _positionSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _writeTimer?.cancel();
    _throttleTimer?.cancel();
  }

  /// Updates the count of written samples from the local file using an isolate.
  ///
  /// Offloads the file reading operation to a separate isolate to avoid blocking.
  Future<void> updateWrittenSamples() async {
    try {
      // Create a ReceivePort to receive messages from the isolate
      final ReceivePort receivePort = ReceivePort();

      // Spawn an isolate to handle file reading
      //await Isolate.spawn<SendPort>(
      //_readSamplesIsolate,
      // receivePort.sendPort,
      //);

      // Wait for the isolate to send the number of lines
      final int lineCount = await receivePort.first;

      _writtenSamples = lineCount;
      onWrittenSamplesUpdated(_writtenSamples);
    } catch (e) {
      developer.log('Error reading written samples: $e');
    }
  }

  /// Isolate entry point for reading the number of lines in the file.
  ///
  /// Receives a [SendPort] to communicate back.
  static Future<void> _readSamplesIsolate(SendPort sendPort) async {
    int lineCount = 0;
    try {
      final file = await getLocalFile();
      if (await file.exists()) {
        final lines = await file.readAsLines();
        lineCount = lines.length;
      }
    } catch (e) {
      developer.log('Error in isolate while reading samples: $e');
    }

    // Send the line count back to the main isolate
    sendPort.send(lineCount);
  }

  /// Gets whether data collection is currently active.
  bool get isCollectingData => _isCollectingData;

  set isCollectingData(bool value) {
    _isCollectingData = value;
  }

  /// Gets the total number of written samples.
  int get writtenSamples => _writtenSamples;

  /// Gets the list of collected data not yet written to file.
  List<HistoricData> get tempHistoricData => _tempHistoricData;

  /// Gets the current position.
  Position? get currentPosition => _currentPosition;
}

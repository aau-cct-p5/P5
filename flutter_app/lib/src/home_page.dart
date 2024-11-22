import 'package:flutter/material.dart';
import 'package:flutter_app/src/data_collection/collect_data.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'HistoricData.dart';
import 'data_export/export_data.dart';
import 'dart:developer' as developer;
import 'map.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart'
    as fr;
import 'permissions/activity.dart'; // Import the new activity permission file
import 'package:connectivity_plus/connectivity_plus.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Position? _currentPosition;
  UserAccelerometerEvent? _userAccelerometerEvent;
  GyroscopeEvent? _gyroscopeEvent;
  final MapController _mapController = MapController();
  final double _currentZoom = 20.0;
  late Future<void> _initialPositionFuture;
  bool _isCollectingData = false;
  bool _isDebugVisible = false; // Add state variable for debug visibility
  bool _isMapVisible = true; // Add state variable for map visibility
  int _writtenSamples = 0; // Add state variable for written samples count
  bool _isCycling = false; // Add state variable to track cycling status
  StreamSubscription<fr.Activity>?
      _activitySubscription; // Add activity subscription
  fr.ActivityType _currentActivity =
      fr.ActivityType.UNKNOWN; // Add state variable for current activity

  // List to store historic data temporarily
  final List<HistoricData> _tempHistoricData = [];
  Timer? _throttleTimer;
  Timer? _minuteTimer; // Timer to send data every minute

  // Add stream subscriptions
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  @override
  void initState() {
    super.initState();
    _initialPositionFuture =
        _getInitialPosition(); // Update to directly get initial position
    _updateWrittenSamples(); // Initialize written samples count
    _subscribeActivityStream(); // Subscribe to activity stream
  }

  @override
  void dispose() {
    _minuteTimer?.cancel(); // Cancel the timer when the widget is disposed
    _positionSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _activitySubscription?.cancel(); // Cancel activity subscription
    super.dispose();
  }

  Future<void> _getInitialPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      developer
          .log('Initial position: ${position.latitude}, ${position.longitude}');
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      developer.log('Error getting initial position: $e');
    }
  }

  StreamSubscription<Position> _listenToLocationChanges() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      ),
    ).listen((Position position) {
      developer
          .log('New position: ${position.latitude}, ${position.longitude}');
      setState(() {
        _currentPosition = position;
        if (_mapController.mapEventStream.isBroadcast) {
          _mapController.move(
              LatLng(position.latitude, position.longitude), _currentZoom);
        }
      });
      _throttleSaveHistoricData();
    });
  }

  StreamSubscription<UserAccelerometerEvent> _listenToAccelerometer() {
    return userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      setState(() {
        _userAccelerometerEvent = event;
      });
      _throttleSaveHistoricData();
    });
  }

  StreamSubscription<GyroscopeEvent> _listenToGyroscope() {
    return gyroscopeEvents.listen((GyroscopeEvent event) {
      setState(() {
        _gyroscopeEvent = event;
      });
      _throttleSaveHistoricData();
    });
  }

  void _throttleSaveHistoricData() {
    if (!_isCollectingData) return;
    if (_throttleTimer?.isActive ?? false) return;

    _throttleTimer = Timer(const Duration(milliseconds: 50), () {
      _saveHistoricData();
    });
  }

  Future<void> _saveHistoricData() async {
    if (_userAccelerometerEvent != null && _gyroscopeEvent != null) {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      setState(() {
        _currentPosition = position;
      });
      final data = HistoricData(
        timestamp: DateTime.now(),
        position: position,
        userAccelerometerEvent: _userAccelerometerEvent!,
        gyroscopeEvent: _gyroscopeEvent!,
      );
      _tempHistoricData.add(data);
      _appendWrittenSamplesCount(); // Update written samples count
    }
  }

  // Method to append all temporary historic data to the file every 5 seconds
  Future<void> _appendHistoricDataToFile() async {
    if (_tempHistoricData.isEmpty) {
      developer.log('No data to append');
      return;
    }

    try {
      final List<HistoricData> dataToAppend = List.from(_tempHistoricData);
      for (var data in dataToAppend) {
        await writeDataToFile(data); // Write data to file
      }
      developer.log('All temporary historic data written to file successfully');

      // Clear the temporary list after writing
      setState(() {
        _tempHistoricData.clear();
      });
    } catch (e) {
      developer.log('Error writing temporary historic data to file: $e');
    }
  }

  void _toggleDataCollection() {
    setState(() {
      _isCollectingData = !_isCollectingData;
    });

    if (_isCollectingData) {
      _startDataCollection();
    } else {
      _stopDataCollection();
    }
  }

  void _toggleDebugVisibility() {
    // Add method to toggle debug visibility
    setState(() {
      _isDebugVisible = !_isDebugVisible;
    });
  }

  void _toggleMapVisibility() {
    // Add method to toggle map visibility
    setState(() {
      _isMapVisible = !_isMapVisible;
    });
  }

  Future<void> _updateWrittenSamples() async {
    // Add method to update written samples count
    try {
      final file = await getLocalFile();
      if (await file.exists()) {
        final lines = await file.readAsLines();
        setState(() {
          _writtenSamples = lines.length;
        });
      } else {
        setState(() {
          _writtenSamples = 0;
        });
      }
    } catch (e) {
      developer.log('Error reading written samples: $e');
    }
  }

  Future<void> sendDataToServer() async {
    // Modify sendDataToServer to update written samples
    await sendDataToServerFromExportData(); // Ensure sendDataToServer is accessible
    await _updateWrittenSamples(); // Update the written samples count after sending
  }

  Future<void> _appendWrittenSamplesCount() async {
    // Add method to increment written samples count
    setState(() {
      _writtenSamples += 1;
    });
  }

  void _subscribeActivityStream() async {
    bool hasPermission =
        await checkAndRequestActivityPermission(); // Use the new method
    if (hasPermission) {
      _activitySubscription = fr
          .FlutterActivityRecognition.instance.activityStream
          .listen(_onActivityChange, onError: _onActivityError);
    } else {
      developer.log('Activity recognition permission not granted.');
    }
  }

  void _onActivityChange(fr.Activity activity) {
    // Use alias
    if (activity.type == fr.ActivityType.ON_BICYCLE) {
      // Use alias
      if (!_isCycling) {
        setState(() {
          _isCycling = true;
          _isCollectingData = true;
          _currentActivity =
              fr.ActivityType.ON_BICYCLE; // Update current activity
        });
        _startDataCollection();
        developer
            .log('Cycling detected. Data collection started automatically.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Cycling started. Data collection initiated.')),
        ); // Add SnackBar for cycling start
      }
    } else {
      if (_isCycling) {
        setState(() {
          _isCycling = false;
          _isCollectingData = false;
          _currentActivity =
              fr.ActivityType.ON_BICYCLE; // Update current activity
        });
        _stopDataCollection();
        developer
            .log('Cycling stopped. Data collection stopped automatically.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Cycling stopped. Data collection halted.')),
        ); // Add SnackBar for cycling stop
        _checkIfConnected();
      } else {
        setState(() {
          _currentActivity = fr.ActivityType
              .ON_BICYCLE; // Update current activity for other activities
        });
        developer.log('Activity detected: ${_currentActivity}');
      }
    }
  }

  Future<void> _checkIfConnected() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi) {
      developer.log('Connected, sending data...');
      sendDataToServer();
    } else {
      developer.log('Not connected to wifi, trying again later...');
    }
  }

  void _onActivityError(dynamic error) {
    developer.log('Activity recognition error: $error');
  }

  void _startDataCollection() {
    _positionSubscription = _listenToLocationChanges();
    _accelerometerSubscription = _listenToAccelerometer();
    _gyroscopeSubscription = _listenToGyroscope();
    _minuteTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      _appendHistoricDataToFile();
    });
  }

  void _stopDataCollection() {
    _positionSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _positionSubscription = null;
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _minuteTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon:
                Icon(_isDebugVisible ? Icons.visibility_off : Icons.visibility),
            onPressed: _toggleDebugVisibility,
          ),
          IconButton(
            icon: Icon(_isMapVisible ? Icons.map_outlined : Icons.map),
            onPressed: _toggleMapVisibility,
          ),
        ],
      ),
      body: Center(
        child: FutureBuilder<void>(
          future: _initialPositionFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (_isMapVisible) ...[
                    if (_currentPosition != null)
                      MapWidget(
                        mapController: _mapController,
                        currentPosition: _currentPosition!,
                        currentZoom: _currentZoom,
                      ),
                  ],
                  if (_isDebugVisible) ...[
                    const Text('GPS Data:'),
                    if (_currentPosition != null)
                      Text(
                          'Lat: ${_currentPosition!.latitude}, Lon: ${_currentPosition!.longitude}'),
                    const SizedBox(height: 20),
                    const Text('Accelerometer Data:'),
                    StreamBuilder<UserAccelerometerEvent>(
                      stream: userAccelerometerEvents,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final event = snapshot.data!;
                          return Text(
                              'X: ${event.x}, Y: ${event.y}, Z: ${event.z}');
                        } else {
                          return const Text(
                              'Waiting for accelerometer data...');
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text('Gyroscope Data:'),
                    StreamBuilder<GyroscopeEvent>(
                      stream: gyroscopeEvents,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final event = snapshot.data!;
                          return Text(
                              'X: ${event.x}, Y: ${event.y}, Z: ${event.z}');
                        } else {
                          return const Text('Waiting for gyroscope data...');
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text('Historic Data:'),
                    Expanded(
                      child: SingleChildScrollView(
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _tempHistoricData.length,
                          itemBuilder: (context, index) {
                            final data = _tempHistoricData[index];
                            return ListTile(
                              title: Text(
                                  'Time: ${data.timestamp}, Lat: ${data.position.latitude}, Lon: ${data.position.longitude}'),
                              subtitle: Text(
                                  'Acc: X=${data.userAccelerometerEvent.x}, Y=${data.userAccelerometerEvent.y}, Z=${data.userAccelerometerEvent.z}\n'
                                  'Gyro: X=${data.gyroscopeEvent.x}, Y=${data.gyroscopeEvent.y}, Z=${data.gyroscopeEvent.z}'),
                            );
                          },
                        ),
                      ),
                    ),
                    Text(
                        'Samples in Memory: ${_tempHistoricData.length}'), // Existing samples count
                    Text(
                        'Written Samples: $_writtenSamples'), // Add written samples statistic
                    const SizedBox(height: 20),
                    const Text('Current Activity:'),
                    Text(_currentActivity.toString()),
                    const SizedBox(height: 20),
                    // Hide the toggle button if cycling is detected
                    if (!_isCycling)
                      ElevatedButton(
                        onPressed: _toggleDataCollection,
                        child: Text(_isCollectingData
                            ? 'Stop Data Collection'
                            : 'Start Data Collection'),
                      ),
                    ElevatedButton(
                      onPressed: () async {
                        await sendDataToServer();
                      },
                      child: const Text('Send Data to Server'),
                    ),
                  ],
                  // Add Bicycle Icon indicating cycling status
                  Icon(
                    _isCycling
                        ? Icons.directions_bike
                        : Icons.directions_bike_outlined,
                    color: _isCycling ? Colors.green : Colors.grey,
                    size: 48.0,
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}

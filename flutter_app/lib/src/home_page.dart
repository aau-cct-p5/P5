import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'HistoricData.dart';
import 'export_data.dart';
import 'dart:developer' as developer;
import 'map.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Position? _currentPosition;
  AccelerometerEvent? _accelerometerEvent;
  GyroscopeEvent? _gyroscopeEvent;
  final MapController _mapController = MapController();
  final double _currentZoom = 20.0;
  late Future<void> _initialPositionFuture;
  bool _isCollectingData = false;

  // List to store historic data temporarily
  final List<HistoricData> _tempHistoricData = [];
  Timer? _throttleTimer;
  Timer? _minuteTimer; // Timer to send data every minute

  // Add stream subscriptions
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  @override
  void initState() {
    super.initState();
    _initialPositionFuture = _requestPermissionsAndGetInitialPosition();
  }

  @override
  void dispose() {
    _minuteTimer?.cancel(); // Cancel the timer when the widget is disposed
    _positionSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _requestPermissionsAndGetInitialPosition() async {
    final status = await [
      Permission.locationWhenInUse,
      Permission.location,
      Permission.locationAlways, // Request always permission for background
    ].request();

    if (status[Permission.locationWhenInUse]!.isGranted &&
        status[Permission.location]!.isGranted &&
        status[Permission.locationAlways]!.isGranted) {
      await _getInitialPosition();
    } else {
      developer.log('Location permissions not fully granted');
    }
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
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
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

  StreamSubscription<AccelerometerEvent> _listenToAccelerometer() {
    return accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        _accelerometerEvent = event;
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

    _throttleTimer = Timer(const Duration(seconds: 1), () {
      _saveHistoricData();
    });
  }

  void _saveHistoricData() {
    if (_currentPosition != null &&
        _accelerometerEvent != null &&
        _gyroscopeEvent != null) {
      final data = HistoricData(
        timestamp: DateTime.now(),
        position: _currentPosition!,
        accelerometerEvent: _accelerometerEvent!,
        gyroscopeEvent: _gyroscopeEvent!,
      );
      _tempHistoricData.add(data);
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
      // Start data collection
      _positionSubscription = _listenToLocationChanges();
      _accelerometerSubscription = _listenToAccelerometer();
      _gyroscopeSubscription = _listenToGyroscope();
      _minuteTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
        _appendHistoricDataToFile();
      });
    } else {
      // Stop data collection
      _positionSubscription?.cancel();
      _accelerometerSubscription?.cancel();
      _gyroscopeSubscription?.cancel();
      _positionSubscription = null;
      _accelerometerSubscription = null;
      _gyroscopeSubscription = null;
      _minuteTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
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
                  const Text('GPS Data:'),
                  if (_currentPosition != null)
                    Text(
                        'Lat: ${_currentPosition!.latitude}, Lon: ${_currentPosition!.longitude}'),
                  const SizedBox(height: 20),
                  const Text('Accelerometer Data:'),
                  StreamBuilder<AccelerometerEvent>(
                    stream: accelerometerEvents,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final event = snapshot.data!;
                        return Text(
                            'X: ${event.x}, Y: ${event.y}, Z: ${event.z}');
                      } else {
                        return const Text('Waiting for accelerometer data...');
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
                  if (_currentPosition != null)
                    MapWidget(
                      mapController: _mapController,
                      currentPosition: _currentPosition!,
                      currentZoom: _currentZoom,
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
                                'Acc: X=${data.accelerometerEvent.x}, Y=${data.accelerometerEvent.y}, Z=${data.accelerometerEvent.z}\n'
                                'Gyro: X=${data.gyroscopeEvent.x}, Y=${data.gyroscopeEvent.y}, Z=${data.gyroscopeEvent.z}'),
                          );
                        },
                      ),
                    ),
                  ),
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
              );
            }
          },
        ),
      ),
    );
  }
}

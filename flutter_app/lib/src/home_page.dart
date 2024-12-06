import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'data_export/export_data.dart';
import 'dart:developer' as developer;
import 'map.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart'
    as fr;
// Import the new activity permission file
import 'ml_training_ui.dart';
import 'data_collection/DataCollectionManager.dart';
import 'ActivityRecognitionManager.dart';
import 'app.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Position? _currentPosition;
  final MapController _mapController = MapController();
  final double _currentZoom = 15.0;
  late Future<void> _initialPositionFuture;
  bool _isDebugVisible = false; // Add state variable for debug visibility
  bool _isMapVisible = true; // Add state variable for map visibility
  String _currentSurfaceType = 'none';
  bool _showMLWidget = false;

  // Data collection manager
  late DataCollectionManager _dataCollectionManager;

  // Activity recognition manager
  late ActivityRecognitionManager _activityRecognitionManager;

  // Add global variable
  bool isManualDataCollection = false;

  @override
  void initState() {
    super.initState();
    _initialPositionFuture =
        _getInitialPosition(); // Update to directly get initial position

    _dataCollectionManager = DataCollectionManager(
      onWrittenSamplesUpdated: (int newCount) {
        setState(() {
          // Update written samples count in UI
          // This will be managed within DataCollectionManager
        });
      },
      onDataUpdated: () {
        setState(() {
          // Update UI when data is updated
          _currentPosition = _dataCollectionManager.currentPosition;
          if (_currentPosition != null &&
              _mapController.mapEventStream.isBroadcast) {
            _mapController.move(
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              _currentZoom,
            );
          }
        });
      },
      getCurrentSurfaceType: () => _currentSurfaceType,
    );

    _activityRecognitionManager = ActivityRecognitionManager(
      context: context,
      onCyclingStatusChanged: (bool isCycling) {
        setState(() {
          // Update UI when cycling status changes
          // Perhaps show/hide buttons, etc.
        });
      },
      onActivityChanged: (fr.ActivityType activityType) {
        setState(() {
          // Update current activity
          // For UI display
        });
      },
      startDataCollectionCallback: () {
        _dataCollectionManager.startDataCollection();
      },
      stopDataCollectionCallback: () {
        _dataCollectionManager.stopDataCollection();
      },
      sendDataToServerCallback: sendDataToServer,
    );

    _dataCollectionManager
        .updateWrittenSamples(); // Initialize written samples count
    _activityRecognitionManager.subscribeActivityStream(); // Subscribe to activity stream
  }

  @override
  void dispose() {
    _dataCollectionManager.dispose();
    _activityRecognitionManager.dispose();
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

  void _toggleDataCollection() {
    setState(() {
      _dataCollectionManager.isCollectingData =
          !_dataCollectionManager.isCollectingData;
    });

    if (_dataCollectionManager.isCollectingData) {
      _dataCollectionManager.startDataCollection();
    } else {
      _dataCollectionManager.stopDataCollection();
    }
  }

  void _toggleManualDataCollection() {
    setState(() {
      if (isManualDataCollection) {
        // Stop manual data collection
        isManualDataCollection = false;
        isCollectingData = false; // Update the global collecting data flag
        _dataCollectionManager.stopDataCollection();
      } else {
        // Start manual data collection and stop auto if active
        isManualDataCollection = true;
        isCollectingData = true; // Update the global collecting data flag
        _dataCollectionManager.startDataCollection();
        if (isAutoDataCollection) {
          isAutoDataCollection = false;
          _activityRecognitionManager.unsubscribeActivityStream();
          _dataCollectionManager.stopAutoDataCollection();
        }
      }
    });
  }

  void _toggleAutoDataCollection() {
    setState(() {
      if (isAutoDataCollection) {
        // Stop auto data collection
        isAutoDataCollection = false;
        // Do not directly update isCollectingData here
        _activityRecognitionManager.unsubscribeActivityStream();
        _dataCollectionManager.stopAutoDataCollection();
      } else {
        // Start auto data collection and stop manual if active
        isAutoDataCollection = true;
        _activityRecognitionManager.subscribeActivityStream();
        if (isManualDataCollection) {
          isManualDataCollection = false;
          _dataCollectionManager.stopDataCollection();
        }
      }
    });
  }

  Future<void> sendDataToServer() async {
    // Modify sendDataToServer to update written samples
    await sendDataToServerFromExportData(); // Ensure sendDataToServer is accessible
    await _dataCollectionManager
        .updateWrittenSamples(); // Update the written samples count after sending
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
          ElevatedButton(
            onPressed: () {
              setState(() {
                _showMLWidget = !_showMLWidget;
              });
            },
            child: const Text('ML'),
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
                          itemCount:
                              _dataCollectionManager.tempHistoricData.length,
                          itemBuilder: (context, index) {
                            final data =
                                _dataCollectionManager.tempHistoricData[index];
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
                        'Samples in Memory: ${_dataCollectionManager.tempHistoricData.length}'), // Existing samples count
                    Text(
                        'Written Samples: ${_dataCollectionManager.writtenSamples}'), // Add written samples statistic
                    const SizedBox(height: 20),
                    const Text('Current Activity:'),
                    Text(_activityRecognitionManager.currentActivity
                        .toString()),
                    const SizedBox(height: 20),
                    // Hide the toggle button if cycling is detected
                    if (!_activityRecognitionManager.isCycling)
                      ElevatedButton(
                        onPressed: _toggleDataCollection,
                        child: Text(_dataCollectionManager.isCollectingData
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
                  if (_showMLWidget)
                    MLTrainingWidget(
                      onSurfaceTypeChanged: (String newSurfaceType) {
                        setState(() {
                          _currentSurfaceType = newSurfaceType;
                        });
                      },
                    ),
                  ElevatedButton(
                    onPressed: _toggleManualDataCollection,
                    child: Text(isManualDataCollection
                        ? 'Stop Manual Data Collection'
                        : 'Start Manual Data Collection'),
                  ),
                  ElevatedButton(
                    onPressed: _toggleAutoDataCollection,
                    child: Text(isAutoDataCollection
                        ? 'Stop Auto Data Collection'
                        : 'Start Auto Data Collection'),
                  ),
                  Icon(
                    Icons.directions_bike,
                    color: isCollectingData ? Colors.green : Colors.grey, // Modified line
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

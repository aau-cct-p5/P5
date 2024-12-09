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
import 'data_collection/data_collection_manager.dart';
import 'activity_recognition_manager.dart';
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

  bool isManualDataCollection = false;
  List<String> logs = [];

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
    _activityRecognitionManager
        .subscribeActivityStream(); // Subscribe to activity stream
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

  Future<List<String>> sendDataToServer() async {
    // Modify sendDataToServer to update written samples
    logs =
        await sendDataToServerFromExportData(); // Ensure sendDataToServer is accessible
    await _dataCollectionManager
        .updateWrittenSamples(); // Update the written samples count after sending
    return logs;
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Center(
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
                            if (_currentPosition != null) ...[
                              Text('Lat: ${_currentPosition!.latitude}'),
                              Text('Lon: ${_currentPosition!.longitude}'),
                            ],
                            const SizedBox(height: 20),
                            // Accelerometer Data
                            const Text('Accelerometer Data:'),
                            StreamBuilder<UserAccelerometerEvent>(
                              stream: userAccelerometerEvents,
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final event = snapshot.data!;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 150,
                                            child: const Text('X:'),
                                          ),
                                          Text('${event.x}'),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 150,
                                            child: const Text('Y:'),
                                          ),
                                          Text('${event.y}'),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 150,
                                            child: const Text('Z:'),
                                          ),
                                          Text('${event.z}'),
                                        ],
                                      ),
                                    ],
                                  );
                                } else {
                                  return const Text(
                                      'Waiting for accelerometer data...');
                                }
                              },
                            ),
                            const SizedBox(height: 20),
                            // Gyroscope Data
                            const Text('Gyroscope Data:'),
                            StreamBuilder<GyroscopeEvent>(
                              stream: gyroscopeEvents,
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final event = snapshot.data!;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 150,
                                            child: const Text('X:'),
                                          ),
                                          Text('${event.x}'),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 150,
                                            child: const Text('Y:'),
                                          ),
                                          Text('${event.y}'),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 150,
                                            child: const Text('Z:'),
                                          ),
                                          Text('${event.z}'),
                                        ],
                                      ),
                                    ],
                                  );
                                } else {
                                  return const Text(
                                      'Waiting for gyroscope data...');
                                }
                              },
                            ),
                            const SizedBox(height: 20),
                            const Text('Historic Data:'),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _dataCollectionManager
                                  .tempHistoricData.length,
                              itemBuilder: (context, index) {
                                final data = _dataCollectionManager
                                    .tempHistoricData[index];
                                return ListTile(
                                  title: Text(
                                      'Time: ${data.timestamp}, Lat: ${data.position.latitude}, Lon: ${data.position.longitude}'),
                                  subtitle: Text(
                                      'Acc: X=${data.userAccelerometerEvent.x}, Y=${data.userAccelerometerEvent.y}, Z=${data.userAccelerometerEvent.z}\n'
                                      'Gyro: X=${data.gyroscopeEvent.x}, Y=${data.gyroscopeEvent.y}, Z=${data.gyroscopeEvent.z}'),
                                );
                              },
                            ),
                            Text(
                                'Samples in Memory: ${_dataCollectionManager.tempHistoricData.length}'),
                            Text(
                                'Written Samples: ${_dataCollectionManager.writtenSamples}'),
                            const SizedBox(height: 20),
                            const Text('Current Activity:'),
                            Text(_activityRecognitionManager.currentActivity
                                .toString()),
                            const SizedBox(height: 20),
                            if (!_activityRecognitionManager.isCycling)
                              ElevatedButton(
                                onPressed: _toggleDataCollection,
                                child: Text(
                                    _dataCollectionManager.isCollectingData
                                        ? 'Stop Data Collection'
                                        : 'Start Data Collection'),
                              ),
                            ElevatedButton(
                              onPressed: () async {
                                logs = await sendDataToServer();
                                String log = logs.last;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Hello? $log')),
                                );
                              },
                              child: const Text('Send Data to Server'),
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
                              color:
                                  isCollectingData ? Colors.green : Colors.grey,
                              size: 48.0,
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
                        ],
                      );
                    }
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    // Show Snackbar when starting to send data
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Sending data to server...'),
                        behavior:
                            SnackBarBehavior.floating, // Make snackbar floating
                        elevation: 6.0, // Elevate snackbar
                      ),
                    );

                    try {
                      logs = await sendDataToServer();
                      String log = logs.last;

                      // Show Snackbar when data has been sent successfully
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Data sent: $log'),
                          behavior: SnackBarBehavior
                              .floating, // Make snackbar floating
                          elevation: 6.0, // Elevate snackbar
                        ),
                      );
                    } catch (e) {
                      // Show Snackbar if there was an error sending data
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to send data: $e'),
                          behavior: SnackBarBehavior
                              .floating, // Make snackbar floating
                          elevation: 6.0, // Elevate snackbar
                        ),
                      );
                    }
                  },
                  child: const Text('Send Data to Server'),
                ),
                ElevatedButton(
                  onPressed: _toggleDataCollection,
                  child: Text(
                    _dataCollectionManager.isCollectingData
                        ? 'Stop Data Collection'
                        : 'Start Data Collection',
                  ),
                ),
                ElevatedButton(
                  onPressed: _toggleManualDataCollection,
                  child: Text(
                    isManualDataCollection
                        ? 'Stop Manual Data Collection'
                        : 'Start Manual Data Collection',
                  ),
                ),
                ElevatedButton(
                  onPressed: _toggleAutoDataCollection,
                  child: Text(
                    isAutoDataCollection
                        ? 'Stop Auto Data Collection'
                        : 'Start Auto Data Collection',
                  ),
                ),
                Icon(
                  Icons.directions_bike,
                  color: isCollectingData ? Colors.green : Colors.grey,
                  size: 48.0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

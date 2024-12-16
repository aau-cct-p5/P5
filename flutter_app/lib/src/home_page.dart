import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'data_export/export_data.dart';
import 'dart:developer' as developer;
import 'map.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart'
    as fr;
import 'ml_training_ui.dart';
import 'data_collection/data_collection_manager.dart';
import 'activity_recognition_manager.dart';
import 'app.dart';
import 'snackbar_helper.dart';
import 'ui/debug_section.dart';
import 'ui/footer_controls.dart';

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
  bool _isDebugVisible = false;
  bool _isMapVisible = true;
  String _currentSurfaceType = 'none';
  bool _showMLWidget = false;

  late DataCollectionManager _dataCollectionManager;
  late ActivityRecognitionManager _activityRecognitionManager;

  bool isManualDataCollection = false;

  @override
  void initState() {
    super.initState();
    _initialPositionFuture = _getInitialPosition();

    _dataCollectionManager = DataCollectionManager(
      onWrittenSamplesUpdated: (int newCount) {
        setState(() {
          // Update written samples count in UI
        });
      },
      onDataUpdated: () {
        setState(() {
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
          // Update UI on cycling status change
        });
      },
      onActivityChanged: (fr.ActivityType activityType) {
        setState(() {
          // Update current activity for UI
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

    _activityRecognitionManager.subscribeActivityStream();
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
    setState(() {
      _isDebugVisible = !_isDebugVisible;
    });
  }

  void _toggleMapVisibility() {
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
        isCollectingData = false;
        _dataCollectionManager.stopDataCollection();
      } else {
        // Start manual data collection and stop auto if active
        isManualDataCollection = true;
        isCollectingData = true;
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

  Future<String> sendDataToServer() async {
    String status = await sendDataToServerFromExportData();
    return status;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: rootScaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
          actions: [
            IconButton(
              icon: Icon(
                  _isDebugVisible ? Icons.visibility_off : Icons.visibility),
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
                          children: [
                            if (_isMapVisible && _currentPosition != null)
                              MapWidget(
                                mapController: _mapController,
                                currentPosition: _currentPosition!,
                                currentZoom: _currentZoom,
                              ),
                            if (_isDebugVisible)
                              DebugSection(
                                currentPosition: _currentPosition,
                                dataCollectionManager: _dataCollectionManager,
                                activityRecognitionManager:
                                    _activityRecognitionManager,
                                toggleDataCollection: _toggleDataCollection,
                                toggleManualDataCollection:
                                    _toggleManualDataCollection,
                                toggleAutoDataCollection:
                                    _toggleAutoDataCollection,
                                sendDataToServer: sendDataToServer,
                              ),
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
            FooterControls(
              dataCollectionManager: _dataCollectionManager,
              toggleDataCollection: _toggleDataCollection,
              toggleManualDataCollection: _toggleManualDataCollection,
              toggleAutoDataCollection: _toggleAutoDataCollection,
              sendDataToServer: sendDataToServer,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'permissions/location.dart';
import 'package:logger/logger.dart';
import 'permissions/permissions_modal.dart';

// Flags for data collection modes
bool isManualDataCollection = false;
bool isAutoDataCollection = false;
bool isCollectingData = false;

// Initializes the app by setting up resources and permissions
Future<void> initializeApp() async {
  await _createFileIfNotExists();
  await requestLocationPermissions();
}

// Creates the measurements file if it does not exist
Future<void> _createFileIfNotExists() async {
  final Logger logger = Logger();
  try {
    // Get the application documents directory
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/measurements.txt');
    if (!await file.exists()) {
      // Create the file if it doesn't exist
      await file.create();
      logger.i('File created: ${file.path}');
    }
  } catch (e) {
    // Log any errors encountered during file creation
    logger.e('Error creating file: $e');
  }
}

// MyApp is the root widget of the application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bike Hero',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PermissionsModal(), // Displays permissions modal on startup
    );
  }
}

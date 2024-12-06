import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:path_provider/path_provider.dart';
import '../firebase_options.dart';
import 'dart:io';
import 'home_page.dart';
import 'permissions/location.dart';
import 'package:logger/logger.dart';
import 'permissions/permissions_modal.dart';

bool isManualDataCollection = false;
bool isAutoDataCollection = false;
bool isCollectingData = false; // Ensure this line exists and is globally accessible

Future<void> initializeApp() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await _createFileIfNotExists();
  await requestLocationPermissions(); // Add this line to request location permissions
}

Future<void> _createFileIfNotExists() async {
  final Logger logger = Logger();
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/measurements.txt');
    if (!await file.exists()) {
      await file.create();
      logger.i('File created: ${file.path}');
    }
  } catch (e) {
    logger.e('Error creating file: $e');
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bike Hero',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PermissionsModal(), // Change this line to show the permissions modal first
    );
  }
}

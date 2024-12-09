import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'permissions/location.dart';
import 'package:logger/logger.dart';
import 'permissions/permissions_modal.dart';

bool isManualDataCollection = false;
bool isAutoDataCollection = false;
bool isCollectingData = false;

Future<void> initializeApp() async {
  await _createFileIfNotExists();
  await requestLocationPermissions();
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
      home: const PermissionsModal(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:path_provider/path_provider.dart';
import '../firebase_options.dart';
import 'dart:io';
import 'home_page.dart';

Future<void> initializeApp() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await _createFileIfNotExists();
}

Future<void> _createFileIfNotExists() async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/measurements.txt');
    if (!await file.exists()) {
      await file.create();
    }
  } catch (e) {
    print('Error creating file: $e');
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
      home: const MyHomePage(title: 'Bike Hero'),
    );
  }
}

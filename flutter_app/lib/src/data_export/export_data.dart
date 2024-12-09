import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../historic_data.dart';
import 'dart:developer' as developer;
import 'package:flutter/services.dart' show rootBundle;
import '../data_collection/collect_data.dart';

Map<String, dynamic> prepareData(HistoricData data) {
  return {
    '@timestamp': data.timestamp.toUtc().toIso8601String(),
    'location': {
      'lat': data.position.latitude,
      'lon': data.position.longitude,
    },
    'accelerometer': {
      'x': data.userAccelerometerEvent.x,
      'y': data.userAccelerometerEvent.y,
      'z': data.userAccelerometerEvent.z,
    },
    'gyroscope': {
      'x': data.gyroscopeEvent.x,
      'y': data.gyroscopeEvent.y,
      'z': data.gyroscopeEvent.z,
    },
    'rmsAcceleration': data.rmsAcceleration,
    'surfaceType': data.surfaceType,
  };
}

Future<SecurityContext> get globalContext async {
  final sslCert = await rootBundle.load('assets/ca/elasticsearch.crt');
  SecurityContext securityContext = SecurityContext(withTrustedRoots: false);
  securityContext.setTrustedCertificatesBytes(sslCert.buffer.asInt8List());
  return securityContext;
}

Future<List<String>> sendDataToServerFromExportData() async {
  List<String> logs = [];

  developer.log('Starting to send data to server.');
  logs.add('Starting to send data to server');

  final file = await getLocalFile();
  if (!await file.exists()) {
    developer.log('No data to send.');
    logs.add('No data to send');
    return logs;
  }

  final lines = await file.readAsLines();
  developer.log('Number of data entries to send: ${lines.length}');
  logs.add('Number of data entries to send: ${lines.length}');

  final headers = {
    'Content-Type': 'application/json',
    'Authorization':
        'ApiKey eFl6eXVKSUJfQU5hdks2UWFycTg6WWIyUUJPQWpRcW14cDVBN0Z3NVhjZw=='
  };

  final remainingLines = <String>[];
  int successCount = 0;

  final bulkBody =
      '${lines.expand((line) => ['{"create":{}}', line]).join('\n')}\n';
  final bulkUrl = Uri.parse(
      'https://elastic.mcmogens.dk/bikehero-data-stream/_bulk?refresh');
  final response = await http.post(
    bulkUrl,
    headers: headers,
    body: bulkBody,
  );
  if (response.statusCode == 200) {
    developer.log('Bulk data sent successfully.');
    logs.add('Bulk data sent successfully.');
    try {
      await file.writeAsString('');
      developer.log(
          'All data sent successfully. measurements.txt deleted. Total data points sent: $successCount');
      logs.add('All data sent successfully. measurements.txt deleted. Total data points sent: $successCount');
    } catch (e) {
      developer.log('Error deleting file: $e');
      logs.add('Error deleting file: $e');

    }
  } else {
    developer
        .log('Failed to send bulk data. Status code: ${response.statusCode}.');
    logs.add('Failed to send bulk data. Status code: ${response.statusCode}.');
    await file.writeAsString(remainingLines.join('\n'));
    developer.log(
        '${remainingLines.length} data entries could not be sent and have been retained. Total data points sent: $successCount');
    logs.add('${remainingLines.length} data entries could not be sent and have been retained. Total data points sent: $successCount');
  }

  return logs;
}

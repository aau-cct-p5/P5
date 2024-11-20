import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import '../HistoricData.dart';
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
      'x': data.accelerometerEvent.x,
      'y': data.accelerometerEvent.y,
      'z': data.accelerometerEvent.z,
    },
    'gyroscope': {
      'x': data.gyroscopeEvent.x,
      'y': data.gyroscopeEvent.y,
      'z': data.gyroscopeEvent.z,
    },
    'rmsAcceleration': data.rmsAcceleration,
  };
}

Future<SecurityContext> get globalContext async {
  final sslCert = await rootBundle.load('assets/ca/elasticsearch.crt');
  SecurityContext securityContext = SecurityContext(withTrustedRoots: false);
  securityContext.setTrustedCertificatesBytes(sslCert.buffer.asInt8List());
  return securityContext;
}

Future<int> sendDataToServerFromExportData() async {
  developer.log('Starting to send data to server.');

  final file = await getLocalFile();
  if (!await file.exists()) {
    developer.log('No data to send.');
    return 0;
  }

  final lines = await file.readAsLines();
  developer.log('Number of data entries to send: ${lines.length}');

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
    try {
      await file.delete();
      developer.log(
          'All data sent successfully. measurements.txt deleted. Total data points sent: $successCount');
    } catch (e) {
      developer.log('Error deleting file: $e');
    }
  } else {
    developer
        .log('Failed to send bulk data. Status code: ${response.statusCode}.');
    await file.writeAsString(remainingLines.join('\n'));
    developer.log(
        '${remainingLines.length} data entries could not be sent and have been retained. Total data points sent: $successCount');
  }

  return successCount; // Return the number of successfully sent samples
}

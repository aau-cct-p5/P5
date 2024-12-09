import 'dart:io';
import 'package:flutter_app/src/snackbar_helper.dart';
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

Future<String> sendDataToServerFromExportData() async {
  String statusMessage = '';

  developer.log('Starting to send data to server.');
  statusMessage += 'Starting to send data to server.\n';

  final file = await getLocalFile();
  if (!await file.exists()) {
    developer.log('No data to send.');
    statusMessage += 'No data to send.';
    return statusMessage;
  }

  final lines = await file.readAsLines();
  developer.log('Number of data entries to send: ${lines.length}');
  statusMessage += 'Number of data entries to send: ${lines.length}.\n';

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
    statusMessage += 'Bulk data sent successfully.\n';
    try {
      await file.writeAsString('');
      developer.log(
          'All data sent successfully. measurements.txt deleted. Total data points sent: $successCount');
      statusMessage +=
          'All data sent successfully. measurements.txt deleted. Total data points sent: $successCount.';
    } catch (e) {
      developer.log('Error deleting file: $e');
      statusMessage += 'Error deleting file: $e.';
    }
  } else {
    developer
        .log('Failed to send bulk data. Status code: ${response.statusCode}.');
    statusMessage +=
        'Failed to send bulk data. Status code: ${response.statusCode}.\n';
    await file.writeAsString(remainingLines.join('\n'));
    developer.log(
        '${remainingLines.length} data entries could not be sent and have been retained. Total data points sent: $successCount');
    statusMessage +=
        '${remainingLines.length} data entries could not be sent and have been retained. Total data points sent: $successCount.';

    // Throw an exception with the error code
    throw Exception(
        'Failed to send data to server. Status code: ${response.statusCode}');
  }

  SnackbarManager().showSnackBar(statusMessage);

  return statusMessage;
}

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

  final bulkUrl = Uri.parse(
      'https://elastic.mcmogens.dk/bikehero-data-stream/_bulk?refresh');

  // Helper function to send data in fixed batch size (1000)
  Future<void> sendInBatches(List<String> allLines, int batchSize) async {
    List<String> remainingLines = List.from(allLines);
    int totalSent = 0;

    for (int i = 0; i < allLines.length; i += batchSize) {
      final chunkEnd =
          (i + batchSize > allLines.length) ? allLines.length : i + batchSize;
      final chunk = allLines.sublist(i, chunkEnd);

      final bulkBody =
          '${chunk.expand((line) => ['{"create":{}}', line]).join('\n')}\n';
      final response = await http.post(
        bulkUrl,
        headers: headers,
        body: bulkBody,
      );

      developer.log('Bulk request response status: ${response.statusCode}');
      developer.log('Bulk request response body: ${response.body}');

      if (response.statusCode == 200) {
        developer.log('Batch from $i to ${chunkEnd - 1} sent successfully.');
        totalSent += chunk.length;
        // Remove the sent portion from the remaining lines
        remainingLines = remainingLines.sublist(chunk.length);
      } else {
        developer.log(
            'Failed to send bulk data for batch starting at $i. Status code: ${response.statusCode}, Response: ${response.body}');
        // Write back remaining lines
        await file.writeAsString(remainingLines.join('\n'));
        SnackbarManager().showSnackBar(
            'Failed to send data to server. Status code: - ${response.statusCode} - ${response.body} ');

        // Throw an exception to stop execution as requested
        throw Exception(
            'Failed to send batch $i to ${chunkEnd - 1}. Stopping execution.');
      }
    }

    // If all lines sent successfully, clear the file
    try {
      await file.writeAsString('');
      developer.log(
          'All data sent successfully. measurements.txt cleared. Total data points sent: $totalSent');
    } catch (e) {
      throw Exception('Error deleting file: $e');
    }
  }

  // Attempt to send all data in batches of 1000
  try {
    await sendInBatches(lines, 1000);
    statusMessage += 'All data sent successfully.\n';
    SnackbarManager().showSnackBar(statusMessage);
  } catch (e) {
    developer.log('Data sending failed. Exception: $e');
    statusMessage += 'Data sending failed. Check snackbar for details.\n';
  }

  return statusMessage;
}

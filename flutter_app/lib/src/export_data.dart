import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'HistoricData.dart';
import 'dart:developer' as developer;
import 'package:flutter/services.dart' show rootBundle;

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
  };
}

Future<SecurityContext> get globalContext async {
  final sslCert = await rootBundle.load('assets/ca/elasticsearch.crt');
  SecurityContext securityContext = SecurityContext(withTrustedRoots: false);
  securityContext.setTrustedCertificatesBytes(sslCert.buffer.asInt8List());
  return securityContext;
}

Future<File> _getLocalFile() async {
  final directory = await getApplicationDocumentsDirectory();
  return File('${directory.path}/measurements.txt');
}

Future<void> writeDataToFile(HistoricData data) async {
  final file = await _getLocalFile();
  final body = jsonEncode(prepareData(data));
  await file.writeAsString('$body\n', mode: FileMode.append);
}

Future<void> sendDataToServer() async {
  developer.log('Starting to send data to server.');
  
  final file = await _getLocalFile();
  if (!await file.exists()) {
    developer.log('No data to send.');
    return;
  }

  final lines = await file.readAsLines();
  developer.log('Number of data entries to send: ${lines.length}');
  
  final url = Uri.parse(
      'https://elastic.mcmogens.dk/bikehero-data-stream/_doc'); // Elastic receiver
  final headers = {
    'Content-Type': 'application/json',
    'Authorization':
        'ApiKey eFl6eXVKSUJfQU5hdks2UWFycTg6WWIyUUJPQWpRcW14cDVBN0Z3NVhjZw=='
  };

  final remainingLines = <String>[];
  int successCount = 0;

  for (final line in lines) {
    try {
      developer.log('Sending data: $line');
      final response = await http.post(
        url,
        headers: headers,
        body: line,
      );

      if (response.statusCode == 201) {
        developer.log('Data sent successfully: ${response.body}');
        successCount++;
      } else {
        developer.log(
            'Failed to send data. Status code: ${response.statusCode}. Body: ${response.body}');
        remainingLines.add(line);
      }
    } catch (e) {
      developer.log('Error sending data: $e');
      remainingLines.add(line);
    }
  }

  if (remainingLines.isEmpty) {
    await file.delete();
    developer.log(
        'All data sent successfully. measurements.txt deleted. Total data points sent: $successCount');
  } else {
    await file.writeAsString(remainingLines.join('\n'));
    developer.log(
        '${remainingLines.length} data entries could not be sent and have been retained. Total data points sent: $successCount');
  }
}

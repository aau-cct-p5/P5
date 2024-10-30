import 'dart:io';

import 'package:http/http.dart' as http;
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


Future<void> sendDataToServer(HistoricData data) async {
  final url = Uri.parse('https://elastic.mcmogens.dk/bikehero-data-stream/_doc'); // Elastic receiver
  final headers = {'Content-Type': 'application/json', 'Authorization': 'ApiKey eFl6eXVKSUJfQU5hdks2UWFycTg6WWIyUUJPQWpRcW14cDVBN0Z3NVhjZw=='};

  try {
    final body = jsonEncode(prepareData(data));  // Convert data to JSON

    final response = await http.post(
      url,
      headers: headers,
      body: body,
    );
    
    if (response.statusCode == 201) {
      developer.log('Data sent successfully: ${response.body}');
    } else {
      developer.log('Failed to send data. Status code: ${response.statusCode}');
    }
  } catch (e) {
    developer.log('Error sending data: $e');
  }
}

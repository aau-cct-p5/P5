import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../HistoricData.dart';
import 'dart:developer' as developer;

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

Future<File> getLocalFile() async {
  final directory = await getApplicationDocumentsDirectory();
  return File('${directory.path}/measurements.txt');
}

Future<void> writeDataToFile(HistoricData data) async {
  final file = await getLocalFile();
  final body = jsonEncode(prepareData(data));
  await file.writeAsString('$body\n', mode: FileMode.append);
}
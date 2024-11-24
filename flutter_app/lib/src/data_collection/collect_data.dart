import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../HistoricData.dart';
import 'dart:developer' as developer;

int _writeCount = 0;

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

Future<File> getLocalFile() async {
  final directory = await getApplicationDocumentsDirectory();
  return File('${directory.path}/measurements.txt');
}

Future<void> writeDataToFile(HistoricData data) async {
  final file = await getLocalFile();
  final body = jsonEncode(prepareData(data));
  await file.writeAsString('$body\n', mode: FileMode.append);
  
  _writeCount++;
  if (_writeCount % 50 == 0) {
    developer.log('Saved $_writeCount data: $body');
  }
}

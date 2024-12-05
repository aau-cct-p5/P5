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
  developer.log('Getting local file...');
  final directory = await getApplicationDocumentsDirectory();
  developer.log('File path: ${(await getApplicationDocumentsDirectory()).path}');
  return File('${directory.path}/measurements.txt');
}

Future<void> writeDataToFile(List<HistoricData> dataList, String filePath) async {
  developer.log('Writing data to file...');
  final file = File(filePath);
  developer.log('File path: $file');
  
  final StringBuffer buffer = StringBuffer();

  for (var data in dataList) {
    developer.log('Preparing data for saving...');
    final body = jsonEncode(prepareData(data));
    buffer.writeln(body);
    developer.log('Data prepared for saving: $body');
  }

  await file.writeAsString(buffer.toString(), mode: FileMode.append);
  developer.log('Batch data saved successfully.');

  _writeCount += dataList.length;
  if (_writeCount % 50 == 0) {
    developer.log('Saved $_writeCount data entries.');
  }
}

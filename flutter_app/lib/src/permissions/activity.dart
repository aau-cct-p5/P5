import 'package:flutter_activity_recognition/flutter_activity_recognition.dart'
    as fr;

Future<bool> checkAndRequestActivityPermission() async {
  fr.ActivityPermission permission =
      await fr.FlutterActivityRecognition.instance.checkPermission();
  if (permission == fr.ActivityPermission.PERMANENTLY_DENIED) {
    // Permission has been permanently denied.
    return false;
  } else if (permission == fr.ActivityPermission.DENIED) {
    permission =
        await fr.FlutterActivityRecognition.instance.requestPermission();
    if (permission != fr.ActivityPermission.GRANTED) {
      // Permission is denied.
      return false;
    }
  }
  return true;
}

import 'package:flutter_activity_recognition/flutter_activity_recognition.dart'
    as fr;

// Checks and requests activity recognition permission
Future<bool> checkAndRequestActivityPermission() async {
  // Check current activity permission status
  fr.ActivityPermission permission =
      await fr.FlutterActivityRecognition.instance.checkPermission();

  if (permission == fr.ActivityPermission.PERMANENTLY_DENIED) {
    // Permission has been permanently denied.
    return false;
  } else if (permission == fr.ActivityPermission.DENIED) {
    // Request activity permission
    permission =
        await fr.FlutterActivityRecognition.instance.requestPermission();
    if (permission != fr.ActivityPermission.GRANTED) {
      // Permission is denied.
      return false;
    }
  }
  return true;
}

import 'permissions_service.dart';
import 'package:logger/logger.dart';

Future<void> requestLocationPermissions() async {
  final permissionsService = PermissionsService();
  final Logger logger = Logger();

  bool permissionGranted = await permissionsService.requestLocationPermission();
  if (!permissionGranted) {
    logger.i('Location permission not granted');
    return;
  }

  bool backgroundModeEnabled = await permissionsService.enableBackgroundMode();
  if (!backgroundModeEnabled) {
    logger.i('Failed to enable background mode');
  }
}

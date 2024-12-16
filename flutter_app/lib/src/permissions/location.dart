import 'permissions_service.dart';
import 'package:logger/logger.dart';

/// Requests location and background permissions.
Future<void> requestLocationPermissions() async {
  final permissionsService =
      PermissionsService(); // Initialize permissions service
  final Logger logger = Logger(); // Initialize logger

  // Request location permission
  bool permissionGranted = await permissionsService.requestLocationPermission();
  if (!permissionGranted) {
    logger.i('Location permission not granted');
    return;
  }

  // Enable background mode for location updates
  bool backgroundModeEnabled = await permissionsService.enableBackgroundMode();
  if (!backgroundModeEnabled) {
    logger.i('Failed to enable background mode');
  }
}

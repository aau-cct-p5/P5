import 'package:flutter_app/src/permissions/activity.dart';
import 'package:location/location.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart';

class PermissionsService {
  final Location _location = Location();
  final Logger _logger = Logger();

  Future<bool> requestLocationPermission() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        _logger.i('Location service not enabled');
        return false;
      }
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        _logger.i('Location permission not granted');
        return false;
      }
    }

    _logger.i('Location permission granted');
    return true;
  }

  Future<bool> enableBackgroundMode() async {
    try {
      bool enabled = await _location.enableBackgroundMode(enable: true);
      if (enabled) {
        _logger.i('Background mode enabled');
      } else {
        _logger.i('Failed to enable background mode');
      }
      return enabled;
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        _logger.i('Background location permission denied');
        
      }
      return false;
    }
  }

  Future<bool> checkAllPermissions() async {
    bool locationPermission = await requestLocationPermission();
    bool activityPermission = await checkAndRequestActivityPermission();
    return locationPermission && activityPermission;
  }
}

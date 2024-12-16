import 'package:flutter/material.dart';
import 'permissions_service.dart';
import 'activity.dart';
import 'package:logger/logger.dart';
import '../home_page.dart';

// Modal widget to handle permission requests
class PermissionsModal extends StatefulWidget {
  const PermissionsModal({super.key});

  @override
  _PermissionsModalState createState() => _PermissionsModalState();
}

class _PermissionsModalState extends State<PermissionsModal> {
  final PermissionsService _permissionsService = PermissionsService();
  final Logger _logger = Logger();
  bool _locationPermissionGranted = false;
  bool _activityPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions(); // Initialize permission checks
  }

  // Checks and requests location and activity permissions
  Future<void> _checkPermissions() async {
    _locationPermissionGranted =
        await _permissionsService.requestLocationPermission();
    _activityPermissionGranted = await checkAndRequestActivityPermission();
    setState(() {}); // Refresh UI with updated permissions

    if (_locationPermissionGranted && _activityPermissionGranted) {
      await Future.delayed(
          const Duration(seconds: 2)); // Wait before navigation
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (context) => const MyHomePage(title: 'Bike Hero')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions Required'), // Modal header
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPermissionItem(
              'Location Permission',
              _locationPermissionGranted,
            ),
            _buildPermissionItem(
              'Activity Recognition Permission',
              _activityPermissionGranted,
            ),
            const SizedBox(height: 20),
            if (!_locationPermissionGranted || !_activityPermissionGranted)
              const Text(
                'Please grant all permissions to proceed.',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  // Builds a widget to display the status of a permission
  Widget _buildPermissionItem(String permissionName, bool granted) {
    return Row(
      children: [
        Icon(
          granted ? Icons.check_box : Icons.error,
          color: granted ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 10),
        Text(permissionName),
      ],
    );
  }
}

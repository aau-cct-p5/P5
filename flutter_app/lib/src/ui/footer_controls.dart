
import 'package:flutter/material.dart';
import 'package:flutter_app/src/app.dart';
import '../data_collection/data_collection_manager.dart';
import '../snackbar_helper.dart'; // If needed for SnackbarManager

class FooterControls extends StatelessWidget {
  final DataCollectionManager dataCollectionManager;
  final VoidCallback toggleDataCollection;
  final VoidCallback toggleManualDataCollection;
  final VoidCallback toggleAutoDataCollection;
  final Future<String> Function() sendDataToServer;

  const FooterControls({
    Key? key,
    required this.dataCollectionManager,
    required this.toggleDataCollection,
    required this.toggleManualDataCollection,
    required this.toggleAutoDataCollection,
    required this.sendDataToServer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              SnackbarManager().showSnackBar('Sending data to server...');
              try {
                await sendDataToServer();
                SnackbarManager().showSnackBar('Data sent successfully.');
              } catch (e) {
                SnackbarManager().showSnackBar('Failed to send data: $e');
              }
            },
            child: const Text('Send Data to Server'),
          ),
          ElevatedButton(
            onPressed: toggleDataCollection,
            child: Text(
              dataCollectionManager.isCollectingData
                  ? 'Stop Data Collection'
                  : 'Start Data Collection',
            ),
          ),
          ElevatedButton(
            onPressed: toggleManualDataCollection,
            child: Text(
              isManualDataCollection
                  ? 'Stop Manual Data Collection'
                  : 'Start Manual Data Collection',
            ),
          ),
          ElevatedButton(
            onPressed: toggleAutoDataCollection,
            child: Text(
              isAutoDataCollection
                  ? 'Stop Auto Data Collection'
                  : 'Start Auto Data Collection',
            ),
          ),
          Icon(
            Icons.directions_bike,
            color: isCollectingData ? Colors.green : Colors.grey,
            size: 48.0,
          ),
        ],
      ),
    );
  }
}
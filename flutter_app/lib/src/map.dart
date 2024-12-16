import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

// MapWidget displays a map centered at the user's current location
class MapWidget extends StatelessWidget {
  // Map controller for managing map interactions
  final MapController mapController;
  // User's current geographical position
  final Position currentPosition;
  // Current zoom level of the map view
  final double currentZoom;

  const MapWidget({
    super.key,
    required this.mapController,
    required this.currentPosition,
    required this.currentZoom,
  });

  @override
  Widget build(BuildContext context) {
    // Build the map widget
    return SizedBox(
      height: 200,
      width: 200,
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          // Set the initial center and zoom level of the map
          initialCenter: LatLng(
            currentPosition.latitude,
            currentPosition.longitude,
          ),
          initialZoom: 15,
        ),
        children: [
          // Add OpenStreetMap tile layer
          TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
          // Add a marker to show the user's location
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(
                  currentPosition.latitude,
                  currentPosition.longitude,
                ),
                child: const SizedBox(
                  width: 40.0,
                  height: 40.0,
                  child: Icon(
                    Icons.location_on,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

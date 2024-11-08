import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

const String ApiKey = "71216300-309d-4f72-86ef-4a9fffd93491";

class MapWidget extends StatelessWidget {
  final MapController mapController;
  final Position currentPosition;
  final double currentZoom;

  const MapWidget({
    Key? key,
    required this.mapController,
    required this.currentPosition,
    required this.currentZoom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: 200,
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: LatLng(
            currentPosition.latitude,
            currentPosition.longitude,
          ),
          initialZoom: 15,
        ),
        children: [
          TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
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

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RiskMap extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String riskLevel;

  const RiskMap({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.riskLevel,
  });

  Color getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case "high":
        return Colors.redAccent;
      case "medium":
        return Colors.orangeAccent;
      case "low":
        return Colors.greenAccent;
      default:
        return Colors.blueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng position = LatLng(latitude, longitude);

    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: position,
            initialZoom: 16,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: 'com.civicsense.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  width: 80,
                  height: 80,
                  point: position,
                  child: Icon(
                    Icons.location_on,
                    size: 50,
                    color: getRiskColor(riskLevel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart'; // 1. Added missing import
import 'package:gpx/gpx.dart';

class MapView extends StatelessWidget {
  final gpxData;

  const MapView({super.key, this.gpxData});

  List<LatLng> _extractPointsFromGpx() {
    if (gpxData == null) return [];

    List<LatLng> points = [];

    // Extract track points
    for (var trk in gpxData!.trks) {
      for (var seg in trk.trksegs) {
        for (var pt in seg.trkpts) {
          if (pt.lat != null && pt.lon != null) {
            points.add(LatLng(pt.lat!, pt.lon!));
          }
        }
      }
    }

    // Extract route points
    for (var rte in gpxData!.rtes) {
      for (var pt in rte.rtepts) {
        if (pt.lat != null && pt.lon != null) {
          points.add(LatLng(pt.lat!, pt.lon!));
        }
      }
    }

    // Extract waypoints
    for (var wpt in gpxData!.wpts) {
      if (wpt.lat != null && wpt.lon != null) {
        points.add(LatLng(wpt.lat!, wpt.lon!));
      }
    }

    return points;
  }

  LatLng _calculateCenter() {
    List<LatLng> points = _extractPointsFromGpx();
    if (points.isEmpty) return const LatLng(51.509364, -0.128928);

    double avgLat =
        points.fold(0.0, (sum, pt) => sum + pt.latitude) / points.length;
    double avgLon =
        points.fold(0.0, (sum, pt) => sum + pt.longitude) / points.length;
    return LatLng(avgLat, avgLon);
  }

  @override
  Widget build(BuildContext context) {
    List<LatLng> routePoints = _extractPointsFromGpx();
    LatLng center = _calculateCenter();
    double zoom = routePoints.isNotEmpty ? 10.0 : 2.2;

    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: zoom),
      children: [
        TileLayer(
          urlTemplate:
              'https://a.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}@2x.png',

          userAgentPackageName: 'com.yourteam.weatherapp',
        ),
        if (routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                strokeWidth: 4.0,
                color: Colors.blue,
              ),
            ],
          ),
        // Boilerplate below - ignore
        RichAttributionWidget(
          alignment: AttributionAlignment.bottomRight,
          attributions: [
            TextSourceAttribution(
              '© CARTO, © OpenStreetMap contributors',
              onTap: () async {
                final Uri url = Uri.parse(
                  'https://carto.com/help/working-with-data/attribution-requirements/',
                );
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/WeatherData.dart';

class MapView extends StatefulWidget {
  final gpxData;

  const MapView({super.key, this.gpxData});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  List<Map<String, dynamic>> pointData = [];
  bool isLoadingPoints = false;
  Map<String, dynamic>? selectedPoint;

  @override
  void initState() {
    super.initState();
    _loadPointData();
  }

  Future<void> _loadPointData() async {
    if (widget.gpxData == null) return;

    setState(() {
      isLoadingPoints = true;
    });

    try {
      List<(double, double)> routeCoords = _extractCoordinatesFromGpx();
      if (routeCoords.isNotEmpty) {
        final data = await WeatherData.getPointData(routeCoords);
        setState(() {
          pointData = data;
        });
      }
    } catch (e) {
      print('Error loading point data: $e');
    } finally {
      setState(() {
        isLoadingPoints = false;
      });
    }
  }

  List<(double, double)> _extractCoordinatesFromGpx() {
    if (widget.gpxData == null) return [];

    List<(double, double)> coords = [];

    // Extract track points
    for (var trk in widget.gpxData!.trks) {
      for (var seg in trk.trksegs) {
        for (var pt in seg.trkpts) {
          if (pt.lat != null && pt.lon != null) {
            coords.add((pt.lat! as double, pt.lon! as double));
          }
        }
      }
    }

    // Extract route points
    for (var rte in widget.gpxData!.rtes) {
      for (var pt in rte.rtepts) {
        if (pt.lat != null && pt.lon != null) {
          coords.add((pt.lat! as double, pt.lon! as double));
        }
      }
    }

    // Extract waypoints
    for (var wpt in widget.gpxData!.wpts) {
      if (wpt.lat != null && wpt.lon != null) {
        coords.add((wpt.lat! as double, wpt.lon! as double));
      }
    }

    return coords;
  }

  List<LatLng> _extractPointsFromGpx() {
    if (widget.gpxData == null) return [];

    List<LatLng> points = [];

    // Extract track points
    for (var trk in widget.gpxData!.trks) {
      for (var seg in trk.trksegs) {
        for (var pt in seg.trkpts) {
          if (pt.lat != null && pt.lon != null) {
            points.add(LatLng(pt.lat!, pt.lon!));
          }
        }
      }
    }

    // Extract route points
    for (var rte in widget.gpxData!.rtes) {
      for (var pt in rte.rtepts) {
        if (pt.lat != null && pt.lon != null) {
          points.add(LatLng(pt.lat!, pt.lon!));
        }
      }
    }

    // Extract waypoints
    for (var wpt in widget.gpxData!.wpts) {
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

  List<Marker> _buildMarkers() {
    return pointData.map((point) {
      return Marker(
        point: LatLng(
          point['latitude'] as double,
          point['longitude'] as double,
        ),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () {
            setState(() {
              selectedPoint = point;
            });
            _showPointDetails(point);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${(point['windSpeed'] as double).toStringAsFixed(1)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  void _showPointDetails(Map<String, dynamic> point) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Route Point Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                'Wind Speed',
                '${(point['windSpeed'] as double).toStringAsFixed(1)} m/s',
              ),
              _buildDetailRow(
                'Wind Direction',
                '${(point['windDirection'] as double).toStringAsFixed(1)}°',
              ),
              _buildDetailRow(
                'Temperature',
                '${(point['temperature'] as double).toStringAsFixed(1)}°C',
              ),
              _buildDetailRow(
                'Latitude',
                (point['latitude'] as double).toStringAsFixed(4),
              ),
              _buildDetailRow(
                'Longitude',
                (point['longitude'] as double).toStringAsFixed(4),
              ),
              _buildDetailRow('Time', point['time'].toString()),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<LatLng> routePoints = _extractPointsFromGpx();
    LatLng center = _calculateCenter();
    double zoom = routePoints.isNotEmpty ? 10.0 : 2.2;

    return Stack(
      children: [
        FlutterMap(
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
            if (pointData.isNotEmpty) MarkerLayer(markers: _buildMarkers()),
            // Boilerplate below - ignore
            RichAttributionWidget(
              alignment: AttributionAlignment.bottomRight,
              attributions: [
                TextSourceAttribution(
                  '© CARTO',
                  onTap: () async {
                    final Uri url = Uri.parse(
                      'https://carto.com/help/working-with-data/attribution-requirements/',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
                TextSourceAttribution(
                  '© OpenStreetMap contributors',
                  onTap: () async {
                    final Uri url = Uri.parse(
                      'https://openstreetmap.org/copyright',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        if (isLoadingPoints)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      ],
    );
  }
}

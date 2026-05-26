import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:weather_app_sailing/utils/UnitConversionUtils.dart';
import '../utils/WeatherData.dart';
import '../globals.dart';

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

  DateTime _roundToNearestHour(DateTime dateTime) {
    if (dateTime.minute < 30) {
      return DateTime(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        dateTime.hour,
      );
    } else {
      return DateTime(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        dateTime.hour + 1,
      );
    }
  }

  Future<void> _loadPointData({DateTime? time}) async {
    if (widget.gpxData == null) return;

    setState(() {
      isLoadingPoints = true;
    });

    try {
      List<(double, double)> routeCoords = _extractCoordinatesFromGpx();
      if (routeCoords.isNotEmpty) {
        final roundedTime = _roundToNearestHour(
          time ?? DateTime.now(),
        ); //gotta round idk
        final data = await WeatherData.getRouteData(routeCoords, roundedTime);
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

  Future<void> _updatePointTime(
    Map<String, dynamic> point,
    DateTime newTime,
  ) async {
    setState(() {
      isLoadingPoints = true;
    });

    try {
      final lat = point['latitude'] as double;
      final lon = point['longitude'] as double;
      final roundedTime = _roundToNearestHour(newTime);

      final data = await WeatherData.getRouteData([(lat, lon)], roundedTime);

      if (data.isNotEmpty) {
        final newPointData = data[0];

        // Find and the point
        final index = pointData.indexWhere(
          (p) => p['latitude'] == lat && p['longitude'] == lon,
        );

        if (index != -1) {
          setState(() {
            pointData[index] = newPointData;
          });
        }
      }
    } catch (e) {
      print('Error updating point time: $e');
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
    return _extractCoordinatesFromGpx()
        .map((coord) => LatLng(coord.$1, coord.$2))
        .toList();
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
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                (selectedPoint == point) ? '' : '', //fuck knows
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

  //dont touch. ts took me ages. i will find you.
  void _showPointDetails(Map<String, dynamic> point) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Route Point Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Wind Speed', _formatSpeed(point['windSpeed'])),
                _buildDetailRow('Gust Speed', _formatSpeed(point['gustSpeed'])),
                _buildDetailRow(
                  'Wind Direction',
                  '${(point['windDirection'] as double).toStringAsFixed(1)}°',
                ),
                _buildDetailRow(
                  'Temperature',
                  _formatTemperature(point['temperature'] as double),
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
                  child: ElevatedButton.icon(
                    onPressed: () => _selectNewTime(context, point),
                    icon: const Icon(Icons.access_time),
                    label: const Text('Change Time'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectNewTime(
    BuildContext context,
    Map<String, dynamic> point,
  ) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    ); // looks buns but its built and i cba

    if (pickedDate != null && context.mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final DateTime selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        await _updatePointTime(point, selectedDateTime);
        if (context.mounted) {
          Navigator.pop(context);
        }
      }
    }
  }

  // request already handles units, don't need to manually convert after - ben.
  // fuck u ben no it didn't. why did u keep the if statement dumb ass
  String _formatTemperature(double temp) {
    if (isCelsius) {
      return '${temp.toStringAsFixed(1)}°C';
    } else {
      return '${temp.toStringAsFixed(1)}°F';
    }
  }

  String _formatSpeed(double temp) {
    if (isKnots) {
      return '${temp.toStringAsFixed(1)} knots';
    } else {
      return '${temp.toStringAsFixed(1)} m/s';
    }
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
                    color: Colors.black.withValues(alpha: 0.1),
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

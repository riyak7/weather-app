import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:weather_app_sailing/utils/HeatMapUtils.dart';
import 'dart:async';

import 'package:weather_app_sailing/utils/WeatherData.dart';
import 'package:weather_app_sailing/globals.dart';

// We use a stateful widget so that we get access to the destructor
// so we can free memory to avoid leaks when widget destroyed.
class HeatMapView extends StatefulWidget {
  const HeatMapView({super.key});

  @override
  State<HeatMapView> createState() => _HeatMapViewState();
}

class _HeatMapViewState extends State<HeatMapView> {
  // _heatmapTiles stores each tile in the heatmap as a Polygon.
  // The heatmap tiles constantly change so make a ValueNotifer so we can handle
  // them in a special way so only this layer gets rebuilt and not the whole map.
  //
  // When we change the value of _heatmapTiles it automatically alerts the changes
  // everywhere that uses it.
  // The same is true for _arrows which store the wind direction markers
  final ValueNotifier<List<Polygon>> _heatmapTiles =
      ValueNotifier<List<Polygon>>([]);
  final ValueNotifier<List<Marker>> _arrows = ValueNotifier<List<Marker>>([]);

  // This timer is used for debouncing, when the user scrolls on the
  // map it triggers many events throughout the scroll hence we need to
  // debounce to only trigger it once, when the events end to avoid flooding
  // api requests.
  Timer? _timer;
  final Duration _debounceDuration = Duration(milliseconds: 500);

  // The size of the grid we render 15*15 = 225 tiles and arrows rendered
  static final _gridSize = 10;

  // Our grid is blocky, we need to blur to make it look nice
  static final _blur = 24.0;

  // Global rawData var so we don't have to keep calling the api when
  // we are just changing the time
  // `late` to signify we will initialise this later
  late Map<DateTime, Set<(num, num, num, num)>> rawData;

  // The current viewing area in LatLngs
  late LatLngBounds bounds;

  // Add a listener to the time bar current time variable.
  // When time is changed the arrow layer and heatmap layer get redrawn.
  @override
  void initState() {
    reactiveSelectedTime.addListener(() {
      double gridWidth = (bounds.east - bounds.west) / _gridSize;
      double gridHeight = (bounds.north - bounds.south) / _gridSize;

      _heatmapTiles.value = rawToPolygon(
        rawData[reactiveSelectedTime.value]!,
        gridWidth,
        gridHeight,
      );

      _arrows.value = rawToMarker(
        rawData[reactiveSelectedTime.value]!,
        gridWidth,
        gridHeight,
      );
    });
  }

  // Clean up on deletion
  @override
  dispose() {
    _heatmapTiles.dispose();
    _arrows.dispose();
    _timer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(51.509364, -0.128928),
              initialZoom: 5.2,
              onMapEvent: (event) {
                if (event is MapEventMoveEnd ||
                    event is MapEventDoubleTapZoomEnd ||
                    event is MapEventFlingAnimationEnd ||
                    event is MapEventScrollWheelZoom ||
                    event is MapEventNonRotatedSizeChange) {
                  _timer?.cancel();
                  _timer = Timer(_debounceDuration, () async {
                    bounds = event.camera.visibleBounds;
                    rawData = await WeatherData.getWindData(
                      WeatherData.locationsFromGrid(
                        bounds.north,
                        bounds.west,
                        bounds.south,
                        bounds.east,
                        _gridSize,
                        _gridSize,
                      ),
                    );
                    if (!mounted) return;
                    if (rawData.values.isNotEmpty) {
                      double gridWidth =
                          (bounds.east - bounds.west) / _gridSize;
                      double gridHeight =
                          (bounds.north - bounds.south) / _gridSize;
                      print(selectedTime);
                      print(rawData);
                      _heatmapTiles.value = rawToPolygon(
                        rawData[selectedTime]!,
                        gridWidth,
                        gridHeight,
                      );
                      _arrows.value = rawToMarker(
                        rawData.values.first,
                        gridWidth,
                        gridHeight,
                      );
                    }
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://a.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}@2x.png',
                userAgentPackageName: 'weather_app_sailing',
              ),
              ValueListenableBuilder<List<Polygon>>(
                valueListenable: _heatmapTiles,
                builder: (context, polygons, child) {
                  return ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: _blur, sigmaY: _blur),
                    child: PolygonLayer(polygons: polygons),
                  );
                },
              ),
              ValueListenableBuilder<List<Marker>>(
                valueListenable: _arrows,
                builder: (context, markers, child) {
                  return MarkerLayer(markers: markers);
                },
              ),
              RichAttributionWidget(
                alignment: AttributionAlignment.bottomRight,
                attributions: [
                  TextSourceAttribution(
                    '© CARTO',
                    onTap: () async {
                      final Uri url = Uri.parse(
                        'https://carto.com/help/working-with-data/attribution-requirements/',
                      );
                      if (await canLaunchUrl(url))
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                    },
                  ),
                  TextSourceAttribution(
                    '© OpenStreetMap contributors',
                    onTap: () async {
                      final Uri url = Uri.parse(
                        'https://openstreetmap.org/copyright',
                      );
                      if (await canLaunchUrl(url))
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // Time bar at the bottom
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color.fromARGB(255, 205, 216, 228),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (i) {
                  final day = DateTime.now().add(Duration(days: i));
                  final label = [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun',
                  ][day.weekday - 1];
                  final isSelected = selectedTime.day == day.day;
                  return GestureDetector(
                    onTap: () => setState(() {
                      selectedTime = DateTime(
                        day.year,
                        day.month,
                        day.day,
                        selectedTime.hour,
                      );
                      reactiveSelectedTime.value = DateTime(
                        day.year,
                        day.month,
                        day.day,
                        selectedTime.hour,
                      );
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color.fromARGB(255, 100, 149, 190)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black54,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Hour',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  Text(
                    '${selectedTime.hour.toString().padLeft(2, '0')}:00',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Slider(
                min: 0,
                max: 23,
                divisions: 23,
                value: selectedTime.hour.toDouble(),
                onChanged: (val) => setState(() {
                  selectedTime = DateTime(
                    selectedTime.year,
                    selectedTime.month,
                    selectedTime.day,
                    val.toInt(),
                  );
                  reactiveSelectedTime.value = DateTime(
                    selectedTime.year,
                    selectedTime.month,
                    selectedTime.day,
                    val.toInt(),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

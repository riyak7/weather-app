import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:weather_app_sailing/utils/HeatMapUtils.dart';
import 'dart:async';

import 'package:weather_app_sailing/utils/WeatherData.dart';

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
  final ValueNotifier<List<Polygon>> _heatmapTiles = ValueNotifier<List<Polygon>>([]);
  final ValueNotifier<List<Marker>> _arrows = ValueNotifier<List<Marker>>([]);

  // This timer is used for debouncing, when the user scrolls on the
  // map it triggers many events throughout the scroll hence we need to
  // debounce to only trigger it once, when the events end to avoid flooding
  // api requests.
  Timer? _timer;
  final Duration _debounceDuration = Duration(milliseconds: 500);

  // The size of the grid we render 15*15 = 225 tiles and arrows rendered
  static final _gridSize = 15;

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
    return FlutterMap(
      options: MapOptions(
        // Initial configs
        initialCenter: const LatLng(51.509364, -0.128928), // London, UK
        initialZoom: 5.2,

        // Update heatmap and data when the map view changes,
        // needs to be debounced to prevent spamming api calls
        onMapEvent: (event) {
          if (event is MapEventMoveEnd ||
              event is MapEventDoubleTapZoomEnd ||
              event is MapEventFlingAnimationEnd ||
              event is MapEventScrollWheelZoom) {
            // Debounce logic, if we already have a timer -> cancel it
            // Now create a new one that runs remake heatmap after _debounceDuration milliseconds
            _timer?.cancel();
            _timer = Timer(_debounceDuration, () async {
              var bounds = event.camera.visibleBounds;

              // Get raw data
              var rawData = await WeatherData.getWindData(
                WeatherData.locationsFromGrid(bounds.north, bounds.west, bounds.south, bounds.east, _gridSize, _gridSize),
              );

              // TODO, currently we just look at the first time but we should look at the current time
              if (rawData.values.isNotEmpty) {
                print(rawData.values.first.length);
                // Using the data fetched from the api create the heatmap and the arrows
                // 1.07 scaling needed because without it tiles too small, idk why
                double gridWidth = 1.07 * (bounds.east - bounds.west)/_gridSize;
                double gridHeight = 1.07 * (bounds.north - bounds.south)/_gridSize;

                // Converts the raw data to polygon data that can be drawn to a map
                _heatmapTiles.value = rawToPolygon(
                  rawData.values.first,
                  gridWidth,
                  gridHeight,
                );

                // Converts the raw data to marker data for map
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
        // TileLayer is where we get the actual map from,
        // cartocdn is minimal and doesn't need an api key
        TileLayer(
          urlTemplate:
              'https://a.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}@2x.png',
          userAgentPackageName: 'weather_app_sailing',
        ),
        // This is the heatmap layer. It is essentially a grid of
        // squares (Polygons) drawn over the map.
        ValueListenableBuilder<List<Polygon>>(
          valueListenable: _heatmapTiles,
          builder: (context, polygons, child) {
            return PolygonLayer(polygons: polygons);
          },
        ),
        // And this is the arrow layer
        ValueListenableBuilder<List<Marker>>(
          valueListenable: _arrows,
          builder: (context, markers, child) {
            return MarkerLayer(markers: markers);
          },
        ),
        
        // Boilerplate below from flutter_maps docs - ignore RichAttributionWidget
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
                  await launchUrl(url, mode: LaunchMode.externalApplication);
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
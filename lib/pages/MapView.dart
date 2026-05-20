// TODO add update on move, add arrows and sourcing actual data
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:weather_app_sailing/utils/HeatMapUtils.dart';
import 'dart:async';

import 'package:weather_app_sailing/utils/WeatherData.dart';

// We use a stateful widget so that we get access to the destructor
// so we can free memory to avoid leaks when widget destroyed.
class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  // _heatmapTiles stores each tile in the heatmap as a Polygon.
  // The heatmap tiles constantly change so make a ValueNotifer so we can handle
  // them in a special way so only this layer gets rebuilt and not the whole map.
  //
  // When we change the value of _heatmapTiles it automatically alerts the changes
  // everywhere that uses it.
  final ValueNotifier<List<Polygon>> _heatmapTiles =
      ValueNotifier<List<Polygon>>(
        rawToPolygon(
          // Test Data - Initialise to [] normally
          {
            (50.0, -3.0, 12.4, 210),
            (50.0, -2.5, 14.1, 215),
            (50.0, -2.0, 15.8, 220),
            (50.0, -1.5, 11.2, 195),
            (50.0, -1.0, 9.5, 180),

            (50.5, -3.0, 13.1, 205),
            (50.5, -2.5, 16.2, 225),
            (50.5, -2.0, 17.5, 230), // Strongest patch
            (50.5, -1.5, 13.4, 210),
            (50.5, -1.0, 10.1, 190),

            (51.0, -3.0, 10.2, 190),
            (51.0, -2.5, 12.8, 210),
            (51.0, -2.0, 14.2, 220),
            (51.0, -1.5, 11.0, 200),
            (51.0, -1.0, 8.4, 175),

            (51.5, -3.0, 8.1, 180),
            (51.5, -2.5, 9.4, 195),
            (51.5, -2.0, 10.5, 205),
            (51.5, -1.5, 8.9, 185),
            (51.5, -1.0, 6.2, 160),
          },
          0.5,
          0.5,
        ),
      );

  // This timer is used for debouncing, when the user scrolls on the
  // map it triggers many events throughout the scroll hence we need to
  // debounce to only trigger it once, when the events end to avoid flooding
  // api requests.
  Timer? _timer;
  final Duration _debounceDuration = Duration(milliseconds: 500);

  @override
  dispose() {
    _heatmapTiles.dispose();
    _timer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("Start Build");
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

              var rawData = await WeatherData.getWindData(
                WeatherData.locationsFromGrid(55.0, -5, 45.0, 5, 11, 11),
              );

              print(rawData.values.first.length); 
              if (rawData.values.isNotEmpty) {
                _heatmapTiles.value = rawToPolygon(
                  rawData.values.first,
                  1,
                  1,
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

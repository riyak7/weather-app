import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:weather_app_sailing/utils/WeatherData.dart';
import 'dart:async';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  double topLeftLat = 53.0;
  double topLeftLong = -3.0;
  double botRightLat = 51.0;
  double botRightLong = -1.0;
  Timer? _debounce;

  @override
  Widget build(BuildContext context) {
    // Lat, Long, WS, WD
    // Get these globally somehow

    Future<Map<DateTime, Set<(num, num, num, num)>>> current_tiles =
        /*WeatherData.getWindData(
          WeatherData.locationsFromGrid(
            topLeftLat,
            topLeftLong,
            botRightLat,
            botRightLong,
            10,
            10,
          ),
        );*/
        // AI generated debug points
        Future.value({
          DateTime.now(): {
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
        });

    return FlutterMap(
      options: MapOptions(
        initialCenter: const LatLng(51.509364, -0.128928), // London, UK
        initialZoom: 5.2,
        onMapEvent: (event) {
          print("hi");
          if (event is MapEventMoveEnd) {
            setState(() {
              var bounds = event.camera.visibleBounds;
              topLeftLat = bounds.northWest.latitude;
              topLeftLong = bounds.northWest.longitude;
              botRightLat = bounds.southEast.latitude;
              botRightLong = bounds.southEast.longitude;
              print(bounds);
            });
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://a.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}@2x.png',

          userAgentPackageName: 'com.yourteam.weatherapp',
        ),
        FutureBuilder<Map<DateTime, Set<(num, num, num, num)>>>(
          future: current_tiles,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            if (snapshot.hasError) return const SizedBox.shrink();
            // Check above two lines

            const tile_size = 0.1;
            var current_time = DateTime.now();
            //Set<(num, num, num, num)> tiles = snapshot.data![current_time]!;
            Set<(num, num, num, num)> tiles = snapshot.data!.values.first;
            var min = tiles.reduce(
              (curr, next) => curr.$3 < next.$3 ? curr : next,
            );
            var max = tiles.reduce(
              (curr, next) => curr.$3 > next.$3 ? curr : next,
            );

            return PolygonLayer(
              polygons: [
                for (var tile in tiles)
                  Polygon(
                    points: [
                      LatLng(tile.$1.toDouble(), tile.$2.toDouble()),
                      LatLng(
                        tile.$1.toDouble() + tile_size,
                        tile.$2.toDouble(),
                      ),
                      LatLng(tile.$1 + tile_size, tile.$2 + tile_size),
                      LatLng(tile.$1.toDouble(), tile.$2 + tile_size),
                    ],
                    color: Color.fromRGBO(
                      0,
                      0,
                      255,
                      (0.5 * tile.$3 / (max.$3 - min.$3)).clamp(0.0, 1.0),
                    ),
                  ),
              ],
            );
          },
        ),
        // Boilerplate below - ignore RichAttributionWidget
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

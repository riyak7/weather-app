import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart'; // 1. Added missing import

class MapView extends StatelessWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(51.509364, -0.128928), // London, UK
        initialZoom: 2.2,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://a.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}@2x.png',

          userAgentPackageName: 'com.yourteam.weatherapp',
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

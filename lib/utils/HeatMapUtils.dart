// Converts raw data in the form of a list of tuples (lat, long, wind speed, wind dir)
// into actual polygon data that can be drawn

import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

List<Polygon> rawToPolygon(
  Set<(num, num, num, num)> rawData,
  double width,
  double height,
) {
  final min = rawData.reduce((cur, next) => cur.$3 < next.$3 ? cur : next).$3;
  final max = rawData.reduce((cur, next) => cur.$3 > next.$3 ? cur : next).$3;

  return rawData
      .map(
        (rawTile) => Polygon(
          points: [
            LatLng(rawTile.$1.toDouble(), rawTile.$2.toDouble()),
            LatLng(rawTile.$1.toDouble(), rawTile.$2.toDouble() + width),
            LatLng(
              rawTile.$1.toDouble() + height,
              rawTile.$2.toDouble() + width,
            ),
            LatLng(rawTile.$1.toDouble() + height, rawTile.$2.toDouble()),
          ],
          color: Color.fromRGBO(
            0,
            0,
            255,
            calculateOpacity(min, max, rawTile.$3),
          ),
        ),
      )
      .toList();
}

// Interpolates opacity, higher windspeed means darker blue / less opaque
double calculateOpacity(num min, num max, num cur) {
  return 0.5 * (cur - min) / (max - min);
}

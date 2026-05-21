// Converts raw data in the form of a list of tuples (lat, long, wind speed, wind dir)
// into actual polygon data that can be drawn
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' as icons;

final _opacity = 0.50;

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
            LatLng(rawTile.$1.toDouble() - height/2, rawTile.$2.toDouble() - width/2),
            LatLng(rawTile.$1.toDouble()-height/2, rawTile.$2.toDouble() + width/2),
            LatLng(
              rawTile.$1.toDouble() + height/2,
              rawTile.$2.toDouble() + width/2,
            ),
            LatLng(rawTile.$1.toDouble() + height/2, rawTile.$2.toDouble()-width/2),
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

List<Marker> rawToMarker(
  Set<(num, num, num, num)> rawData,
  double width,
  double height
){
  return rawData.map((data) =>
    Marker(
      point: LatLng(data.$1 as double, data.$2 as double),
      width: 20,
      height: 20,
      child: Transform.rotate(angle: data.$4 * pi / 180, child: icons.ArrowUp(color: const Color.fromARGB(64, 100, 100, 100))),
    )
  ).toList();
}

// Interpolates opacity, higher windspeed means darker blue / less opaque
double calculateOpacity(num min, num max, num cur) {
  return _opacity * (cur - min) / (max - min);
}
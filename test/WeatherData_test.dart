import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app_sailing/main.dart';
import 'package:weather_app_sailing/utils/WeatherData.dart';

void main() {
  test('Testing WeatherData._getMapLocations', () {
    var out = WeatherData.getMapLocations(0,0,100,100, 9, 9);
    print(out.map((x) => (x.latitude)));
    print(out.map((x) => (x.longitude)));

  });
}

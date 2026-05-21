import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app_sailing/utils/WeatherData.dart';

void main() {
  test('Testing WeatherData._getMapLocations', () {
    var out = WeatherData.locationsFromGrid(0,0,100,100, 9, 9);
    print(out.map((x) => (x.latitude)));
    print(out.map((x) => (x.longitude)));

  });

  test('checking format of api response', () async {
    var locations = WeatherData.locationsFromGrid(0, 0, 100,100, 1, 1);
    print(locations.map((x) => (x.longitude, x.latitude)));
    var out = await WeatherData.getWindData(locations);
    print(out);

  });
}

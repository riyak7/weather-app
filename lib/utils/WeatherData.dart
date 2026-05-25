import 'package:open_meteo/open_meteo.dart';
import 'package:weather_app_sailing/globals.dart';

class WeatherData {
  static var _weather = WeatherApi(
    windspeedUnit: WindspeedUnit.ms,
    temperatureUnit: TemperatureUnit.celsius,
  );
  static bool _isCelsiusCurrently = true;
  static bool _isKnotsCurrently = false;

  static void checkUnits() {
    // only replace WeatherApi object if units have changed
    if (_isCelsiusCurrently != isCelsius || _isKnotsCurrently != isKnots) {
      _isCelsiusCurrently = isCelsius;
      _isKnotsCurrently = isKnots;
      _weather = WeatherApi(
        temperatureUnit: isCelsius
            ? TemperatureUnit.celsius
            : TemperatureUnit.fahrenheit,
        windspeedUnit: isKnots ? WindspeedUnit.kn : WindspeedUnit.ms,
      );
    }
    return;
  }

  static List<OpenMeteoLocation> locationsFromGrid(
    num latitudeTopLeft,
    num longitudeTopLeft,
    num latitudeBottomRight,
    num longitudeBottomRight,
    int samplesLatitude,
    int samplesLongitude,
  ) {
    // Given the latitude and longitude of 2 corners,
    // and a sample counts for each axis,
    // generate objects for each location to request wind data
    return [
      for (var i = 0; i < samplesLongitude * samplesLatitude; i++)
        OpenMeteoLocation(
          latitude:
              (latitudeTopLeft +
              (0.5 + (i % samplesLatitude)) *
                  (latitudeBottomRight - latitudeTopLeft) /
                  (samplesLatitude)),
          longitude:
              (longitudeTopLeft +
              (0.5 + (i ~/ samplesLatitude)) *
                  (longitudeBottomRight - longitudeTopLeft) /
                  (samplesLongitude)),
        ),
    ];
    // Note this returns coordinates at the centre of each box
  }

  static List<OpenMeteoLocation> locationsFromCoordList(
    List<(num, num)> coords,
  ) {
    // Convert between (latitude, longitude) form and OpenMeteoLocation for a list of points
    return [
      for (final l in coords)
        OpenMeteoLocation(
          latitude: l.$1.toDouble(),
          longitude: l.$2.toDouble(),
        ),
    ];
  }

  static Future<Map<DateTime, List<Map<String, dynamic>>>> getMultipleData(
    List<OpenMeteoLocation> locations,
  ) async {
    checkUnits();

    // Fetch weather data
    final response = await _weather.request(
      locations: Set.from(locations),
      hourly: {
        WeatherHourly.wind_speed_10m,
        WeatherHourly.wind_direction_10m,
        WeatherHourly.temperature_2m,
        WeatherHourly.visibility,
        WeatherHourly.wind_gusts_10m,
        WeatherHourly.pressure_msl,
      },
    );

    // Build point data with weather info
    Map<DateTime, List<Map<String, dynamic>>> pointData = {};
    for (int i = 0; i < response.segments.length; i++) {
      final item = response.segments[i];

      for (DateTime time
          in item.hourlyData[WeatherHourly.wind_speed_10m]?.values.keys ?? []) {
        if (!pointData.containsKey(time)) {
          pointData[time] = [];
        }

        pointData[time]!.add({
          'latitude': locations[i]
              .latitude, // use location from request not that returns since it returns nearest available locatoion with data, not to the exact location
          'longitude': locations[i].longitude,
          'windSpeed':
              item.hourlyData[WeatherHourly.wind_speed_10m]?.values[time] ??
              0.0,
          'gustSpeed':
              item.hourlyData[WeatherHourly.wind_gusts_10m]?.values[time] ??
              0.0,
          'windDirection':
              item.hourlyData[WeatherHourly.wind_direction_10m]?.values[time] ??
              0.0,
          'temperature':
              item.hourlyData[WeatherHourly.temperature_2m]?.values[time] ??
              0.0,
          'pressure':
              item.hourlyData[WeatherHourly.pressure_msl]?.values[time] ?? 0.0,
          'time': time,
          'index': 0,
        });
      }
    }

    return pointData;
  }

  static Future<Map<DateTime, Map<String, dynamic>>> getSingleData(
    double lat,
    double long,
  ) async {
    // just a wrapper around getMultipleData

    final locations = locationsFromCoordList([(lat, long)]);

    Map<DateTime, List<Map<String, dynamic>>> data = await getMultipleData(
      locations,
    );

    final Map<DateTime, Map<String, dynamic>> singleData = {};
    for (DateTime k in data.keys) {
      singleData[k] = data[k]![0];
    }

    return singleData;
  }

  static Future<List<Map<String, dynamic>>> getRouteData(
    List<(double, double)> routePoints,
    DateTime time,
  ) async {
    final int sampleInterval = (routePoints.length / 20)
        .ceil(); // Maximum 20 points
    final List<(double, double)> sampledPoints = [];
    final List<int> sampledIndices = []; // Track original indices

    for (int i = 0; i < routePoints.length; i += sampleInterval) {
      sampledPoints.add(routePoints[i]);
      sampledIndices.add(i);
    }

    List<OpenMeteoLocation> locations = locationsFromCoordList(sampledPoints);
    Map<DateTime, List<Map<String, dynamic>>> data = await getMultipleData(
      locations,
    );

    for (List<Map<String, dynamic>> l in data.values) {
      for (var i = 0; i < l.length; i++) {
        l[i]['index'] = sampledIndices[i];
      }
    }

    return data.containsKey(time) ? data[time]! : [];
  }

  static Future<Map<DateTime, Set<(num, num, num, num)>>> getWindData(
    List<OpenMeteoLocation> locations,
  ) async {
    // returns Map from time a DateTime object to a set of
    // (latitude, longitude, windspeed, wind direction) records
    Map<DateTime, List<Map<String, dynamic>>> data = await getMultipleData(
      locations,
    );

    Map<DateTime, Set<(num, num, num, num)>> dataOldFormat = {};
    for (DateTime time in data.keys) {
      dataOldFormat[time] = {};
      for (Map<String, dynamic> item in data[time] ?? []) {
        dataOldFormat[time]!.add((
          item['latitude'] as num,
          item['longitude'] as num,
          item['windSpeed'] as num,
          item['windDirection'] as num,
        ));
      }
    }
    return dataOldFormat;
  }
}

import 'package:open_meteo/open_meteo.dart';

class WeatherData {
  static var _weather = WeatherApi(temperatureUnit: TemperatureUnit.celsius);

  static Set<OpenMeteoLocation> locationsFromGrid(num latitudeTopLeft, 
                                                  num longitudeTopLeft, 
                                                  num latitudeBottomRight, 
                                                  num longitudeBottomRight, 
                                                  int samplesLatitude,
                                                  int samplesLongitude) {
    // Given the latitude and longitude of 2 corners, 
    // and a sample counts for each axis,
    // generate objects for each location to request wind data 
    return {
      for (var i=0; i < samplesLongitude * samplesLatitude; i++)
        OpenMeteoLocation(latitude:  double.parse((latitudeTopLeft + (1+(i % samplesLatitude)) * (latitudeBottomRight-latitudeTopLeft) / (samplesLatitude + 1)).toStringAsFixed(5)), 
                          longitude: double.parse((longitudeTopLeft + (1+(i ~/ samplesLatitude)) * (longitudeBottomRight-longitudeTopLeft) / (samplesLongitude + 1)).toStringAsFixed(5)) )
                          // Arnav - Fixed issue where didn't add original lat and long, hence coords were returned starting from (0,0)
    };
  }

static Set<OpenMeteoLocation> locationsFromCoordList(List<(num, num)> coords) {
    // Given the latitude and longitude of 2 corners, 
    // and a sample counts for each axis,
    // generate objects for each location to request wind data 
    return {
      for (final l in coords)
        OpenMeteoLocation(latitude: l.$1 as double, longitude: l.$2 as double )
    };
  }

  static Future<Map<DateTime, Set<(num, num, num, num)> >> getWindData(Set<OpenMeteoLocation> locations) async {
    // returns Map from time a DateTime object to a set of 
    // (latitude, longitude, windspeed, wind direction) records
    // Arnav - Changed above comment ^, it returns (latitude, longitude, ...)
    final response = await _weather.request(
      locations: locations, //convert to set of locations not list
      hourly: {WeatherHourly.wind_speed_10m, WeatherHourly.wind_direction_10m},
    );

    // TODO - check no error with request

    Map<DateTime, Set<(num, num, num, num)> > data = {};
    for (final item in response.segments) {
      // Arnav - Changed second check to wind direction (was wind_speed earlier which was same as first check)
      if ((item.hourlyData[WeatherHourly.wind_speed_10m]?.values.isEmpty ?? true ) || (item.hourlyData[WeatherHourly.wind_direction_10m]?.values.isEmpty ?? true )) {
        throw Exception("Data not found");
      }
      for (final time in (item.hourlyData[WeatherHourly.wind_speed_10m]!.values.keys)) {
        if (!data.containsKey(time)) {
          data[time] = {};
        }
        data[time]?.add((item.latitude, 
                        item.longitude, 
                        item.hourlyData[WeatherHourly.wind_speed_10m]!.values[time]!, 
                        item.hourlyData[WeatherHourly.wind_direction_10m]!.values[time]!
                        ));
      }
    }
    return data;
  }

  static void changeTemperatureUnit(String unit) {
    switch (unit) {
      // Arnav - Corrected typo for 'celcius'
      case "celsius":
        _weather = WeatherApi(temperatureUnit: TemperatureUnit.celsius);
        break;
      case "fahrenheit":
        _weather = WeatherApi(temperatureUnit: TemperatureUnit.fahrenheit);
        break;
      default: 
        throw Exception("Unit not supported");
    }
    return;
  }
}
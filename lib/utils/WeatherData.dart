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
        OpenMeteoLocation(latitude:  (latitudeTopLeft + (0.5+(i % samplesLatitude)) * (latitudeBottomRight-latitudeTopLeft) / (samplesLatitude)), 
                          longitude: (longitudeTopLeft + (0.5+(i ~/ samplesLatitude)) * (longitudeBottomRight-longitudeTopLeft) / (samplesLongitude)) )
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

    // final output returns data at locations slightly off the requested ones, 
    // so have to store locations requested and match these up later
    final coordsList = [for (final l in locations) (l.latitude, l.longitude)];
    coordsList.sort((a,b) => a.$1.compareTo(b.$1));

    final response = await _weather.request(
      locations: locations, 
      hourly: {WeatherHourly.wind_speed_10m, WeatherHourly.wind_direction_10m},
    );

    // TODO - check no error with request

    // aligning locations to the requested coordinates instead of those returned by API
    var responseSorted = response.segments;
    responseSorted.sort((a,b) => (a.latitude == b.latitude ? a.longitude.compareTo(b.longitude) : a.latitude.compareTo(b.latitude)) );

    Map<DateTime, Set<(num, num, num, num)> > data = {};
    for (var i=0; i<responseSorted.length; i++) {
      final item = responseSorted[i];
      // Arnav - Changed second check to wind direction (was wind_speed earlier which was same as first check)
      if ((item.hourlyData[WeatherHourly.wind_speed_10m]?.values.isEmpty ?? true ) || (item.hourlyData[WeatherHourly.wind_direction_10m]?.values.isEmpty ?? true )) {
        throw Exception("Data not found");
      }
      for (final time in (item.hourlyData[WeatherHourly.wind_speed_10m]!.values.keys)) {
        if (!data.containsKey(time)) {
          data[time] = {};
        }
        data[time]?.add((coordsList[i].$1, 
                        coordsList[i].$2, 
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
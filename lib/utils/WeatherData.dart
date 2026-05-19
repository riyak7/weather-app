import 'package:open_meteo/open_meteo.dart';

class WeatherData {
  static TemperatureUnit _tempUnit = TemperatureUnit.celsius;

  static List<OpenMeteoLocation> getMapLocations(double latitudeTopLeft, 
                                                  double longitudeTopLeft, 
                                                  double latitudeBottomRight, 
                                                  double longitudeBottomRight, 
                                                  int samplesLatitude,
                                                  int samplesLongitude) {
    // Given the latitude and longitude of 2 corners, 
    // and a sample counts for each axis,
    // generate objects for each location to request wind data 
    return List.generate(
      samplesLongitude * samplesLatitude,
      (i) => OpenMeteoLocation(latitude:  (1+(i % samplesLatitude)) * (latitudeBottomRight-latitudeTopLeft) / (samplesLatitude + 1), 
                              longitude: (1+(i ~/ samplesLatitude)) * (longitudeBottomRight-longitudeTopLeft) / (samplesLongitude + 1)),
    );
  }

  static List<(double, double, double, double)> getWindData(List<OpenMeteoLocation> locations) {
    final weather = WeatherApi(
    userAgent: "My-Flutter-App",
    temperatureUnit: _tempUnit,
  );

  static void changeTemperatureUnit(String unit)
  }
}
import "dart:math";
import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import "package:geolocator/geolocator.dart";
import "../utils/LocationUtils.dart";
import "../utils/UnitConversionUtils.dart";
import "../widgets/WindCompass.dart";
import "../globals.dart";
import "../utils/WeatherData.dart";


class CurrentLocationView extends StatelessWidget {
  const CurrentLocationView({super.key});

  Future<List<Map<String, dynamic>>> getForecast() async {
    Position position = await LocationUtils.determinePosition();
    String town = await LocationUtils.getCurrentAddress(position);
    List<Map<String, dynamic>> hourlyData = (await WeatherData.getSingleData(position.latitude, position.longitude)).values.toList();
    hourlyData.add({"town": town}); // Add the town name to the data so we can display it in the UI
    return hourlyData;
  }

  @override
  Widget build(BuildContext context){
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: getForecast(),
      builder: (context, snapshot) {
        if(snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        
        if(snapshot.hasError) {
          return Text(
            "Error: ${snapshot.error}",
            style: const TextStyle(color: Colors.white, fontSize: 28)
          );
        }

        List<Map<String, dynamic>> forecastData = snapshot.data ?? [];
        List<List<Map<String, dynamic>>> groupedData = [];
        String town = forecastData.isNotEmpty ? forecastData.removeLast()["town"] : "Unknown Location";
        double windDirection = forecastData.isNotEmpty ? forecastData[0]["windDirection"] as double : 0.0;
        DateTime datetime = DateTime.now();

        // Partition the forecast into separate lists for each day, to check the L/H for each day
        int currentDay = datetime.day;
        for(var map in forecastData) {
          if(map["time"].day != currentDay) {
            groupedData.add([map]);
            currentDay = map["time"].day;
          } else if(groupedData.isEmpty) {
            groupedData.add([map]);
          } else {
            groupedData.last.add(map);
          }
        }

        List<Map<String, double>> dailyHighLows = [];
        for(int i=0; i<7; i++) {
          double lowTemp = groupedData[i].map((e) => e["temperature"] as double).reduce(min);
          double highTemp = groupedData[i].map((e) => e["temperature"] as double).reduce(max);
          dailyHighLows.add({"lowTemp": lowTemp, "highTemp": highTemp});
        }

        datetime = DateTime(datetime.year, datetime.month, datetime.day, datetime.hour); // Round down to the nearest hour for comparison with forecast data
        print("Current datetime: $datetime");

        forecastData.removeWhere(
          (map) => map["time"].isBefore(datetime)
        );

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue[600]!, Colors.blue[300]!],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /*FutureBuilder<String>(
                                  future: town,
                                  builder: (context, snapshot) {
                                    if(snapshot.connectionState == ConnectionState.waiting) {
                                      return const CircularProgressIndicator();
                                    }
                                    
                                    if(snapshot.hasError) {
                                      return Text(
                                        "Error: ${snapshot.error}",
                                        style: const TextStyle(color: Colors.white, fontSize: 28)
                                      );
                                    }

                            */Text(
                                town,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                              )
                            ),
                            Text(
                              'Mon, Mar 2',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    forecastData.isNotEmpty ? UnitConversionUtils.tempWithUnit(forecastData[0]["temperature"]) : ("--" + (isCelsius ? "°C" : "°F")),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 96,
                      fontWeight: FontWeight.w200,
                    ),
                  ),
                  const Text(
                    'Partly Cloudy',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    forecastData.isNotEmpty ? 'H: ${UnitConversionUtils.tempWithUnit(dailyHighLows[0]["highTemp"]!)} L: ${UnitConversionUtils.tempWithUnit(dailyHighLows[0]["lowTemp"]!)}' : 'L: --° H: --°',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 16,
                    ),
                  ),
                  WindCompass(
                    degrees: windDirection
                  ),
                  const SizedBox(height: 40),
                  Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                'Hourly Forecast',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 130,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: 24,
                                itemBuilder: (context, index) {
                                  return _buildHourlyItem(
                                    context,
                                    time: index == 0
                                        ? 'Now'
                                        : '${forecastData[index]["time"].hour < 12 ? forecastData[index]["time"].hour : forecastData[index]["time"].hour - 12}${forecastData[index]["time"].hour < 12 ? 'AM' : 'PM'}',
                                    temp: '${UnitConversionUtils.temp(forecastData[index]["temperature"])}°\n${UnitConversionUtils.windSpeed(forecastData[index]["windSpeed"])}',
                                    icon: index < 6
                                        ? Icons.wb_cloudy
                                        : Icons.wb_sunny,
                                    isDark: isDark,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Center(
                              child: Text(
                                '7-Day Forecast',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildDayForecast(
                              'Today',
                              dailyHighLows[0]["highTemp"]!,
                              dailyHighLows[0]["lowTemp"]!,
                              Icons.wb_sunny,
                              isDark,
                            ),
                            _buildDayForecast(
                              'Tue',
                              dailyHighLows[1]["highTemp"]!,
                              dailyHighLows[1]["lowTemp"]!,
                              Icons.wb_cloudy,
                              isDark,
                            ),
                            _buildDayForecast(
                              'Wed',
                              dailyHighLows[2]["highTemp"]!,
                              dailyHighLows[2]["lowTemp"]!,
                              Icons.umbrella,
                              isDark,
                            ),
                            _buildDayForecast('Thu', dailyHighLows[3]["highTemp"]!, dailyHighLows[3]["lowTemp"]!, Icons.grain, isDark),
                            _buildDayForecast(
                              'Fri',
                              dailyHighLows[4]["highTemp"]!,
                              dailyHighLows[4]["lowTemp"]!,
                              Icons.wb_cloudy,
                              isDark,
                            ),
                            _buildDayForecast(
                              'Sat',
                              dailyHighLows[5]["highTemp"]!,
                              dailyHighLows[5]["lowTemp"]!,
                              Icons.wb_sunny,
                              isDark,
                            ),
                            _buildDayForecast(
                              'Sun',
                              dailyHighLows[6]["highTemp"]!,
                              dailyHighLows[6]["lowTemp"]!,
                              Icons.wb_sunny,
                              isDark,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildWeatherDetail(
                                    Icons.wind_power,
                                    'Wind Speed',
                                    (UnitConversionUtils.windSpeed(forecastData.isNotEmpty ? forecastData[0]["windSpeed"] as double : 0.0)).toString(),
                                    isDark,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildWeatherDetail(
                                    Icons.air,
                                    'Gust Speed',
                                    (UnitConversionUtils.windSpeed(forecastData.isNotEmpty ? forecastData[0]["gustSpeed"] as double : 0.0)).toString(),
                                    isDark,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildWeatherDetail(
                                    Icons.compress_outlined,
                                    'Air Pressure',
                                    forecastData.isNotEmpty ? '${(forecastData[0]["pressure"] as double).round()} hPa' : '-- hPa',
                                    isDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }



  Widget _buildHourlyItem(
    BuildContext context, {
    required String time,
    required String temp,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      width: 60,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.grey[600],
            ),
          ),
          Icon(icon, color: Colors.orange),
          Text(temp, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDayForecast(
    String day,
    double high,
    double low,
    IconData icon,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              day,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Icon(icon, color: Colors.orange, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 30,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text('${UnitConversionUtils.tempWithUnit(low)}'),
          const SizedBox(width: 12),
          Text('${UnitConversionUtils.tempWithUnit(high)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(
    IconData icon,
    String label,
    String value,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

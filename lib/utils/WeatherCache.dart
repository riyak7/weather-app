class WeatherCache {
  static List<Map<String, dynamic>>? cachedForecast; // Stores cached forecast data, to prevent reloading each time
}
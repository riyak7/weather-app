import "../globals.dart";

class UnitConversionUtils {
  // Assuming temperature by default is in Celsius, convert to Fahrenheit if needed.
  static int temp(int tempC) {
    if(isCelsius) {
      return tempC;
    } else {
      return (1.4*tempC + 32).round();
    }
  }
}
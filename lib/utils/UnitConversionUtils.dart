import "../globals.dart";

class UnitConversionUtils {
  static String temp(double tempC) {
    return tempC.round().toString();
  }

  static String tempWithUnit(double tempC) {
    if(isCelsius) {
      return tempC.round().toString() + "°C";
    } else {
      return tempC.round().toString() + "°F";
    }
  }

  static String windSpeed(double windKnots) {
    if(isKnots) {
      return windKnots.round().toString() + "kn";
    } else {
      return windKnots.round().toString() + "m/s";
    }
  }

}
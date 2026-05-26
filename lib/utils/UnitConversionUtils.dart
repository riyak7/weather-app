import "../globals.dart";

class UnitConversionUtils {
  static String temp(double temp) {
    if(isCelsius) {
      return temp.round().toString();
    } else {
      return (temp*1.8 + 32).round().toString();
    }
  }

  static String tempWithUnit(double temp) {
    if(isCelsius) {
      return temp.round().toString() + "°C";
    } else {
      return (temp * 1.8 + 32).round().toString() + "°F";
    }
  }



  static String windSpeed(double windKnots) {
    if(isKnots) {
      return windKnots.round().toString() + "kn";
    } else {
      return (windKnots*1.944).round().toString() + "m/s";
    }
  }

}
import "../globals.dart";

class UnitConversionUtils {
  
  static String tempWithUnit(double temp) {
    if(isCelsius) {
      return temp.round().toString() + "°C";
    } else {
      return temp.round().toString() + "°F";
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
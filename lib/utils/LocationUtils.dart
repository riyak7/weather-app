import "dart:convert";
import "package:flutter/foundation.dart";
import "package:geolocator/geolocator.dart";
import "package:geocoding/geocoding.dart";
import "package:http/http.dart" as http;

class LocationUtils {

  //static final position = determinePosition();
  static final town = getCurrentAddress();

  static Future<Position> determinePosition() async {
    LocationPermission permission;
    bool serviceEnabled;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the 
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale 
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately. 
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
    } 

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  static Future<String> getCurrentAddress() async {
    if(kIsWeb) {
      return await _getCurrentAddressWeb();
    } else {
      return await _getCurrentAddressMobile();
    }
  }


  // Uses OpenStreetMap's Nominatim API to reverse geocode the coordinates into an address. For web only.
  static Future<String> _getCurrentAddressWeb() async {
    try {
      Position position = await determinePosition();
      final url = "https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${position.latitude}&lon=${position.longitude}&addressdetails=1";
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "User-Agent": "FlutterApp/1.0"
        }
      );

      if(response.statusCode != 200) {
        return "Failed to retrieve address: ${response.statusCode}";
      }

      final data = jsonDecode(response.body);
      final town = data["address"]["town"] ?? data["address"]["city"] ?? data["address"]["village"] ?? "Unknown Location";
      
      return town;
    } catch(e) {
      return "Error retrieving address: $e";
    }
  }

  // Uses geocoding package to reverse geocode the coordinates into an address. For mobile only.
  static Future<String> _getCurrentAddressMobile() async {
    try {
        Position position = await determinePosition();
        debugPrint("Position: $position");
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        debugPrint("Placemarks: $placemarks");

        if(placemarks.isEmpty) {
          return "No address found";
        }

        Placemark place = placemarks.first;
        return "${place.street ?? ''}, ${place.locality ?? ''}, ${place.postalCode ?? ''}, ${place.country ?? ''}";

    } catch(e, stack) {
        debugPrint("Error retrieving address: $e");
        debugPrintStack(stackTrace: stack);
        return "Error retrieving address: $e";
    }
  }
}
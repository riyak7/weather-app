import "package:flutter/foundation.dart" show kIsWeb;
import 'package:flutter/material.dart';
import "package:geolocator/geolocator.dart";
import "package:geocoding/geocoding.dart";

class CurrentLocationView extends StatelessWidget {
  const CurrentLocationView({super.key});

  @override
  Widget build(BuildContext context){
    return FutureBuilder<String>(
      future: _getCurrentAddress(),
      builder: (context, snapshot) {
        if(snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if(snapshot.hasError) {
          return Text("Error: ${snapshot.error}");
        } else {
          return Text("Current location: ${snapshot.data}\n\nNote: This feature is not available on web platforms, only mobile apparently?? Someone check when possible.");
        }
      }
    );
  }

Future<Position> _determinePosition() async {
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


  Future<String> _getCurrentAddress() async {
    try {
        Position position = await _determinePosition();
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        
        if(placemarks.isEmpty) {
          return "No address found";
        }

        Placemark place = placemarks[0];
        return "${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}";

    } catch(e) {
        return "Error retrieving address: $e";
    }
  }


}
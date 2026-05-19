import 'package:flutter/material.dart';
import "../utils/LocationUtils.dart";


class CurrentLocationView extends StatelessWidget {
  const CurrentLocationView({super.key});

  @override
  Widget build(BuildContext context){
    return FutureBuilder<String>(
      future: LocationUtils.getCurrentAddress(),
      builder: (context, snapshot) {
        if(snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if(snapshot.hasError) {
          return Text("Error: ${snapshot.error}");
        } else {
          return Text("Current location: ${snapshot.data}");
        }
      }
    );


  }




}
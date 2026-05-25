import 'package:flutter/material.dart';

bool isCelsius = true;
bool isKnots = false;
var importedGpxData;
DateTime selectedTime = DateTime.now();

// Reactive variable that streams when it is changed.
final ValueNotifier<DateTime> reactiveSelectedTime = ValueNotifier<DateTime>(DateTime.now());
import 'package:flutter/material.dart';

bool isCelsius = true;
bool isKnots = false;
var importedGpxData;

DateTime currentTime = DateTime.now();
DateTime selectedTime = DateTime(
                        currentTime.year,
                        currentTime.month,
                        currentTime.day,
                        currentTime.hour,
                      );

// Reactive variable that streams when it is changed.
final ValueNotifier<DateTime> reactiveSelectedTime = ValueNotifier<DateTime>(selectedTime);

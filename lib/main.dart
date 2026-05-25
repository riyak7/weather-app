import 'package:flutter/material.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' as icons;
import 'pages/pages.dart';
import 'package:weather_app_sailing/globals.dart';

// This is the main app and it acts as a controller for what page is shown.
// There are 4 pages: map view, current location view, route view and settings
// each of which is a widget.
//
// I have grouped all of them together in the 'pages' folder, so we only
// need to edit the files in there i.e. we only need to edit the pages now
// and the code below is mainly just boilerplate that handles the top bar
// with its fancy icons and switching between pages.

void main() {
  runApp(MaterialApp(home: const MainApp()));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  // creates the state of StatefulWidget
  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  // The top bar elements (icons)
  static const List<Widget> tabs = <Widget>[
    icons.Globe(),
    icons.NavigatorAlt(),
    icons.Strategy(),
    icons.Settings(),
  ];

  @override
  Widget build(BuildContext context) {
    // The tab system including the interactive top bar for switching
    // and each page that gets displayed.
    return DefaultTabController(
      length: tabs.length,

      child: Builder(
        builder: (context) {
          final controller = DefaultTabController.of(context)!;

          return AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return Scaffold(
                // Top bar
                appBar: AppBar(
                  title: const TabBar(
                    tabs: tabs,
                    dividerColor: Colors.transparent,
                    labelPadding: EdgeInsets.only(bottom: 5.0),
                  ),
                ),

                // The actual content
                body: TabBarView(
                  children: [
                    HeatMapView(),
                    CurrentLocationView(),
                    RouteView(),
                    SettingsView(),
                  ],
                ),

                // ONLY SHOW ON MAP TAB
                bottomNavigationBar: controller.index == 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        color: const Color.fromARGB(255, 205, 216, 228),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                              children: List.generate(7, (i) {
                                final day =
                                    DateTime.now().add(Duration(days: i));

                                final label = [
                                  'Mon',
                                  'Tue',
                                  'Wed',
                                  'Thu',
                                  'Fri',
                                  'Sat',
                                  'Sun',
                                ][day.weekday - 1];

                                final isSelected =
                                    selectedTime.day == day.day;

                  return GestureDetector(
                    onTap: () => setState(() {
                      selectedTime = DateTime(
                        day.year,
                        day.month,
                        day.day,
                        selectedTime.hour,
                      );
                      reactiveSelectedTime.value = DateTime(
                        day.year,
                        day.month,
                        day.day,
                        selectedTime.hour,
                      );
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color.fromARGB(255, 100, 149, 190)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black54,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Hour',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  Text(
                    '${selectedTime.hour.toString().padLeft(2, '0')}:00',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Slider(
                min: 0,
                max: 23,
                divisions: 23,
                value: selectedTime.hour.toDouble(),
                onChanged: (val) => setState(() {
                  selectedTime = DateTime(
                    selectedTime.year,
                    selectedTime.month,
                    selectedTime.day,
                    val.toInt(),
                  );
                  reactiveSelectedTime.value = DateTime(
                    selectedTime.year,
                    selectedTime.month,
                    selectedTime.day,
                    val.toInt(),
                  );
                }),
              ),
            ],
          ),
                    ) : null,
              );
            },
          );
        },
      ),       

    );
  }
}
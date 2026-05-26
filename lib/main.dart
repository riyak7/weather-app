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

      child: Scaffold(
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
      ),
    );
  }
}

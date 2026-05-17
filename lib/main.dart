import 'package:flutter/material.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' as icons;

// This is the main app, we build widgets and place them here
// like top bar and other pages etc...

void main() {
  runApp(MaterialApp(home: const MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  static const List<Widget> tabs = <Widget>[
    icons.Globe(),
    icons.NavigatorAlt(),
    icons.Strategy(),
    icons.Settings(),
  ];

  @override
  Widget build(BuildContext ctx){
    // The whole app
    return DefaultTabController(
      length: tabs.length,

      child: Scaffold (

        appBar: AppBar(
          title: const TabBar(
            tabs: tabs,
            dividerColor: Colors.transparent,
            labelPadding: const EdgeInsets.only(bottom: 5.0)
          )
        ),

        body: TabBarView(
          children: [
            icons.Globe(),
            icons.NavigatorAlt(),
            icons.Strategy(),
            icons.Settings(),
          ],
          
        )

      )
    );
  }
}
//centerTitle: true, title: MenuButtonHolder()
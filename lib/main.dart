import 'package:flutter/material.dart';
import 'MenuButtonHolder.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext ctx){
    return MaterialApp(
      home: Scaffold (
        appBar: AppBar(
          centerTitle: true,
          title: MenuButtonHolder(),
        ),
      )
    );
  }
}
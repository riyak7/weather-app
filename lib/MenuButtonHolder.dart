import 'package:flutter/material.dart';
import 'MenuButton.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart';

class MenuButtonHolder extends StatelessWidget {

  const MenuButtonHolder({super.key});

  @override
  Widget build(BuildContext ctx){
    return const Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        spacing: 5.0,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const MenuButton(Globe()),
          const MenuButton(NavigatorAlt()),
          const MenuButton(Strategy()),
        ],
      )
    );
  }
}
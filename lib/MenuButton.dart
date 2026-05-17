import 'package:flutter/material.dart';

class MenuButton extends StatelessWidget {

  const MenuButton(this.icon, {super.key});

  final Widget icon;

  @override
  Widget build(BuildContext ctx){
    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        //border: Border.all(color: Colors.grey.shade300),
        // TODO: Maybe style the box to make it clear it's a button?
      ),
      child: Center(
        child: icon
      )
    );
  }
}
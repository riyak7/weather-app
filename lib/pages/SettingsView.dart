import 'package:flutter/material.dart';
import 'package:weather_app_sailing/globals.dart';

//C:\Users\riyak\OneDrive\Documents\weather app\weather-app\lib\globals.dart

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late bool _isCelcius = isCelcius;

  @override
  Widget build(BuildContext context) {
    //return Text("The settings should be here");
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 205, 216, 228),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 205, 216, 228),
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color.fromARGB(255, 0, 0, 0),
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          const Text(
            'UNITS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Temperature',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Row(
                children: [
                  _ToggleButton(
                    label: '°F',
                    selected: !_isCelcius,
                    onTap: () => setState(() {
                      _isCelcius = false;
                      isCelcius = false;
                    }),
                  ),
                  _ToggleButton(
                    label: '°C',
                    selected: _isCelcius,
                    onTap: () => setState(() {
                      _isCelcius = true;
                      isCelcius = true;
                    }),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 48,
        height: 36,
        decoration: BoxDecoration(
          color: selected
              ? const Color.fromARGB(255, 100, 149, 190)
              : const Color.fromARGB(255, 180, 195, 210),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black54,
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

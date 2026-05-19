import 'dart:math';
import 'package:flutter/material.dart';

class WindCompass extends StatelessWidget {
  final double degrees;

  const WindCompass({
    super.key,
    required this.degrees,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "Wind Direction",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Compass circle
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white70,
                    width: 2,
                  ),
                ),
              ),

              // Direction labels
              const Positioned(top: 8, child: Text("N")),
              const Positioned(bottom: 8, child: Text("S")),
              const Positioned(left: 8, child: Text("W")),
              const Positioned(right: 8, child: Text("E")),

              // Needle
              // Needle
              Transform.rotate(
                angle: degrees * pi / 180,
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Needle shaft
                      Positioned(
                        top: 20,
                        child: Container(
                          width: 4,
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),

                      // Center pivot
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ]
          )
        ),

        const SizedBox(height: 8),

        Text(
          "${degrees.toStringAsFixed(0)}°",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
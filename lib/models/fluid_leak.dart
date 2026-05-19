import 'package:flutter/material.dart';

class FluidLeak {
  final String id;
  final String fluidType;
  final Color typicalColor;
  final String colorDescription;
  final String severity;            // 'Critical' | 'High' | 'Medium' | 'Low'
  final List<String> commonCauses;
  final String whatToDo;
  final bool driveableNow;
  final String texture;
  final String smell;
  final String beginnerExplanation;
  final List<String> leakLocations;

  const FluidLeak({
    required this.id,
    required this.fluidType,
    required this.typicalColor,
    required this.colorDescription,
    required this.severity,
    required this.commonCauses,
    required this.whatToDo,
    required this.driveableNow,
    required this.texture,
    required this.smell,
    required this.beginnerExplanation,
    required this.leakLocations,
  });
}

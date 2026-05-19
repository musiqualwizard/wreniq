import 'package:flutter/material.dart';

class WarningLight {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String severity;           // 'Critical' | 'Warning' | 'Info'
  final bool safeToRide;
  final String whatItMeans;
  final String whatToDo;
  final String beginnerExplanation;
  final String category;           // 'Engine' | 'Safety' | 'Fluid' | 'Electrical' | 'Tires'

  const WarningLight({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.severity,
    required this.safeToRide,
    required this.whatItMeans,
    required this.whatToDo,
    required this.beginnerExplanation,
    required this.category,
  });
}

import 'package:flutter/material.dart';

class EngineComponent {
  final String id;
  final String name;
  final String shortDescription;
  final String whatItDoes;
  final String beginnerExplanation;
  final double relX;           // 0.0–1.0 relative to map width
  final double relY;           // 0.0–1.0 relative to map height
  final String failureRisk;    // 'High' | 'Medium' | 'Low'
  final List<String> symptoms;
  final String maintenanceTip;
  final Color dotColor;

  const EngineComponent({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.whatItDoes,
    required this.beginnerExplanation,
    required this.relX,
    required this.relY,
    required this.failureRisk,
    required this.symptoms,
    required this.maintenanceTip,
    required this.dotColor,
  });
}

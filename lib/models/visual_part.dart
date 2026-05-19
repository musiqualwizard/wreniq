import 'package:flutter/material.dart';

class VisualPartResult {
  final String partName;
  final String whatItDoes;
  final String beginnerExplanation;
  final List<String> symptoms;
  final String urgency;           // 'Critical' | 'High' | 'Medium' | 'Low'
  final String priceRange;
  final String diyDifficulty;
  final List<String> videoSearchTerms;
  final List<String> safetyWarnings;
  final double confidence;
  final String imagePath;
  final DateTime identifiedAt;

  const VisualPartResult({
    required this.partName,
    required this.whatItDoes,
    required this.beginnerExplanation,
    required this.symptoms,
    required this.urgency,
    required this.priceRange,
    required this.diyDifficulty,
    required this.videoSearchTerms,
    required this.safetyWarnings,
    required this.confidence,
    required this.imagePath,
    required this.identifiedAt,
  });

  Color get urgencyColor {
    switch (urgency) {
      case 'Critical': return const Color(0xFFFF3B30);
      case 'High':     return const Color(0xFFFF6B35);
      case 'Medium':   return const Color(0xFFFFB800);
      default:         return const Color(0xFF00E676);
    }
  }

  IconData get urgencyIcon {
    switch (urgency) {
      case 'Critical': return Icons.dangerous_outlined;
      case 'High':     return Icons.warning_amber_rounded;
      case 'Medium':   return Icons.info_outline;
      default:         return Icons.check_circle_outline;
    }
  }
}

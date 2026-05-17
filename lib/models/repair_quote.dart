enum QuoteRating { fair, slightlyHigh, overpriced, suspicious }

class QuoteLineItem {
  final String description;
  final double quotedPrice;
  final double fairMin;
  final double fairMax;
  final bool isSuspicious;
  final bool isCommonScam;
  final String explanation;
  final String urgency; // 'Critical' | 'Recommended' | 'Optional'

  const QuoteLineItem({
    required this.description,
    required this.quotedPrice,
    required this.fairMin,
    required this.fairMax,
    required this.isSuspicious,
    required this.isCommonScam,
    required this.explanation,
    required this.urgency,
  });

  bool get isOverpriced => quotedPrice > fairMax * 1.25;
  String get fairRange  => '\$${fairMin.toStringAsFixed(0)}–\$${fairMax.toStringAsFixed(0)}';
}

class RepairQuote {
  final String id;
  final String rawText;
  final double totalQuoted;
  final double fairEstimateMin;
  final double fairEstimateMax;
  final QuoteRating rating;
  final List<QuoteLineItem> lineItems;
  final List<String> redFlags;
  final List<String> positives;
  final DateTime analyzedAt;

  const RepairQuote({
    required this.id,
    required this.rawText,
    required this.totalQuoted,
    required this.fairEstimateMin,
    required this.fairEstimateMax,
    required this.rating,
    required this.lineItems,
    required this.redFlags,
    required this.positives,
    required this.analyzedAt,
  });

  double get potentialSavings =>
      (totalQuoted - fairEstimateMax).clamp(0.0, double.infinity);

  String get ratingLabel => switch (rating) {
    QuoteRating.fair        => 'Fair',
    QuoteRating.slightlyHigh => 'Slightly High',
    QuoteRating.overpriced   => 'Overpriced',
    QuoteRating.suspicious   => 'Suspicious',
  };
}

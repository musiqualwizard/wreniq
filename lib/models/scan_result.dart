// Where to buy the identified part
class BuyOption {
  final String store;
  final String priceRange;
  final String url;

  const BuyOption({
    required this.store,
    required this.priceRange,
    required this.url,
  });

  Map<String, dynamic> toJson() => {
    'store': store,
    'priceRange': priceRange,
    'url': url,
  };

  factory BuyOption.fromJson(Map<String, dynamic> json) => BuyOption(
    store: json['store'] as String,
    priceRange: json['priceRange'] as String,
    url: json['url'] as String,
  );
}

// Full result returned after AI part analysis.
// Phase 1 fields kept for backward compatibility with saved scans.
// Phase 2 fields use ?? defaults in fromJson so old data still loads.
class ScanResult {
  final String id;
  final String imagePath;
  final String partName;
  final double confidenceScore;       // 0.0 – 1.0
  final String priceEstimate;         // formatted fallback e.g. "$85 – $200"
  final double estimatedPriceLow;     // Phase 2: numeric low end
  final double estimatedPriceHigh;    // Phase 2: numeric high end
  final String repairDifficulty;      // Beginner / Intermediate / Advanced
  final List<String> toolsNeeded;
  final List<String> repairSteps;
  final List<BuyOption> buyOptions;
  final List<String> compatibleParts;
  final String explanation;           // Phase 2: AI reasoning for identification
  final String fitmentWarning;        // Phase 2: part-specific fitment caveat
  final List<String> suggestedSearchTerms; // Phase 2: search terms for finding the part
  final List<String> safetyWarnings;       // Phase 3: part-specific safety warnings from AI
  final DateTime scannedAt;
  final String vehicleInfo;

  const ScanResult({
    required this.id,
    required this.imagePath,
    required this.partName,
    required this.confidenceScore,
    required this.priceEstimate,
    required this.estimatedPriceLow,
    required this.estimatedPriceHigh,
    required this.repairDifficulty,
    required this.toolsNeeded,
    required this.repairSteps,
    required this.buyOptions,
    required this.compatibleParts,
    required this.explanation,
    required this.fitmentWarning,
    required this.suggestedSearchTerms,
    required this.safetyWarnings,
    required this.scannedAt,
    required this.vehicleInfo,
  });

  // Formatted price range — uses numeric fields if populated, else fallback string
  String get priceRange =>
      estimatedPriceLow > 0 && estimatedPriceHigh > 0
          ? '\$${estimatedPriceLow.toStringAsFixed(0)} – \$${estimatedPriceHigh.toStringAsFixed(0)}'
          : priceEstimate;

  Map<String, dynamic> toJson() => {
    'id': id,
    'imagePath': imagePath,
    'partName': partName,
    'confidenceScore': confidenceScore,
    'priceEstimate': priceEstimate,
    'estimatedPriceLow': estimatedPriceLow,
    'estimatedPriceHigh': estimatedPriceHigh,
    'repairDifficulty': repairDifficulty,
    'toolsNeeded': toolsNeeded,
    'repairSteps': repairSteps,
    'buyOptions': buyOptions.map((b) => b.toJson()).toList(),
    'compatibleParts': compatibleParts,
    'explanation': explanation,
    'fitmentWarning': fitmentWarning,
    'suggestedSearchTerms': suggestedSearchTerms,
    'safetyWarnings': safetyWarnings,
    'scannedAt': scannedAt.toIso8601String(),
    'vehicleInfo': vehicleInfo,
  };

  // Phase 2 fields fall back to safe defaults so Phase 1 saved scans still load.
  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
    id: json['id'] as String,
    imagePath: json['imagePath'] as String,
    partName: json['partName'] as String,
    confidenceScore: (json['confidenceScore'] as num).toDouble(),
    priceEstimate: json['priceEstimate'] as String? ?? '',
    estimatedPriceLow:
        (json['estimatedPriceLow'] as num?)?.toDouble() ?? 0.0,
    estimatedPriceHigh:
        (json['estimatedPriceHigh'] as num?)?.toDouble() ?? 0.0,
    repairDifficulty: json['repairDifficulty'] as String,
    toolsNeeded: List<String>.from(json['toolsNeeded'] as List),
    repairSteps: List<String>.from(json['repairSteps'] as List),
    buyOptions: (json['buyOptions'] as List)
        .map((b) => BuyOption.fromJson(b as Map<String, dynamic>))
        .toList(),
    compatibleParts: List<String>.from(json['compatibleParts'] as List),
    explanation: json['explanation'] as String? ?? '',
    fitmentWarning: json['fitmentWarning'] as String? ??
        'Always verify fitment using your VIN before purchasing.',
    suggestedSearchTerms: json['suggestedSearchTerms'] != null
        ? List<String>.from(json['suggestedSearchTerms'] as List)
        : [],
    safetyWarnings: json['safetyWarnings'] != null
        ? List<String>.from(json['safetyWarnings'] as List)
        : [],
    scannedAt: DateTime.parse(json['scannedAt'] as String),
    vehicleInfo: json['vehicleInfo'] as String,
  );
}

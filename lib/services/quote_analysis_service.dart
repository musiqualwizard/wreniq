import '../models/repair_quote.dart';

// Heuristic quote analyser.
// Phase 2: replace with backend AI call that accepts image/PDF + text.
class QuoteAnalysisService {
  // ── Fair price database ─────────────────────────────────────────────────────
  // (min, max, isCommonScam, explanation, urgency)
  static const _db = <String, (double, double, bool, String, String)>{
    'oil change':            (25, 75,  false, 'Standard oil + filter service. DIY cost ≈ \$25–\$45.',                 'Recommended'),
    'cabin air filter':      (15, 50,  true,  'DIY cost ≈ \$10–\$20. Shops often mark this up 3–5×.',                'Optional'),
    'engine air filter':     (15, 45,  false, 'Easy DIY for ~\$15. Shop labour minimal.',                             'Recommended'),
    'brake pads':            (100, 300, false, 'Front or rear. Price varies by vehicle and pad grade.',               'Critical'),
    'brake fluid':           (30, 100,  false, 'Flush every 2–3 years or 30 k miles.',                               'Recommended'),
    'brake rotors':          (150, 400, false, 'Often replaced with pads. Ask if resurfacing is an option first.',    'Critical'),
    'spark plugs':           (100, 350, false, 'Iridium plugs cost more. Interval: 30–100 k miles by spec.',         'Recommended'),
    'throttle body cleaning': (50, 150, true,  'Rarely necessary unless idle is rough. Common upsell.',               'Optional'),
    'fuel system cleaning':  (50, 150, true,  'Unnecessary with modern fuel injectors on regular use.',              'Optional'),
    'transmission service':  (100, 300, false, 'Interval 30–60 k miles depending on transmission type.',             'Recommended'),
    'power steering flush':  (50, 150, true,  'Often unnecessary unless power steering is electric.',                'Optional'),
    'coolant flush':         (60, 150, false, 'Needed every 2–5 years. Legitimate service.',                         'Recommended'),
    'alignment':             (50, 120, false, 'Needed after suspension work or if car pulls to one side.',           'Recommended'),
    'tire rotation':         (15, 50,  false, 'Should be done every 5 k–7.5 k miles.',                              'Recommended'),
    'battery':               (100, 280, false, 'Includes part and installation. Test before replacing.',             'Critical'),
    'alternator':            (300, 750, false, 'Labour-intensive. Price varies widely by vehicle.',                  'Critical'),
    'water pump':            (200, 650, false, 'Often done with timing belt/chain for efficiency.',                  'Critical'),
    'timing belt':           (300, 800, false, 'Critical service. Interval per manufacturer spec.',                  'Critical'),
    'serpentine belt':       (75, 200, false, 'Inspect for cracks. Replace every 60–100 k miles.',                  'Recommended'),
    'ac recharge':           (75, 200, false, 'Refrigerant recharge. Includes leak check.',                         'Optional'),
    'wheel bearing':         (200, 500, false, 'Replace one side at a time. Front vs rear price varies.',            'Critical'),
    'cv axle':               (200, 500, false, 'CV boots can sometimes be replaced cheaper than full axle.',         'Critical'),
    'wiper blades':          (15, 40,  true,  'DIY replacement in 2 minutes. Shops charge 2–4× parts cost.',        'Optional'),
    'tire pressure':         (0, 10,   true,  'Inflating tires is free at many gas stations. Never pay over \$5.',  'Optional'),
    'diagnostic fee':        (50, 150, false, 'Reasonable for computer scan. Should be waived if you get repair.', 'Recommended'),
    'fuel injector cleaning': (60, 200, true, 'Usually unnecessary unless misfires or poor fuel economy confirmed.', 'Optional'),
    'differential service':  (80, 250, false, 'Interval 30–60 k miles. Legitimate for 4WD/AWD vehicles.',          'Recommended'),
  };

  // ── Public API ──────────────────────────────────────────────────────────────

  static RepairQuote analyze(String rawText) {
    if (rawText.trim().isEmpty) return _emptyQuote(rawText);

    final lower     = rawText.toLowerCase();
    final prices    = _extractPrices(rawText);
    final lineItems = <QuoteLineItem>[];
    final redFlags  = <String>[];
    final positives = <String>[];

    // Match known repair types from pasted text
    for (final entry in _db.entries) {
      if (lower.contains(entry.key)) {
        final (fairMin, fairMax, isScam, explain, urgency) = entry.value;
        // Find a price in the text near this keyword (best-effort heuristic)
        final price = _findNearestPrice(rawText, entry.key, prices);
        lineItems.add(QuoteLineItem(
          description: _titleCase(entry.key),
          quotedPrice: price ?? ((fairMin + fairMax) / 2 * 1.1),
          fairMin:     fairMin,
          fairMax:     fairMax,
          isSuspicious: price != null && price > fairMax * 1.3,
          isCommonScam: isScam,
          explanation:  explain,
          urgency:      urgency,
        ));
        if (isScam) {
          redFlags.add('${_titleCase(entry.key)} is a frequent unnecessary upsell — verify it is actually needed.');
        }
      }
    }

    // Urgency language red flags
    if (lower.contains('must') || lower.contains('urgent') || lower.contains('immediately')) {
      redFlags.add('Urgency language detected. Take time to get a second opinion before authorising work.');
    }
    if (lower.contains('complimentary') || lower.contains('free inspection')) {
      positives.add('Complimentary inspection offered — legitimate shops commonly do this.');
    }
    if (lineItems.where((i) => i.isCommonScam).length >= 2) {
      redFlags.add('Multiple optional/upsell services included. These may not all be needed for your vehicle.');
    }

    // If nothing matched, create a generic line item from total price
    double total;
    if (lineItems.isEmpty && prices.isNotEmpty) {
      total = prices.reduce((a, b) => a > b ? a : b);
      final fairMin = total * 0.65;
      final fairMax = total * 0.85;
      lineItems.add(QuoteLineItem(
        description: 'Total Repair Work (unrecognised items)',
        quotedPrice: total,
        fairMin:     fairMin,
        fairMax:     fairMax,
        isSuspicious: false,
        isCommonScam: false,
        explanation: 'Wreniq could not identify individual line items. '
            'Paste each service on a separate line for detailed analysis.',
        urgency: 'Unknown',
      ));
    }

    total = lineItems.fold(0.0, (s, i) => s + i.quotedPrice);
    final fairMin = lineItems.fold(0.0, (s, i) => s + i.fairMin);
    final fairMax = lineItems.fold(0.0, (s, i) => s + i.fairMax);

    final rating = _rateQuote(total, fairMax, lineItems, redFlags);

    if (rating == QuoteRating.fair) {
      positives.add('Overall pricing appears within normal range.');
    }

    return RepairQuote(
      id:              DateTime.now().millisecondsSinceEpoch.toString(),
      rawText:         rawText,
      totalQuoted:     total,
      fairEstimateMin: fairMin,
      fairEstimateMax: fairMax,
      rating:          rating,
      lineItems:       lineItems,
      redFlags:        redFlags,
      positives:       positives,
      analyzedAt:      DateTime.now(),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static RepairQuote _emptyQuote(String raw) => RepairQuote(
    id:              DateTime.now().millisecondsSinceEpoch.toString(),
    rawText:         raw,
    totalQuoted:     0,
    fairEstimateMin: 0,
    fairEstimateMax: 0,
    rating:          QuoteRating.fair,
    lineItems:       [],
    redFlags:        [],
    positives:       [],
    analyzedAt:      DateTime.now(),
  );

  static List<double> _extractPrices(String text) {
    final results = <double>[];
    final pattern = RegExp(r'\$\s*(\d+(?:[.,]\d{1,2})?)', caseSensitive: false);
    for (final m in pattern.allMatches(text)) {
      final val = double.tryParse(m.group(1)!.replaceAll(',', ''));
      if (val != null && val > 0) results.add(val);
    }
    return results;
  }

  static double? _findNearestPrice(
      String text, String keyword, List<double> prices) {
    if (prices.isEmpty) return null;
    final lower   = text.toLowerCase();
    final kIdx    = lower.indexOf(keyword);
    if (kIdx < 0) return null;
    final pattern = RegExp(r'\$\s*(\d+(?:[.,]\d{1,2})?)', caseSensitive: false);
    double? best;
    int bestDist = 99999;
    for (final m in pattern.allMatches(text)) {
      final dist = (m.start - kIdx).abs();
      if (dist < bestDist) {
        bestDist = dist;
        best = double.tryParse(m.group(1)!.replaceAll(',', ''));
      }
    }
    return best;
  }

  static QuoteRating _rateQuote(
    double total,
    double fairMax,
    List<QuoteLineItem> items,
    List<String> flags,
  ) {
    final scamCount = items.where((i) => i.isCommonScam).length;
    final overCount = items.where((i) => i.isOverpriced).length;

    if (scamCount >= 3 || overCount >= 2 || flags.length >= 3) {
      return QuoteRating.suspicious;
    }
    if (fairMax > 0 && total > fairMax * 1.5) return QuoteRating.overpriced;
    if (fairMax > 0 && total > fairMax * 1.15) return QuoteRating.slightlyHigh;
    return QuoteRating.fair;
  }

  static String _titleCase(String s) =>
      s.split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
}

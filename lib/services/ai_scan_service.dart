import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/scan_result.dart';
import 'mock_ai_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ScanAnalysis — wrapper returned by AiScanService.analyze()
//
// Carries the result AND whether mock mode was used, so the UI can show
// the appropriate banner without polluting ScanResult itself.
// ─────────────────────────────────────────────────────────────────────────────
class ScanAnalysis {
  final ScanResult result;
  final bool wasMock;
  final String? fallbackReason; // non-null when backend failed and mock was used

  const ScanAnalysis({
    required this.result,
    required this.wasMock,
    this.fallbackReason,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom exceptions — each maps to a user-friendly message in ScanProvider
// ─────────────────────────────────────────────────────────────────────────────
class _AiScanException implements Exception {
  final String message;
  const _AiScanException(this.message);
  @override
  String toString() => message;
}

class _ImageTooLargeException extends _AiScanException {
  const _ImageTooLargeException()
      : super('Image is too large (max 4 MB). Please choose a smaller photo.');
}

class _BackendNotConfiguredException extends _AiScanException {
  const _BackendNotConfiguredException()
      : super('Backend not configured. Set backendUrl in lib/config/api_config.dart.');
}

class _NoInternetException extends _AiScanException {
  const _NoInternetException()
      : super('No internet connection. Check your network and try again.');
}

class _TimeoutException extends _AiScanException {
  const _TimeoutException()
      : super('Request timed out. Check your connection and try again.');
}

class _BadResponseException extends _AiScanException {
  const _BadResponseException(super.detail);
}

// ─────────────────────────────────────────────────────────────────────────────
// AiScanService
// ─────────────────────────────────────────────────────────────────────────────
class AiScanService {
  // Routing logic:
  //   ApiConfig.hasBackend == false  →  mock always
  //   ApiConfig.hasBackend == true   →  POST to backend, fallback to mock on error
  static Future<ScanAnalysis> analyze({
    required String imagePath,
    required String year,
    required String make,
    required String model,
    required String trim,
  }) async {
    if (!ApiConfig.hasBackend) {
      final result = await MockAiService.analyze(
        imagePath: imagePath,
        year: year,
        make: make,
        model: model,
        trim: trim,
      );
      return ScanAnalysis(result: result, wasMock: true);
    }

    // ── Live path — call backend proxy ───────────────────────────────────────
    try {
      final result = await _backendAnalyze(
        imagePath: imagePath,
        year:      year,
        make:      make,
        model:     model,
        trim:      trim,
      );
      return ScanAnalysis(result: result, wasMock: false);
    } on _AiScanException {
      rethrow; // ScanProvider shows a proper error snackbar for these
    } catch (e) {
      // Unexpected error — fall back to mock so the user still gets a result
      final result = await MockAiService.analyze(
        imagePath: imagePath,
        year: year,
        make: make,
        model: model,
        trim: trim,
      );
      return ScanAnalysis(
        result:         result,
        wasMock:        true,
        fallbackReason: 'backend not connected.',
      );
    }
  }

  // ── Backend proxy call ────────────────────────────────────────────────────
  static Future<ScanResult> _backendAnalyze({
    required String imagePath,
    required String year,
    required String make,
    required String model,
    required String trim,
  }) async {
    // 1. Validate file size before uploading
    final imageFile = File(imagePath);
    final fileSize  = await imageFile.length();
    if (fileSize > ApiConfig.maxImageBytes) {
      throw const _ImageTooLargeException();
    }

    // 2. Build multipart request
    final uri     = Uri.parse(ApiConfig.backendUrl);
    final request = http.MultipartRequest('POST', uri);

    request.fields['year']  = year;
    request.fields['make']  = make;
    request.fields['model'] = model;
    request.fields['trim']  = trim;

    request.files.add(
      await http.MultipartFile.fromPath('image', imagePath),
    );

    // 3. Send with timeout
    final http.StreamedResponse streamed;
    try {
      streamed = await request.send().timeout(ApiConfig.requestTimeout);
    } on SocketException {
      throw const _NoInternetException();
    } on TimeoutException {
      throw const _TimeoutException();
    }

    final response = await http.Response.fromStream(streamed);

    // 4. Handle HTTP errors
    if (response.statusCode == 401) {
      throw const _BadResponseException(
          'Backend rejected API key. Check OPENAI_API_KEY in backend/.env.');
    }
    if (response.statusCode == 413) throw const _ImageTooLargeException();
    if (response.statusCode == 503) {
      throw const _BackendNotConfiguredException();
    }
    if (response.statusCode != 200) {
      String detail = 'Backend error (HTTP ${response.statusCode}).';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['error'] != null) detail = body['error'].toString();
      } catch (_) {}
      throw _BadResponseException(detail);
    }

    // 5. Parse the JSON the backend returns
    final Map<String, dynamic> partJson;
    try {
      partJson = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const _BadResponseException(
          'Backend returned invalid JSON. Please try again.');
    }

    // 6. Build ScanResult
    return _buildScanResult(
      json:        partJson,
      imagePath:   imagePath,
      vehicleInfo: '$year $make $model, Trim/Engine: $trim',
    );
  }

  // ── ScanResult builder ────────────────────────────────────────────────────
  static List<String> _safeStringList(dynamic val) {
    if (val is List) return val.map((e) => e.toString()).toList();
    return [];
  }

  static ScanResult _buildScanResult({
    required Map<String, dynamic> json,
    required String imagePath,
    required String vehicleInfo,
  }) {
    final confidence = ((json['confidence'] as num?)?.toDouble() ?? 0.5)
        .clamp(0.0, 1.0);
    final priceLow  = (json['estimatedPriceLow']  as num?)?.toDouble() ?? 0.0;
    final priceHigh = (json['estimatedPriceHigh'] as num?)?.toDouble() ?? 0.0;

    const validDifficulties = ['Beginner', 'Intermediate', 'Advanced'];
    final rawDifficulty = json['repairDifficulty'] as String? ?? '';
    final difficulty = validDifficulties.contains(rawDifficulty)
        ? rawDifficulty
        : 'Intermediate';

    // Backend may send a pre-formatted priceEstimate; fall back to computing it
    final priceEstimate = (json['priceEstimate'] as String?)?.isNotEmpty == true
        ? json['priceEstimate'] as String
        : (priceLow > 0
            ? '\$${priceLow.toStringAsFixed(0)} – \$${priceHigh.toStringAsFixed(0)}'
            : 'Price unavailable');

    // Buy options — backend sends them; parse or fall back to placeholders
    final rawBuyOptions = json['buyOptions'];
    final buyOptions = (rawBuyOptions is List)
        ? rawBuyOptions
            .map((o) => BuyOption(
                  store:      (o['store']      as String?) ?? '',
                  priceRange: (o['priceRange'] as String?) ?? 'Search on site',
                  url:        (o['url']        as String?) ?? '',
                ))
            .toList()
        : const [
            BuyOption(store: 'AutoZone',      priceRange: 'Search on site', url: 'autozone.com'),
            BuyOption(store: 'RockAuto',      priceRange: 'Search on site', url: 'rockauto.com'),
            BuyOption(store: "O'Reilly Auto", priceRange: 'Search on site', url: 'oreillyauto.com'),
          ];

    return ScanResult(
      id:          DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath:   imagePath,
      vehicleInfo: vehicleInfo,
      scannedAt:   DateTime.now(),

      partName:        json['partName']    as String? ?? 'Unknown Part',
      confidenceScore: confidence,
      explanation:     json['explanation'] as String? ?? '',
      fitmentWarning:  json['fitmentWarning'] as String? ??
          'Always verify fitment using your VIN before purchasing.',

      priceEstimate:      priceEstimate,
      estimatedPriceLow:  priceLow,
      estimatedPriceHigh: priceHigh,

      repairDifficulty: difficulty,
      toolsNeeded:      _safeStringList(json['toolsNeeded']),
      repairSteps:      _safeStringList(json['repairSteps']),

      suggestedSearchTerms: _safeStringList(json['suggestedSearchTerms']),
      safetyWarnings:       _safeStringList(json['safetyWarnings']),
      compatibleParts:      _safeStringList(json['compatibleParts']),

      buyOptions: buyOptions,
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/recall_alert.dart';

class RecallService {
  static const _nhtsaBase =
      'https://api.nhtsa.gov/recalls/recallsByVehicle';

  static String nhtsaSearchUrl({
    required String year,
    required String make,
    required String model,
  }) {
    final y  = Uri.encodeComponent(year);
    final mk = Uri.encodeComponent(make.toUpperCase());
    final mo = Uri.encodeComponent(model.toUpperCase());
    return '$_nhtsaBase?make=$mk&model=$mo&modelYear=$y';
  }

  static Future<List<RecallAlert>> fetchRecalls({
    required String year,
    required String make,
    required String model,
  }) async {
    final url = nhtsaSearchUrl(year: year, make: make, model: model);
    debugPrint('[RecallService] GET $url');
    try {
      final response = await http
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      debugPrint('[RecallService] status ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('[RecallService] error body: ${response.body}');
        throw RecallFetchException(
            'NHTSA returned HTTP ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'];
      if (results is! List) return [];

      return results
          .map((r) => _fromNhtsa(r as Map<String, dynamic>))
          .toList();
    } on TimeoutException {
      throw const RecallFetchException('Request timed out — check your connection.');
    } on RecallFetchException {
      rethrow;
    } catch (e) {
      debugPrint('[RecallService] unexpected error: $e');
      throw RecallFetchException('Unable to load recalls: ${e.runtimeType}');
    }
  }

  static RecallAlert _fromNhtsa(Map<String, dynamic> r) {
    final component = (r['Component'] as String? ?? '').toLowerCase();
    RecallSeverity severity;
    if (component.contains('brake') ||
        component.contains('air bag') ||
        component.contains('fuel') ||
        component.contains('steering') ||
        component.contains('seatbelt')) {
      severity = RecallSeverity.safety;
    } else if (component.contains('emission') || component.contains('nox')) {
      severity = RecallSeverity.emissions;
    } else {
      severity = RecallSeverity.defect;
    }

    DateTime reportedDate;
    try {
      final raw = r['ReportReceivedDate'] as String? ?? '';
      final ms  = int.parse(raw.replaceAll(RegExp(r'[^0-9]'), ''));
      reportedDate = DateTime.fromMillisecondsSinceEpoch(ms);
    } catch (_) {
      reportedDate = DateTime.now();
    }

    return RecallAlert(
      id:           r['NHTSACampaignNumber'] as String? ?? '',
      title:        r['Subject']             as String? ?? 'Recall',
      description:  r['Summary']             as String? ?? '',
      component:    r['Component']           as String? ?? '',
      severity:     severity,
      remedy:       r['Remedy']              as String? ?? 'Contact dealer.',
      nhtsaNumber:  r['NHTSACampaignNumber'] as String? ?? '',
      reportedDate: reportedDate,
      isMock:       false,
    );
  }
}

class RecallFetchException implements Exception {
  final String message;
  const RecallFetchException(this.message);
  @override
  String toString() => message;
}

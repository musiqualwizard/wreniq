import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ═══════════════════════════════════════════════════════════════════════════
// Wreniq Backend Config — single source of truth for all backend URLs.
//
// To change hosting: update baseUrl only. All endpoints derive from it.
// To disable the backend: set hasBackend = false (shows offline fallback).
// ═══════════════════════════════════════════════════════════════════════════
class BackendConfig {
  // ── Base URL ──────────────────────────────────────────────────────────────
  static const String baseUrl = 'https://wreniq-backend.onrender.com';

  // ── Endpoints (all derived from baseUrl — no manual string building) ──────
  static String get healthUrl       => '$baseUrl/health';
  static String get scanPartUrl     => '$baseUrl/api/scan-part';
  static String get mechanicChatUrl => '$baseUrl/api/mechanic-chat';
  static String get partsSearchUrl  => '$baseUrl/api/search-parts';

  // ── Request settings ──────────────────────────────────────────────────────
  // 90 s covers Render free-tier cold starts (~50 s) + OpenAI processing time.
  static const Duration timeout  = Duration(seconds: 90);
  static const int maxImageBytes = 4 * 1024 * 1024; // 4 MB

  // Set to false to force offline/mock mode regardless of network availability.
  static const bool hasBackend = true;

  // ── Health check ──────────────────────────────────────────────────────────
  /// Calls GET /health. Returns (isOk, humanReadableMessage).
  /// Uses a short 15 s timeout — just a ping, not a full AI call.
  static Future<(bool, String)> checkHealth() async {
    debugPrint('[BackendConfig] health check → $healthUrl');
    try {
      final response = await http
          .get(Uri.parse(healthUrl), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      debugPrint('[BackendConfig] health ${response.statusCode}  body: ${response.body}');
      if (response.statusCode == 200) {
        return (true, 'Connected (${response.statusCode} OK)');
      }
      return (false, 'Backend responded ${response.statusCode}');
    } on TimeoutException {
      return (false, 'Timed out — backend may be cold-starting (try again in 30 s).');
    } catch (e) {
      debugPrint('[BackendConfig] health check error: $e');
      return (false, 'Unreachable: ${e.runtimeType}');
    }
  }
}

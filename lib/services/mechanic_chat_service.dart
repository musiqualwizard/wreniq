import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/backend_config.dart';
import '../models/chat_message.dart';
import '../models/scan_result.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MechanicChatService
//
// Flutter → POST /api/mechanic-chat → backend → OpenAI → reply
// OpenAI key lives on the backend only — never in Flutter.
//
// Fallback: returns offlineMessage only after a genuine failure
// (timeout, network error, non-200). Errors are always logged.
// ─────────────────────────────────────────────────────────────────────────────
class MechanicChatService {
  static const offlineMessage =
      'Wreniq AI is not responding right now. '
      'The backend may be waking up (Render free tier). '
      'Please wait 30 seconds and try again.';

  static Future<String> send({
    required String message,
    required List<ChatMessage> history,
    String? vehicleInfo,
    ScanResult? scan,
  }) async {
    if (!BackendConfig.hasBackend) {
      debugPrint('[MechanicChat] hasBackend=false — returning offline message');
      return offlineMessage;
    }

    debugPrint('[MechanicChat] baseUrl  : ${BackendConfig.baseUrl}');
    debugPrint('[MechanicChat] chatUrl  : ${BackendConfig.mechanicChatUrl}');
    debugPrint('[MechanicChat] timeout  : ${BackendConfig.timeout.inSeconds}s');

    try {
      return await _backendSend(
        message:     message,
        history:     history,
        vehicleInfo: vehicleInfo ?? '',
        scanContext: scan != null ? _scanContext(scan) : '',
      );
    } on TimeoutException {
      debugPrint('[MechanicChat] request timed out after ${BackendConfig.timeout.inSeconds}s');
      return 'Request timed out. The backend may be cold-starting — please try again in 30 seconds.';
    } catch (e) {
      debugPrint('[MechanicChat] error (${e.runtimeType}): $e');
      return offlineMessage;
    }
  }

  // ── Backend call ───────────────────────────────────────────────────────────
  static Future<String> _backendSend({
    required String message,
    required List<ChatMessage> history,
    required String vehicleInfo,
    required String scanContext,
  }) async {
    final uri  = Uri.parse(BackendConfig.mechanicChatUrl);
    final body = jsonEncode({
      'message':     message,
      'vehicleInfo': vehicleInfo,
      'scanContext': scanContext,
      'history':     history.map((m) => m.toOpenAiMessage()).toList(),
    });

    debugPrint('[MechanicChat] POST ${uri.toString()}');
    debugPrint('[MechanicChat] req  : message(${message.length}c) vehicleInfo(${vehicleInfo.length}c) scanContext(${scanContext.length}c) history(${history.length})');
    debugPrint('[MechanicChat] body : ${body.length} bytes');

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept':       'application/json',
          },
          body: body,
        )
        .timeout(BackendConfig.timeout);

    debugPrint('[MechanicChat] status  : ${response.statusCode}');
    debugPrint('[MechanicChat] body    : ${response.body}');

    if (response.statusCode != 200) {
      // Surface the backend's error message when available.
      String detail = 'Backend returned ${response.statusCode}.';
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['error'] != null) detail = json['error'].toString();
      } catch (_) {}
      debugPrint('[MechanicChat] ERROR   : $detail');
      throw Exception('[MechanicChat] $detail');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final reply = data['reply'] as String?;
    if (reply == null || reply.isEmpty) {
      debugPrint('[MechanicChat] ERROR   : response has no "reply" field');
      throw Exception('[MechanicChat] Unexpected response shape — no "reply" field.');
    }

    debugPrint('[MechanicChat] reply   : ${reply.length} chars received');
    return reply;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  static String _scanContext(ScanResult scan) {
    final parts = <String>[];
    if (scan.partName.isNotEmpty)         parts.add('Part: ${scan.partName}');
    if (scan.repairDifficulty.isNotEmpty) parts.add('Difficulty: ${scan.repairDifficulty}');
    if (scan.priceEstimate.isNotEmpty)    parts.add('Price range: ${scan.priceEstimate}');
    if (scan.toolsNeeded.isNotEmpty)      parts.add('Tools: ${scan.toolsNeeded.join(', ')}');
    if (scan.fitmentWarning.isNotEmpty)   parts.add('Fitment note: ${scan.fitmentWarning}');
    return parts.join('. ');
  }
}

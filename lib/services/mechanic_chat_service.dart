import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/chat_message.dart';
import '../models/scan_result.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MechanicChatService
//
// Flutter → POST /api/mechanic-chat → backend → OpenAI text model → reply
// OpenAI key stays on the backend; never in Flutter.
//
// Offline / no-backend fallback: returns a static notice string so the UI
// always gets something meaningful back.
// ─────────────────────────────────────────────────────────────────────────────
class MechanicChatService {
  static const offlineMessage =
      'Wreniq AI chat is offline. Start the backend to enable live answers.';

  static Future<String> send({
    required String message,
    required List<ChatMessage> history,
    String? vehicleInfo,
    ScanResult? scan,
  }) async {
    if (!ApiConfig.hasBackend) return offlineMessage;
    try {
      return await _backendSend(
        message:     message,
        history:     history,
        vehicleInfo: vehicleInfo ?? '',
        scanContext: scan != null ? _scanContext(scan) : '',
      );
    } catch (_) {
      return offlineMessage;
    }
  }

  // ── Backend call ──────────────────────────────────────────────────────────
  static Future<String> _backendSend({
    required String message,
    required List<ChatMessage> history,
    required String vehicleInfo,
    required String scanContext,
  }) async {
    final uri  = Uri.parse(ApiConfig.mechanicChatUrl);
    final body = jsonEncode({
      'message':     message,
      'vehicleInfo': vehicleInfo,
      'scanContext': scanContext,
      'history':     history.map((m) => m.toOpenAiMessage()).toList(),
    });

    final response = await http
        .post(uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept':       'application/json',
            },
            body: body)
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw Exception('Backend chat error ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['reply'] as String?) ?? offlineMessage;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static String _scanContext(ScanResult scan) {
    final parts = <String>[];
    if (scan.partName.isNotEmpty)         parts.add('Part: ${scan.partName}');
    if (scan.repairDifficulty.isNotEmpty) parts.add('Difficulty: ${scan.repairDifficulty}');
    if (scan.priceRange.isNotEmpty)       parts.add('Price range: ${scan.priceRange}');
    if (scan.toolsNeeded.isNotEmpty)      parts.add('Tools: ${scan.toolsNeeded.join(', ')}');
    if (scan.fitmentWarning.isNotEmpty)   parts.add('Fitment note: ${scan.fitmentWarning}');
    return parts.join('. ');
  }
}

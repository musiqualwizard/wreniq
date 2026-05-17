// ═══════════════════════════════════════════════════════════════════════════
// Wreniq Backend Configuration
// ═══════════════════════════════════════════════════════════════════════════
//
// Flutter never calls OpenAI directly — all AI calls go through the Wreniq
// backend (backend/server.js) which holds the API key server-side.
//
// ── HOW TO SWITCH TARGETS ────────────────────────────────────────────────
//
//   Change `_target` to the right option for your build:
//
//   _BackendTarget.androidEmulator
//     → 192.168.12.154:5050  (host machine localhost from the Android emulator)
//     → Use when running `flutter run` on an Android emulator with the
//       backend running locally.
//
//   _BackendTarget.hosted
//     → _hostedBase below  (your deployed backend URL)
//     → Replace 'https://your-backend.example.com' with the real URL first,
//       then switch _target to this value for physical device builds / APK.
//
// ── HOW TO RUN LOCALLY ───────────────────────────────────────────────────
//   1. cd backend && npm install
//   2. cp .env.example .env  → paste OPENAI_API_KEY
//   3. node server.js        → backend on port 5050
//   4. flutter run
//
// ═══════════════════════════════════════════════════════════════════════════

enum _BackendTarget { androidEmulator, hosted }

class ApiConfig {
  // ── ▼  CHANGE THIS LINE to switch targets  ▼ ──────────────────────────
  static const _BackendTarget _target = _BackendTarget.androidEmulator;
  // ── ▲  CHANGE THIS LINE to switch targets  ▲ ──────────────────────────

  // Android emulator: 10.0.2.2 routes to the host machine's localhost.
  static const String _androidEmulatorBase = 'http://192.168.12.154:5050';

  // Hosted backend: replace with your deployed URL before switching target.
  static const String _hostedBase = 'https://your-backend.example.com';

  // ── Resolved base URL ─────────────────────────────────────────────────
  static String get _baseUrl => switch (_target) {
        _BackendTarget.androidEmulator => _androidEmulatorBase,
        _BackendTarget.hosted          => _hostedBase,
      };

  // ── API endpoints ─────────────────────────────────────────────────────
  static String get backendUrl      => '$_baseUrl/api/scan-part';
  static String get partsSearchUrl  => '$_baseUrl/api/search-parts';
  static String get mechanicChatUrl => '$_baseUrl/api/mechanic-chat';

  // ── Request settings ──────────────────────────────────────────────────
  // Vision calls can be slow. Give the backend ample time to call OpenAI.
  static const Duration requestTimeout = Duration(seconds: 60);

  // Client-side size guard before uploading. Backend enforces 4 MB too.
  static const int maxImageBytes = 4 * 1024 * 1024; // 4 MB

  // False when the hosted URL is still the placeholder — keeps the offline
  // fallback message showing until a real URL is configured.
  static bool get hasBackend =>
      _target == _BackendTarget.androidEmulator ||
      _hostedBase != 'https://your-backend.example.com';
}

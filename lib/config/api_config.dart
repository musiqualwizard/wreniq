// Thin compatibility shim — delegates everything to BackendConfig.
// Existing services (ai_scan_service, parts_search_service) import this and
// continue to work unchanged. New code should import BackendConfig directly.
import 'backend_config.dart';

class ApiConfig {
  static String   get backendUrl      => BackendConfig.scanPartUrl;
  static String   get partsSearchUrl  => BackendConfig.partsSearchUrl;
  static String   get mechanicChatUrl => BackendConfig.mechanicChatUrl;
  static Duration get requestTimeout  => BackendConfig.timeout;
  static int      get maxImageBytes   => BackendConfig.maxImageBytes;
  static bool     get hasBackend      => BackendConfig.hasBackend;
}

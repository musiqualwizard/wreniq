import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

/// Wraps Firebase initialization so the app never crashes if Firebase is
/// unreachable or misconfigured. Check [isAvailable] before using Firebase APIs.
class FirebaseService {
  static bool _isAvailable = false;
  static bool get isAvailable => _isAvailable;

  /// Call once from main() before runApp(). Never throws.
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isAvailable = true;
    } catch (_) {
      _isAvailable = false;
    }
  }
}

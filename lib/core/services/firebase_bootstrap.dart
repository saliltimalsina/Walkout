import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';

import '../constants/app_constants.dart';

/// Guarded Firebase startup. Everything here is a no-op (and never throws into
/// the app) until [AppConstants.firebaseEnabled] is true AND the native
/// google-services config exists (added by `flutterfire configure`). This lets
/// the app compile and run on bundled data before the backend is provisioned.
class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static bool _ready = false;
  static bool get isReady => _ready;

  /// Guards against two callers racing an init (e.g. the dataset load and the
  /// widget refresh both landing on a cold start).
  static Future<bool>? _inFlight;

  /// True once the FCM topic subscribe has landed, so we only retry it while it
  /// is still outstanding. Failure here must never block Firestore reads.
  static bool _subscribed = false;

  /// Initializes Firebase if enabled. Returns true when Firebase is live.
  static Future<bool> init() => _inFlight ??= _init().whenComplete(() {
        _inFlight = null;
      });

  /// Same as [init] but a no-op once ready. Call this before any Firestore read
  /// so a cold start that raced the network (or came up offline) can still reach
  /// the backend on a later attempt instead of being stuck on bundled data for
  /// the rest of the session.
  static Future<bool> ensureReady() async {
    if (_ready) return true;
    return init();
  }

  static Future<bool> _init() async {
    if (!AppConstants.firebaseEnabled) return false;
    if (!_ready) {
      try {
        // Re-entrant safe: a hot restart or a background isolate may already
        // have the default app registered.
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp();
        }
        _ready = true;
      } catch (e) {
        debugPrint('[firebase] init failed: $e');
        _ready = false;
        return false;
      }
    }
    // Push registration is a separate concern from data access — it needs a
    // network round trip (and an APNs token on iOS), so a failure here must
    // not flip _ready and silently strand the app on bundled data.
    if (!_subscribed) {
      try {
        await FirebaseMessaging.instance
            .subscribeToTopic(AppConstants.fcmTopic);
        _subscribed = true;
      } catch (e) {
        debugPrint('[firebase] topic subscribe deferred: $e');
      }
    }
    return _ready;
  }
}

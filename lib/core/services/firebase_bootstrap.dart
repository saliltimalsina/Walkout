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

  /// Initializes Firebase if enabled. Returns true when Firebase is live.
  static Future<bool> init() async {
    if (!AppConstants.firebaseEnabled) return false;
    try {
      await Firebase.initializeApp();
      // Subscribe to the data-changed topic so publishes reach this device.
      await FirebaseMessaging.instance.subscribeToTopic(AppConstants.fcmTopic);
      _ready = true;
    } catch (e) {
      debugPrint('[firebase] init skipped: $e');
      _ready = false;
    }
    return _ready;
  }
}

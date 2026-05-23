import 'package:flutter/foundation.dart';

class NotificationService {
  static Future<void> initialize() async {
    // Push notifications will be wired up in a later phase (P3).
    // Firebase / APNs initialization happens here when firebase_core is added.
    if (kDebugMode) {
      debugPrint('NotificationService: stub – no Firebase yet');
    }
  }
}

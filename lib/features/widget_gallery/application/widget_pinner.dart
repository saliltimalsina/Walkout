import 'dart:io';

import 'package:home_widget/home_widget.dart';

/// Thin wrapper over the Android "pin app widget" flow (API 26+). Maps a
/// [FaceSpec.providerClass] to its fully-qualified receiver name — the same
/// package `HomeWidgetService` broadcasts to.
abstract final class WidgetPinner {
  const WidgetPinner._();

  static const _pkg = 'com.walkout.walkout.widgets';

  /// False on iOS/desktop (the plugin has no pin path there), on Android < 8,
  /// and on launchers that don't support pinning.
  static Future<bool> isSupported() async {
    if (!Platform.isAndroid) return false;
    try {
      return await HomeWidget.isRequestPinWidgetSupported() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Shows the system pin sheet for [providerClass]. Returns as soon as the
  /// sheet is up — it does not await the user's confirmation.
  static Future<void> pin(String providerClass) => HomeWidget.requestPinWidget(
        qualifiedAndroidName: '$_pkg.$providerClass',
      );
}

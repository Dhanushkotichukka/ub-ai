import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Platform-aware link opener.
/// - Mobile: launches in external browser (or InAppWebView for supported platforms)
/// - Web: opens in new tab via dart:html
class LinkLauncher {
  static Future<void> open(String url, {bool inApp = true}) async {
    final uri = Uri.parse(url);

    if (kIsWeb) {
      // Flutter Web → new tab
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } else {
      // Flutter Mobile → in-app browser
      if (inApp) {
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  static Future<bool> canOpen(String url) async {
    return canLaunchUrl(Uri.parse(url));
  }
}

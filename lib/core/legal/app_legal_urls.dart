import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';

/// Public legal documents are served from the API origin (see `src/server.js`).
abstract final class AppLegalUrls {
  static Uri get privacyPolicy => Uri.parse('${ApiService.originUrl}/privacy-policy');
  static Uri get termsOfService => Uri.parse('${ApiService.originUrl}/terms-of-service');

  static Future<void> openPrivacy(BuildContext context) => _open(context, privacyPolicy);
  static Future<void> openTerms(BuildContext context) => _open(context, termsOfService);

  static Future<void> _open(BuildContext context, Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link. Check your browser or connection.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link.')),
        );
      }
    }
  }

  /// Compact row for login / profile footers.
  static Widget inlineTextButtons(BuildContext context) {
    final style = TextStyle(
      color: Colors.white.withValues(alpha: 0.55),
      fontSize: 12,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: Colors.white38,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        TextButton(
          onPressed: () => openPrivacy(context),
          child: Text('Privacy Policy', style: style),
        ),
        Text('|', style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 12)),
        TextButton(
          onPressed: () => openTerms(context),
          child: Text('Terms of Service', style: style),
        ),
      ],
    );
  }
}

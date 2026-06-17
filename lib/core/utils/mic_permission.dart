import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:permission_handler/permission_handler.dart';

class MicPermissionResult {
  final bool granted;
  final String? message;
  final bool openSettings;

  const MicPermissionResult({
    required this.granted,
    this.message,
    this.openSettings = false,
  });
}

Future<MicPermissionResult> ensureVoicePermissions({
  bool speechRecognition = false,
}) async {
  if (kIsWeb) {
    return const MicPermissionResult(
      granted: false,
      message: 'Voice capture is not supported in the browser.',
    );
  }

  final mic = await _request(Permission.microphone);
  if (!mic.granted) return mic;

  if (speechRecognition && defaultTargetPlatform == TargetPlatform.iOS) {
    return _request(Permission.speech);
  }

  return const MicPermissionResult(granted: true);
}

Future<MicPermissionResult> _request(Permission permission) async {
  var status = await permission.status;
  if (!status.isGranted) {
    status = await permission.request();
  }

  if (status.isGranted) {
    return const MicPermissionResult(granted: true);
  }

  if (status.isPermanentlyDenied || status.isRestricted) {
    return MicPermissionResult(
      granted: false,
      openSettings: true,
      message: _blockedMessage(permission),
    );
  }

  return MicPermissionResult(
    granted: false,
    message: _deniedMessage(permission),
  );
}

String _deniedMessage(Permission permission) {
  if (permission == Permission.speech) {
    return 'Speech recognition permission denied.';
  }
  return 'Microphone permission denied.';
}

String _blockedMessage(Permission permission) {
  if (permission == Permission.speech) {
    return 'Speech recognition is blocked. Open Settings and allow BallChart to use Speech Recognition.';
  }
  return 'Microphone access is blocked. Open Settings and allow BallChart to use the Microphone.';
}

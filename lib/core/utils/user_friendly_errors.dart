import 'dart:async';
import 'dart:io';

/// Maps any thrown value to copy that is safe to show in dialogs — no URLs,
/// stack traces, hostnames, or errno details.
class AuthDialogCopy {
  final String title;
  final String message;

  const AuthDialogCopy({required this.title, required this.message});
}

/// True if [raw] looks like a technical/network error string we must not show verbatim.
bool _looksTechnical(String raw) {
  final s = raw.toLowerCase();
  return s.contains('http://') ||
      s.contains('https://') ||
      s.contains('uri=') ||
      s.contains('uri:') ||
      s.contains('socketexception') ||
      s.contains('clientexception') ||
      s.contains('failed host lookup') ||
      s.contains('os error') ||
      s.contains('errno') ||
      s.contains('address associated') ||
      s.contains('connection refused') ||
      s.contains('connection reset') ||
      s.contains('handshakeexception') ||
      s.contains('certificate') ||
      s.contains('xmlhttp') ||
      s.contains('failed to fetch');
}

bool _isNetworkFailure(Object error, String s) {
  if (error is SocketException) return true;
  if (error is TimeoutException) return true;
  if (s.contains('socketexception')) return true;
  if (s.contains('clientexception')) return true;
  if (s.contains('failed host lookup')) return true;
  if (s.contains('no address associated')) return true;
  if (s.contains('network is unreachable')) return true;
  if (s.contains('connection refused')) return true;
  if (s.contains('connection timed out')) return true;
  if (s.contains('handshakeexception')) return true;
  if (s.contains('timeout')) return true;
  return false;
}

bool _isCredentialFailure(String s) {
  return s.contains('invalid admin credentials') ||
      s.contains('invalid coach credentials') ||
      s.contains('invalid player credentials') ||
      s.contains('invalid credentials') ||
      s.contains('unauthorized') ||
      s.contains('incorrect password') ||
      s.contains('wrong password') ||
      s.contains('email or password') ||
      s.contains('invalid email or password') ||
      RegExp(r'\b401\b').hasMatch(s);
}

AuthDialogCopy resolveAuthDialogCopy(Object error, {required bool isSignup}) {
  final raw = error.toString();
  final s = raw.toLowerCase();

  if (_isNetworkFailure(error, s)) {
    return AuthDialogCopy(
      title: isSignup ? 'No connection' : 'No internet connection',
      message:
          'We can’t reach the server. Check your Wi‑Fi or mobile data, then try again.',
    );
  }

  if (s.contains('server_error_')) {
    return AuthDialogCopy(
      title: isSignup ? 'Server busy' : 'Server issue',
      message:
          'The server couldn’t complete that request. Please try again in a few minutes.',
    );
  }

  if (_isCredentialFailure(s)) {
    return AuthDialogCopy(
      title: isSignup ? 'Couldn’t create account' : 'Sign-in failed',
      message: isSignup
          ? 'We couldn’t complete signup. If you already have an account, try signing in instead.'
          : 'That email or password doesn’t match our records. Double-check and try again, or reset your password.',
    );
  }

  // Backend / API messages we intentionally surface (short, no URLs)
  var cleaned = raw.replaceAll(RegExp(r'^Exception:\s*'), '').trim();
  if (cleaned.length > 200 || _looksTechnical(cleaned)) {
    return AuthDialogCopy(
      title: isSignup ? 'Something went wrong' : 'Something went wrong',
      message:
          'We couldn’t finish that request. Please try again in a moment. If it keeps happening, contact support.',
    );
  }

  return AuthDialogCopy(
    title: isSignup ? 'Signup issue' : 'Something went wrong',
    message: cleaned,
  );
}

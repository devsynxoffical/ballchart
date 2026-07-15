import '../services/api_service.dart';
import '../models/strategy_model.dart';

/// Best-effort YouTube video id from common URL shapes.
String? extractYoutubeVideoId(String? rawUrl) {
  final raw = (rawUrl ?? '').trim();
  if (raw.isEmpty) return null;

  Uri? uri;
  try {
    uri = Uri.parse(raw);
  } catch (_) {
    return null;
  }

  final host = uri.host.toLowerCase();
  if (host.contains('youtu.be')) {
    final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
    return id.isEmpty ? null : id;
  }

  if (host.contains('youtube.com') || host.contains('youtube-nocookie.com')) {
    final v = uri.queryParameters['v'];
    if (v != null && v.trim().isNotEmpty) return v.trim();

    final segments = uri.pathSegments;
    // /embed/ID, /shorts/ID, /live/ID, /v/ID
    for (var i = 0; i < segments.length - 1; i++) {
      final s = segments[i].toLowerCase();
      if (s == 'embed' || s == 'shorts' || s == 'live' || s == 'v') {
        final id = segments[i + 1];
        if (id.isNotEmpty) return id;
      }
    }
  }

  return null;
}

/// Public YouTube thumbnail for [videoUrl], or null if not a YouTube link.
String? youtubeThumbnailUrl(String? videoUrl, {String quality = 'hqdefault'}) {
  final id = extractYoutubeVideoId(videoUrl);
  if (id == null || id.isEmpty) return null;
  return 'https://img.youtube.com/vi/$id/$quality.jpg';
}

/// Persistable thumbnail for create/update: explicit value, else YouTube frame.
String? deriveStrategyThumbnailUrl({
  String? thumbnailUrl,
  String? videoUrl,
}) {
  final explicit = (thumbnailUrl ?? '').trim();
  if (explicit.isNotEmpty) return explicit;
  return youtubeThumbnailUrl(videoUrl);
}

/// Display URL for strategy cards/reels (resolved for device).
String resolveStrategyThumbnailDisplay(StrategyModel strategy) {
  final explicit = (strategy.thumbnailUrl ?? '').trim();
  if (explicit.isNotEmpty) {
    return ApiService.resolveMediaUrl(explicit);
  }

  final yt = youtubeThumbnailUrl(strategy.videoUrl);
  if (yt != null) return yt;

  final meta = strategy.metadata ?? const <String, dynamic>{};
  final diagram = (meta['localDiagramPath'] ?? meta['diagramUrl'] ?? '').toString().trim();
  if (diagram.isNotEmpty) {
    return ApiService.resolveMediaUrl(diagram);
  }

  return '';
}

bool strategyHasThumbnail(StrategyModel strategy) =>
    resolveStrategyThumbnailDisplay(strategy).trim().isNotEmpty;

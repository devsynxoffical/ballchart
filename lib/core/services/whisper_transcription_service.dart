import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:whisper_ggml/src/models/requests/transcribe_request_dto.dart';
import 'package:whisper_ggml/src/models/whisper_dto.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

/// Thrown when the user cancels the model download.
class WhisperDownloadCancelled implements Exception {
  const WhisperDownloadCancelled();
}

typedef _WReqNative = Pointer<Utf8> Function(Pointer<Utf8> body);

/// Offline speech-to-text for tactical commands.
///
/// The English Base model (~142 MB) is downloaded once, stored in the app's
/// private storage, and reused afterwards. Audio never leaves the device.
///
/// Android note: whisper_ggml always runs FFmpeg before inference. On Android
/// release APKs that step often hangs forever even when the input is already
/// 16 kHz mono WAV. We skip FFmpeg for WAV inputs and call libwhisper directly.
class WhisperTranscriptionService {
  static const WhisperModel _model = WhisperModel.baseEn;

  final WhisperController _controller = WhisperController();

  /// ggml-base.en.bin is ~141 MB; anything much smaller is a truncated
  /// download that whisper would silently fail on forever.
  static const int _minValidModelBytes = 130 * 1024 * 1024;

  /// True when a complete model file is already on this device.
  /// Deletes truncated/corrupt files so they get re-downloaded.
  Future<bool> isModelReady() async {
    final path = await _controller.getPath(_model);
    final file = File(path);
    if (!file.existsSync()) return false;
    if (file.lengthSync() < _minValidModelBytes) {
      try {
        file.deleteSync();
      } catch (_) {}
      return false;
    }
    return true;
  }

  /// Downloads the model with byte-level progress.
  ///
  /// [onProgress] receives 0.0–1.0 (or -1 when total size is unknown).
  /// When [isCancelled] returns true the download stops and the partial
  /// file is deleted.
  Future<void> downloadModel({
    void Function(double progress, int receivedBytes)? onProgress,
    bool Function()? isCancelled,
  }) async {
    if (await isModelReady()) return;

    final destination = File(await _controller.getPath(_model));
    await destination.parent.create(recursive: true);
    final tempFile = File('${destination.path}.download');

    final client = http.Client();
    IOSink? sink;
    try {
      final response = await client.send(
        http.Request('GET', _model.modelUri)..followRedirects = true,
      );
      if (response.statusCode != 200) {
        throw Exception('Model download failed (HTTP ${response.statusCode})');
      }

      final total = response.contentLength ?? -1;
      var received = 0;
      sink = tempFile.openWrite();
      await for (final chunk in response.stream) {
        if (isCancelled?.call() == true) {
          throw const WhisperDownloadCancelled();
        }
        sink.add(chunk);
        received += chunk.length;
        if (onProgress != null) {
          onProgress(total > 0 ? received / total : -1, received);
        }
      }
      await sink.flush();
      await sink.close();
      sink = null;

      if (total > 0 && tempFile.lengthSync() < total) {
        throw Exception('Model download was interrupted — please try again.');
      }
      await tempFile.rename(destination.path);
    } catch (_) {
      await sink?.close();
      if (tempFile.existsSync()) {
        try {
          tempFile.deleteSync();
        } catch (_) {}
      }
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Transcribes [audioPath] and returns the recognized text.
  ///
  /// Throws on real failures (bad model, unreadable audio) instead of
  /// returning an empty string, so callers can tell "silence" apart from
  /// "something is broken".
  Future<String> transcribe(
    String audioPath, {
    void Function(int percent)? onProgress,
  }) async {
    final audio = File(audioPath);
    if (!audio.existsSync() || audio.lengthSync() < 1024) {
      throw Exception('Recording file is missing or empty');
    }
    if (!await isModelReady()) {
      throw Exception('Voice model is missing — tap the mic again to download it');
    }

    final modelPath = await _controller.getPath(_model);
    final wavPath = await _ensureWavForWhisper(audioPath);

    // Progress callbacks go through NativeCallable.listener on the UI isolate.
    // Passing that into Isolate.run is fine on iOS but has been observed to
    // stall Android release builds, so Android gets a soft progress ticker.
    final useNativeProgress = onProgress != null && !Platform.isAndroid;
    final NativeCallable<Void Function(Int32)>? progressCallable =
        useNativeProgress
            ? NativeCallable<Void Function(Int32)>.listener(onProgress)
            : null;

    Timer? softProgress;
    var softPercent = 5;
    if (onProgress != null && !useNativeProgress) {
      onProgress(softPercent);
      softProgress = Timer.periodic(const Duration(milliseconds: 700), (_) {
        if (softPercent < 90) {
          softPercent += 3;
          onProgress(softPercent);
        }
      });
    }

    try {
      final request = TranscribeRequest(
        audio: wavPath,
        language: 'en',
        isNoTimestamps: true,
        // File transcription — realtime mode is for live streams only.
        isRealtime: false,
        threads: Platform.numberOfProcessors.clamp(2, 6),
        initialPrompt:
            'Basketball tactics. Player one, player two, player three, player '
            'four, player five. Pass, screen, cut, shoot, dribble, handoff, '
            'pick and roll, drive, wing, corner, elbow, paint, basket.',
        noContext: true,
        suppressNonSpeechTokens: true,
      );

      final result = await _invokeWhisper(
        TranscribeRequestDto.fromTranscribeRequest(
          request,
          modelPath,
          progressCallbackAddress: progressCallable?.nativeFunction.address,
        ),
      ).timeout(
        const Duration(seconds: 90),
        onTimeout: () => throw Exception(
          'Voice-to-text timed out on this device. Try a shorter command.',
        ),
      );

      if (result['text'] == null) {
        throw Exception(result['message']?.toString() ?? 'Transcription failed');
      }

      onProgress?.call(100);
      return (result['text'] as String).trim();
    } finally {
      softProgress?.cancel();
      progressCallable?.close();
    }
  }

  /// Whisper needs 16 kHz mono PCM WAV. Tactical recording already produces
  /// that format, so skip FFmpeg (which hangs on many Android release APKs).
  Future<String> _ensureWavForWhisper(String audioPath) async {
    final lower = audioPath.toLowerCase();
    if (lower.endsWith('.wav')) {
      return audioPath;
    }

    // Non-WAV fallback: try FFmpeg with a short timeout, then fall back.
    final out = File('$audioPath.wav');
    try {
      final converted = await WhisperAudioConvert(
        audioInput: File(audioPath),
        audioOutput: out,
      ).convert().timeout(const Duration(seconds: 12));
      if (converted != null && converted.existsSync()) {
        return converted.path;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FFmpeg convert skipped/failed: $e');
      }
    }
    return audioPath;
  }

  Future<Map<String, dynamic>> _invokeWhisper(WhisperRequestDto request) {
    return Isolate.run(() {
      final data = request.toRequestString().toNativeUtf8();
      try {
        final lib = _openLib();
        final fn = lib.lookupFunction<_WReqNative, _WReqNative>('request');
        final res = fn(data);
        try {
          return json.decode(res.toDartString()) as Map<String, dynamic>;
        } finally {
          malloc.free(res);
        }
      } finally {
        malloc.free(data);
      }
    });
  }

  static DynamicLibrary _openLib() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libwhisper.so');
    }
    if (Platform.isWindows) {
      return DynamicLibrary.open('whisper_ggml.dll');
    }
    if (Platform.isLinux) {
      return DynamicLibrary.open('libwhisper_ggml.so');
    }
    return DynamicLibrary.process();
  }
}

import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'api_service.dart';
import '../utils/mic_permission.dart';

class VoiceClip {
  final String localPath;
  final Duration duration;

  const VoiceClip({required this.localPath, required this.duration});
}

class VoiceNoteService {
  /// [playbackOnly] skips creating an [AudioRecorder] so play widgets do not
  /// grab the microphone / audio focus on Android.
  VoiceNoteService({
    AudioRecorder? recorder,
    AudioPlayer? player,
    bool playbackOnly = false,
  })  : _playbackOnly = playbackOnly,
        _recorder = playbackOnly ? null : (recorder ?? AudioRecorder()),
        _player = player ?? AudioPlayer() {
    unawaited(_configurePlayer());
  }

  factory VoiceNoteService.playback() => VoiceNoteService(playbackOnly: true);

  final bool _playbackOnly;
  AudioRecorder? _recorder;
  final AudioPlayer _player;
  final ApiService _api = ApiService();

  String? _activePath;
  DateTime? _startedAt;
  String? _currentlyPlayingSource;
  bool _playerReady = false;

  AudioRecorder get _rec {
    if (_playbackOnly) {
      throw StateError('This VoiceNoteService is playback-only');
    }
    return _recorder ??= AudioRecorder();
  }

  Future<void> _configurePlayer() async {
    if (_playerReady || kIsWeb) {
      _playerReady = true;
      return;
    }
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setAudioContext(
        AudioContextConfig(
          route: AudioContextConfigRoute.speaker,
          focus: AudioContextConfigFocus.gain,
        ).build(),
      );
    } catch (_) {
      // Older platforms may ignore context; playback can still work.
    }
    _playerReady = true;
  }

  Future<bool> ensureMicPermission() async {
    final result = await ensureVoicePermissions();
    return result.granted;
  }

  Future<String> _newTempPath() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  Future<bool> get isRecording async {
    if (_playbackOnly || _recorder == null) return false;
    return _rec.isRecording();
  }

  Future<void> startRecording() async {
    if (await isRecording) return;
    final permission = await ensureVoicePermissions();
    if (!permission.granted) {
      throw Exception(permission.message ?? 'Microphone permission denied');
    }
    _activePath = await _newTempPath();
    _startedAt = DateTime.now();

    // On Android prefer the recognition audio source so STT + recorder can
    // share better (default exclusive mic would kill live transcription).
    final config = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
            numChannels: 1,
            androidConfig: AndroidRecordConfig(
              audioSource: AndroidAudioSource.voiceRecognition,
            ),
          )
        : const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
            numChannels: 1,
          );

    await _rec.start(config, path: _activePath!);
  }

  Future<VoiceClip?> stopRecording() async {
    String? filePath;
    try {
      if (await isRecording) {
        filePath = await _rec.stop();
      }
    } catch (_) {}

    filePath ??= _activePath;
    _activePath = null;
    final started = _startedAt;
    _startedAt = null;

    if (filePath == null || filePath.isEmpty) return null;
    final file = File(filePath);
    if (!await file.exists()) return null;

    // Empty / focus-loss recordings are a few hundred bytes at most and cannot play.
    final bytes = await file.length();
    if (bytes < 512) {
      try {
        await file.delete();
      } catch (_) {}
      return null;
    }

    final elapsed = started != null ? DateTime.now().difference(started) : Duration.zero;
    final duration = elapsed.inMilliseconds < 200
        ? Duration(milliseconds: (bytes / 16).round().clamp(200, 600000))
        : elapsed;
    return VoiceClip(localPath: filePath, duration: duration);
  }

  Future<void> cancelRecording() async {
    try {
      if (await isRecording) {
        await _rec.stop();
      }
    } catch (_) {}
    final path = _activePath;
    _activePath = null;
    _startedAt = null;
    if (path != null) {
      final f = File(path);
      if (await f.exists()) await f.delete();
    }
  }

  Future<String> uploadClip(VoiceClip clip) async {
    final file = File(clip.localPath);
    if (!await file.exists()) {
      throw Exception('Voice file missing');
    }
    final res = await _api.uploadAudio(file);
    final url = res['url']?.toString() ?? '';
    if (url.isEmpty) throw Exception('Upload failed');
    return url;
  }

  Future<void> playUrl(String url) async {
    await _configurePlayer();
    final resolved = ApiService.resolveMediaUrl(url);
    if (resolved.isEmpty) {
      throw Exception('Voice URL is empty');
    }
    if (_currentlyPlayingSource == resolved) {
      await stopPlayback();
      return;
    }
    await _player.stop();
    _currentlyPlayingSource = resolved;
    await _player.play(UrlSource(resolved));
  }

  Future<void> playLocal(String path) async {
    await _configurePlayer();
    if (path.isEmpty) {
      throw Exception('Voice file path is empty');
    }
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('Voice file missing on device');
      }
      final bytes = await file.length();
      if (bytes < 512) {
        throw Exception('Voice file is empty — record again');
      }
    }
    if (_currentlyPlayingSource == path) {
      await stopPlayback();
      return;
    }
    await _player.stop();
    // Brief pause so Android releases the previous recorder focus.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    _currentlyPlayingSource = path;
    await _player.play(DeviceFileSource(path));
  }

  Future<void> stopPlayback() async {
    await _player.stop();
    _currentlyPlayingSource = null;
  }

  Stream<PlayerState> get playerStateStream => _player.onPlayerStateChanged;
  Stream<Duration> get positionStream => _player.onPositionChanged;
  Stream<Duration> get durationStream => _player.onDurationChanged;

  String? get currentlyPlayingSource => _currentlyPlayingSource;

  bool isPlayingSource(String source) =>
      _currentlyPlayingSource == source &&
      _player.state == PlayerState.playing;

  void dispose() {
    _recorder?.dispose();
    _player.dispose();
  }
}

import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'api_service.dart';

class VoiceClip {
  final String localPath;
  final Duration duration;

  const VoiceClip({required this.localPath, required this.duration});
}

class VoiceNoteService {
  VoiceNoteService({AudioRecorder? recorder, AudioPlayer? player})
      : _recorder = recorder ?? AudioRecorder(),
        _player = player ?? AudioPlayer();

  final AudioRecorder _recorder;
  final AudioPlayer _player;
  final ApiService _api = ApiService();

  String? _activePath;
  DateTime? _startedAt;
  String? _currentlyPlayingUrl;

  Future<bool> ensureMicPermission() async {
    if (kIsWeb) return false;
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<String> _newTempPath() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  Future<void> startRecording() async {
    if (await _recorder.isRecording()) return;
    if (!await ensureMicPermission()) {
      throw Exception('Microphone permission denied');
    }
    _activePath = await _newTempPath();
    _startedAt = DateTime.now();
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _activePath!,
    );
  }

  Future<VoiceClip?> stopRecording() async {
    if (!await _recorder.isRecording()) return null;
    final path = await _recorder.stop();
    final filePath = path ?? _activePath;
    _activePath = null;
    if (filePath == null || filePath.isEmpty) return null;
    final file = File(filePath);
    if (!await file.exists()) return null;
    final started = _startedAt;
    _startedAt = null;
    final elapsed = started != null ? DateTime.now().difference(started) : Duration.zero;
    return VoiceClip(localPath: filePath, duration: elapsed);
  }

  Future<void> cancelRecording() async {
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
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
    final resolved = ApiService.resolveMediaUrl(url);
    if (_currentlyPlayingUrl == resolved) {
      await _player.stop();
      _currentlyPlayingUrl = null;
      return;
    }
    await _player.stop();
    _currentlyPlayingUrl = resolved;
    await _player.play(UrlSource(resolved));
  }

  Future<void> playLocal(String path) async {
    await _player.stop();
    _currentlyPlayingUrl = path;
    await _player.play(DeviceFileSource(path));
  }

  Future<void> stopPlayback() async {
    await _player.stop();
    _currentlyPlayingUrl = null;
  }

  Stream<PlayerState> get playerStateStream => _player.onPlayerStateChanged;

  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}

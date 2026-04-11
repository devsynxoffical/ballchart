import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Client helpers for Phase 5 real-time tactical sync.
class TacticalSocketSync {
  TacticalSocketSync._();

  static void joinBattleRoom(IO.Socket socket, String battleId) {
    socket.emit('join_tactical_room', {'battleId': battleId});
  }

  static void emitAnimationFrame(IO.Socket socket, String battleId, Map<String, dynamic> frame) {
    socket.emit('TACTICAL_ANIMATION_FRAME', {
      'battleId': battleId,
      ...frame,
      'ts': DateTime.now().toUtc().millisecondsSinceEpoch,
    });
  }

  static void onRemoteFrames(IO.Socket socket, void Function(Map<String, dynamic> data) onData) {
    socket.on('TACTICAL_ANIMATION_FRAME', (raw) {
      if (raw is Map) onData(Map<String, dynamic>.from(raw));
    });
  }
}

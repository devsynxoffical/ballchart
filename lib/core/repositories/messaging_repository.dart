import '../models/messaging_models.dart';
import '../services/api_service.dart';
import 'dart:io';

class MessagingRepository {
  final ApiService _api = ApiService();

  Future<List<MessagingParticipant>> fetchEligibleContacts() async {
    final dynamic res = await _api.get('/messages/eligible-contacts');
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => MessagingParticipant.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ConversationSummary> createOrGetConversation(String participantId) async {
    final res = await _api.post('/messages/conversations', {'participantId': participantId});
    if (res is! Map) throw Exception('Invalid conversation response');
    return ConversationSummary.fromJson(Map<String, dynamic>.from(res));
  }

  Future<List<ConversationSummary>> fetchConversations() async {
    final dynamic res = await _api.get('/messages/conversations');
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => ConversationSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<MessagesPage> fetchMessages(String conversationId, {String? before}) async {
    var path = '/messages/conversations/$conversationId/messages?limit=50';
    if (before != null && before.isNotEmpty) path += '&before=$before';
    final dynamic res = await _api.get(path);
    if (res is Map) {
      final map = Map<String, dynamic>.from(res);
      final rawList = map['messages'];
      final peerRaw = map['peerLastReadAt'];
      DateTime? peer;
      if (peerRaw != null) {
        peer = DateTime.tryParse(peerRaw.toString());
      }
      final rawParts = map['participants'];
      final participants = rawParts is List
          ? rawParts
              .whereType<Map>()
              .map((e) => MessagingParticipant.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : <MessagingParticipant>[];
      final list = rawList is List
          ? rawList
              .whereType<Map>()
              .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : <ChatMessage>[];
      return MessagesPage(messages: list, peerLastReadAt: peer, participants: participants);
    }
    if (res is List) {
      final list = res
          .whereType<Map>()
          .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return MessagesPage(messages: list);
    }
    return MessagesPage(messages: []);
  }

  Future<ChatMessage> sendMessage(
    String conversationId,
    String body, {
    String? replyToMessageId,
  }) async {
    final map = <String, dynamic>{'body': body, 'type': 'text'};
    if (replyToMessageId != null && replyToMessageId.isNotEmpty) {
      map['replyToMessageId'] = replyToMessageId;
    }
    final res = await _api.post('/messages/conversations/$conversationId/messages', map);
    if (res is! Map) throw Exception('Invalid message response');
    return ChatMessage.fromJson(Map<String, dynamic>.from(res));
  }

  Future<ChatMessage> sendVoiceMessage(
    String conversationId, {
    required String voiceUrl,
    required int voiceDurationMs,
    String? replyToMessageId,
  }) async {
    final map = <String, dynamic>{
      'type': 'voice',
      'voiceUrl': voiceUrl,
      'voiceDurationMs': voiceDurationMs,
      'body': '🎤 Voice message',
    };
    if (replyToMessageId != null && replyToMessageId.isNotEmpty) {
      map['replyToMessageId'] = replyToMessageId;
    }
    final res = await _api.post('/messages/conversations/$conversationId/messages', map);
    if (res is! Map) throw Exception('Invalid message response');
    return ChatMessage.fromJson(Map<String, dynamic>.from(res));
  }

  Future<void> markRead(String conversationId) async {
    await _api.post('/messages/conversations/$conversationId/read', {});
  }

  /// Uploads a PDF and sends it as an in-app message payload.
  /// Falls back to plain text with link if backend doesn't support `type:file`.
  Future<void> sendPdfMessage(
    String conversationId, {
    required File pdfFile,
    required String title,
  }) async {
    String? mediaUrl;
    Object? uploadErr;
    for (final endpoint in const ['/upload/file', '/upload/document', '/upload/image']) {
      try {
        final uploaded = await _api.uploadFile(endpoint, pdfFile, fieldName: 'file');
        mediaUrl = (uploaded['url'] ?? uploaded['fileUrl'] ?? uploaded['path'] ?? '').toString();
        if (mediaUrl.isNotEmpty) break;
      } catch (e) {
        uploadErr = e;
      }
    }

    if (mediaUrl == null || mediaUrl.isEmpty) {
      throw Exception(uploadErr?.toString() ?? 'Could not upload PDF');
    }

    final resolved = ApiService.resolveMediaUrl(mediaUrl);
    try {
      await _api.post('/messages/conversations/$conversationId/messages', {
        'type': 'file',
        'body': 'PDF report: $title',
        'fileUrl': mediaUrl,
        'fileName': pdfFile.path.replaceAll(r'\', '/').split('/').last,
        'mimeType': 'application/pdf',
      });
    } catch (_) {
      await sendMessage(conversationId, 'PDF report: $title\n$resolved');
    }
  }
}

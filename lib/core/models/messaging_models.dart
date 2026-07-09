int _toUnreadInt(dynamic raw) {
  if (raw is num) return raw.toInt().clamp(0, 999);
  if (raw is String) return (int.tryParse(raw) ?? 0).clamp(0, 999);
  if (raw is bool) return raw ? 1 : 0;
  return 0;
}

int _parseUnread(Map<String, dynamic> json) {
  final direct = json['unreadCount'] ??
      json['unread'] ??
      json['unreadMessages'] ??
      json['unread_messages'] ??
      json['newMessagesCount'];
  final v = _toUnreadInt(direct);
  if (v > 0) return v;

  final counters = json['counters'];
  if (counters is Map) {
    final nested = _toUnreadInt(counters['unreadMessages'] ?? counters['unreadCount']);
    if (nested > 0) return nested;
  }
  return 0;
}

class ConversationSummary {
  final String id;
  final String lastMessagePreview;
  final DateTime? lastMessageAt;
  final MessagingParticipant? other;
  /// `direct` (1:1) or `team` (group for one roster).
  final String kind;
  final String? teamId;
  final String? teamName;
  final int unreadCount;

  ConversationSummary({
    required this.id,
    required this.lastMessagePreview,
    this.lastMessageAt,
    this.other,
    this.kind = 'direct',
    this.teamId,
    this.teamName,
    this.unreadCount = 0,
  });

  bool get isTeamGroup => kind == 'team';

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    final k = (json['kind'] ?? 'direct').toString();
    return ConversationSummary(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      lastMessagePreview: json['lastMessagePreview']?.toString() ?? '',
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'].toString())
          : null,
      other: json['other'] is Map
          ? MessagingParticipant.fromJson(Map<String, dynamic>.from(json['other'] as Map))
          : null,
      kind: k,
      teamId: json['teamId']?.toString(),
      teamName: json['teamName']?.toString(),
      unreadCount: _parseUnread(json),
    );
  }
}

class MessagingParticipant {
  final String id;
  final String username;
  final String role;
  final String? email;
  /// Resolved media path or absolute URL from API (`avatarUrl`).
  final String? avatarUrl;

  MessagingParticipant({
    required this.id,
    required this.username,
    required this.role,
    this.email,
    this.avatarUrl,
  });

  factory MessagingParticipant.fromJson(Map<String, dynamic> json) {
    return MessagingParticipant(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      username: json['username']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      email: json['email']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String body;
  final String type;
  final String? voiceUrl;
  final String? fileUrl;
  final String? fileName;
  final String? mimeType;
  final int voiceDurationMs;
  final DateTime? createdAt;
  final String? replyToMessageId;
  final String? replyBody;
  final String? replySenderId;
  /// Client-only: optimistic send in flight.
  final bool pending;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.body,
    this.type = 'text',
    this.voiceUrl,
    this.fileUrl,
    this.fileName,
    this.mimeType,
    this.voiceDurationMs = 0,
    this.createdAt,
    this.replyToMessageId,
    this.replyBody,
    this.replySenderId,
    this.pending = false,
  });

  bool get isVoice => type == 'voice';
  bool get isFile => type == 'file' || (fileUrl?.isNotEmpty ?? false) || (mimeType?.contains('pdf') ?? false);

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      senderId: (json['senderId'] ?? '').toString(),
      body: json['body']?.toString() ?? '',
      type: (json['type'] ?? 'text').toString(),
      voiceUrl: json['voiceUrl']?.toString(),
      fileUrl: (json['fileUrl'] ?? json['attachmentUrl'] ?? json['url'])?.toString(),
      fileName: (json['fileName'] ?? json['attachmentName'])?.toString(),
      mimeType: (json['mimeType'] ?? json['contentType'])?.toString(),
      voiceDurationMs: (json['voiceDurationMs'] is num) ? (json['voiceDurationMs'] as num).toInt() : 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      replyToMessageId: json['replyToMessageId']?.toString(),
      replyBody: json['replyBody']?.toString(),
      replySenderId: json['replySenderId']?.toString(),
      pending: json['pending'] == true,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? body,
    String? type,
    String? voiceUrl,
    String? fileUrl,
    String? fileName,
    String? mimeType,
    int? voiceDurationMs,
    DateTime? createdAt,
    String? replyToMessageId,
    String? replyBody,
    String? replySenderId,
    bool? pending,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      body: body ?? this.body,
      type: type ?? this.type,
      voiceUrl: voiceUrl ?? this.voiceUrl,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      voiceDurationMs: voiceDurationMs ?? this.voiceDurationMs,
      createdAt: createdAt ?? this.createdAt,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyBody: replyBody ?? this.replyBody,
      replySenderId: replySenderId ?? this.replySenderId,
      pending: pending ?? this.pending,
    );
  }
}

/// GET messages response (peer read cursor for ticks).
class MessagesPage {
  final List<ChatMessage> messages;
  final DateTime? peerLastReadAt;
  /// Present for team threads: roster + coaches (for names on bubbles).
  final List<MessagingParticipant> participants;

  MessagesPage({
    required this.messages,
    this.peerLastReadAt,
    this.participants = const [],
  });
}

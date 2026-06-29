int _parseUnread(Map<String, dynamic> json) {
  final raw = json['unreadCount'] ?? json['unread'];
  if (raw is num) return raw.toInt().clamp(0, 999);
  if (raw == true) return 1;
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
    this.voiceDurationMs = 0,
    this.createdAt,
    this.replyToMessageId,
    this.replyBody,
    this.replySenderId,
    this.pending = false,
  });

  bool get isVoice => type == 'voice';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      senderId: (json['senderId'] ?? '').toString(),
      body: json['body']?.toString() ?? '',
      type: (json['type'] ?? 'text').toString(),
      voiceUrl: json['voiceUrl']?.toString(),
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

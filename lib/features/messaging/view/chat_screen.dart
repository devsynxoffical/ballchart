import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ballchart/core/utils/app_messenger.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:ballchart/core/models/local_academy_models.dart';
import 'package:ballchart/core/models/messaging_models.dart';
import 'package:ballchart/core/repositories/messaging_repository.dart';
import 'package:ballchart/core/services/api_service.dart';
import 'package:ballchart/core/services/voice_note_service.dart';
import 'package:ballchart/core/utils/mic_permission.dart';
import 'package:ballchart/core/widgets/messaging/voice_note_bubble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ballchart/features/messaging/widgets/chat_participant_profile_sheet.dart';
import 'package:ballchart/features/messaging/widgets/messaging_avatar.dart';
import 'package:ballchart/features/player/view/player_detail_screen.dart';
import 'package:ballchart/features/profile/viewmodel/profile_viewmodel.dart';
import 'package:ballchart/features/inbox/viewmodel/inbox_viewmodel.dart';
import 'package:ballchart/core/widgets/in_app_pdf_viewer_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherName,
    required this.otherId,
    this.myUserId,
    this.otherAvatarUrl,
    this.otherEmail,
    this.otherRole,
    this.isTeamGroup = false,
  });

  final String conversationId;
  final String otherName;
  final String otherId;
  final String? myUserId;
  final String? otherAvatarUrl;
  final String? otherEmail;
  final String? otherRole;
  /// Whole-team thread (players + coaches); titles use [otherName] as team label.
  final bool isTeamGroup;

  static const Color primaryColor = Color(0xFFFFD900);
  static const Color bgColor = Color(0xFF131313);
  static const Color bubbleOther = Color(0xFF1F2C33);
  static const Color bubbleMine = Color(0xFF2A3942);
  static const Color outlineColor = Color(0xFF9D8F79);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _DateRow {
  _DateRow(this.anchor);
  final DateTime anchor;
}

class _MsgRow {
  _MsgRow(this.index);
  final int index;
}

class _ChatScreenState extends State<ChatScreen> {
  final MessagingRepository _repo = MessagingRepository();
  final ApiService _api = ApiService();
  final VoiceNoteService _voiceSvc = VoiceNoteService();
  final TextEditingController _text = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _inputFocus = FocusNode();
  List<ChatMessage> _messages = [];
  /// Other participant's last read time — drives double-tick (seen).
  DateTime? _peerLastReadAt;
  bool _syncing = true;
  String? _loadError;
  bool _sending = false;
  bool _recordingVoice = false;
  int _recordingElapsedSec = 0;
  Timer? _recordingTimer;
  bool _initialScrollDone = false;
  ChatMessage? _replyingTo;
  List<MessagingParticipant> _roster = [];
  final Map<String, String> _nameByUserId = {};
  final Map<String, String?> _avatarByUserId = {};
  final Map<String, String> _pendingVoiceLocalPaths = {};

  @override
  void initState() {
    super.initState();
    _api.connectSocket();
    _socketSub();
    _load(animatedScroll: false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  void _socketSub() {
    final s = _api.socket;
    if (s == null) return;
    s.on('MESSAGE_NEW', _onMessageNewSocket);
    s.on('CONVERSATION_READ', _onConversationReadSocket);
  }

  void _onMessageNewSocket(dynamic data) {
    if (data is! Map) return;
    final cid = data['conversationId']?.toString();
    if (cid != widget.conversationId) return;
    if (!mounted) return;
    _ingestIncomingMessage(Map<String, dynamic>.from(data));
    // Viewing this thread — keep it marked read so the home badge clears.
    _markRead();
  }

  void _onConversationReadSocket(dynamic data) {
    if (widget.isTeamGroup) return;
    if (data is! Map) return;
    if (data['conversationId']?.toString() != widget.conversationId) return;
    final rid = data['readerUserId']?.toString();
    if (rid != widget.otherId) return;
    final raw = data['lastReadAt']?.toString();
    final parsed = raw != null ? DateTime.tryParse(raw) : null;
    if (parsed == null || !mounted) return;
    final local = parsed.toLocal();
    setState(() {
      if (_peerLastReadAt == null || local.isAfter(_peerLastReadAt!)) {
        _peerLastReadAt = local;
      }
    });
  }

  @override
  void dispose() {
    final s = _api.socket;
    s?.off('MESSAGE_NEW', _onMessageNewSocket);
    s?.off('CONVERSATION_READ', _onConversationReadSocket);
    _recordingTimer?.cancel();
    _voiceSvc.dispose();
    _text.dispose();
    _scroll.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    try {
      await _repo.markRead(widget.conversationId);
      if (!mounted) return;
      // Refresh home chat badge after messages are seen.
      await context.read<InboxViewModel>().refresh();
    } catch (_) {}
  }

  Future<void> _load({bool animatedScroll = true}) async {
    if (mounted) {
      setState(() {
        _syncing = true;
        _loadError = null;
      });
    }
    try {
      final page = await _repo.fetchMessages(widget.conversationId);
      if (!mounted) return;
      final peer = page.peerLastReadAt?.toLocal();
      setState(() {
        _messages = page.messages;
        _peerLastReadAt = peer;
        _syncing = false;
        _loadError = null;
        if (widget.isTeamGroup && page.participants.isNotEmpty) {
          _roster = List<MessagingParticipant>.from(page.participants);
          _nameByUserId
            ..clear()
            ..addEntries(_roster.map((p) => MapEntry(p.id, p.username)));
          _avatarByUserId
            ..clear()
            ..addEntries(_roster.map((p) => MapEntry(p.id, p.avatarUrl)));
        }
      });
      final useAnim = animatedScroll && _initialScrollDone;
      _scrollToEnd(animated: useAnim);
      _initialScrollDone = true;
    } catch (e) {
      if (mounted) {
        setState(() {
          _syncing = false;
          _loadError = '$e';
        });
      }
    }
  }

  void _ingestIncomingMessage(Map<String, dynamic> data) {
    try {
      final m = ChatMessage.fromJson(data);
      if (m.id.isEmpty) return;
      setState(() {
        _messages.removeWhere(
          (x) =>
              x.pending &&
              x.senderId == m.senderId &&
              (x.isVoice
                  ? m.isVoice
                  : x.body == m.body),
        );
        if (_messages.any((x) => x.id == m.id)) return;
        _messages.add(m);
        _messages.sort(
          (a, b) => _msgSortKey(a).compareTo(_msgSortKey(b)),
        );
      });
      _scrollToEnd(animated: true);
    } catch (_) {}
  }

  int _msgSortKey(ChatMessage m) {
    final t = m.createdAt;
    if (t == null) return 0;
    return t.millisecondsSinceEpoch;
  }

  void _scrollToEnd({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      if (animated) {
        _scroll.animateTo(
          max,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scroll.jumpTo(max);
      }
    });
  }

  String _userFacingSendError(Object error, {bool voice = false}) {
    final raw = error
        .toString()
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^Upload error:\s*'), '')
        .replaceFirst(RegExp(r'^Upload failed:\s*'), '')
        .trim();

    if (raw.contains('404') || raw.toLowerCase().contains('not found')) {
      return voice
          ? "Couldn't send voice message. Upload isn't available yet — please try again later."
          : "Couldn't send message. The server isn't ready yet — please try again later.";
    }
    if (raw.toLowerCase().contains('permission')) {
      return raw;
    }
    if (raw.contains('No audio captured')) {
      return 'No audio was recorded. Tap the mic, speak, then tap again to send.';
    }
    if (raw.contains('SocketException') ||
        raw.contains('Connection') ||
        raw.toLowerCase().contains('network')) {
      return "Couldn't send message. Check your connection and try again.";
    }
    return voice
        ? "Couldn't send voice message. Please try again."
        : "Couldn't send message. Please try again.";
  }

  void _showSendErrorSnackBar(String message) {
    AppMessenger.showSnackBar(context, 
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFB3261E),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _toggleVoiceNote() async {
    if (_sending) return;
    if (_recordingVoice) {
      _recordingTimer?.cancel();
      _recordingTimer = null;
      final myId = _myId(context);
      final replyId = _replyingTo?.id;
      final replyBody = _replyingTo?.isVoice == true ? '🎤 Voice message' : _replyingTo?.body;
      final replySenderId = _replyingTo?.senderId;
      final tempId = 'pending_voice_${DateTime.now().millisecondsSinceEpoch}';
      setState(() {
        _recordingVoice = false;
        _recordingElapsedSec = 0;
        _sending = true;
      });
      try {
        final clip = await _voiceSvc.stopRecording();
        if (clip == null) {
          throw Exception('No audio captured');
        }
        final optimistic = ChatMessage(
          id: tempId,
          senderId: myId,
          body: '🎤 Voice message',
          type: 'voice',
          voiceUrl: '',
          voiceDurationMs: clip.duration.inMilliseconds,
          createdAt: DateTime.now(),
          replyToMessageId: replyId,
          replyBody: replyBody,
          replySenderId: replySenderId,
          pending: true,
        );
        if (!mounted) return;
        setState(() {
          _messages.add(optimistic);
          _pendingVoiceLocalPaths[tempId] = clip.localPath;
          _replyingTo = null;
        });
        _scrollToEnd(animated: true);

        final voiceUrl = await _voiceSvc.uploadClip(clip);
        final saved = await _repo.sendVoiceMessage(
          widget.conversationId,
          voiceUrl: voiceUrl,
          voiceDurationMs: clip.duration.inMilliseconds,
          replyToMessageId: replyId,
        );
        if (!mounted) return;
        setState(() {
          final i = _messages.indexWhere((m) => m.id == tempId);
          if (i >= 0) {
            _messages[i] = saved.copyWith(pending: false);
          } else if (!_messages.any((m) => m.id == saved.id)) {
            _messages.add(saved);
          }
          _pendingVoiceLocalPaths.remove(tempId);
          _sending = false;
        });
        _scrollToEnd(animated: true);
      } catch (e) {
        if (mounted) {
          setState(() {
            _messages.removeWhere((m) => m.id == tempId);
            _pendingVoiceLocalPaths.remove(tempId);
            _sending = false;
          });
          _showSendErrorSnackBar(_userFacingSendError(e, voice: true));
        }
      }
      return;
    }

    final permission = await ensureVoicePermissions();
    if (!permission.granted) {
      if (mounted) {
        AppMessenger.showSnackBar(context, 
          SnackBar(
            content: Text(permission.message ?? 'Microphone permission denied'),
            backgroundColor: Colors.redAccent,
            action: permission.openSettings
                ? SnackBarAction(
                    label: 'Settings',
                    textColor: Colors.white,
                    onPressed: openAppSettings,
                  )
                : null,
          ),
        );
      }
      return;
    }

    try {
      await _voiceSvc.startRecording();
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _recordingElapsedSec += 1);
      });
      setState(() {
        _recordingVoice = true;
        _recordingElapsedSec = 0;
      });
    } catch (e) {
      if (mounted) {
        _showSendErrorSnackBar(_userFacingSendError(e, voice: true));
      }
    }
  }

  Future<void> _send() async {
    final t = _text.text.trim();
    if (t.isEmpty || _sending) return;
    final myId = _myId(context);
    final replyId = _replyingTo?.id;
    final tempId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = ChatMessage(
      id: tempId,
      senderId: myId,
      body: t,
      createdAt: DateTime.now(),
      replyToMessageId: _replyingTo?.id,
      replyBody: _replyingTo?.body,
      replySenderId: _replyingTo?.senderId,
      pending: true,
    );
    setState(() {
      _messages.add(optimistic);
      _replyingTo = null;
    });
    _text.clear();
    _scrollToEnd(animated: true);

    setState(() => _sending = true);
    try {
      final saved = await _repo.sendMessage(
        widget.conversationId,
        t,
        replyToMessageId: replyId,
      );
      if (!mounted) return;
      setState(() {
        final i = _messages.indexWhere((m) => m.id == tempId);
        if (i >= 0) {
          _messages[i] = saved.copyWith(pending: false);
        } else if (!_messages.any((m) => m.id == saved.id)) {
          _messages.add(saved);
        }
        _sending = false;
      });
      _scrollToEnd(animated: true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.id == tempId);
          _sending = false;
        });
        _showSendErrorSnackBar(_userFacingSendError(e));
      }
    }
  }

  bool _msgSeen(ChatMessage m, String myId) {
    if (m.senderId != myId || m.pending) return false;
    final pr = _peerLastReadAt;
    final ca = m.createdAt;
    if (pr == null || ca == null) return false;
    return !ca.toLocal().isAfter(pr);
  }

  String _myId(BuildContext context) {
    final fromWidget = widget.myUserId;
    if (fromWidget != null && fromWidget.isNotEmpty) return fromWidget.trim();
    return (context.read<ProfileViewmodel>().user?.id ?? '').trim();
  }

  bool _isMine(ChatMessage m, String myId) {
    final sid = m.senderId.trim();
    final mid = myId.trim();
    if (sid.isEmpty || mid.isEmpty) return false;
    return sid == mid;
  }

  bool _peerIsPlayer() {
    final r = (widget.otherRole ?? '').toLowerCase().trim();
    return r == 'player';
  }

  String _displayNameForSender(String senderId, String myId) {
    if (senderId == myId) return 'You';
    if (widget.isTeamGroup) {
      return _nameByUserId[senderId] ?? 'Member';
    }
    return widget.otherName;
  }

  String? _avatarUrlForSender(String senderId) {
    if (widget.isTeamGroup) {
      return _avatarByUserId[senderId];
    }
    return widget.otherAvatarUrl;
  }

  void _openParticipantFromRoster(String userId) {
    MessagingParticipant? p;
    for (final x in _roster) {
      if (x.id == userId) {
        p = x;
        break;
      }
    }
    if (p == null) return;
    final r = (p.role).toLowerCase().trim();
    if (r == 'player') {
      final pl = Player(
        id: p.id,
        name: p.username,
        email: p.email ?? '',
        position: '—',
        age: 0,
        profileImageUrl: p.avatarUrl,
      );
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PlayerDetailScreen(player: pl, canEdit: false),
        ),
      );
      return;
    }
    showChatParticipantProfileSheet(
      context,
      name: p.username,
      userId: p.id,
      email: p.email,
      role: p.role,
      avatarUrl: p.avatarUrl,
    );
  }

  void _openTeamRosterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ChatScreen.bgColor,
      isScrollControlled: true,
      builder: (ctx) {
        final listHeight = MediaQuery.sizeOf(ctx).height * 0.45;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherName.toUpperCase(),
                  style: const TextStyle(
                    color: ChatScreen.primaryColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Team chat · ${_roster.length} members',
                  style: TextStyle(color: ChatScreen.outlineColor.withValues(alpha: 0.9), fontSize: 13),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: listHeight,
                  child: ListView.separated(
                    itemCount: _roster.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF2A2A2A)),
                    itemBuilder: (_, i) {
                      final p = _roster[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: MessagingAvatar(name: p.username, imageUrl: p.avatarUrl, size: 40),
                        title: Text(p.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          p.role.replaceAll('_', ' '),
                          style: const TextStyle(color: ChatScreen.outlineColor, fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          _openParticipantFromRoster(p.id);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openPeerProfile() {
    if (widget.isTeamGroup) {
      _openTeamRosterSheet();
      return;
    }
    if (_peerIsPlayer()) {
      final p = Player(
        id: widget.otherId,
        name: widget.otherName,
        email: widget.otherEmail ?? '',
        position: '—',
        age: 0,
        profileImageUrl: widget.otherAvatarUrl,
      );
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PlayerDetailScreen(player: p, canEdit: false),
        ),
      );
      return;
    }
    showChatParticipantProfileSheet(
      context,
      name: widget.otherName,
      userId: widget.otherId,
      email: widget.otherEmail,
      role: widget.otherRole,
      avatarUrl: widget.otherAvatarUrl,
    );
  }

  void _startReply(ChatMessage m) {
    setState(() => _replyingTo = m);
    _inputFocus.requestFocus();
  }

  String _replyAuthorLabel(ChatMessage m, String myId) {
    final rs = m.replySenderId;
    if (rs == null || rs.isEmpty) {
      return widget.isTeamGroup ? 'Member' : widget.otherName;
    }
    if (rs == myId) return 'You';
    return _displayNameForSender(rs, myId);
  }

  bool _showTeamSenderName(int index, String myId) {
    if (!widget.isTeamGroup) return false;
    final m = _messages[index];
    if (m.senderId == myId) return false;
    if (index == 0) return true;
    return _messages[index - 1].senderId != m.senderId;
  }

  /// WhatsApp-style: show peer avatar only on the last bubble in a consecutive block from them.
  bool _showPeerAvatar(int index) {
    final myId = _myId(context);
    final m = _messages[index];
    if (m.senderId == myId) return false;
    final next = index + 1 < _messages.length ? _messages[index + 1] : null;
    if (next == null) return true;
    return next.senderId != m.senderId;
  }

  List<Object> _buildListRows() {
    final out = <Object>[];
    for (var i = 0; i < _messages.length; i++) {
      final m = _messages[i];
      final prev = i > 0 ? _messages[i - 1] : null;
      final needDate = i == 0 || !_sameCalendarDay(_effectiveDay(prev), _effectiveDay(m));
      if (needDate) {
        out.add(_DateRow(_dayAnchor(m.createdAt)));
      }
      out.add(_MsgRow(i));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final myId = _myId(context);
    final rows = _buildListRows();

    return Scaffold(
      backgroundColor: ChatScreen.bgColor,
      appBar: AppBar(
        backgroundColor: ChatScreen.bgColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 4,
        title: InkWell(
          onTap: _openPeerProfile,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Hero(
                  tag: 'chat_avatar_${widget.conversationId}',
                  child: widget.isTeamGroup
                      ? CircleAvatar(
                          radius: 20,
                          backgroundColor: ChatScreen.bubbleOther,
                          child: const Icon(Icons.groups_rounded, color: ChatScreen.primaryColor, size: 24),
                        )
                      : MessagingAvatar(
                          name: widget.otherName,
                          imageUrl: widget.otherAvatarUrl,
                          size: 40,
                          fontSize: 16,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.otherName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        widget.isTeamGroup
                            ? 'Team chat · tap for members'
                            : (_peerIsPlayer() ? 'Tap for player profile' : 'Tap for profile'),
                        style: TextStyle(
                          color: ChatScreen.outlineColor.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_syncing)
            const LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Color(0xFF1A1A1A),
              color: ChatScreen.primaryColor,
            ),
          if (_loadError != null)
            Material(
              color: const Color(0xFF3E1F1F),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _loadError!,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _load(animatedScroll: false),
                      child: const Text('Retry', style: TextStyle(color: ChatScreen.primaryColor)),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
                    color: ChatScreen.primaryColor,
                    backgroundColor: ChatScreen.bubbleOther,
                    onRefresh: () => _load(animatedScroll: false),
                    child: SlidableAutoCloseBehavior(
                      child: ListView.builder(
                        controller: _scroll,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        itemCount: rows.isEmpty ? 1 : rows.length,
                        itemBuilder: (context, listIndex) {
                            if (rows.isEmpty) {
                              return SizedBox(
                                height: MediaQuery.of(context).size.height * 0.42,
                                child: Center(
                                  child: Text(
                                    'Say hello — start the conversation.',
                                    style: TextStyle(color: ChatScreen.outlineColor.withValues(alpha: 0.9)),
                                  ),
                                ),
                              );
                            }
                            final row = rows[listIndex];
                            if (row is _DateRow) {
                              return _DateDividerChip(anchor: row.anchor);
                            }
                            if (row is! _MsgRow) return const SizedBox.shrink();
                            final index = row.index;
                            final m = _messages[index];
                            final mine = _isMine(m, myId);
                            final showAvatar = _showPeerAvatar(index);
                            final seen = mine && _msgSeen(m, myId);
                            final bubbleMaxW = MediaQuery.of(context).size.width * 0.75;
                            final bubble = _MessageBubble(
                              body: m.body,
                              mine: mine,
                              isVoice: m.isVoice,
                              isFile: m.isFile,
                              fileUrl: m.fileUrl,
                              fileName: m.fileName,
                              voiceUrl: m.voiceUrl,
                              voiceDurationMs: m.voiceDurationMs,
                              voiceLocalPath: _pendingVoiceLocalPaths[m.id],
                              formattedTime: m.createdAt != null ? _fmt(m.createdAt!) : '',
                              replyQuoteBody: m.replyBody,
                              replyQuoteLabel: (m.replyBody != null && m.replyBody!.isNotEmpty)
                                  ? _replyAuthorLabel(m, myId)
                                  : null,
                              pending: m.pending,
                              showReceipt: mine,
                              seen: seen,
                            );

                            // Keep bubble width intrinsic — Slidable expands to parent otherwise
                            // and both sides look like the same full-width row.
                            final slidableBubble = Align(
                              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: bubbleMaxW),
                                child: Slidable(
                                  key: ValueKey<String>('msg-${m.id}'),
                                  closeOnScroll: true,
                                  startActionPane: ActionPane(
                                    extentRatio: 0.28,
                                    motion: const DrawerMotion(),
                                    children: [
                                      SlidableAction(
                                        onPressed: (_) => _startReply(m),
                                        backgroundColor: const Color(0xFF3D4F57),
                                        foregroundColor: ChatScreen.primaryColor,
                                        icon: Icons.reply_rounded,
                                        label: 'Reply',
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ],
                                  ),
                                  child: bubble,
                                ),
                              ),
                            );

                            if (mine) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 48, bottom: 4),
                                child: slidableBubble,
                              );
                            }
                            return Padding(
                              padding: EdgeInsets.only(right: 28, bottom: showAvatar ? 10 : 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  SizedBox(
                                    width: 36,
                                    child: showAvatar
                                        ? InkWell(
                                            onTap: widget.isTeamGroup
                                                ? () => _openParticipantFromRoster(m.senderId)
                                                : _openPeerProfile,
                                            customBorder: const CircleBorder(),
                                            child: MessagingAvatar(
                                              name: _displayNameForSender(m.senderId, myId),
                                              imageUrl: _avatarUrlForSender(m.senderId),
                                              size: 32,
                                              fontSize: 13,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_showTeamSenderName(index, myId))
                                          Padding(
                                            padding: const EdgeInsets.only(left: 4, bottom: 3),
                                            child: Text(
                                              _displayNameForSender(m.senderId, myId),
                                              style: TextStyle(
                                                color: ChatScreen.primaryColor.withValues(alpha: 0.95),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        slidableBubble,
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
          ),
          if (_replyingTo != null)
            _ReplyComposerStrip(
              preview: _replyingTo!.isVoice ? '🎤 Voice message' : _replyingTo!.body,
              replyLabel: _replyingTo!.senderId == myId
                  ? 'You'
                  : _displayNameForSender(_replyingTo!.senderId, myId),
              onCancel: () => setState(() => _replyingTo = null),
            ),
          if (_recordingVoice)
            Material(
              color: const Color(0xFF2A1F1F),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.mic_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Recording ${_recordingElapsedSec}s — tap mic to send',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Material(
                    color: _recordingVoice
                        ? Colors.redAccent.withValues(alpha: 0.9)
                        : ChatScreen.bubbleOther.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: _toggleVoiceNote,
                      borderRadius: BorderRadius.circular(24),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          _recordingVoice ? Icons.stop_rounded : Icons.mic_rounded,
                          color: _recordingVoice ? Colors.white : ChatScreen.primaryColor,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _text,
                      focusNode: _inputFocus,
                      minLines: 1,
                      maxLines: 5,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Message',
                        hintStyle: TextStyle(color: ChatScreen.outlineColor.withValues(alpha: 0.55)),
                        filled: true,
                        fillColor: ChatScreen.bubbleOther.withValues(alpha: 0.85),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: ChatScreen.primaryColor, width: 1),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Material(
                    color: ChatScreen.primaryColor.withValues(alpha: _sending ? 0.45 : 1),
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: _sending ? null : _send,
                      borderRadius: BorderRadius.circular(24),
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(Icons.send_rounded, color: Colors.black, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) {
    final t = TimeOfDay.fromDateTime(d.toLocal());
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}

DateTime _effectiveDay(ChatMessage? m) {
  if (m == null) return _dayAnchor(null);
  return _dayAnchor(m.createdAt);
}

DateTime _dayAnchor(DateTime? d) {
  final x = d ?? DateTime.now();
  final l = x.toLocal();
  return DateTime(l.year, l.month, l.day);
}

bool _sameCalendarDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DateDividerChip extends StatelessWidget {
  const _DateDividerChip({required this.anchor});

  final DateTime anchor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2A3942).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            _dateDividerLabel(anchor),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

String _dateDividerLabel(DateTime dayAnchor) {
  final t = dayAnchor;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  if (t == today) return 'Today';
  if (t == yesterday) return 'Yesterday';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[t.month - 1]} ${t.day}, ${t.year}';
}

class _ReplyComposerStrip extends StatelessWidget {
  const _ReplyComposerStrip({
    required this.preview,
    required this.replyLabel,
    required this.onCancel,
  });

  final String preview;
  final String replyLabel;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A2428),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 4,
              height: 42,
              decoration: BoxDecoration(
                color: ChatScreen.primaryColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Replying to $replyLabel',
                    style: TextStyle(
                      color: ChatScreen.primaryColor.withValues(alpha: 0.95),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13, height: 1.25),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onCancel,
              icon: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.55)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.body,
    required this.mine,
    required this.formattedTime,
    this.isVoice = false,
    this.isFile = false,
    this.voiceUrl,
    this.fileUrl,
    this.fileName,
    this.voiceDurationMs = 0,
    this.voiceLocalPath,
    this.replyQuoteBody,
    this.replyQuoteLabel,
    this.pending = false,
    this.showReceipt = false,
    this.seen = false,
  });

  final String body;
  final bool mine;
  final bool isVoice;
  final bool isFile;
  final String? voiceUrl;
  final String? fileUrl;
  final String? fileName;
  final int voiceDurationMs;
  final String? voiceLocalPath;
  final String formattedTime;
  final String? replyQuoteBody;
  final String? replyQuoteLabel;
  final bool pending;
  final bool showReceipt;
  final bool seen;

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.of(context).size.width * 0.78;
    final hasReply = replyQuoteBody != null &&
        replyQuoteBody!.isNotEmpty &&
        replyQuoteLabel != null &&
        replyQuoteLabel!.isNotEmpty;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxW,
        minWidth: isVoice ? 210 : 0,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: mine ? ChatScreen.bubbleMine : ChatScreen.bubbleOther,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(8),
            topRight: const Radius.circular(8),
            bottomLeft: Radius.circular(mine ? 8 : 2),
            bottomRight: Radius.circular(mine ? 2 : 8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasReply)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.22),
                      border: Border(
                        left: BorderSide(
                          color: ChatScreen.primaryColor.withValues(alpha: 0.85),
                          width: 3,
                        ),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          replyQuoteLabel!,
                          style: TextStyle(
                            color: ChatScreen.primaryColor.withValues(alpha: 0.95),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          replyQuoteBody!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 13,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (isVoice)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VoiceNoteBubble(
                      voiceUrl: voiceUrl ?? '',
                      durationMs: voiceDurationMs,
                      mine: mine,
                      localPath: voiceLocalPath,
                      uploading: pending,
                    ),
                    if (formattedTime.isNotEmpty || (showReceipt && mine))
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (formattedTime.isNotEmpty)
                                Text(
                                  formattedTime,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontSize: 11,
                                  ),
                                ),
                              if (showReceipt && mine) ...[
                                const SizedBox(width: 4),
                                _ReceiptRow(
                                  pending: pending,
                                  seen: seen,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                )
              else if (isFile)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final raw = (fileUrl ?? '').trim();
                          if (raw.isEmpty) return;
                          final resolved = ApiService.resolveMediaUrl(raw);
                          if (resolved.isEmpty) return;
                          if (!context.mounted) return;
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => InAppPdfViewerScreen(
                                url: resolved,
                                title: (fileName != null && fileName!.trim().isNotEmpty)
                                    ? fileName!
                                    : 'PDF report',
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ChatScreen.primaryColor.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.picture_as_pdf_rounded, color: ChatScreen.primaryColor, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  (fileName != null && fileName!.trim().isNotEmpty) ? fileName! : 'Open PDF report',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Color(0xFFE9EDEF), fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (formattedTime.isNotEmpty || (showReceipt && mine))
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (formattedTime.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 4, bottom: 1),
                                child: Text(
                                  formattedTime,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            if (showReceipt && mine)
                              _ReceiptRow(
                                pending: pending,
                                seen: seen,
                              ),
                          ],
                        ),
                      ),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        body,
                        style: const TextStyle(
                          color: Color(0xFFE9EDEF),
                          height: 1.38,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (formattedTime.isNotEmpty || (showReceipt && mine))
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (formattedTime.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 4, bottom: 1),
                                child: Text(
                                  formattedTime,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            if (showReceipt && mine)
                              _ReceiptRow(
                                pending: pending,
                                seen: seen,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.pending, required this.seen});

  final bool pending;
  final bool seen;

  @override
  Widget build(BuildContext context) {
    if (pending) {
      return SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: ChatScreen.primaryColor.withValues(alpha: 0.85),
        ),
      );
    }
    if (seen) {
      return const Icon(
        Icons.done_all_rounded,
        size: 15,
        color: Color(0xFF7DD3FC),
      );
    }
    return Icon(
      Icons.done_rounded,
      size: 15,
      color: Colors.white.withValues(alpha: 0.45),
    );
  }
}

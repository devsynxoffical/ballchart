import 'package:flutter/material.dart';
import 'package:ballchart/core/utils/app_messenger.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:ballchart/core/models/messaging_models.dart';
import 'package:ballchart/core/repositories/messaging_repository.dart';
import 'package:ballchart/core/services/api_service.dart';
import 'package:ballchart/features/messaging/view/chat_screen.dart';
import 'package:ballchart/features/messaging/widgets/messaging_avatar.dart';
import 'package:ballchart/features/inbox/viewmodel/inbox_viewmodel.dart';
import 'package:ballchart/features/profile/viewmodel/profile_viewmodel.dart';

/// Inbox: lists DM threads and opens [ChatScreen].
class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({super.key});

  static const Color primaryColor = Color(0xFFFFD900);
  static const Color bgColor = Color(0xFF131313);
  static const Color surfaceHigh = Color(0xFF2A2A2A);
  static const Color outlineColor = Color(0xFF9D8F79);

  @override
  State<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  final MessagingRepository _repo = MessagingRepository();
  final ApiService _api = ApiService();
  List<ConversationSummary> _items = [];
  List<MessagingParticipant> _contacts = [];
  bool _loading = true;
  String? _error;
  final Set<String> _onlineUserIds = {};
  final Map<String, String> _typingByConversation = {};

  void _onMessageNewSocket(dynamic data) {
    if (!mounted || data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final cid = map['conversationId']?.toString() ?? '';
    if (cid.isEmpty) {
      _load(silent: true);
      return;
    }
    final preview = (map['body'] ?? map['lastMessagePreview'] ?? '').toString();
    final createdAt = DateTime.tryParse(map['createdAt']?.toString() ?? '');
    final senderId = map['senderId']?.toString();
    final myId = context.read<ProfileViewmodel>().user?.id ?? '';
    setState(() {
      final idx = _items.indexWhere((c) => c.id == cid);
      if (idx >= 0) {
        final c = _items.removeAt(idx);
        final bumpUnread = senderId != null && senderId.isNotEmpty && senderId != myId;
        _items.insert(
          0,
          c.copyWith(
            lastMessagePreview: preview.isNotEmpty ? preview : c.lastMessagePreview,
            lastMessageAt: createdAt ?? c.lastMessageAt,
            unreadCount: bumpUnread ? c.unreadCount + 1 : c.unreadCount,
          ),
        );
      }
    });
    if (!_items.any((c) => c.id == cid)) {
      _load(silent: true);
    }
    context.read<InboxViewModel>().refresh();
  }

  void _socketSub(IO.Socket s) {
    s.off('MESSAGE_NEW', _onMessageNewSocket);
    s.off('message:new', _onMessageNewSocket);
    s.off('TYPING', _onTypingSocket);
    s.off('USER_ONLINE', _onUserOnline);
    s.off('USER_OFFLINE', _onUserOffline);
    s.on('MESSAGE_NEW', _onMessageNewSocket);
    s.on('message:new', _onMessageNewSocket);
    s.on('TYPING', _onTypingSocket);
    s.on('USER_ONLINE', _onUserOnline);
    s.on('USER_OFFLINE', _onUserOffline);
  }

  void _onTypingSocket(dynamic data) {
    if (!mounted || data is! Map) return;
    final cid = data['conversationId']?.toString();
    final uid = data['userId']?.toString();
    if (cid == null || uid == null) return;
    setState(() {
      if (data['isTyping'] == true) {
        _typingByConversation[cid] = uid;
      } else {
        _typingByConversation.remove(cid);
      }
    });
  }

  void _onUserOnline(dynamic data) {
    if (!mounted || data is! Map) return;
    final id = data['userId']?.toString();
    if (id == null || id.isEmpty) return;
    setState(() => _onlineUserIds.add(id));
  }

  void _onUserOffline(dynamic data) {
    if (!mounted || data is! Map) return;
    final id = data['userId']?.toString();
    if (id == null || id.isEmpty) return;
    setState(() => _onlineUserIds.remove(id));
  }

  @override
  void initState() {
    super.initState();
    _api.onSocketConnect(_socketSub);
    _api.connectSocket();
    _load();
  }

  @override
  void dispose() {
    _api.offSocketConnect(_socketSub);
    final s = _api.socket;
    s?.off('MESSAGE_NEW', _onMessageNewSocket);
    s?.off('message:new', _onMessageNewSocket);
    s?.off('TYPING', _onTypingSocket);
    s?.off('USER_ONLINE', _onUserOnline);
    s?.off('USER_OFFLINE', _onUserOffline);
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final list = await _repo.fetchConversations();
      final contacts = await _repo.fetchEligibleContacts();
      final online = await _repo.fetchOnlineUserIds();
      if (mounted) {
        setState(() {
          _items = list;
          _contacts = contacts;
          _onlineUserIds
            ..clear()
            ..addAll(online);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  /// Short time for list trailing (WhatsApp-style).
  String _listTime(DateTime? d) {
    if (d == null) return '';
    final t = TimeOfDay.fromDateTime(d.toLocal());
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _openNewMessage() async {
    if (_contacts.isEmpty) {
      AppMessenger.showSnackBar(context, 
        SnackBar(
          content: const Text('No contacts available yet'),
          backgroundColor: ConversationsListScreen.surfaceHigh,
        ),
      );
      return;
    }
    final picked = await showModalBottomSheet<MessagingParticipant>(
      context: context,
      backgroundColor: ConversationsListScreen.bgColor,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        builder: (_, scroll) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: ConversationsListScreen.outlineColor, borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'NEW MESSAGE',
                style: TextStyle(
                  color: ConversationsListScreen.primaryColor,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scroll,
                itemCount: _contacts.length,
                itemBuilder: (_, i) {
                  final c = _contacts[i];
                  return ListTile(
                    leading: MessagingAvatar(
                      name: c.username,
                      imageUrl: c.avatarUrl,
                      size: 48,
                    ),
                    title: Text(c.username, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      c.role.replaceAll('_', ' '),
                      style: const TextStyle(color: ConversationsListScreen.outlineColor, fontSize: 12),
                    ),
                    onTap: () => Navigator.pop(ctx, c),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    try {
      final conv = await _repo.createOrGetConversation(picked.id);
      if (!mounted) return;
      final o = conv.other ?? picked;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conv.id,
            otherName: o.username,
            otherId: o.id,
            myUserId: context.read<ProfileViewmodel>().user?.id,
            otherAvatarUrl: o.avatarUrl,
            otherEmail: o.email,
            otherRole: o.role,
          ),
        ),
      );
      if (!mounted) return;
      await context.read<InboxViewModel>().refresh();
      _load();
    } catch (e) {
      if (mounted) {
        AppMessenger.showSnackBar(context, 
          SnackBar(content: Text('$e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ConversationsListScreen.bgColor,
      appBar: AppBar(
        backgroundColor: ConversationsListScreen.bgColor,
        elevation: 0,
        title: const Text(
          'MESSAGES',
          style: TextStyle(
            color: ConversationsListScreen.primaryColor,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 14,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'New message',
            icon: const Icon(Icons.add_comment_outlined, color: ConversationsListScreen.primaryColor),
            onPressed: _loading ? null : _openNewMessage,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loading ? null : _openNewMessage,
        backgroundColor: ConversationsListScreen.primaryColor,
        foregroundColor: Colors.black,
        child: const Icon(Icons.chat_bubble_outline),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _load,
                child: const Text('Retry', style: TextStyle(color: ConversationsListScreen.primaryColor)),
              ),
            ],
          ),
        ),
      );
    }

    final myId = context.watch<ProfileViewmodel>().user?.id ?? '';

    if (_items.isEmpty) {
      return Column(
        children: [
          if (_loading)
            const LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Color(0xFF1A1A1A),
              color: ConversationsListScreen.primaryColor,
            ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_loading)
                      Text(
                        'Loading conversations…',
                        style: TextStyle(color: ConversationsListScreen.outlineColor.withValues(alpha: 0.85), fontSize: 14),
                      )
                    else ...[
                      Icon(Icons.forum_outlined, size: 56, color: ConversationsListScreen.outlineColor.withValues(alpha: 0.6)),
                      const SizedBox(height: 16),
                      const Text(
                        'No conversations yet',
                        style: TextStyle(color: ConversationsListScreen.outlineColor, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap + for a direct message. Team group chats appear here when you’re on a roster.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (_loading)
          const LinearProgressIndicator(
            minHeight: 2,
            backgroundColor: Color(0xFF1A1A1A),
            color: ConversationsListScreen.primaryColor,
          ),
        Expanded(
          child: RefreshIndicator(
      color: ConversationsListScreen.primaryColor,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = _items[index];
          final isTeam = item.isTeamGroup;
          final name = isTeam
              ? (item.teamName != null && item.teamName!.trim().isNotEmpty ? item.teamName!.trim() : 'Team chat')
              : (item.other?.username ?? 'Unknown');
          final typingUid = _typingByConversation[item.id];
          final subtitle = typingUid != null
              ? 'typing…'
              : (item.lastMessagePreview.isEmpty
                  ? (isTeam ? 'Team group · players & coaches' : 'Tap to chat')
                  : item.lastMessagePreview);
          final trailingText = _listTime(item.lastMessageAt);
          return Material(
            color: ConversationsListScreen.surfaceHigh,
            borderRadius: BorderRadius.circular(16),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Hero(
                tag: 'chat_avatar_${item.id}',
                child: isTeam
                    ? CircleAvatar(
                        radius: 26,
                        backgroundColor: ConversationsListScreen.surfaceHigh,
                        child: const Icon(Icons.groups_rounded, color: ConversationsListScreen.primaryColor, size: 28),
                      )
                    : MessagingAvatar(
                        name: name,
                        imageUrl: item.other?.avatarUrl,
                        size: 52,
                        isOnline: item.other != null && _onlineUserIds.contains(item.other!.id),
                      ),
              ),
              title: Text(
                name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: typingUid != null
                      ? const Color(0xFF25D366)
                      : ConversationsListScreen.outlineColor,
                  fontSize: 13,
                  fontStyle: typingUid != null ? FontStyle.italic : FontStyle.normal,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.unreadCount > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: ConversationsListScreen.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.unreadCount > 99 ? '99+' : '${item.unreadCount}',
                        style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900),
                      ),
                    ),
                  if (trailingText.isNotEmpty)
                    Text(
                      trailingText,
                      style: TextStyle(
                        color: ConversationsListScreen.outlineColor.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      conversationId: item.id,
                      otherName: name,
                      otherId: item.other?.id ?? '',
                      myUserId: myId,
                      otherAvatarUrl: item.other?.avatarUrl,
                      otherEmail: item.other?.email,
                      otherRole: item.other?.role,
                      isTeamGroup: isTeam,
                    ),
                  ),
                );
                if (!mounted) return;
                await context.read<InboxViewModel>().refresh();
                _load(silent: true);
              },
            ),
          );
        },
      ),
    ),
        ),
      ],
    );
  }
}

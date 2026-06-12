import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ballchart/core/models/messaging_models.dart';
import 'package:ballchart/core/repositories/messaging_repository.dart';
import 'package:ballchart/core/services/api_service.dart';
import 'package:ballchart/features/messaging/view/chat_screen.dart';
import 'package:ballchart/features/messaging/widgets/messaging_avatar.dart';
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

  void _onMessageNewSocket(dynamic data) {
    if (!mounted) return;
    _load();
  }

  @override
  void initState() {
    super.initState();
    _api.connectSocket();
    _api.socket?.on('MESSAGE_NEW', _onMessageNewSocket);
    _load();
  }

  @override
  void dispose() {
    _api.socket?.off('MESSAGE_NEW', _onMessageNewSocket);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.fetchConversations();
      final contacts = await _repo.fetchEligibleContacts();
      if (mounted) {
        setState(() {
          _items = list;
          _contacts = contacts;
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
      ScaffoldMessenger.of(context).showSnackBar(
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
            otherAvatarUrl: o.avatarUrl,
            otherEmail: o.email,
            otherRole: o.role,
          ),
        ),
      );
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
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
          final subtitle = item.lastMessagePreview.isEmpty
              ? (isTeam ? 'Team group · players & coaches' : 'Tap to chat')
              : item.lastMessagePreview;
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
                style: const TextStyle(color: ConversationsListScreen.outlineColor, fontSize: 13),
              ),
              trailing: trailingText.isEmpty
                  ? null
                  : Text(
                      trailingText,
                      style: TextStyle(
                        color: ConversationsListScreen.outlineColor.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
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
                _load();
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

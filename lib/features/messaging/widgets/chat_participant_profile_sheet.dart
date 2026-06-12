import 'package:flutter/material.dart';
import 'package:ballchart/core/models/local_academy_models.dart';
import 'package:ballchart/features/messaging/widgets/messaging_avatar.dart';
import 'package:ballchart/features/player/view/player_detail_screen.dart';

/// WhatsApp-style contact sheet from chat header / avatar tap.
Future<void> showChatParticipantProfileSheet(
  BuildContext context, {
  required String name,
  required String userId,
  String? email,
  String? role,
  String? avatarUrl,
}) {
  final r = (role ?? '').toLowerCase().trim();
  final isPlayer = r == 'player';

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF1E1E1E),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              MessagingAvatar(name: name, imageUrl: avatarUrl, size: 96, fontSize: 36),
              const SizedBox(height: 16),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (role != null && role.isNotEmpty) ...[
                const SizedBox(height: 8),
                Chip(
                  label: Text(
                    role.replaceAll('_', ' '),
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  backgroundColor: const Color(0xFF2A2A2A),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ],
              if (email != null && email.isNotEmpty) ...[
                const SizedBox(height: 12),
                SelectableText(
                  email,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
              const SizedBox(height: 24),
              if (isPlayer)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD900),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      final p = Player(
                        id: userId,
                        name: name,
                        email: email ?? '',
                        position: '—',
                        age: 0,
                        profileImageUrl: avatarUrl,
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlayerDetailScreen(player: p, canEdit: false),
                        ),
                      );
                    },
                    child: const Text('View full profile'),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

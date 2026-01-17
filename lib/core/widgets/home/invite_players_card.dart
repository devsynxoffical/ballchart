import 'package:flutter/material.dart';

import '../custom_button.dart';
import '../dialogues/InvitePlayerDialog.dart';

class InvitePlayersCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF312E81)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invite Players',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Share your team link via WhatsApp or any messaging app',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          CustomButton(
            text: 'Share via WhatsApp',
            backgroundColor: Colors.green,
            textColor: Colors.white, onPressed: () { showDialog(
            context: context,
            barrierDismissible: true,
            builder: (_) => const InvitePlayerDialog(),
          );},
          ),
        ],
      ),
    );
  }
}

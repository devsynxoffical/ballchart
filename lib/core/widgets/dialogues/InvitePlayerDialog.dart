import 'package:flutter/material.dart';

class InvitePlayerDialog extends StatefulWidget {
  const InvitePlayerDialog({super.key});

  @override
  State<InvitePlayerDialog> createState() => _InvitePlayerDialogState();
}

class _InvitePlayerDialogState extends State<InvitePlayerDialog> {
  String selectedTeam = 'Thunder Squad';

  final List<String> teams = [
    'Thunder Squad',
    'Rising Stars',
    'Elite Dunkers',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF020617),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFF59E0B),
                  child: Icon(Icons.add, color: Colors.black),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Invite Player',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),

            const SizedBox(height: 6),
            const Text(
              'Share team invitation link',
              style: TextStyle(color: Colors.white60),
            ),

            const SizedBox(height: 20),

            /// Select Team
            const Text(
              'Select Team',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),

            Column(
              children: teams.map((team) {
                final isSelected = team == selectedTeam;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedTeam = team;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: isSelected
                          ? Border.all(
                        color: const Color(0xFFF59E0B),
                        width: 1.5,
                      )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            team,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check,
                            color: Color(0xFFF59E0B),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            /// Invitation Link
            const Text(
              'Invitation Link',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'https://hoopstar.app/join/1',
                style: TextStyle(color: Colors.white70),
              ),
            ),

            const SizedBox(height: 14),

            /// Copy Link
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.copy, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Copy Link',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            /// Share Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.share, color: Colors.black),
                    SizedBox(width: 8),
                    Text(
                      'Share via...',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

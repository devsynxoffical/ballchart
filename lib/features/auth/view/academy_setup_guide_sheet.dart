import 'package:flutter/material.dart';

/// Post-registration setup steps — shown from Registration Success "View Guide".
Future<void> showAcademySetupGuide(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (ctx) {
      const primaryColor = Color(0xFFFFD900);
      const bgColor = Color(0xFF181710);
      const surfaceColor = Color(0xFF1E293B);
      const outlineColor = Color(0xFF9D8F79);

      final steps = <({String title, String body, IconData icon})>[
        (
          title: 'Sign in',
          body: 'Tap Go to Dashboard, sign in with the email and password you just registered.',
          icon: Icons.login_rounded,
        ),
        (
          title: 'Complete your profile',
          body: 'Add your name, academy details, and role so players and staff see the right dashboard.',
          icon: Icons.person_outline_rounded,
        ),
        (
          title: 'Create your first team',
          body: 'From the academy home, add a team (e.g. U14), upload a team photo, and set the division.',
          icon: Icons.groups_rounded,
        ),
        (
          title: 'Invite coaches & players',
          body: 'Add coaching staff with access rights, then invite players to the roster.',
          icon: Icons.person_add_alt_1_rounded,
        ),
        (
          title: 'Schedule a game & strategy',
          body: 'Use Games to schedule sessions and Strategy to build plays for your team.',
          icon: Icons.sports_basketball_rounded,
        ),
      ];

      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: outlineColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'ACADEMY SETUP GUIDE',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Quick steps to get your academy running on BallChart.',
                  style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 24),
                ...steps.asMap().entries.map((entry) {
                  final i = entry.key;
                  final s = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
                          ),
                          child: Icon(s.icon, color: primaryColor, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${i + 1}. ${s.title}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                s.body,
                                style: TextStyle(
                                  color: outlineColor.withValues(alpha: 0.95),
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: bgColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'GOT IT',
                      style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repositories/profile_repository.dart';
import '../../features/auth/viewmodel/auth_viewmodel.dart';

const String kDeleteAccountConfirmPhrase = 'DELETE MY ACCOUNT';

/// Google Play–style account deletion: user must type the confirmation phrase.
Future<void> showDeleteAccountDialog(BuildContext context) async {
  final phraseCtrl = TextEditingController();
  final profileRepo = ProfileRepository();
  final hostContext = context;

  await showDialog<void>(
    context: hostContext,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setLocal) {
          final match = phraseCtrl.text.trim() == kDeleteAccountConfirmPhrase;
          return AlertDialog(
            backgroundColor: const Color(0xFF201F1F),
            title: const Text('Delete account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This permanently deletes your BallChart account and related data you are allowed to remove from this app. For academy admins, teams and roster data under your academy may also be removed.',
                    style: TextStyle(color: Colors.white70, height: 1.4, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Type the phrase below exactly to confirm:',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    kDeleteAccountConfirmPhrase,
                    style: const TextStyle(color: Color(0xFFFFD900), fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phraseCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: kDeleteAccountConfirmPhrase,
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
                      filled: true,
                      fillColor: const Color(0xFF131313),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (_) => setLocal(() {}),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              TextButton(
                onPressed: !match
                    ? null
                    : () async {
                        Navigator.pop(dialogContext);
                        if (!hostContext.mounted) return;
                        showDialog<void>(
                          context: hostContext,
                          barrierDismissible: false,
                          builder: (_) => const Center(
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: CircularProgressIndicator(color: Color(0xFFFFD900)),
                            ),
                          ),
                        );
                        try {
                          await profileRepo.deleteMyAccount();
                          if (!hostContext.mounted) return;
                          Navigator.of(hostContext, rootNavigator: true).pop();
                          await hostContext.read<AuthViewmodel>().logout(hostContext);
                          if (!hostContext.mounted) return;
                          ScaffoldMessenger.of(hostContext).showSnackBar(
                            const SnackBar(content: Text('Your account has been deleted.')),
                          );
                        } catch (e) {
                          if (!hostContext.mounted) return;
                          Navigator.of(hostContext, rootNavigator: true).pop();
                          ScaffoldMessenger.of(hostContext).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent),
                          );
                        }
                      },
                child: Text('Delete forever', style: TextStyle(color: match ? Colors.redAccent : Colors.white24)),
              ),
            ],
          );
        },
      );
    },
  );

  phraseCtrl.dispose();
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/auth/viewmodel/auth_viewmodel.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _SettingsTile(icon: Icons.notifications, title: 'Notifications'),
        SizedBox(height: 10),
        _SettingsTile(icon: Icons.lock, title: 'Privacy'),
        SizedBox(height: 14),
        _SignOutButton(),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SettingsTile({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(color: Colors.white)),
          const Spacer(),
          const Icon(Icons.chevron_right, color: Colors.white38),
        ],
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewmodel>(
      builder: (context, authVm, child) {
        return GestureDetector(
          onTap: () => authVm.logout(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text(
                'Sign Out',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );
      },
    );
  }
}

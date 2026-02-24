import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:courtiq/features/management/viewmodel/academy_provider.dart';

class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        title: const Text('Staff Dashboard'),
      ),
      body: Consumer<AcademyProvider>(
        builder: (context, provider, _) {
          final staff = provider.currentStaff;
          if (staff == null) {
            return const Center(
              child: Text(
                'No coach profile found in dummy data.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${staff.name}',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Role: ${staff.role == 'custom' ? (staff.customRoleName ?? 'Custom') : staff.role}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Allowed Actions',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (staff.permissions.createPlayer) _actionTile('Create Player', Icons.person_add_alt_1),
                if (staff.permissions.readPlayer) _actionTile('Read Player', Icons.visibility_outlined),
                if (staff.permissions.updatePlayer) _actionTile('Update Player', Icons.edit_outlined),
                if (staff.permissions.deletePlayer) _actionTile('Delete Player', Icons.delete_outline),
                if (staff.permissions.createTeam) _actionTile('Create Team', Icons.group_add),
                if (staff.permissions.manageStaff) _actionTile('Manage Staff', Icons.manage_accounts_outlined),
                if (!staff.permissions.createPlayer &&
                    !staff.permissions.readPlayer &&
                    !staff.permissions.updatePlayer &&
                    !staff.permissions.deletePlayer &&
                    !staff.permissions.createTeam &&
                    !staff.permissions.manageStaff)
                  const Text(
                    'No extra permissions assigned.',
                    style: TextStyle(color: Colors.white54),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _actionTile(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFACC15)),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

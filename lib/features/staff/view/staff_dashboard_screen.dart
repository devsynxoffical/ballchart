import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:courtiq/features/profile/viewmodel/profile_viewmodel.dart';
import 'package:courtiq/core/repositories/dashboard_repository.dart';

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
      body: FutureBuilder<Map<String, dynamic>>(
        future: DashboardRepository().getCoachDashboard(),
        builder: (context, snapshot) {
          final user = context.watch<ProfileViewmodel>().user;
          if (!snapshot.hasData || user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final profile = (data['profile'] as Map?)?.cast<String, dynamic>() ?? {};
          final permissions = (profile['permissions'] as Map?)?.cast<String, dynamic>() ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${user.username}',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Role: ${user.role}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Allowed Actions',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (permissions['createPlayer'] == true) _actionTile('Create Player', Icons.person_add_alt_1),
                if (permissions['readPlayer'] == true) _actionTile('Read Player', Icons.visibility_outlined),
                if (permissions['updatePlayer'] == true) _actionTile('Update Player', Icons.edit_outlined),
                if (permissions['deletePlayer'] == true) _actionTile('Delete Player', Icons.delete_outline),
                if (permissions['createTeam'] == true) _actionTile('Create Team', Icons.group_add),
                if (permissions['manageStaff'] == true) _actionTile('Manage Staff', Icons.manage_accounts_outlined),
                if (permissions.isEmpty)
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

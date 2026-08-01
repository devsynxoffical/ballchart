import 'package:flutter/material.dart';
import 'package:ballchart/core/utils/app_messenger.dart';
import 'package:provider/provider.dart';
import '../viewmodel/academy_provider.dart';
import '../../../../core/models/local_academy_models.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/dialogues/CreateTeamDialog.dart';
import '../../../../core/widgets/dialogues/CreateStaffDialog.dart';

class ManagementScreen extends StatefulWidget {
  const ManagementScreen({super.key});

  @override
  State<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Organization Management',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildManagementCard(
              context,
              title: 'Teams Support',
              subtitle: 'Create and manage your basketball teams',
              icon: Icons.groups_rounded,
              color: AppColors.yellow,
              onTap: () {
                // Future: Detailed Teams list
              },
            ),
            const SizedBox(height: 16),
            _buildManagementCard(
              context,
              title: 'Coaching Staff',
              subtitle: 'Add Coaches and Assistant Coaches',
              icon: Icons.badge_rounded,
              color: Colors.blueAccent,
              onTap: () {
                // Future: Detailed Staff list
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Quick Actions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.add_business_rounded,
                    label: 'Add Team',
                    color: AppColors.yellow,
                    onTap: () => _showCreateTeam(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.person_add_rounded,
                    label: 'Add Staff',
                    color: Colors.blueAccent,
                    onTap: () => _showCreateStaff(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateTeam(BuildContext context) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => CreateTeamDialog(
        onTeamCreated: (name, age, color, logo, coachId, assistantId) async {
          final provider = context.read<AcademyProvider>();
          await provider.addTeamToBackend(
            Team(
              id: '',
              name: name,
              ageGroup: age,
              colorValue: color.value,
              logoPath: logo,
              players: [],
              coachStaffId: coachId,
              assistantCoachStaffId: assistantId,
            ),
            showSuccessMessage: false,
          );
        },
      ),
    );
    if (created == true && mounted) {
      AppMessenger.show(
        context,
        message: 'Team created successfully!',
        kind: AppMessageKind.success,
      );
    }
  }

  Future<void> _showCreateStaff(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => CreateStaffDialog(
        initialRole: 'Coach',
        onStaffCreated: (staffData) async {
          final provider = context.read<AcademyProvider>();
          await provider.addStaffToBackend(
            Staff(
              id: provider.nextId('s'),
              name: staffData['name'] ?? '',
              email: staffData['email'] ?? '',
              password: staffData['password'] ?? '',
              role: (staffData['role'] ?? 'coach').toString().toLowerCase().replaceAll(' ', '_'),
              customRoleName: staffData['customRoleName']?.toString(),
              assignedTeamIds: const [],
              permissions: Permissions.fromDynamic(staffData['permissions']),
            ),
            showSuccessMessage: false,
          );
        },
      ),
    );
  }

  Widget _buildManagementCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.3), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

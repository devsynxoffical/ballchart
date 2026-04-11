import 'package:flutter/material.dart';
import 'package:ballchart/core/constants/colors.dart';
import 'package:ballchart/features/staff/service/staff_service.dart';
import 'package:provider/provider.dart';
import 'package:ballchart/features/profile/viewmodel/profile_viewmodel.dart';
import 'package:ballchart/core/widgets/dialogues/CreateStaffDialog.dart';
import 'package:ballchart/core/widgets/dialogues/CreatePlayerDialog.dart';
import 'package:ballchart/core/models/local_academy_models.dart';
import 'package:ballchart/features/management/viewmodel/academy_provider.dart';

class StaffTab extends StatefulWidget {
  const StaffTab({super.key});

  @override
  State<StaffTab> createState() => _StaffTabState();
}

class _StaffTabState extends State<StaffTab> {
  final StaffService _staffService = StaffService();
  List<Map<String, dynamic>> _staffList = [];
  bool _isLoading = true;
  String? _error;

  // BallChart Design Tokens
  static const Color primaryColor = Color(0xFFFFD900);
  static const Color bgColor = Color(0xFF111111);
  static const Color cardColor = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _staffService.getStaffCredentials();
      _staffList = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatRole(String role) {
    switch (role) {
      case 'head_coach': return 'Head Coach';
      case 'assistant_coach': return 'Asst. Coach';
      case 'coach': return 'Coach';
      default: return role;
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'head_coach': return primaryColor;
      case 'assistant_coach': return const Color(0xFF8B5CF6);
      case 'coach': return const Color(0xFF3B82F6);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<ProfileViewmodel>().user;
    final role = user?.role ?? 'coach';

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryColor));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white24, size: 64),
              const SizedBox(height: 16),
              Text(
                _error!.contains('Exception:') 
                  ? _error!.replaceAll('Exception: ', '')
                  : _error!,
                style: const TextStyle(color: Colors.white60), 
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadStaff,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('RETRY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          const Text(
            'STAFF DIRECTORY',
            style: TextStyle(
              color: primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage your elite coaching and analytical team.',
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
          const SizedBox(height: 32),

          // Actions
          if (role == 'head_coach') ...[
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.person_add_rounded,
                    label: 'ADD STAFF',
                    color: const Color(0xFF8B5CF6),
                    onTap: () => _showCreateStaffDialog(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.sports_basketball_rounded,
                    label: 'ADD PLAYER',
                    color: const Color(0xFF3B82F6),
                    onTap: () => _showCreatePlayerDialog(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],

          // "You" Card
          _buildStaffCard(
            name: user?.username ?? 'You',
            role: _formatRole(role),
            email: user?.email ?? '',
            roleColor: _roleColor(role),
            isYou: true,
          ),
          const SizedBox(height: 32),

          // Staff List
          if (_staffList.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ACADEMY STAFF',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_staffList.length}',
                    style: const TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._staffList.map((staff) {
              final staffRole = staff['role'] ?? 'staff';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildStaffCard(
                  name: staff['username'] ?? 'Unknown',
                  role: _formatRole(staffRole),
                  email: staff['email'] ?? '',
                  roleColor: _roleColor(staffRole),
                  isYou: false,
                ),
              );
            }),
          ],

          if (_staffList.isEmpty && role == 'head_coach')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  Icon(Icons.badge_outlined, color: Colors.white.withOpacity(0.1), size: 64),
                  const SizedBox(height: 16),
                  const Text('No staff members registered', style: TextStyle(color: Colors.white54, fontSize: 15)),
                  const SizedBox(height: 4),
                  const Text('Invite coaches to start tracking', style: TextStyle(color: Colors.white24, fontSize: 13)),
                ],
              ),
            ),
          
          const SizedBox(height: 100), // Bottom nav space
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffCard({
    required String name,
    required String role,
    required String email,
    required Color roleColor,
    required bool isYou,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isYou ? roleColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          width: isYou ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            alignment: Alignment.center,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(color: roleColor, fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isYou) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('OWNER', style: TextStyle(color: primaryColor, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      role.toUpperCase(),
                      style: TextStyle(color: roleColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                    if (email.isNotEmpty && !isYou) ...[
                      const SizedBox(width: 8),
                      const Text('•', style: TextStyle(color: Colors.white24)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          email,
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white24),
        ],
      ),
    );
  }

  void _showCreateStaffDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => CreateStaffDialog(
        initialRole: 'Coach',
        onStaffCreated: (staffData) async {
          final provider = context.read<AcademyProvider>();
          try {
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
            );
          } catch (_) {
            // addStaffToBackend surfaces error via provider.error
          }
          if (context.mounted) await _loadStaff();
        },
      ),
    );
  }

  void _showCreatePlayerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => CreatePlayerDialog(
        onPlayerCreated: (player) {},
      ),
    );
  }
}

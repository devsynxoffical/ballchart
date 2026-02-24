import 'package:flutter/material.dart';
import 'package:courtiq/core/constants/colors.dart';
import 'package:courtiq/features/staff/service/staff_service.dart';
import 'package:provider/provider.dart';
import 'package:courtiq/features/profile/viewmodel/profile_viewmodel.dart';
import 'package:courtiq/core/widgets/dialogues/CreateStaffDialog.dart';
import 'package:courtiq/core/widgets/dialogues/CreatePlayerDialog.dart';

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

    final user = Provider.of<ProfileViewmodel>(context, listen: false).user;
    final isDemo = user?.id.startsWith('demo_') ?? false;

    try {
      if (isDemo) {
        await Future.delayed(const Duration(milliseconds: 500));
        _staffList = [
          {'username': 'Coach Carter', 'role': 'coach', 'email': 'carter@ballchart.com'},
          {'username': 'Coach Smith', 'role': 'assistant_coach', 'email': 'smith@ballchart.com'},
        ];
      } else {
        final data = await _staffService.getStaffCredentials();
        _staffList = List<Map<String, dynamic>>.from(data);
      }
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
      case 'head_coach':
        return 'Head Coach';
      case 'assistant_coach':
        return 'Asst. Coach';
      case 'coach':
        return 'Coach';
      default:
        return role;
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'head_coach':
        return AppColors.yellow;
      case 'assistant_coach':
        return const Color(0xFF8B5CF6);
      case 'coach':
        return const Color(0xFF3B82F6);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<ProfileViewmodel>().user;
    final role = user?.role ?? 'coach';

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.yellow));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white38, size: 48),
              const SizedBox(height: 12),
              Text('Error: $_error', style: const TextStyle(color: Colors.white60), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadStaff,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.yellow, foregroundColor: Colors.black),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Action Buttons
          if (role == 'head_coach') ...[
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.person_add_rounded,
                    label: 'Add Staff',
                    color: AppColors.green,
                    onTap: () => _showCreateStaffDialog(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.sports_basketball,
                    label: 'Add Player',
                    color: AppColors.blue,
                    onTap: () => _showCreatePlayerDialog(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // You card
          _buildStaffCard(
            name: user?.username ?? 'You',
            role: _formatRole(role),
            email: user?.email ?? '',
            roleColor: _roleColor(role),
            isYou: true,
          ),
          const SizedBox(height: 12),

          // Staff list header
          if (_staffList.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Row(
                children: [
                  const Text(
                    'Your Staff',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_staffList.length}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            ..._staffList.map((staff) {
              final staffRole = staff['role'] ?? 'staff';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
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
              padding: const EdgeInsets.all(32),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06), style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  Icon(Icons.group_add_outlined, color: Colors.white.withValues(alpha: 0.15), size: 48),
                  const SizedBox(height: 12),
                  const Text('No staff members yet', style: TextStyle(color: Colors.white54, fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  const Text('Tap "Add Staff" to create accounts', style: TextStyle(color: Colors.white30, fontSize: 13)),
                ],
              ),
            ),

          const SizedBox(height: 40),
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: isYou
            ? Border.all(color: roleColor.withValues(alpha: 0.5), width: 1)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(color: roleColor, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isYou) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('YOU', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(role, style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                    if (email.isNotEmpty && !isYou) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          email,
                          style: const TextStyle(color: Colors.white30, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateStaffDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => CreateStaffDialog(
        initialRole: 'Coach',
        onStaffCreated: (staff) {
          _loadStaff();
        },
      ),
    );
  }

  void _showCreatePlayerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => CreatePlayerDialog(
        onPlayerCreated: (player) {
          // Player was created via API
        },
      ),
    );
  }
}

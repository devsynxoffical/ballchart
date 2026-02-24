import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:courtiq/core/models/local_academy_models.dart';
import 'package:courtiq/core/constants/colors.dart';
import 'package:courtiq/core/widgets/dialogues/CreateTeamDialog.dart';
import 'package:courtiq/features/coach/team_details/view/team_detail_screen.dart';
import 'package:courtiq/features/management/viewmodel/academy_provider.dart';

class AcademyDashboardScreen extends StatefulWidget {
  const AcademyDashboardScreen({super.key});

  @override
  State<AcademyDashboardScreen> createState() => _AcademyDashboardScreenState();
}

class _AcademyDashboardScreenState extends State<AcademyDashboardScreen> {
  int _currentTab = 0;
  bool _notificationsEnabled = true;
  bool _weeklyReportsEnabled = true;
  bool _playerAutoAssignEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        elevation: 0,
        title: Text(
          _titleForTab(_currentTab),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search_rounded, color: Colors.white70),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white70),
          ),
        ],
      ),
      body: Consumer<AcademyProvider>(
        builder: (context, provider, _) {
          switch (_currentTab) {
            case 1:
              return _buildTeamsSection(provider);
            case 2:
              return _buildStaffSection(provider);
            case 3:
              return _buildAdminProfileSection(provider);
            default:
              return _buildDashboardSection(provider);
          }
        },
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  String _titleForTab(int tab) {
    switch (tab) {
      case 1:
        return 'Teams';
      case 2:
        return 'Staff Management';
      case 3:
        return 'Admin Profile';
      default:
        return 'Admin Dashboard';
    }
  }

  void _openTeamDetails(BuildContext context, Team team) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeamDetailScreen(teamName: team.name),
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = <_NavItemData>[
      _NavItemData(icon: Icons.dashboard_rounded, label: 'Dashboard'),
      _NavItemData(icon: Icons.groups_rounded, label: 'Teams'),
      _NavItemData(icon: Icons.badge_rounded, label: 'Staff'),
      _NavItemData(icon: Icons.person_rounded, label: 'Profile'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 18,
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = _currentTab == index;
            final activeColor = AppColors.yellow;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _currentTab = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeColor.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        color: isSelected ? activeColor : Colors.white54,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected ? activeColor : Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDashboardSection(AcademyProvider provider) {
    final totalPlayers = provider.academy.teams.fold<int>(
      0,
      (sum, team) => sum + team.players.length,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.yellow.withValues(alpha: 0.2),
                const Color(0xFF1E293B),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.yellow.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ACADEMY OWNER PANEL',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                provider.academy.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Manage teams, records, staff access and academy operations',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                label: 'Teams',
                value: '${provider.academy.teams.length}',
                icon: Icons.groups_rounded,
                color: AppColors.yellow,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricCard(
                label: 'Staff',
                value: '${provider.academy.staff.length}',
                icon: Icons.badge_rounded,
                color: const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricCard(
                label: 'Players',
                value: '$totalPlayers',
                icon: Icons.sports_basketball_rounded,
                color: AppColors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Quick Actions',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _actionButton(
              label: 'Add Team',
              icon: Icons.group_add_rounded,
              color: AppColors.yellow,
              onTap: () => _showCreateTeamDialog(context),
            ),
            _actionButton(
              label: 'Add Staff',
              icon: Icons.person_add_alt_1_rounded,
              color: const Color(0xFF8B5CF6),
              onTap: () => _showAddStaffDialog(context),
            ),
            _actionButton(
              label: 'Add Player',
              icon: Icons.person_add_rounded,
              color: AppColors.blue,
              onTap: () => _showAddPlayerDialog(context),
            ),
            _actionButton(
              label: 'Manage Staff',
              icon: Icons.manage_accounts_rounded,
              color: AppColors.green,
              onTap: () => setState(() => _currentTab = 2),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'All Teams (Dashboard View)',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ...provider.academy.teams.map((team) {
          final coach = provider.getStaffById(team.coachStaffId);
          final assistant = provider.getStaffById(team.assistantCoachStaffId);
          final teamColor = Color(team.colorValue);
          return GestureDetector(
            onTap: () => _openTeamDetails(context, team),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: teamColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.shield_rounded, color: teamColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${team.players.length} players • ${team.ageGroup}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Coach: ${coach?.name ?? 'Not assigned'}',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        Text(
                          'Assistant: ${assistant?.name ?? 'Not assigned'}',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showTeamManagementDialog(context, team),
                    child: const Text('Manage'),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTeamsSection(AcademyProvider provider) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _sectionHeader(
          title: 'Team Management',
          subtitle: 'Assign coach and assistant coach for each team',
          icon: Icons.groups_rounded,
          color: AppColors.yellow,
        ),
        const SizedBox(height: 12),
        ...provider.academy.teams.map((team) {
          final coach = provider.getStaffById(team.coachStaffId);
          final assistant = provider.getStaffById(team.assistantCoachStaffId);
          final teamColor = Color(team.colorValue);
          return GestureDetector(
            onTap: () => _openTeamDetails(context, team),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_rounded, color: teamColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          team.name,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _showTeamManagementDialog(context, team),
                        child: const Text('Manage Team'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Roster: ${team.players.length} players • ${team.ageGroup}',
                    style: const TextStyle(color: Colors.white60),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Coach: ${coach?.name ?? 'Not assigned'}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'Assistant Coach: ${assistant?.name ?? 'Not assigned'}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (team.players.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: team.players
                          .map(
                            (p) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${p.name} • ${p.position}',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
        _actionButton(
          label: 'Create New Team',
          icon: Icons.add_business_rounded,
          color: AppColors.yellow,
          onTap: () => _showCreateTeamDialog(context),
        ),
      ],
    );
  }

  Widget _buildStaffSection(AcademyProvider provider) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _sectionHeader(
          title: 'Staff Directory',
          subtitle: 'Roles, permissions and team access',
          icon: Icons.badge_rounded,
          color: const Color(0xFF8B5CF6),
        ),
        const SizedBox(height: 12),
        _actionButton(
          label: 'Manage Staff',
          icon: Icons.manage_accounts_rounded,
          color: const Color(0xFF8B5CF6),
          onTap: () => _showAddStaffDialog(context),
        ),
        const SizedBox(height: 12),
        ...provider.academy.staff.map((staff) {
          final assignedTeams = provider.academy.teams
              .where((team) => staff.assignedTeamIds.contains(team.id))
              .map((team) => team.name)
              .toList();
          final roleLabel = staff.role == 'custom'
              ? (staff.customRoleName ?? 'Custom')
              : staff.role.replaceAll('_', ' ');
          final roleColor = _staffRoleColor(staff.role);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                          staff.name.isNotEmpty ? staff.name[0].toUpperCase() : 'S',
                          style: TextStyle(
                            color: roleColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            staff.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            roleLabel,
                            style: TextStyle(color: roleColor, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            staff.email,
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit Staff',
                      onPressed: () => _showEditStaffDialog(context, staff),
                      icon: const Icon(Icons.edit_outlined, color: Colors.white54, size: 20),
                    ),
                    IconButton(
                      tooltip: 'Delete Staff',
                      onPressed: () => _confirmDeleteStaff(context, staff),
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (assignedTeams.isNotEmpty)
                  Text(
                    'Teams: ${assignedTeams.join(', ')}',
                    style: const TextStyle(color: Colors.white60),
                  )
                else
                  const Text(
                    'Teams: No team assigned',
                    style: TextStyle(color: Colors.white38),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _permissionChips(staff.permissions),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAdminProfileSection(AcademyProvider provider) {
    final totalPlayers = provider.academy.teams.fold<int>(
      0,
      (sum, team) => sum + team.players.length,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.yellow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.yellow),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Academy Owner',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Admin privileges enabled',
                          style: TextStyle(color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                provider.academy.name,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                '${provider.academy.teams.length} teams • ${provider.academy.staff.length} staff • $totalPlayers players',
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 12),
              if (provider.academy.logoUrl != null && provider.academy.logoUrl!.isNotEmpty)
                Text(
                  'Logo: ${provider.academy.logoUrl}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              const SizedBox(height: 12),
              _actionButton(
                label: 'Manage Academy Profile',
                icon: Icons.edit_rounded,
                color: AppColors.yellow,
                onTap: () => _showManageAcademyDialog(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _switchCard(
          title: 'Notifications',
          value: _notificationsEnabled,
          onChanged: (v) => setState(() => _notificationsEnabled = v),
        ),
        _switchCard(
          title: 'Weekly Reports',
          value: _weeklyReportsEnabled,
          onChanged: (v) => setState(() => _weeklyReportsEnabled = v),
        ),
        _switchCard(
          title: 'Auto Player Assign',
          value: _playerAutoAssignEnabled,
          onChanged: (v) => setState(() => _playerAutoAssignEnabled = v),
        ),
      ],
    );
  }

  Widget _metricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchCard({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.yellow,
          ),
        ],
      ),
    );
  }

  List<Widget> _permissionChips(Permissions p) {
    final values = <MapEntry<String, bool>>[
      MapEntry('Create Player', p.createPlayer),
      MapEntry('Read Player', p.readPlayer),
      MapEntry('Update Player', p.updatePlayer),
      MapEntry('Delete Player', p.deletePlayer),
      MapEntry('Create Team', p.createTeam),
      MapEntry('Manage Staff', p.manageStaff),
    ];
    return values
        .where((e) => e.value)
        .map((e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                e.key,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ))
        .toList();
  }

  Color _staffRoleColor(String role) {
    switch (role) {
      case 'assistant_coach':
        return const Color(0xFF8B5CF6);
      case 'coach':
        return AppColors.blue;
      case 'custom':
        return AppColors.green;
      default:
        return AppColors.yellow;
    }
  }

  InputDecoration _dialogInputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF111827),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.yellow, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _dialogTitle(IconData icon, String title, {String? subtitle, Color color = AppColors.yellow}) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              if (subtitle != null)
                Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  AlertDialog _adminDialog({
    required Widget title,
    required Widget content,
    required List<Widget> actions,
  }) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0B1220),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      title: title,
      content: content,
      actions: actions,
    );
  }

  void _showTeamManagementDialog(BuildContext context, Team team) {
    final provider = context.read<AcademyProvider>();
    String? selectedCoachId = team.coachStaffId;
    String? selectedAssistantId = team.assistantCoachStaffId;

    final coaches = provider.academy.staff.where((s) => s.role == 'coach').toList();
    final assistantCoaches = provider.academy.staff
        .where((s) => s.role == 'assistant_coach')
        .toList();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return _adminDialog(
            title: _dialogTitle(
              Icons.group_work_rounded,
              'Manage ${team.name}',
              subtitle: 'Assign coach hierarchy',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String?>(
                    value: selectedCoachId,
                    dropdownColor: const Color(0xFF111827),
                    style: const TextStyle(color: Colors.white),
                    decoration: _dialogInputDecoration('Assign Coach'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Not assigned'),
                      ),
                      ...coaches.map(
                        (staff) => DropdownMenuItem<String?>(
                          value: staff.id,
                          child: Text(staff.name),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => selectedCoachId = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: selectedAssistantId,
                    dropdownColor: const Color(0xFF111827),
                    style: const TextStyle(color: Colors.white),
                    decoration: _dialogInputDecoration('Assign Assistant Coach'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Not assigned'),
                      ),
                      ...assistantCoaches.map(
                        (staff) => DropdownMenuItem<String?>(
                          value: staff.id,
                          child: Text(staff.name),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => selectedAssistantId = value),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  provider.assignTeamLeads(
                    teamId: team.id,
                    coachStaffId: selectedCoachId,
                    assistantCoachStaffId: selectedAssistantId,
                  );
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showStaffCredentialsDialog(
    BuildContext context, {
    required String name,
    required String email,
    required String password,
  }) {
    showDialog(
      context: context,
      builder: (_) => _adminDialog(
        title: _dialogTitle(
          Icons.verified_user_rounded,
          'Credentials Created',
          subtitle: 'Share securely with staff member',
          color: AppColors.green,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: $name', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 6),
            Text('Email: $email', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 6),
            Text('Password: $password', style: const TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showEditStaffDialog(BuildContext context, Staff staff) {
    final provider = context.read<AcademyProvider>();
    final nameController = TextEditingController(text: staff.name);
    final emailController = TextEditingController(text: staff.email);
    final passwordController = TextEditingController(text: staff.password);
    final customRoleController = TextEditingController(text: staff.customRoleName ?? '');
    String role = staff.role;
    final Set<String> selectedTeamIds = {...staff.assignedTeamIds};
    final permissions = Permissions(
      createPlayer: staff.permissions.createPlayer,
      readPlayer: staff.permissions.readPlayer,
      updatePlayer: staff.permissions.updatePlayer,
      deletePlayer: staff.permissions.deletePlayer,
      createTeam: staff.permissions.createTeam,
      manageStaff: staff.permissions.manageStaff,
    );

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return _adminDialog(
            title: _dialogTitle(
              Icons.edit_note_rounded,
              'Edit Staff',
              subtitle: 'Update profile, access and permissions',
              color: const Color(0xFF8B5CF6),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Text(
                      'Profile & Credentials',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _dialogInputDecoration('Name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: _dialogInputDecoration('Login Email'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _dialogInputDecoration('Password'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: role,
                    dropdownColor: const Color(0xFF111827),
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: 'coach', child: Text('Coach')),
                      DropdownMenuItem(value: 'assistant_coach', child: Text('Assistant Coach')),
                      DropdownMenuItem(value: 'custom', child: Text('Custom')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => role = value);
                    },
                    decoration: _dialogInputDecoration('Role'),
                  ),
                  if (role == 'custom') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: customRoleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _dialogInputDecoration('Custom role name'),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Team Access',
                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        ...provider.academy.teams.map((team) {
                          final selected = selectedTeamIds.contains(team.id);
                          return CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            activeColor: AppColors.yellow,
                            title: Text(team.name, style: const TextStyle(color: Colors.white70)),
                            value: selected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  selectedTeamIds.add(team.id);
                                } else {
                                  selectedTeamIds.remove(team.id);
                                }
                              });
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Permissions',
                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.yellow,
                          title: const Text('Create Player', style: TextStyle(color: Colors.white70)),
                          value: permissions.createPlayer,
                          onChanged: (val) => setState(() => permissions.createPlayer = val ?? false),
                        ),
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.yellow,
                          title: const Text('Read Player', style: TextStyle(color: Colors.white70)),
                          value: permissions.readPlayer,
                          onChanged: (val) => setState(() => permissions.readPlayer = val ?? false),
                        ),
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.yellow,
                          title: const Text('Update Player', style: TextStyle(color: Colors.white70)),
                          value: permissions.updatePlayer,
                          onChanged: (val) => setState(() => permissions.updatePlayer = val ?? false),
                        ),
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.yellow,
                          title: const Text('Delete Player', style: TextStyle(color: Colors.white70)),
                          value: permissions.deletePlayer,
                          onChanged: (val) => setState(() => permissions.deletePlayer = val ?? false),
                        ),
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.yellow,
                          title: const Text('Create Team', style: TextStyle(color: Colors.white70)),
                          value: permissions.createTeam,
                          onChanged: (val) => setState(() => permissions.createTeam = val ?? false),
                        ),
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.yellow,
                          title: const Text('Manage Staff', style: TextStyle(color: Colors.white70)),
                          value: permissions.manageStaff,
                          onChanged: (val) => setState(() => permissions.manageStaff = val ?? false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  provider.updateStaff(
                    Staff(
                      id: staff.id,
                      name: nameController.text.trim(),
                      email: emailController.text.trim(),
                      password: passwordController.text.trim(),
                      role: role,
                      customRoleName: role == 'custom' ? customRoleController.text.trim() : null,
                      assignedTeamIds: selectedTeamIds.toList(),
                      permissions: permissions,
                    ),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteStaff(BuildContext context, Staff staff) {
    showDialog(
      context: context,
      builder: (_) => _adminDialog(
        title: _dialogTitle(
          Icons.warning_amber_rounded,
          'Delete Staff',
          subtitle: 'This action cannot be undone',
          color: Colors.redAccent,
        ),
        content: Text(
          'Are you sure you want to delete ${staff.name}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AcademyProvider>().deleteStaff(staff.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showManageAcademyDialog(BuildContext context) {
    final provider = context.read<AcademyProvider>();
    final academyNameController = TextEditingController(text: provider.academy.name);
    final logoController = TextEditingController(text: provider.academy.logoUrl ?? '');
    final ownerNameController = TextEditingController(text: provider.adminName);
    final ownerEmailController = TextEditingController(text: provider.adminEmail);
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => _adminDialog(
        title: _dialogTitle(
          Icons.apartment_rounded,
          'Manage Academy Profile',
          subtitle: 'Branding, owner profile and security',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: academyNameController,
                style: const TextStyle(color: Colors.white),
                decoration: _dialogInputDecoration('Academy Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: logoController,
                style: const TextStyle(color: Colors.white),
                decoration: _dialogInputDecoration('Academy Logo URL', hint: 'https://...'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ownerNameController,
                style: const TextStyle(color: Colors.white),
                decoration: _dialogInputDecoration('Admin Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ownerEmailController,
                style: const TextStyle(color: Colors.white),
                decoration: _dialogInputDecoration('Admin Email'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                style: const TextStyle(color: Colors.white),
                decoration: _dialogInputDecoration('New Password (optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.updateAcademyProfile(
                academyName: academyNameController.text.trim(),
                logoUrl: logoController.text.trim().isEmpty ? null : logoController.text.trim(),
                ownerName: ownerNameController.text.trim(),
                ownerEmail: ownerEmailController.text.trim(),
                newPassword: passwordController.text.trim(),
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCreateTeamDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => CreateTeamDialog(
        onTeamCreated: (name, ageGroup, color) {
          final provider = context.read<AcademyProvider>();
          provider.addTeam(
            Team(
              id: provider.nextId('t'),
              name: name,
              ageGroup: ageGroup,
              colorValue: color.value,
              players: [],
            ),
          );
        },
      ),
    );
  }

  void _showAddPlayerDialog(BuildContext context, {String? initialTeamId}) {
    final nameController = TextEditingController();
    final positionController = TextEditingController();
    final ageController = TextEditingController();
    String? selectedTeamId = initialTeamId;
    showDialog(
      context: context,
      builder: (_) {
        return Consumer<AcademyProvider>(
          builder: (context, provider, __) {
            selectedTeamId ??=
                provider.academy.teams.isNotEmpty ? provider.academy.teams.first.id : null;
            return _adminDialog(
              title: _dialogTitle(
                Icons.sports_basketball_rounded,
                'Add Player',
                subtitle: 'Create and assign to team',
                color: AppColors.blue,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedTeamId,
                      dropdownColor: const Color(0xFF111827),
                      style: const TextStyle(color: Colors.white),
                      items: provider.academy.teams.map((team) {
                        return DropdownMenuItem(value: team.id, child: Text(team.name));
                      }).toList(),
                      onChanged: (val) => selectedTeamId = val,
                      decoration: _dialogInputDecoration('Team'),
                    ),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _dialogInputDecoration('Name'),
                    ),
                    TextField(
                      controller: positionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _dialogInputDecoration('Position'),
                    ),
                    TextField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: _dialogInputDecoration('Age'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (selectedTeamId == null || nameController.text.trim().isEmpty) return;
                    final age = int.tryParse(ageController.text.trim()) ?? 16;
                    provider.addPlayer(
                      selectedTeamId!,
                      Player(
                        id: provider.nextId('p'),
                        name: nameController.text.trim(),
                        position: positionController.text.trim().isEmpty
                            ? 'Guard'
                            : positionController.text.trim(),
                        age: age,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddStaffDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final customRoleController = TextEditingController();
    String role = 'coach';
    final Set<String> selectedTeamIds = <String>{};
    final permissions = Permissions();

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return _adminDialog(
              title: _dialogTitle(
                Icons.person_add_alt_1_rounded,
                'Create Staff Account',
                subtitle: 'Create credentials and assign access',
                color: const Color(0xFF8B5CF6),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _dialogInputDecoration('Name'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: _dialogInputDecoration('Login Email'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _dialogInputDecoration('Password'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: role,
                      dropdownColor: const Color(0xFF111827),
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: 'coach', child: Text('Coach')),
                        DropdownMenuItem(
                          value: 'assistant_coach',
                          child: Text('Assistant Coach'),
                        ),
                        DropdownMenuItem(value: 'custom', child: Text('Custom')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => role = value);
                      },
                      decoration: _dialogInputDecoration('Role'),
                    ),
                    if (role == 'custom')
                      TextField(
                        controller: customRoleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _dialogInputDecoration('Custom role name'),
                      ),
                    const SizedBox(height: 8),
                    Consumer<AcademyProvider>(
                      builder: (context, provider, __) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Team Access',
                                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...provider.academy.teams.map((team) {
                              final selected = selectedTeamIds.contains(team.id);
                              return CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(team.name, style: const TextStyle(color: Colors.white70)),
                                value: selected,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      selectedTeamIds.add(team.id);
                                    } else {
                                      selectedTeamIds.remove(team.id);
                                    }
                                  });
                                },
                              );
                            }),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Permissions',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Create Player', style: TextStyle(color: Colors.white70)),
                      value: permissions.createPlayer,
                      onChanged: (val) => setState(() => permissions.createPlayer = val ?? false),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Read Player', style: TextStyle(color: Colors.white70)),
                      value: permissions.readPlayer,
                      onChanged: (val) => setState(() => permissions.readPlayer = val ?? false),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Update Player', style: TextStyle(color: Colors.white70)),
                      value: permissions.updatePlayer,
                      onChanged: (val) => setState(() => permissions.updatePlayer = val ?? false),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Delete Player', style: TextStyle(color: Colors.white70)),
                      value: permissions.deletePlayer,
                      onChanged: (val) => setState(() => permissions.deletePlayer = val ?? false),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Create Team', style: TextStyle(color: Colors.white70)),
                      value: permissions.createTeam,
                      onChanged: (val) => setState(() => permissions.createTeam = val ?? false),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Manage Staff', style: TextStyle(color: Colors.white70)),
                      value: permissions.manageStaff,
                      onChanged: (val) => setState(() => permissions.manageStaff = val ?? false),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    if (emailController.text.trim().isEmpty) return;
                    if (passwordController.text.trim().isEmpty) return;
                    if (role == 'custom' && customRoleController.text.trim().isEmpty) return;
                    final provider = context.read<AcademyProvider>();
                    final createdName = nameController.text.trim();
                    final createdEmail = emailController.text.trim();
                    final createdPassword = passwordController.text.trim();
                    provider.addStaff(
                      Staff(
                        id: provider.nextId('s'),
                        name: createdName,
                        email: createdEmail,
                        password: createdPassword,
                        role: role,
                        customRoleName: role == 'custom'
                            ? customRoleController.text.trim()
                            : null,
                        assignedTeamIds: selectedTeamIds.toList(),
                        permissions: permissions,
                      ),
                    );
                    Navigator.pop(context);
                    _showStaffCredentialsDialog(
                      context,
                      name: createdName,
                      email: createdEmail,
                      password: createdPassword,
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;

  _NavItemData({required this.icon, required this.label});
}

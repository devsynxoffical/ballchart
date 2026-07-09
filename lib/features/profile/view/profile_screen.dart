import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../viewmodel/profile_viewmodel.dart';
import 'package:ballchart/core/widgets/dialogues/EditAcademyDialog.dart';
import 'package:ballchart/core/widgets/dialogues/CreateTeamDialog.dart';
import 'package:ballchart/core/repositories/profile_repository.dart';
import 'package:ballchart/core/services/api_service.dart';
import 'package:ballchart/core/legal/app_legal_urls.dart';
import 'package:ballchart/core/widgets/delete_account_dialog.dart';
import 'package:ballchart/features/management/viewmodel/academy_provider.dart';
import 'package:ballchart/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:ballchart/features/player/view/player_detail_screen.dart';
import 'package:ballchart/core/models/local_academy_models.dart';
import 'package:ballchart/core/models/user_model.dart';
import 'package:ballchart/features/staff/service/staff_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  final ApiService _apiService = ApiService();

  static const Color primaryColor = Color(0xFFFFD900);
  static const Color bgColor = Color(0xFF131313);
  static const Color surfaceHigh = Color(0xFF201F1F);
  static const Color outlineColor = Color(0xFF9D8F79);

  void _showEnrollPlayerDialog(BuildContext context, AcademyProvider provider) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String selectedTeamId = provider.academy.teams.isNotEmpty ? provider.academy.teams.first.id : '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceHigh,
        title: const Text('Enroll New Player', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Player Name',
                labelStyle: const TextStyle(color: outlineColor),
                filled: true,
                fillColor: bgColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: const TextStyle(color: outlineColor),
                filled: true,
                fillColor: bgColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedTeamId.isNotEmpty ? selectedTeamId : null,
              decoration: InputDecoration(
                labelText: 'Assign to Team',
                labelStyle: const TextStyle(color: outlineColor),
                filled: true,
                fillColor: bgColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              dropdownColor: surfaceHigh,
              items: provider.academy.teams.map((team) {
                return DropdownMenuItem<String>(
                  value: team.id,
                  child: Text(team.name, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (value) {
                selectedTeamId = value ?? '';
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: outlineColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty && 
                  emailController.text.trim().isNotEmpty && 
                  selectedTeamId.isNotEmpty) {
                try {
                  await provider.addPlayerToBackend(
                    selectedTeamId,
                    Player(
                      id: provider.nextId('p'),
                      name: nameController.text.trim(),
                      email: emailController.text.trim(),
                      age: 18,
                      position: 'Player',
                    ),
                    email: emailController.text.trim(),
                    password: 'temp123', // You might want to generate a random password
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${nameController.text} enrolled successfully!'),
                        backgroundColor: primaryColor,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to enroll player: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Enroll', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileVm = context.watch<ProfileViewmodel>();
    final user = profileVm.user;

    // For player role, use only the detailed player profile screen.
    if (user != null && user.role == 'player') {
      final player = _resolveCurrentPlayer(context, user);
      return PlayerDetailScreen(player: player, canEdit: true, showHeader: false);
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Consumer<ProfileViewmodel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) return const Center(child: CircularProgressIndicator(color: primaryColor));
            final user = viewModel.user;
            if (user == null) return const Center(child: Text('Not signed in', style: TextStyle(color: outlineColor)));

            return RefreshIndicator(
              onRefresh: () async {
                await viewModel.loadProfile(forceRefresh: true);
                final u = viewModel.user;
                if (u != null && context.mounted) {
                  context.read<AcademyProvider>().setCurrentUser(u);
                }
              },
              color: primaryColor,
              backgroundColor: const Color(0xFF2A2A2A),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIdentityHeader(user),
                    const SizedBox(height: 32),
                    if (user.role == 'admin') _buildAcademyPartnership(context),
                    const SizedBox(height: 32),
                    Text(
                      user.role.toString().contains('coach') ? 'COACH PROFILE' : 'ACADEMY PROFILE',
                      style: const TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                    const SizedBox(height: 16),
                    _buildBentoGrid(context, user),
                    if (user.role == 'player') ...[
                      const SizedBox(height: 16),
                      _buildOpenPlayerDetailButton(context, user),
                    ],
                    const SizedBox(height: 32),
                    const Text('OPERATIONAL SETTINGS', style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 16),
                    _buildSystemActions(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Player _resolveCurrentPlayer(BuildContext context, dynamic user) {
    final academyProvider = context.read<AcademyProvider>();
    try {
      return academyProvider.academy.teams
          .expand((t) => t.players)
          .firstWhere((p) => p.email == user.email);
    } catch (_) {
      return Player(
        id: user.id,
        name: user.username,
        email: user.email,
        position: (user.position ?? 'Player').toString(),
        age: int.tryParse((user.ageRange ?? '18').toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 18,
      );
    }
  }

  Widget _buildIdentityHeader(dynamic user) {
    final initials = user.username
        .toString()
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e[0].toUpperCase())
        .join();
    final role = user.role.toString();
    final canEditIdentity = role == 'admin' || role.contains('coach');
    final academyProvider = context.watch<AcademyProvider>();
    String? networkAvatar;
    if (role == 'admin') {
      final logo = academyProvider.academy.logoUrl;
      if (logo != null && logo.trim().isNotEmpty) {
        networkAvatar = ApiService.resolveMediaUrl(logo);
      }
    } else if (user is UserModel) {
      final pic = user.profileImageUrl;
      if (pic != null && pic.trim().isNotEmpty) {
        networkAvatar = ApiService.resolveMediaUrl(pic);
      }
    }
    if (networkAvatar != null && networkAvatar.isEmpty) networkAvatar = null;
    final hasNetworkAvatar = networkAvatar != null &&
        (networkAvatar.startsWith('http://') ||
            networkAvatar.startsWith('https://') ||
            networkAvatar.startsWith('data:'));

    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: canEditIdentity ? () => _showProfilePhotoMenu(context, user) : null,
            child: Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [primaryColor, Color(0xFFFFBA29)])),
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: bgColor,
                  backgroundImage: hasNetworkAvatar ? NetworkImage(networkAvatar!) : null,
                  child: !hasNetworkAvatar
                      ? (role == 'admin'
                          ? Image.asset('basketball_icon.png', fit: BoxFit.cover)
                          : Text(
                              initials.isEmpty ? 'U' : initials,
                              style: const TextStyle(color: primaryColor, fontSize: 30, fontWeight: FontWeight.w900),
                            ))
                      : null,
                ),
              ),
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle, border: Border.fromBorderSide(BorderSide(color: bgColor, width: 3))),
                ),
              ),
              if (canEditIdentity)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                    child: const Icon(Icons.edit, size: 12, color: primaryColor),
                  ),
                ),
            ],
          ),
          ),
        ),
        const SizedBox(height: 20),
        Text(user.username.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk')),
        Text('${user.role.replaceAll('_', ' ').toUpperCase()} // ACTIVE SQUADRON', style: const TextStyle(color: outlineColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildAcademyPartnership(BuildContext context) {
    return Consumer<AcademyProvider>(
      builder: (context, provider, _) {
        final academy = provider.academy;
        final user = provider.currentUser;
        final isAdmin = user?.role == 'admin';
        
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(24), border: Border.all(color: primaryColor.withOpacity(0.1))),
          child: Column(
            children: [
              Row(
                children: [
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.shield, color: primaryColor, size: 24)),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ACADEMY NAME', style: TextStyle(color: outlineColor, fontSize: 8, fontWeight: FontWeight.bold)),
                        Text(academy.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
                      ],
                    ),
                  ),
                  if (isAdmin) // Only show edit button for admin
                    IconButton(
                      icon: const Icon(Icons.edit_note, color: primaryColor, size: 24),
                      onPressed: () => _showEditAcademyDialog(context, provider),
                    ),
                ],
              ),
              // Only show action buttons for admin
              if (isAdmin) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _actionBtn(context, 'NEW SQUAD', Icons.add_moderator, () => _showCreateTeamDialog(context, provider)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionBtn(context, 'ENROLL PLAYER', Icons.person_add_alt_1, () => _showEnrollPlayerDialog(context, provider)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _actionBtn(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black, size: 14),
            const SizedBox(width: 4),
            Expanded(child: Text(title, style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5), textAlign: TextAlign.center, maxLines: 1)),
          ],
        ),
      ),
    );
  }

  void _showEditAcademyDialog(BuildContext context, AcademyProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditAcademyDialog(
        currentName: provider.academy.name,
        currentLogo: provider.academy.logoUrl,
        currentOwner: provider.adminName,
        currentEmail: provider.adminEmail,
      ),
    );
  }

  void _showCreateTeamDialog(BuildContext context, AcademyProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateTeamDialog(onTeamCreated: (name, tier, color, logo, coachId, assistantId) async {
        await provider.addTeamToBackend(Team(
          id: '',
          name: name,
          ageGroup: tier,
          colorValue: color.value,
          logoPath: logo,
          coachStaffId: coachId,
          assistantCoachStaffId: assistantId,
          players: [],
        ));
      }),
    );
  }

  Widget _buildBentoGrid(BuildContext context, dynamic user) {
    final role = user.role.toString();
    final experience = (user.experienceLevel ?? 'Not set').toString();
    final academyProvider = context.watch<AcademyProvider>();
    final academy = academyProvider.academy;
    final assignedTeams = _assignedTeamsDisplay(user, academyProvider);
    final achievements = user.achievements is List ? (user.achievements as List).length.toString() : '0';
    final additional = (user.additionalInfo ?? 'N/A').toString();
    final position = (user.position ?? 'N/A').toString();

    if (role == 'admin') {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _bentoCard(
                  'OWNER NAME',
                  user.username,
                  Icons.person_outline,
                  onTap: () => _showEditProfileDialog(context, user),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _bentoCard(
                  'EMAIL ADDRESS',
                  user.email,
                  Icons.alternate_email,
                  onTap: () => _showEditProfileDialog(context, user),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _bentoCard(
                  'ACADEMY NAME',
                  academy.name,
                  Icons.shield_outlined,
                  onTap: () => _showEditAcademyDialog(context, academyProvider),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _bentoCard(
                  'EXPERIENCE LEVEL',
                  experience,
                  Icons.timeline,
                  onTap: () => _showEditProfileDialog(context, user),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _bentoCard('TOTAL TEAMS', academy.teams.length.toString(), Icons.groups_2_outlined)),
              const SizedBox(width: 16),
              Expanded(child: _bentoCard('TOTAL STAFF', academy.staff.length.toString(), Icons.badge_outlined)),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _bentoCard(
                'EMAIL ADDRESS',
                user.email,
                Icons.alternate_email,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _bentoCard(
                'EXPERIENCE LEVEL',
                role.contains('coach') ? experience : position,
                Icons.timeline,
                onTap: role.contains('coach') ? () => _showEditCoachDialog(context, user) : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _bentoCard(
                'ASSIGNED TEAMS',
                role.contains('coach') ? assignedTeams : (user.ageRange ?? 'N/A').toString(),
                Icons.badge,
                onTap: role.contains('coach') ? () => _showEditCoachDialog(context, user) : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _bentoCard(
                role.contains('coach') ? 'ACHIEVEMENTS' : 'GOALS',
                role.contains('coach') ? achievements : ((user.goals as List?)?.length.toString() ?? '0'),
                Icons.psychology,
                onTap: role.contains('coach') ? () => _showEditCoachDialog(context, user) : null,
              ),
            ),
          ],
        ),
        if (role.contains('coach')) ...[
          const SizedBox(height: 16),
          _bentoCard(
            'ADDITIONAL INFO',
            additional,
            Icons.sticky_note_2_outlined,
            onTap: () => _showEditCoachDialog(context, user),
          ),
        ],
      ],
    );
  }

  String _assignedTeamsDisplay(dynamic user, AcademyProvider academyProvider) {
    final ids = user is UserModel
        ? (user.assignedTeamIds ?? user.assignedTeams ?? const <String>[])
        : (user.assignedTeamIds is List
            ? List<String>.from(user.assignedTeamIds as List)
            : (user.assignedTeams is List ? List<String>.from(user.assignedTeams as List) : const <String>[]));
    if (ids.isEmpty) return 'None';

    final dashboard = academyProvider.coachDashboard;
    final rawTeams = dashboard?['allTeams'] as List? ?? dashboard?['teams'] as List? ?? academyProvider.academy.teams;
    final names = <String>[];
    for (final id in ids) {
      final match = rawTeams.cast<dynamic>().where((t) {
        if (t is Team) return t.id == id;
        if (t is Map) return (t['_id'] ?? t['id'] ?? '').toString() == id;
        return false;
      }).toList();
      if (match.isNotEmpty) {
        final t = match.first;
        names.add(t is Team ? t.name : (t as Map)['name']?.toString() ?? id);
      } else {
        names.add(id);
      }
    }
    return names.join(', ');
  }

  void _showEditCoachDialog(BuildContext context, dynamic user) async {
    final academyProvider = context.read<AcademyProvider>();
    await academyProvider.loadCoachDashboard(force: true);

    final expController = TextEditingController(text: (user.experienceLevel ?? '').toString());
    final sportsController = TextEditingController(text: ((user.sports as List?) ?? const []).join(', '));
    final achievementsController = TextEditingController(text: ((user.achievements as List?) ?? const []).join(', '));
    final infoController = TextEditingController(text: (user.additionalInfo ?? '').toString());

    final initialIds = user is UserModel
        ? Set<String>.from(user.assignedTeamIds ?? user.assignedTeams ?? const <String>[])
        : Set<String>.from(
            user.assignedTeamIds is List
                ? user.assignedTeamIds as List
                : (user.assignedTeams is List ? user.assignedTeams as List : const <String>[]),
          );

    final dashboard = academyProvider.coachDashboard;
    final academyTeams = (dashboard?['allTeams'] as List? ?? dashboard?['teams'] as List? ?? [])
        .map((t) => Map<String, dynamic>.from(t as Map))
        .toList();

    if (!context.mounted) return;

    final selectedTeamIds = Set<String>.from(initialIds);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: surfaceHigh,
          title: const Text('Edit Coach Details', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEditField(expController, 'Experience level'),
                const SizedBox(height: 12),
                _buildEditField(sportsController, 'Sports (comma separated)'),
                const SizedBox(height: 12),
                _buildEditField(achievementsController, 'Achievements (comma separated)'),
                const SizedBox(height: 12),
                _buildEditField(infoController, 'Additional information'),
                const SizedBox(height: 16),
                const Text('ASSIGNED TEAMS', style: TextStyle(color: outlineColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 8),
                if (academyTeams.isEmpty)
                  const Text('No academy teams available yet.', style: TextStyle(color: outlineColor, fontSize: 12))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: academyTeams.map((team) {
                      final id = (team['_id'] ?? team['id'] ?? '').toString();
                      final name = (team['name'] ?? 'Team').toString();
                      final selected = selectedTeamIds.contains(id);
                      return FilterChip(
                        label: Text(name),
                        selected: selected,
                        onSelected: (v) => setDialogState(() {
                          if (v) {
                            selectedTeamIds.add(id);
                          } else {
                            selectedTeamIds.remove(id);
                          }
                        }),
                        selectedColor: primaryColor.withOpacity(0.35),
                        checkmarkColor: primaryColor,
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: outlineColor))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () async {
                final repo = ProfileRepository();
                await repo.completeProfile({
                  'experienceLevel': expController.text.trim(),
                  'sports': sportsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                  'achievements': achievementsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                  'additionalInfo': infoController.text.trim(),
                  'assignedTeamIds': selectedTeamIds.toList(),
                });
                if (context.mounted) {
                  Navigator.pop(ctx);
                  await context.read<ProfileViewmodel>().loadProfile(forceRefresh: true);
                  await context.read<AcademyProvider>().loadCoachDashboard(force: true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coach profile updated'), backgroundColor: primaryColor),
                    );
                  }
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: outlineColor),
        filled: true,
        fillColor: bgColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _bentoCard(String title, String value, IconData icon, {VoidCallback? onTap}) {
    final content = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: surfaceHigh, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: outlineColor, size: 18),
              const Spacer(),
              if (onTap != null) const Icon(Icons.edit_outlined, color: primaryColor, size: 16),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          const Divider(color: Colors.white10),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: outlineColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: content,
    );
  }

  Future<void> _showProfilePhotoMenu(BuildContext context, dynamic user) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: outlineColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: primaryColor),
              title: const Text('Change profile photo', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, 'photo'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: primaryColor),
              title: const Text('Edit name, email & details', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (choice == 'photo') {
      await _pickAndSaveProfilePhoto(context, user);
    } else if (choice == 'edit') {
      await _showEditProfileDialog(context, user);
    }
  }

  Future<void> _pickAndSaveProfilePhoto(BuildContext context, dynamic user) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !context.mounted) return;
    try {
      final staff = StaffService();
      final url = await staff.uploadImage(File(file.path));
      if (url == null || url.isEmpty) {
        throw Exception('Upload returned no URL');
      }
      final repo = ProfileRepository();
      final payload = <String, dynamic>{};
      final r = user.role.toString();
      if (r == 'admin') {
        payload['logoUrl'] = url;
      } else if (r.contains('coach')) {
        payload['profilePic'] = url;
      } else if (r == 'player') {
        payload['profileImageUrl'] = url;
      } else {
        payload['profilePic'] = url;
      }
      await repo.completeProfile(payload);
      if (!context.mounted) return;
      await context.read<ProfileViewmodel>().loadProfile(forceRefresh: true);
      final role = user.role.toString();
      if (role == 'admin') {
        await context.read<AcademyProvider>().loadAdminOverview(force: true);
      } else if (role.contains('coach')) {
        await context.read<AcademyProvider>().loadCoachDashboard(force: true);
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated'), backgroundColor: primaryColor),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update photo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showEditProfileDialog(BuildContext context, dynamic user) async {
    final academyProvider = context.read<AcademyProvider>();
    String initialImg = '';
    if (user is UserModel) {
      if (user.role == 'admin') {
        initialImg = academyProvider.academy.logoUrl?.trim() ?? '';
      } else {
        initialImg = user.profileImageUrl?.trim() ?? '';
      }
    }
    final nameController = TextEditingController(text: user.username.toString());
    final emailController = TextEditingController(text: user.email.toString());
    final experienceController = TextEditingController(text: (user.experienceLevel ?? '').toString());
    final profileImageController = TextEditingController(text: initialImg);

    Future<void> pickAndUploadImage(StateSetter setDialogState) async {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (file == null) return;
      final uploaded = await _apiService.uploadFile('/upload/image', File(file.path));
      final url = uploaded['url']?.toString() ?? '';
      if (url.isNotEmpty) {
        setDialogState(() => profileImageController.text = url);
      }
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: surfaceHigh,
          title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildEditField(nameController, 'Name'),
                const SizedBox(height: 12),
                _buildEditField(emailController, 'Email'),
                const SizedBox(height: 12),
                _buildEditField(experienceController, 'Experience level'),
                const SizedBox(height: 12),
                _buildEditField(profileImageController, 'Profile image URL'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => pickAndUploadImage(setDialogState),
                    icon: const Icon(Icons.upload_file, color: primaryColor),
                    label: const Text('Upload New Picture', style: TextStyle(color: primaryColor)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: outlineColor))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () async {
                final repo = ProfileRepository();
                final payload = <String, dynamic>{
                  'username': nameController.text.trim(),
                  'email': emailController.text.trim(),
                  'experienceLevel': experienceController.text.trim(),
                };
                final img = profileImageController.text.trim();
                if (img.isNotEmpty) {
                  final r = user.role.toString();
                  if (r == 'admin') {
                    payload['logoUrl'] = img;
                  } else if (r.contains('coach')) {
                    payload['profilePic'] = img;
                  } else if (r == 'player') {
                    payload['profileImageUrl'] = img;
                  } else {
                    payload['profilePic'] = img;
                  }
                }
                await repo.completeProfile(payload);
                if (context.mounted) {
                  await context.read<ProfileViewmodel>().loadProfile(forceRefresh: true);
                  final r = user.role.toString();
                  if (r == 'admin') {
                    await context.read<AcademyProvider>().loadAdminOverview(force: true);
                  } else if (r.contains('coach')) {
                    await context.read<AcademyProvider>().loadCoachDashboard(force: true);
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated'), backgroundColor: primaryColor),
                  );
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenPlayerDetailButton(BuildContext context, dynamic user) {
    return GestureDetector(
      onTap: () {
        final academyProvider = context.read<AcademyProvider>();
        Player? existingPlayer;
        try {
          existingPlayer = academyProvider.academy.teams
              .expand((t) => t.players)
              .firstWhere((p) => p.email == user.email);
        } catch (_) {
          existingPlayer = null;
        }

        final player = existingPlayer ??
            Player(
              id: user.id,
              name: user.username,
              email: user.email,
              position: (user.position ?? 'Player').toString(),
              age: int.tryParse((user.ageRange ?? '18').toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 18,
            );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlayerDetailScreen(player: player, canEdit: true, showHeader: false)),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: surfaceHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryColor.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'OPEN DETAILED PLAYER PROFILE',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.6),
            ),
            Icon(Icons.arrow_forward_rounded, color: primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemActions(BuildContext context) {
    return Column(
      children: [
        _systemRow('NOTIFICATIONS ACTIVE', Icons.notifications_active, _notificationsEnabled, (value) {
          setState(() {
            _notificationsEnabled = value;
          });
          // TODO: Implement notification settings logic
        }),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => Provider.of<AuthViewmodel>(context, listen: false).logout(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.05), border: Border.all(color: Colors.redAccent.withOpacity(0.2)), borderRadius: BorderRadius.circular(24)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.power_settings_new, color: Colors.redAccent, size: 20),
                const SizedBox(width: 12),
                const Text('LOGOUT', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk', letterSpacing: 1.5)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(child: AppLegalUrls.inlineTextButtons(context)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => showDeleteAccountDialog(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_forever_outlined, color: Colors.white54, size: 20),
                SizedBox(width: 10),
                Text(
                  'DELETE ACCOUNT',
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _systemRow(String label, IconData icon, bool val, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: surfaceHigh.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: outlineColor, size: 18),
              const SizedBox(width: 16),
              Text(label.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
          Switch(
            value: val, 
            onChanged: onChanged, 
            activeColor: primaryColor, 
            activeTrackColor: primaryColor.withOpacity(0.2), 
            inactiveTrackColor: Colors.white10
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:ballchart/core/utils/app_messenger.dart';
import 'package:provider/provider.dart';
import '../../management/viewmodel/academy_provider.dart';
import 'package:ballchart/core/widgets/dialogues/CreateStaffDialog.dart';
import 'package:ballchart/core/models/local_academy_models.dart';
import 'package:ballchart/core/widgets/user_avatar.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  static const Color primaryColor = Color(0xFFFFD900);
  static const Color tertiaryColor = Color(0xFF28D8FF);
  static const Color bgColor = Color(0xFF131313);
  static const Color surfaceHigh = Color(0xFF2A2A2A);
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color outlineColor = Color(0xFF9D8F79);

  Staff? _selectedStaff;
  bool _isDetailPasswordVisible = false;
  final Set<String> _updatingPermissionKeys = <String>{};
  /// After a permission save, keep this staff's local permission flags for a short window
  /// so any late overview refresh cannot snap the switches back off.
  String? _pinnedStaffId;
  Permissions? _pinnedPermissions;
  DateTime? _pinUntil;

  String _staffRoleLabel(Staff s) {
    final role = s.role.toLowerCase();
    if (role == 'custom' && s.customRoleName != null && s.customRoleName!.trim().isNotEmpty) {
      return s.customRoleName!.trim().toUpperCase();
    }
    return s.role.toUpperCase().replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Consumer<AcademyProvider>(
          builder: (context, provider, _) {
            // Keep selected staff in sync, but never overwrite while a permission
            // toggle request is in flight (that caused switches to snap back).
            // Also honor a short post-save pin so socket/overview races cannot flip toggles off.
            final pinActive = _pinnedStaffId != null &&
                _pinUntil != null &&
                DateTime.now().isBefore(_pinUntil!) &&
                _selectedStaff?.id == _pinnedStaffId;
            if (_selectedStaff != null &&
                _updatingPermissionKeys.isEmpty &&
                !pinActive) {
              try {
                final live =
                    provider.academy.staff.firstWhere((s) => s.id == _selectedStaff!.id);
                _selectedStaff = live;
              } catch (_) {
                _selectedStaff = null;
              }
            } else if (_selectedStaff != null &&
                pinActive &&
                _pinnedPermissions != null) {
              _selectedStaff!.permissions = _pinnedPermissions!;
            }

            return RefreshIndicator(
              onRefresh: () => provider.loadAdminOverview(force: true),
              color: primaryColor,
              backgroundColor: surfaceHigh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildHierarchyTree(provider),
                  const SizedBox(height: 48),
                  if (_selectedStaff != null) ...[
                    _buildStaffDetailCard(provider),
                    const SizedBox(height: 32),
                    _buildPermissionsCard(provider),
                  ] else ...[
                    _buildSelectStaffPlaceholder(),
                  ],
                  const SizedBox(height: 48),
                  _buildOnboardCard(),
                  const SizedBox(height: 120),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'staff_fab',
        onPressed: () => _showAddStaffDialog(context),
        backgroundColor: primaryColor,
        elevation: 10,
        shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        child: const Icon(Icons.add, color: Colors.black, size: 32),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Staff Portal', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
        SizedBox(height: 4),
        Text('STAFF • ACCESS RIGHTS', style: TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
      ],
    );
  }

  Widget _buildHierarchyTree(AcademyProvider provider) {
    final staff = provider.academy.staff;
    if (staff.isEmpty) {
      return const Center(child: Text('NO PERSONNEL DATA FOUND', style: TextStyle(color: outlineColor, fontSize: 10, letterSpacing: 1)));
    }
    final staffList = List<Staff>.from(staff);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('STAFF ROSTER', style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            Text('${staff.length} STAFF MEMBERS', style: const TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 24),
        ...staffList.map((s) {
          final isSelected = _selectedStaff?.id == s.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => setState(() => _selectedStaff = s),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? surfaceHigh : surfaceContainer,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? primaryColor.withOpacity(0.35) : outlineColor.withOpacity(0.14),
                  ),
                ),
                child: Row(
                  children: [
                    UserAvatar(
                      name: s.name,
                      imageUrl: s.profilePic,
                      size: 40,
                      usePersonIconFallback: true,
                      backgroundColor: surfaceContainer,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24 / 2,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Space Grotesk',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _staffRoleLabel(s),
                            style: TextStyle(
                              color: isSelected ? primaryColor : outlineColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isSelected ? Icons.lock : Icons.circle_outlined,
                      size: 18,
                      color: outlineColor,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRootNode(String name, String role, String img) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: surfaceHigh, borderRadius: BorderRadius.circular(20), border: Border.all(color: primaryColor.withOpacity(0.3))),
      child: Row(
        children: [
          UserAvatar(
            name: name,
            imageUrl: img.contains('ui-avatars') ? null : img,
            size: 40,
            usePersonIconFallback: true,
            backgroundColor: surfaceContainer,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
                Text(role.toUpperCase(), style: const TextStyle(color: primaryColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ],
            ),
          ),
          const Icon(Icons.admin_panel_settings_rounded, color: outlineColor, size: 20),
        ],
      ),
    );
  }

  Widget _buildChildNode(String name, String role, String img) {
    return Stack(
      children: [
        Positioned(left: -13, top: 0, bottom: 20, child: Container(width: 2, color: outlineColor.withOpacity(0.2))),
        Positioned(left: -13, top: 20, child: Container(width: 13, height: 2, color: outlineColor.withOpacity(0.2))),
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: surfaceContainer, borderRadius: BorderRadius.circular(12), border: Border.all(color: outlineColor.withOpacity(0.1))),
          child: Row(
            children: [
              UserAvatar(
                name: name,
                imageUrl: img.contains('ui-avatars') ? null : img,
                size: 32,
                usePersonIconFallback: true,
                backgroundColor: surfaceContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
                    Text(role.toUpperCase(), style: const TextStyle(color: outlineColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectStaffPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: surfaceHigh.withOpacity(0.3), borderRadius: BorderRadius.circular(24), border: Border.all(color: outlineColor.withOpacity(0.1))), // placeholder 
      child: const Column(
        children: [
          Icon(Icons.touch_app_outlined, color: outlineColor, size: 48),
          SizedBox(height: 16),
          Text('SELECT A STAFF MEMBER', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
          SizedBox(height: 8),
          Text('Choose a person from the hierarchy or active profiles to manage their access rights and identity.', textAlign: TextAlign.center, style: TextStyle(color: outlineColor, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStaffDetailCard(AcademyProvider provider) {
    if (_selectedStaff == null) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: surfaceHigh, borderRadius: BorderRadius.circular(24), border: Border.all(color: primaryColor.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                name: _selectedStaff!.name,
                imageUrl: _selectedStaff!.profilePic,
                size: 64,
                usePersonIconFallback: true,
                backgroundColor: surfaceContainer,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_selectedStaff!.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
                    Text(_staffRoleLabel(_selectedStaff!), style: const TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    Text(_selectedStaff!.email, style: const TextStyle(color: outlineColor, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(onPressed: () => setState(() {
                _selectedStaff = null;
                _isDetailPasswordVisible = false;
              }), icon: const Icon(Icons.close, color: outlineColor)),
            ],
          ),
          const SizedBox(height: 32),
          const Text('CREDENTIALS', style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 16),
          _detailField('Login Email', _selectedStaff!.email, (val) async {
            if (val.isEmpty) return;
            _selectedStaff!.email = val;
            await provider.updateStaffInBackend(_selectedStaff!);
          }),
          const SizedBox(height: 12),
          _detailField('Current Password', _selectedStaff!.password, (val) async {
             if (val.isEmpty) return;
             _selectedStaff!.password = val;
             await provider.updateStaffInBackend(_selectedStaff!);
             if (mounted) AppMessenger.showSnackBar(context, const SnackBar(content: Text('PASSWORD UPDATED SECURELY')));
          }, isPassword: true),
          const SizedBox(height: 32),
          const Text('IDENTITY & PERSONALIZATION', style: TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 16),
          _detailField('Full Name', _selectedStaff!.name, (val) async {
            if (val.isEmpty) return;
            _selectedStaff!.name = val;
            await provider.updateStaffInBackend(_selectedStaff!);
          }),
          _detailField('Profile Picture URL', _selectedStaff!.profilePic ?? '', (val) async {
            _selectedStaff!.profilePic = val.isEmpty ? null : val;
            await provider.updateStaffInBackend(_selectedStaff!);
          }),
        ],
      ),
    );
  }

  Widget _detailField(String label, String value, Function(String) onSubmitted, {bool isPassword = false}) {
    final controller = TextEditingController(text: value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          obscureText: isPassword && !_isDetailPasswordVisible,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: isPassword ? '••••••••' : 'Enter $label',
            hintStyle: TextStyle(color: outlineColor.withOpacity(0.5)),
            filled: true,
            fillColor: bgColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPassword)
                  IconButton(
                    onPressed: () => setState(() => _isDetailPasswordVisible = !_isDetailPasswordVisible),
                    icon: Icon(
                      _isDetailPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: outlineColor,
                      size: 20,
                    ),
                  ),
                IconButton(onPressed: () => onSubmitted(controller.text), icon: const Icon(Icons.check, color: primaryColor, size: 20)),
              ],
            ),
          ),
          onSubmitted: onSubmitted,
        ),
      ],
    );
  }

  Widget _buildPermissionsCard(AcademyProvider provider) {
    if (_selectedStaff == null) return const SizedBox();
    final p = _selectedStaff!.permissions;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF18181A), borderRadius: BorderRadius.circular(24), border: Border.all(color: outlineColor.withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.key, color: primaryColor),
              SizedBox(width: 12),
              Text('Access rights', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
            ],
          ),
          const SizedBox(height: 24),
          _permissionSwitch('createPlayer', 'Create Players', 'Authorize roster additions', p.createPlayer, (v) => _updatePermission(provider, 'createPlayer', v)),
          _permissionSwitch('updatePlayer', 'Update Vital Data', 'Modify player stats & drills', p.updatePlayer, (v) => _updatePermission(provider, 'updatePlayer', v)),
          _permissionSwitch('deletePlayer', 'Delete Records', 'Permanent removal authority', p.deletePlayer, (v) => _updatePermission(provider, 'deletePlayer', v)),
          _permissionSwitch('createTeam', 'Create Teams', 'Expand academy structure', p.createTeam, (v) => _updatePermission(provider, 'createTeam', v)),
          _permissionSwitch('manageStaff', 'Manage Personnel', 'Add/Edit other staff members', p.manageStaff, (v) => _updatePermission(provider, 'manageStaff', v)),
          _permissionSwitch('createBattle', 'Create Games', 'Schedule new match events', p.createBattle, (v) => _updatePermission(provider, 'createBattle', v)),
          _permissionSwitch('manageBattle', 'Manage Games', 'Control match parameters', p.manageBattle, (v) => _updatePermission(provider, 'manageBattle', v)),
          _permissionSwitch('createStrategy', 'Create Strategy', 'Develop playbooks', p.createStrategy, (v) => _updatePermission(provider, 'createStrategy', v)),
          _permissionSwitch('manageStrategy', 'Manage Strategy', 'Direct strategic operations', p.manageStrategy, (v) => _updatePermission(provider, 'manageStrategy', v)),
        ],
      ),
    );
  }

  Widget _permissionSwitch(
    String key,
    String title,
    String sub,
    bool value,
    Future<void> Function(bool) onChanged,
  ) {
    final isUpdating = _updatingPermissionKeys.contains(key);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(sub, style: const TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: isUpdating ? null : onChanged,
            activeColor: primaryColor,
            activeTrackColor: primaryColor.withOpacity(0.3),
            inactiveThumbColor: outlineColor,
            inactiveTrackColor: surfaceHigh,
          ),
        ],
      ),
    );
  }

  Future<void> _updatePermission(AcademyProvider provider, String key, bool value) async {
    if (_selectedStaff == null) return;
    final previous = _selectedStaff!.permissions.toMap();

    void apply(bool nextValue) {
      switch (key) {
        case 'createPlayer':
          _selectedStaff!.permissions.createPlayer = nextValue;
          break;
        case 'updatePlayer':
          _selectedStaff!.permissions.updatePlayer = nextValue;
          break;
        case 'deletePlayer':
          _selectedStaff!.permissions.deletePlayer = nextValue;
          break;
        case 'createTeam':
          _selectedStaff!.permissions.createTeam = nextValue;
          break;
        case 'manageStaff':
          _selectedStaff!.permissions.manageStaff = nextValue;
          break;
        case 'createBattle':
          _selectedStaff!.permissions.createBattle = nextValue;
          if (!nextValue) {
            _selectedStaff!.permissions.manageBattle = false;
          }
          break;
        case 'manageBattle':
          _selectedStaff!.permissions.manageBattle = nextValue;
          if (nextValue) {
            _selectedStaff!.permissions.createBattle = true;
          }
          break;
        case 'createStrategy':
          _selectedStaff!.permissions.createStrategy = nextValue;
          if (!nextValue) {
            _selectedStaff!.permissions.manageStrategy = false;
          }
          break;
        case 'manageStrategy':
          _selectedStaff!.permissions.manageStrategy = nextValue;
          if (nextValue) {
            _selectedStaff!.permissions.createStrategy = true;
          }
          break;
      }
    }

    setState(() {
      _updatingPermissionKeys.add(key);
      apply(value);
    });

    try {
      await provider.updateStaffInBackend(
        _selectedStaff!,
        refreshAfterUpdate: false,
        rethrowOnError: true,
        announceSuccess: false,
      );
      if (!mounted) return;
      _pinnedStaffId = _selectedStaff!.id;
      _pinnedPermissions = Permissions.fromMap(_selectedStaff!.permissions.toMap());
      _pinUntil = DateTime.now().add(const Duration(seconds: 8));
      // Prefer the local saved permissions over any stale overview row.
      try {
        final live =
            provider.academy.staff.firstWhere((s) => s.id == _selectedStaff!.id);
        live.permissions = _pinnedPermissions!;
        _selectedStaff = live;
      } catch (_) {}
      if (mounted) setState(() {});
      AppMessenger.show(
        context,
        message: 'Permission updated',
        kind: AppMessageKind.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _selectedStaff!.permissions = Permissions.fromMap(previous);
      });
      AppMessenger.show(
        context,
        message: 'Failed to update permission: ${e.toString().replaceAll('Exception: ', '')}',
        kind: AppMessageKind.error,
      );
    } finally {
      if (mounted) {
        setState(() => _updatingPermissionKeys.remove(key));
      }
    }
  }

  Widget _buildOnboardCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: primaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: primaryColor.withOpacity(0.2))),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.person_add, color: Colors.black, size: 28),
          ),
          const SizedBox(height: 20),
          const Text('Onboard New Staff', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Instantly generate a portal invite and set preliminary access roles.', textAlign: TextAlign.center, style: TextStyle(color: outlineColor, fontSize: 12)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showAddStaffDialog(context),
            style: ElevatedButton.styleFrom(backgroundColor: surfaceHigh, foregroundColor: primaryColor, side: const BorderSide(color: primaryColor, width: 0.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            child: const Text('QUICK ACTION: ADD STAFF', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddStaffDialog(BuildContext context) async {
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
}

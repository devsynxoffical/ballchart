import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../management/viewmodel/academy_provider.dart';
import 'package:ballchart/core/widgets/dialogues/CreateStaffDialog.dart';
import 'package:ballchart/core/models/local_academy_models.dart';

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

  String _safeProfilePic(String? url, String name) {
    if (url != null && url.startsWith('http')) return url;
    return 'https://picsum.photos/seed/$name/100/100';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Consumer<AcademyProvider>(
          builder: (context, provider, _) {
            // Find updated selected staff in provider's list to keep it reactive
            if (_selectedStaff != null) {
              try {
                _selectedStaff = provider.academy.staff.firstWhere((s) => s.id == _selectedStaff!.id);
              } catch (_) {
                _selectedStaff = null;
              }
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
                  _buildActiveProfiles(provider),
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
        Text('COMMAND CENTER • HIERARCHY & PERMISSIONS', style: TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
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
            const Text('ORGANIZATIONAL HIERARCHY', style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            Text('${staff.length} NODES ACTIVE', style: const TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold)),
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
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(_safeProfilePic(s.profilePic, s.name)),
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
                            s.role.toUpperCase().replaceAll('_', ' '),
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
          CircleAvatar(radius: 20, backgroundImage: NetworkImage(img), backgroundColor: surfaceContainer, child: img.contains('ui-avatars') ? Icon(Icons.person, color: Colors.white, size: 20) : null),
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
              CircleAvatar(radius: 16, backgroundImage: NetworkImage(img), backgroundColor: surfaceContainer, child: img.contains('ui-avatars') ? Icon(Icons.person, color: Colors.white, size: 16) : null),
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
              CircleAvatar(radius: 32, backgroundImage: NetworkImage(_safeProfilePic(_selectedStaff!.profilePic, _selectedStaff!.name)), backgroundColor: surfaceContainer, child: (_selectedStaff!.profilePic?.contains('ui-avatars') ?? false) ? Icon(Icons.person, color: Colors.white, size: 32) : null),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_selectedStaff!.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
                    Text(_selectedStaff!.role.toUpperCase(), style: const TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
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
             if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PASSWORD UPDATED SECURELY')));
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
              Text('Live Permissions', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
            ],
          ),
          const SizedBox(height: 24),
          _permissionSwitch('createPlayer', 'Create Players', 'Authorize roster additions', p.createPlayer, (v) => _updatePermission(provider, 'createPlayer', v)),
          _permissionSwitch('updatePlayer', 'Update Vital Data', 'Modify player stats & drills', p.updatePlayer, (v) => _updatePermission(provider, 'updatePlayer', v)),
          _permissionSwitch('deletePlayer', 'Delete Records', 'Permanent removal authority', p.deletePlayer, (v) => _updatePermission(provider, 'deletePlayer', v)),
          _permissionSwitch('createTeam', 'Create Teams', 'Expand academy structure', p.createTeam, (v) => _updatePermission(provider, 'createTeam', v)),
          _permissionSwitch('manageStaff', 'Manage Personnel', 'Add/Edit other staff members', p.manageStaff, (v) => _updatePermission(provider, 'manageStaff', v)),
          _permissionSwitch('createBattle', 'Create Battles', 'Schedule new match events', p.createBattle, (v) => _updatePermission(provider, 'createBattle', v)),
          _permissionSwitch('manageBattle', 'Manage Battles', 'Control match parameters', p.manageBattle, (v) => _updatePermission(provider, 'manageBattle', v)),
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
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permission updated'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _selectedStaff!.permissions = Permissions.fromMap(previous);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update permission: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingPermissionKeys.remove(key));
      }
    }
  }

  Widget _buildActiveProfiles(AcademyProvider provider) {
    final staff = provider.academy.staff;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ACTIVE PROFILES', style: TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: staff.take(5).map((s) => InkWell(
              onTap: () => setState(() => _selectedStaff = s),
              borderRadius: BorderRadius.circular(40),
              child: _profileCircle(s.name, s.profilePic ?? 'https://picsum.photos/seed/${s.name}/100/100', s.id == _selectedStaff?.id),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _profileCircle(String name, String img, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isActive ? primaryColor : Colors.transparent, width: 2.5)),
            child: CircleAvatar(radius: 28, backgroundImage: NetworkImage(_safeProfilePic(img, name)), backgroundColor: surfaceContainer, child: img.contains('ui-avatars') ? Icon(Icons.person, color: Colors.white, size: 28) : null),
          ),
          const SizedBox(height: 8),
          Text(name.toUpperCase(), style: TextStyle(color: isActive ? primaryColor : Colors.white, fontSize: 10, fontWeight: isActive ? FontWeight.w900 : FontWeight.bold)),
        ],
      ),
    );
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

  void _showAddStaffDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreateStaffDialog(
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
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${staffData['name']} JOINED THE SQUAD', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), 
                  backgroundColor: primaryColor,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('RECRUITMENT FAILED: $e'), backgroundColor: Colors.redAccent),
              );
            }
          }
        },
      ),
    );
  }
}

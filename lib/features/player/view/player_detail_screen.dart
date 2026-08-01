import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ballchart/core/utils/app_messenger.dart';
import 'package:flutter/services.dart'; // Add for Clipboard
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ballchart/core/models/local_academy_models.dart';
import 'package:ballchart/core/models/battle_model.dart';
import 'package:ballchart/core/repositories/profile_repository.dart';
import 'package:ballchart/core/services/api_service.dart';
import 'package:ballchart/core/legal/app_legal_urls.dart';
import 'package:ballchart/core/widgets/delete_account_dialog.dart';
import 'package:ballchart/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:ballchart/features/management/viewmodel/academy_provider.dart';
import 'package:ballchart/features/profile/viewmodel/profile_viewmodel.dart';
import 'package:ballchart/features/staff/service/staff_service.dart';
import 'package:ballchart/core/widgets/square_image_crop_screen.dart';

class PlayerDetailScreen extends StatefulWidget {
  final Player player;
  final bool canEdit;
  final bool showHeader;

  const PlayerDetailScreen({
    super.key,
    required this.player,
    this.canEdit = false,
    this.showHeader = true,
  });

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> {
  bool _isPasswordVisible = false;

  /// Live row from GET /auth/player/:id when admin/coach opens this screen.
  Map<String, dynamic>? _staffPlayerJson;
  bool _staffPlayerLoading = false;

  String _staffStr(String key, String fallback) {
    final raw = _staffPlayerJson?[key];
    if (raw == null) return fallback;
    final s = raw.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  double _staffAvg(String k, double fallback) {
    final avg = _staffPlayerJson?['averages'];
    if (avg is! Map) return fallback;
    final v = avg[k];
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  int _staffStatInt(String key, int fallback) {
    final st = _staffPlayerJson?['stats'];
    if (st is! Map) return fallback;
    final v = st[key];
    if (v == null) return fallback;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? fallback;
  }

  bool _isOwnProfile(AcademyProvider provider) {
    if (widget.canEdit) return true;
    final currentUser = provider.currentUser;
    // Player app sessions should always be able to edit self profile.
    // Coach/admin sessions remain read-only.
    return currentUser != null && currentUser.role == 'player';
  }

  Map<String, dynamic> _asStringMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  /// Full URL for display (handles `/uploads/...` from API).
  String? _resolvePlayerImageUrl(dynamic raw) {
    final s = raw?.toString().trim();
    if (s == null || s.isEmpty) return null;
    final u = ApiService.resolveMediaUrl(s);
    return u.isEmpty ? null : u;
  }

  bool _isRenderableImageUrl(String? u) =>
      u != null && u.isNotEmpty && (u.startsWith('http://') || u.startsWith('https://') || u.startsWith('data:'));

  @override
  void initState() {
    super.initState();
    // Load fresh data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataWithRetry();
      _loadStaffPlayerSnapshot();
    });
  }

  Future<void> _loadStaffPlayerSnapshot() async {
    final provider = Provider.of<AcademyProvider>(context, listen: false);
    if (_isOwnProfile(provider)) return;
    setState(() => _staffPlayerLoading = true);
    final data = await provider.fetchPlayerForStaff(widget.player.id);
    if (!mounted) return;
    setState(() {
      _staffPlayerJson = data;
      _staffPlayerLoading = false;
    });
  }

  Future<void> _loadDataWithRetry({int retryCount = 3}) async {
    for (int i = 0; i < retryCount; i++) {
      try {
        final provider = Provider.of<AcademyProvider>(context, listen: false);
        if (provider.currentUser?.role == 'player') {
          await provider.loadPlayerDashboard(force: true);
        }
        break; // Success, exit retry loop
      } catch (e) {
        if (i == retryCount - 1) {
          // Last retry failed, show error
          if (mounted) {
            AppMessenger.showSnackBar(context, 
              SnackBar(
                content: Text('Failed to load player data: ${e.toString().replaceAll('Exception: ', '')}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () => _loadDataWithRetry(),
                ),
              ),
            );
          }
        } else {
          // Wait before retrying
          await Future.delayed(Duration(milliseconds: 1000 * (i + 1)));
        }
      }
    }
  }

  static const Color primaryContainer = Color(0xFFFDB927);
  static const Color background = Color(0xFF131313);
  static const Color surfaceDim = Color(0xFF131313);
  static const Color surfaceHigh = Color(0xFF2A2A2A);
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color surfaceHighest = Color(0xFF353534);
  static const Color outline = Color(0xFF9D8F79);
  static const Color tertiaryContainer = Color(0xFF14D7FF);
  static const Color tertiary = Color(0xFFADEBFF);
  static const Color secondaryFixedDim = Color(0xFFE9C400);
  static const Color error = Color(0xFFFFB4AB);

  static const String headlineFont = 'Space Grotesk';
  static const String bodyFont = 'Inter';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: CustomScrollView(
        slivers: [
          if (widget.showHeader) _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildHeroProfile(widget.player.name),
        const SizedBox(height: 28),
        _buildBiometricsBento(),
        const SizedBox(height: 28),
        _buildCredentialsSection(),
        const SizedBox(height: 8),
        _buildPerformanceStats(),
        _buildBattleStats(),
        _buildScoutingNotes(),
        _buildLegalAndDeleteSection(context),
        _buildLogoutSection(context),
        const SizedBox(height: 100),
      ],
    );
  }

  String _displayValue(dynamic raw, {String empty = '—'}) {
    final s = raw?.toString().trim() ?? '';
    if (s.isEmpty || s.toUpperCase() == 'N/A') return empty;
    return s;
  }

  Widget _sectionLabel(String title, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: primaryContainer,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                fontFamily: headlineFont,
              ),
            ),
          ),
          if (trailing != null && trailing.isNotEmpty)
            Text(
              trailing,
              style: TextStyle(
                color: primaryContainer.withValues(alpha: 0.9),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                fontFamily: bodyFont,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegalAndDeleteSection(BuildContext context) {
    return Consumer<AcademyProvider>(
      builder: (context, provider, _) {
        if (!_isOwnProfile(provider)) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: AppLegalUrls.inlineTextButtons(context)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => showDeleteAccountDialog(context),
                icon: const Icon(Icons.delete_forever_outlined, color: Colors.white54, size: 18),
                label: const Text(
                  'DELETE ACCOUNT',
                  style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w700, letterSpacing: 0.6, fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white54,
                  side: const BorderSide(color: Colors.white12),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogoutSection(BuildContext context) {
    return Consumer<AcademyProvider>(
      builder: (context, provider, _) {
        if (!_isOwnProfile(provider)) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
          child: GestureDetector(
            onTap: () => context.read<AuthViewmodel>().logout(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.28)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'LOG OUT',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCredentialsSection() {
    return Consumer<AcademyProvider>(
      builder: (context, provider, _) {
        final isOwnProfile = _isOwnProfile(provider);

        if (isOwnProfile && provider.isPlayerLoading) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: surfaceHigh, borderRadius: BorderRadius.circular(18)),
              child: const CircularProgressIndicator(color: primaryContainer, strokeWidth: 2),
            ),
          );
        }

        final ownPlayerData = _asStringMap(provider.playerDashboard?['player']);
        final fallbackPlayer = provider.academy.teams
            .expand((t) => t.players)
            .where((p) => p.id == widget.player.id)
            .cast<Player?>()
            .firstWhere((p) => p != null, orElse: () => null);

        final emailValue = isOwnProfile
            ? (ownPlayerData['email'] ?? ownPlayerData['loginEmail'] ?? widget.player.email)?.toString()
            : _staffStr(
                'email',
                (widget.player.email.isNotEmpty ? widget.player.email : fallbackPlayer?.email) ?? '',
              );

        final passwordValue = isOwnProfile
            ? (ownPlayerData['tempPassword'] ?? ownPlayerData['password'] ?? widget.player.tempPassword)?.toString()
            : _staffStr(
                'tempPassword',
                (widget.player.tempPassword?.isNotEmpty == true ? widget.player.tempPassword : fallbackPlayer?.tempPassword) ?? '',
              );

        final safeEmail = (emailValue == null || emailValue.trim().isEmpty) ? 'Not available' : emailValue;
        final safePassword = (passwordValue == null || passwordValue.trim().isEmpty) ? 'Not available' : passwordValue;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('ACCOUNT'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceHigh,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  children: [
                    _credentialTile('LOGIN EMAIL', safeEmail, Icons.mail_outline_rounded),
                    Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
                    _credentialTile(
                      'PASSWORD',
                      safePassword,
                      Icons.lock_outline_rounded,
                      isPassword: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _credentialTile(String label, String value, IconData icon, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryContainer, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: outline.withValues(alpha: 0.95),
                    fontSize: 10,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                    fontFamily: bodyFont,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isPassword && !_isPasswordVisible ? '••••••••' : value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: bodyFont,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isPassword)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(_isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: outline, size: 18),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.copy_rounded, color: outline, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              AppMessenger.showSnackBar(
                context,
                const SnackBar(content: Text('Copied', style: TextStyle(fontWeight: FontWeight.bold))),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: surfaceDim,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryContainer, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: surfaceContainer, shape: BoxShape.circle),
            child: Icon(Icons.shield_rounded, color: primaryContainer, size: 16),
          ),
          const SizedBox(width: 12),
          Consumer<AcademyProvider>(
            builder: (context, provider, _) => Text(
              provider.academy.name.toUpperCase(),
              style: TextStyle(
                color: primaryContainer,
                fontFamily: headlineFont,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Consumer<AcademyProvider>(
          builder: (context, provider, _) {
            return IconButton(
              icon: Icon(Icons.notifications_none_rounded, color: primaryContainer),
              onPressed: () {},
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeroProfile(String name) {
    return Consumer<AcademyProvider>(
      builder: (context, provider, _) {
        final dashboard = provider.playerDashboard;
        final error = provider.playerDashboardError ?? provider.error;
        final isOwnProfile = _isOwnProfile(provider);
        
        // Admin/coach: live data from GET /auth/player/:id
        if (!isOwnProfile) {
          if (_staffPlayerLoading && _staffPlayerJson == null) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Center(child: CircularProgressIndicator(color: primaryContainer, strokeWidth: 2)),
            );
          }
          final s = _staffPlayerJson;
          return _buildPlayerHeroContent(
            name: _staffStr('username', widget.player.name),
            isEliteProspect: (s?['isEliteProspect'] == true) || widget.player.isEliteProspect,
            classYear: _staffStr('classYear', widget.player.classYear),
            position: _staffStr('position', widget.player.position),
            heroImageUrl: _resolvePlayerImageUrl(
              s?['profileImageUrl'] ?? s?['profilePic'] ?? widget.player.profileImageUrl,
            ),
            jerseyNumber: _staffStr('jerseyNumber', widget.player.jerseyNumber),
            onTapHeroPhoto: null,
          );
        }
        
        // For players viewing their own profile
        if (provider.isPlayerLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Center(child: CircularProgressIndicator(color: primaryContainer, strokeWidth: 2)),
          );
        }
        
        if (error != null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceHigh,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
                  const SizedBox(height: 10),
                  const Text(
                    'Could not load profile',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    error,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () => _loadDataWithRetry(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryContainer,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('RETRY'),
                  ),
                ],
              ),
            ),
          );
        }
        
        final playerData = _asStringMap(dashboard?['player']);
        final isEliteProspect = playerData['isEliteProspect'] ?? widget.player.isEliteProspect;
        final classYear = playerData['classYear'] ?? widget.player.classYear;
        final heroPic = _resolvePlayerImageUrl(
          playerData['profileImageUrl'] ?? playerData['profilePic'] ?? widget.player.profileImageUrl,
        );

        return _buildPlayerHeroContent(
          name: widget.player.name,
          isEliteProspect: isEliteProspect,
          classYear: classYear,
          position: widget.player.position,
          heroImageUrl: heroPic,
          jerseyNumber: widget.player.jerseyNumber,
          onTapHeroPhoto: () => _showPlayerProfilePhotoMenu(context),
        );
      },
    );
  }

  Future<void> _showPlayerProfilePhotoMenu(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: surfaceContainer,
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
              decoration: BoxDecoration(color: outline.withOpacity(0.5), borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: primaryContainer),
              title: const Text('Change profile photo', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, 'photo'),
            ),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: primaryContainer),
              title: const Text('Edit full profile', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (choice == 'photo') {
      await _pickAndSavePlayerPhoto(context);
    } else if (choice == 'edit') {
      final provider = Provider.of<AcademyProvider>(context, listen: false);
      final dashboard = provider.playerDashboard;
      final playerData = _asStringMap(dashboard?['player']);
      if (context.mounted) {
        _showEditBiometricsDialog(context, playerData);
      }
    }
  }

  Future<void> _pickAndSavePlayerPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
    if (file == null || !context.mounted) return;
    final cropped = await Navigator.of(context).push<File>(
      MaterialPageRoute(
        builder: (_) => SquareImageCropScreen(imageFile: File(file.path)),
      ),
    );
    if (cropped == null || !context.mounted) return;
    try {
      final url = await StaffService().uploadImage(cropped);
      if (url == null || url.isEmpty) throw Exception('Upload returned no URL');
      final resolved = ApiService.resolveMediaUrl(url);
      final updated = await ProfileRepository().completeProfile({
        'profileImageUrl': url,
        'profilePic': url,
      });
      if (!context.mounted) return;
      final withPhoto = (updated.profileImageUrl == null || updated.profileImageUrl!.trim().isEmpty)
          ? updated.copyWith(profileImageUrl: resolved.isNotEmpty ? resolved : url)
          : updated;
      context.read<ProfileViewmodel>().setUser(withPhoto);
      context.read<AcademyProvider>().setCurrentUser(withPhoto);
      await context.read<AcademyProvider>().loadPlayerDashboard(force: true);
      if (!context.mounted) return;
      setState(() {});
      AppMessenger.show(
        context,
        message: 'Profile photo updated',
        kind: AppMessageKind.success,
      );
    } catch (e) {
      if (context.mounted) {
        AppMessenger.show(
          context,
          message: 'Could not update photo: $e',
          kind: AppMessageKind.error,
        );
      }
    }
  }
  
  Widget _buildPlayerHeroContent({
    required String name,
    required bool isEliteProspect,
    required String classYear,
    required String position,
    String? heroImageUrl,
    required String jerseyNumber,
    VoidCallback? onTapHeroPhoto,
  }) {
    final showPhoto = _isRenderableImageUrl(heroImageUrl);
    final pos = _displayValue(position);
    final jersey = _displayValue(jerseyNumber);
    final year = _displayValue(classYear);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceHigh,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              surfaceHigh,
              surfaceContainer,
            ],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: onTapHeroPhoto,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryContainer.withValues(alpha: 0.55), width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: primaryContainer.withValues(alpha: 0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: showPhoto
                          ? Image.network(
                              heroImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _avatarFallback(),
                            )
                          : _avatarFallback(),
                    ),
                  ),
                  if (onTapHeroPhoto != null)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: primaryContainer,
                          shape: BoxShape.circle,
                          border: Border.all(color: surfaceHigh, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.black),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isEliteProspect || year != '—')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (isEliteProspect)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'ELITE',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          if (year != '—')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Text(
                                year.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 9,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                      fontFamily: headlineFont,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _metaChip(pos == '—' ? 'POS —' : pos),
                      const SizedBox(width: 8),
                      _metaChip(jersey == '—' ? '# —' : '#$jersey', accent: true),
                    ],
                  ),
                  if (onTapHeroPhoto != null) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: onTapHeroPhoto,
                      child: Text(
                        'Edit profile',
                        style: TextStyle(
                          color: primaryContainer.withValues(alpha: 0.95),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      color: surfaceHighest,
      alignment: Alignment.center,
      child: const Icon(Icons.person_outline_rounded, color: primaryContainer, size: 36),
    );
  }

  Widget _metaChip(String text, {bool accent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent ? primaryContainer.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accent ? primaryContainer.withValues(alpha: 0.35) : Colors.white12,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: accent ? primaryContainer : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          fontFamily: bodyFont,
        ),
      ),
    );
  }

  Widget _buildBiometricsBento() {
    return Consumer<AcademyProvider>(
      builder: (context, provider, _) {
        final dashboard = provider.playerDashboard;
        final isOwnProfile = _isOwnProfile(provider);
        
        if (!isOwnProfile) {
          if (_staffPlayerLoading && _staffPlayerJson == null) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(color: primaryContainer)),
            );
          }
          return _buildBiometricsContent(
            height: _staffStr('height', widget.player.height),
            weight: _staffStr('weight', widget.player.weight),
            wingspan: _staffStr('wingspan', widget.player.wingspan),
            age: widget.player.age.toString(),
            isOwnProfile: false,
          );
        }
        
        // For players viewing their own profile
        if (provider.isPlayerLoading) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: primaryContainer)),
          );
        }
        
        if (provider.playerDashboardError != null) {
          return const SizedBox.shrink(); // Don't show biometrics if dashboard failed
        }

        final playerData = _asStringMap(dashboard?['player']);
        
        return _buildBiometricsContent(
          height: playerData['height'] ?? widget.player.height,
          weight: playerData['weight'] ?? widget.player.weight,
          wingspan: playerData['wingspan'] ?? widget.player.wingspan,
          age: (playerData['age'] ?? widget.player.age).toString(),
          isOwnProfile: isOwnProfile,
        );
      },
    );
  }
  
  Widget _buildBiometricsContent({
    required String height,
    required String weight,
    required String wingspan,
    required String age,
    required bool isOwnProfile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('BIOMETRICS', trailing: isOwnProfile ? 'TAP TO EDIT' : null),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: surfaceHigh,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _biometricBit(
                    Icons.height_rounded,
                    'Height',
                    _displayValue(height),
                    onTap: isOwnProfile
                        ? () => _showQuickFieldEditDialog(
                              context: context,
                              title: 'Edit Height',
                              fieldKey: 'height',
                              initialValue: height,
                            )
                        : null,
                  ),
                ),
                Container(width: 1, height: 52, color: Colors.white.withValues(alpha: 0.08)),
                Expanded(
                  child: _biometricBit(
                    Icons.monitor_weight_outlined,
                    'Weight',
                    _displayValue(weight),
                    onTap: isOwnProfile
                        ? () => _showQuickFieldEditDialog(
                              context: context,
                              title: 'Edit Weight',
                              fieldKey: 'weight',
                              initialValue: weight,
                            )
                        : null,
                  ),
                ),
                Container(width: 1, height: 52, color: Colors.white.withValues(alpha: 0.08)),
                Expanded(
                  child: _biometricBit(
                    Icons.straighten_rounded,
                    'Wingspan',
                    _displayValue(wingspan),
                    onTap: isOwnProfile
                        ? () => _showQuickFieldEditDialog(
                              context: context,
                              title: 'Edit Wingspan',
                              fieldKey: 'wingspan',
                              initialValue: wingspan,
                            )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _biometricBit(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Column(
            children: [
              Icon(icon, color: primaryContainer, size: 20),
              const SizedBox(height: 8),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: outline.withValues(alpha: 0.95),
                  fontSize: 9,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  fontFamily: bodyFont,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: headlineFont,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showQuickFieldEditDialog({
    required BuildContext context,
    required String title,
    required String fieldKey,
    required String initialValue,
  }) async {
    final controller = TextEditingController(text: initialValue == 'N/A' ? '' : initialValue);
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceContainer,
        title: Text(title, style: const TextStyle(color: Colors.white, fontFamily: headlineFont)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter value',
            hintStyle: TextStyle(color: outline),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: outline)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryContainer)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: outline))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryContainer),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (shouldSave != true || !mounted) return;
    final profileRepository = ProfileRepository();
    await profileRepository.completeProfile({fieldKey: controller.text.trim()});
    if (!mounted) return;
    await Provider.of<AcademyProvider>(context, listen: false).loadPlayerDashboard(force: true);
    if (mounted) {
      AppMessenger.show(
        context,
        message: 'Updated successfully',
        kind: AppMessageKind.success,
      );
    }
  }

  Widget _buildPerformanceStats() {
    return Consumer<AcademyProvider>(
      builder: (context, provider, _) {
        final isOwnProfile = _isOwnProfile(provider);
        
        if (!isOwnProfile) {
          return _buildPerformanceContent(
            ppg: _staffAvg('ppg', widget.player.ppg),
            apg: _staffAvg('apg', widget.player.apg),
            rpg: _staffAvg('rpg', widget.player.rpg),
            matchesPlayed: _staffStatInt('matchesPlayed', widget.player.matchesPlayed),
            wins: _staffStatInt('wins', widget.player.wins),
          );
        }
        
        // For players viewing their own profile
        if (provider.isPlayerLoading) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: primaryContainer)),
          );
        }
        
        final dashboard = provider.playerDashboard;
        if (dashboard == null) {
          return const SizedBox.shrink();
        }
        
        final playerData = _asStringMap(dashboard['player']);
        final stats = _asStringMap(playerData['stats']).isNotEmpty ? _asStringMap(playerData['stats']) : playerData;
        
        return _buildPerformanceContent(
          ppg: (stats['ppg'] ?? widget.player.ppg).toDouble(),
          apg: (stats['apg'] ?? widget.player.apg).toDouble(),
          rpg: (stats['rpg'] ?? widget.player.rpg).toDouble(),
          matchesPlayed: stats['matchesPlayed'] ?? widget.player.matchesPlayed,
          wins: stats['wins'] ?? widget.player.wins,
        );
      },
    );
  }
  
  Widget _buildPerformanceContent({
    required double ppg,
    required double apg,
    required double rpg,
    required int matchesPlayed,
    required int wins,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _sectionLabel('SEASON', trailing: 'AVERAGES'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(child: _statTile('PPG', ppg.toStringAsFixed(1))),
              const SizedBox(width: 10),
              Expanded(child: _statTile('APG', apg.toStringAsFixed(1))),
              const SizedBox(width: 10),
              Expanded(child: _statTile('RPG', rpg.toStringAsFixed(1))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: outline.withValues(alpha: 0.95),
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              fontFamily: bodyFont,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              fontFamily: headlineFont,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleStats() {
    return Consumer<AcademyProvider>(
      builder: (context, provider, _) {
        final isOwnProfile = _isOwnProfile(provider);
        
        if (!isOwnProfile) {
          if (_staffPlayerLoading) {
            return const Padding(
              padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Center(child: CircularProgressIndicator(color: primaryContainer)),
            );
          }
          final teamLabel = _staffStr('teamName', 'UNASSIGNED');
          return _buildBattleContent(
            totalBattles: _staffStatInt('matchesPlayed', widget.player.matchesPlayed),
            wins: _staffStatInt('wins', widget.player.wins),
            points: _staffStatInt('points', widget.player.points),
            teamName: teamLabel.isEmpty ? 'UNASSIGNED' : teamLabel,
            isOwnProfile: false,
            battleStats: null,
          );
        }
        
        // For players viewing their own profile
        if (provider.isPlayerLoading) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: primaryContainer)),
          );
        }
        
        final dashboard = provider.playerDashboard;
        if (dashboard == null) {
          return const SizedBox.shrink();
        }
        
        final playerData = _asStringMap(dashboard['player']);
        final stats = _asStringMap(playerData['stats']).isNotEmpty ? _asStringMap(playerData['stats']) : playerData;
        final battleStats = _asStringMap(playerData['battleStats']);
        final teamObj = dashboard['team'];
        var resolvedTeam = 'UNASSIGNED';
        if (teamObj is Map) {
          final n = _asStringMap(teamObj)['name']?.toString().trim();
          if (n != null && n.isNotEmpty) resolvedTeam = n;
        }
        if (resolvedTeam == 'UNASSIGNED') {
          final pn = playerData['teamName']?.toString().trim();
          if (pn != null && pn.isNotEmpty) resolvedTeam = pn;
        }
        
        return _buildBattleContent(
          totalBattles: battleStats['totalBattles'] ?? widget.player.matchesPlayed,
          wins: battleStats['wins'] ?? widget.player.wins,
          points: battleStats['totalPoints'] ?? stats['points'] ?? widget.player.points,
          teamName: resolvedTeam,
          isOwnProfile: true,
          battleStats: battleStats,
        );
      },
    );
  }
  
  Widget _buildBattleContent({
    required int totalBattles,
    required int wins,
    required int points,
    required String teamName,
    required bool isOwnProfile,
    Map<String, dynamic>? battleStats,
  }) {
    final losses = (totalBattles - wins).clamp(0, totalBattles);
    final winRate = totalBattles > 0 ? ((wins / totalBattles) * 100).round() : 0;
    final recent = (battleStats?['recentBattles'] is List) ? (battleStats!['recentBattles'] as List) : const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        _sectionLabel('GAMES', trailing: 'CAREER'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surfaceHigh,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: primaryContainer.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.groups_rounded, color: primaryContainer, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TEAM',
                            style: TextStyle(
                              color: outline.withValues(alpha: 0.95),
                              fontSize: 10,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            teamName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              fontFamily: headlineFont,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$winRate% WR',
                      style: const TextStyle(
                        color: primaryContainer,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _battleStatTile('W', wins.toString(), accent: true)),
                    const SizedBox(width: 8),
                    Expanded(child: _battleStatTile('L', losses.toString())),
                    const SizedBox(width: 8),
                    Expanded(child: _battleStatTile('GP', totalBattles.toString())),
                    const SizedBox(width: 8),
                    Expanded(child: _battleStatTile('PTS', points.toString(), accent: true)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surfaceHigh,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RECENT',
                  style: TextStyle(
                    color: outline.withValues(alpha: 0.95),
                    fontSize: 10,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (!isOwnProfile)
                  Text('Visible on your own profile', style: TextStyle(color: outline, fontSize: 13))
                else if (recent.isEmpty)
                  Text('No recent games yet', style: TextStyle(color: outline, fontSize: 13))
                else
                  ...recent.take(3).map((b) {
                    if (b is Map) return _recentBattleItem(Map<String, dynamic>.from(b));
                    return const SizedBox.shrink();
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _battleStatTile(String label, String value, {bool accent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: accent ? primaryContainer.withValues(alpha: 0.1) : background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent ? primaryContainer.withValues(alpha: 0.28) : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: outline.withValues(alpha: 0.95),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: accent ? primaryContainer : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFamily: headlineFont,
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentBattleItem(Map<String, dynamic> battle) {
    final isWin = battle['result'] == 'win';
    final opponent = battle['opponent'] ?? 'Unknown';
    final points = battle['points'] ?? 0;
    final date = battle['date'] ?? 'Recent';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: isWin ? primaryContainer : Colors.redAccent, width: 3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isWin ? Icons.emoji_events_rounded : Icons.close_rounded,
            color: isWin ? primaryContainer : Colors.redAccent,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'vs $opponent',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                ),
                Text('$date', style: TextStyle(color: outline, fontSize: 11)),
              ],
            ),
          ),
          Text(
            isWin ? 'W' : 'L',
            style: TextStyle(
              color: isWin ? primaryContainer : Colors.redAccent,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Text('$points', style: TextStyle(color: outline, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildScoutingNotes() {
    return Consumer<AcademyProvider>(
      builder: (context, provider, _) {
        final isOwnProfile = _isOwnProfile(provider);
        final dashboard = (isOwnProfile ? provider.playerDashboard : {'player': {}}) ?? {'player': {}};
        
        if (isOwnProfile && (provider.isPlayerLoading || provider.playerDashboard == null)) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: primaryContainer)),
          );
        }
        
        if (isOwnProfile && provider.playerDashboardError != null) {
          return const SizedBox.shrink(); // Don't show scouting notes if there's an error
        }

        final playerData = _asStringMap(dashboard['player']);
        final scoutingNotes = isOwnProfile
            ? (playerData['scoutingNotes'] ?? widget.player.scoutingNotes)
            : _staffStr('scoutingNotes', widget.player.scoutingNotes);
        final notes = scoutingNotes.toString().trim();
        final displayNotes = (notes.isEmpty || notes.toUpperCase() == 'N/A') ? '' : notes;
        
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 28, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('SCOUTING'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceHigh,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayNotes.isEmpty
                            ? 'No scouting notes yet.'
                            : displayNotes,
                        style: TextStyle(
                          color: displayNotes.isEmpty ? outline : Colors.white70,
                          fontSize: 14,
                          height: 1.55,
                          fontStyle: displayNotes.isEmpty ? FontStyle.normal : FontStyle.italic,
                          fontFamily: bodyFont,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(Icons.verified_rounded, color: primaryContainer.withValues(alpha: 0.9), size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'HEAD COACH',
                            style: TextStyle(
                              color: outline.withValues(alpha: 0.95),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditBiometricsDialog(BuildContext context, Map<String, dynamic> playerData) {
    final heightController = TextEditingController(text: playerData['height']?.toString() ?? widget.player.height);
    final weightController = TextEditingController(text: playerData['weight']?.toString() ?? widget.player.weight);
    final wingspanController = TextEditingController(text: playerData['wingspan']?.toString() ?? widget.player.wingspan);
    final positionController = TextEditingController(text: playerData['position']?.toString() ?? widget.player.position);
    final jerseyController = TextEditingController(text: playerData['jerseyNumber']?.toString() ?? widget.player.jerseyNumber);
    final classYearController = TextEditingController(text: playerData['classYear']?.toString() ?? widget.player.classYear);
    final scoutingNotesController = TextEditingController(text: playerData['scoutingNotes']?.toString() ?? widget.player.scoutingNotes);
    final profileImageController = TextEditingController(text: playerData['profileImageUrl']?.toString() ?? widget.player.profileImageUrl ?? '');
    final emailController = TextEditingController(text: playerData['email']?.toString() ?? widget.player.email);
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceContainer,
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white, fontFamily: headlineFont)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: heightController,
                decoration: InputDecoration(
                  labelText: 'Height (cm)',
                  labelStyle: TextStyle(color: outline),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: outline)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryContainer)),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: weightController,
                decoration: InputDecoration(
                  labelText: 'Weight (kg)',
                  labelStyle: TextStyle(color: outline),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: outline)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryContainer)),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: wingspanController,
                decoration: InputDecoration(
                  labelText: 'Wingspan (cm)',
                  labelStyle: TextStyle(color: outline),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: outline)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryContainer)),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: positionController,
                decoration: InputDecoration(
                  labelText: 'Position',
                  labelStyle: TextStyle(color: outline),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: outline)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryContainer)),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: jerseyController,
                decoration: InputDecoration(
                  labelText: 'Jersey Number (00–99)',
                  labelStyle: TextStyle(color: outline),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: outline)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryContainer)),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                maxLength: 2,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: classYearController,
                decoration: InputDecoration(
                  labelText: 'Class Year',
                  labelStyle: TextStyle(color: outline),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: outline)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryContainer)),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: scoutingNotesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Scouting Notes',
                  labelStyle: TextStyle(color: outline),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: outline)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryContainer)),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: profileImageController,
                decoration: InputDecoration(
                  labelText: 'Profile Image URL',
                  labelStyle: TextStyle(color: outline),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: outline)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryContainer)),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Login Email',
                  labelStyle: TextStyle(color: outline),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: outline)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryContainer)),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password (optional)',
                  labelStyle: TextStyle(color: outline),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: outline)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryContainer)),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: outline)),
          ),
          ElevatedButton(
            onPressed: () async {
              final jersey = jerseyController.text.trim();
              if (jersey.isNotEmpty && (jersey.length > 2 || int.tryParse(jersey) == null)) {
                AppMessenger.showSnackBar(context, 
                  const SnackBar(content: Text('Jersey number must be 1–2 digits (00–99).'), backgroundColor: Colors.redAccent),
                );
                return;
              }
              try {
                final profileRepository = ProfileRepository();
                await profileRepository.completeProfile({
                  'height': heightController.text,
                  'weight': weightController.text,
                  'wingspan': wingspanController.text,
                  'position': positionController.text,
                  'jerseyNumber': jersey,
                  'classYear': classYearController.text,
                  'scoutingNotes': scoutingNotesController.text,
                  'profileImageUrl': profileImageController.text.trim().isEmpty ? null : profileImageController.text.trim(),
                  'email': emailController.text.trim(),
                  if (passwordController.text.trim().isNotEmpty) 'password': passwordController.text.trim(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  // Refresh the dashboard data
                  final provider = Provider.of<AcademyProvider>(context, listen: false);
                  await provider.loadPlayerDashboard(force: true);
                  
                  AppMessenger.show(
                    context,
                    message: 'Profile updated successfully!',
                    kind: AppMessageKind.success,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  AppMessenger.show(
                    context,
                    message: 'Error updating profile: $e',
                    kind: AppMessageKind.error,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryContainer),
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

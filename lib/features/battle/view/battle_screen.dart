import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/battle_viewmodel.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/battle/battle_header.dart';
import '../../../core/widgets/battle/rank_progress_card.dart';
import '../../../core/models/battle_model.dart';
import '../../profile/viewmodel/profile_viewmodel.dart';

class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  BattleViewmodel? _battleViewmodel;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final battleViewModel = context.read<BattleViewmodel>();
      _battleViewmodel = battleViewModel;
      battleViewModel.loadBattles();
      battleViewModel.startLiveUpdates();
      final profileViewModel = context.read<ProfileViewmodel>();
      if (profileViewModel.user == null) {
        profileViewModel.loadProfile();
      }
    });
  }

  @override
  void dispose() {
    _battleViewmodel?.stopLiveUpdates();
    super.dispose();
  }

  bool _canCreateBattle(String? role) {
    return role == 'admin' ||
        role == 'head_coach' ||
        role == 'coach' ||
        role == 'assistant_coach';
  }

  String _formatDateTime(DateTime dateTime) {
    final date = '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year}';
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$date • $hour:$minute $suffix';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ongoing':
        return Colors.lightBlueAccent;
      case 'finished':
        return Colors.greenAccent;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return AppColors.yellow;
    }
  }

  Future<DateTime?> _pickDateTime(BuildContext context, DateTime? initial) async {
    final now = DateTime.now();
    final base = initial ?? now.add(const Duration(hours: 1));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate == null || !context.mounted) return null;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (pickedTime == null) return null;

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  String _relativeTimeLabel(DateTime dateTime) {
    final diff = dateTime.difference(DateTime.now());
    if (diff.inMinutes.abs() < 1) return 'now';
    if (diff.isNegative) {
      if (diff.inHours.abs() < 24) return '${diff.inHours.abs()}h ago';
      return '${diff.inDays.abs()}d ago';
    }
    if (diff.inHours < 24) return 'in ${diff.inHours}h';
    return 'in ${diff.inDays}d';
  }

  List<BattleModel> _applyFilter(
    List<BattleModel> battles,
    String filter,
    String? currentUserId,
  ) {
    if (filter == 'joined') {
      return battles.where((battle) => battle.isJoined).toList();
    }
    if (filter == 'hosting') {
      return battles.where((battle) => battle.host?.id == currentUserId).toList();
    }
    if (filter == 'upcoming') {
      final now = DateTime.now();
      return battles
          .where((battle) => battle.dateTime.isAfter(now) && battle.status == 'pending')
          .toList();
    }
    return battles;
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.yellow),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip({
    required String id,
    required String label,
  }) {
    final selected = _selectedFilter == id;
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => setState(() => _selectedFilter = id),
      selectedColor: AppColors.yellow,
      backgroundColor: const Color(0xFF1E293B),
      labelStyle: TextStyle(
        color: selected ? Colors.black : Colors.white70,
        fontWeight: FontWeight.w600,
      ),
      side: const BorderSide(color: Colors.white10),
    );
  }

  Future<void> _showCreateBattleSheet(BuildContext context) async {
    final locationController = TextEditingController();
    DateTime? selectedDateTime = DateTime.now().add(const Duration(hours: 1));
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0B1220),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create New Battle',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Set a location and match time so players can join.',
                    style: TextStyle(color: Colors.white60),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: locationController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Battle location (e.g. Court A)',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await _pickDateTime(context, selectedDateTime);
                      if (picked == null) return;
                      setSheetState(() {
                        selectedDateTime = picked;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, color: AppColors.yellow),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              selectedDateTime == null
                                  ? 'Select battle date & time'
                                  : _formatDateTime(selectedDateTime!),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final location = locationController.text.trim();
                              if (location.isEmpty || selectedDateTime == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter location and date/time')),
                                );
                                return;
                              }
                              setSheetState(() => isSubmitting = true);
                              try {
                                await context.read<BattleViewmodel>().createBattle(location, selectedDateTime!);
                                if (context.mounted) {
                                  Navigator.pop(sheetContext);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Battle created successfully')),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                                  );
                                }
                              } finally {
                                if (context.mounted) {
                                  setSheetState(() => isSubmitting = false);
                                }
                              }
                            },
                      icon: isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.add),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.yellow,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      label: const Text('Create Battle'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _battleCard(BattleModel battle, BattleViewmodel viewModel, String? currentUserId) {
    final statusColor = _statusColor(battle.status);
    final hostName = battle.host?.username.isNotEmpty == true
        ? battle.host!.username
        : 'Unknown host';
    final hostRole = battle.host?.role ?? 'staff';
    final participantNames = battle.participants
        .map((participant) => participant.username.trim())
        .where((name) => name.isNotEmpty)
        .take(5)
        .toList();
    final isHost = battle.host?.id == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  battle.location,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  battle.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatDateTime(battle.dateTime),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            _relativeTimeLabel(battle.dateTime),
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            'Host: $hostName (${hostRole.replaceAll('_', ' ')})',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            '${battle.participantCount} participants',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          if (participantNames.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Players: ${participantNames.join(', ')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: (battle.canJoin && !isHost)
                  ? () async {
                      try {
                        await viewModel.joinBattle(battle.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Joined battle successfully')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                          );
                        }
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellow,
                foregroundColor: Colors.black,
              ),
              child: Text(
                isHost
                    ? 'Hosting'
                    : battle.isJoined
                    ? 'Joined'
                    : (battle.status == 'pending' ? 'Join Battle' : 'Closed'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Consumer<ProfileViewmodel>(
              builder: (context, profileViewModel, child) {
                final user = profileViewModel.user;
                final canCreateBattle = _canCreateBattle(user?.role);
                return Consumer<BattleViewmodel>(
                  builder: (context, viewModel, _) {
                    final battles = viewModel.battles;
                    final filteredBattles = _applyFilter(battles, _selectedFilter, user?.id);
                    final joinedCount = battles.where((battle) => battle.isJoined).length;
                    final hostingCount = battles.where((battle) => battle.host?.id == user?.id).length;
                    final upcomingCount = battles
                        .where((battle) =>
                            battle.status == 'pending' &&
                            battle.dateTime.isAfter(DateTime.now()))
                        .length;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BattleHeader(),
                        const SizedBox(height: 20),
                        user != null
                            ? RankProgressCard(user: user)
                            : const SizedBox(
                                height: 100,
                                child: Center(child: CircularProgressIndicator()),
                              ),
                        const SizedBox(height: 22),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Battle Flow',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Create by coach/assistant, players join, and updates sync live every few seconds.',
                                style: TextStyle(color: Colors.white60, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _summaryCard(
                              label: 'All Battles',
                              value: '${battles.length}',
                              icon: Icons.sports_basketball_outlined,
                            ),
                            const SizedBox(width: 10),
                            _summaryCard(
                              label: 'Upcoming',
                              value: '$upcomingCount',
                              icon: Icons.schedule,
                            ),
                            const SizedBox(width: 10),
                            _summaryCard(
                              label: 'Joined',
                              value: '$joinedCount',
                              icon: Icons.check_circle_outline,
                            ),
                            const SizedBox(width: 10),
                            _summaryCard(
                              label: 'Hosting',
                              value: '$hostingCount',
                              icon: Icons.workspace_premium_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: canCreateBattle ? () => _showCreateBattleSheet(context) : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.yellow,
                                  foregroundColor: Colors.black,
                                  minimumSize: const Size.fromHeight(46),
                                ),
                                icon: const Icon(Icons.add_circle_outline),
                                label: Text(canCreateBattle ? 'Create Battle' : 'Only staff can create'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              onPressed: viewModel.isLoading
                                  ? null
                                  : () => context.read<BattleViewmodel>().loadBattles(),
                              icon: const Icon(Icons.refresh, color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _filterChip(id: 'all', label: 'All'),
                            _filterChip(id: 'upcoming', label: 'Upcoming'),
                            _filterChip(id: 'joined', label: 'Joined'),
                            _filterChip(id: 'hosting', label: 'Hosting'),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Live Battles',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (viewModel.isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (filteredBattles.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'No battles found in this filter.',
                              style: TextStyle(color: Colors.white60),
                            ),
                          )
                        else
                          ...filteredBattles
                              .map((battle) => _battleCard(battle, viewModel, user?.id)),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

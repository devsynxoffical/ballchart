import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/battle_viewmodel.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/battle/battle_header.dart';
import '../../../core/widgets/battle/leader_board_Header.dart';
import '../../../core/widgets/battle/rank_progress_card.dart';
import '../../../core/models/battle_model.dart';
import '../../profile/viewmodel/profile_viewmodel.dart';

class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BattleViewmodel>().loadBattles();
      final profileViewModel = context.read<ProfileViewmodel>();
      if (profileViewModel.user == null) {
        profileViewModel.loadProfile();
      }
    });
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

  Widget _battleCard(BattleModel battle, BattleViewmodel viewModel) {
    final statusColor = _statusColor(battle.status);
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
            '${battle.participants.length} participants',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () async {
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellow,
                foregroundColor: Colors.black,
              ),
              child: const Text('Join Battle'),
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
                return Consumer<BattleViewmodel>(
                  builder: (context, viewModel, _) {
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
                                '1) Tap Create Battle  •  2) Set location & time  •  3) Share with players  •  4) Players join',
                                style: TextStyle(color: Colors.white60, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showCreateBattleSheet(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.yellow,
                                  foregroundColor: Colors.black,
                                  minimumSize: const Size.fromHeight(46),
                                ),
                                icon: const Icon(Icons.add_circle_outline),
                                label: const Text('Create Battle'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              onPressed: viewModel.isLoading
                                  ? null
                                  : () => context.read<BattleViewmodel>().loadBattles(),
                              icon: const Icon(Icons.refresh, color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Active Battles',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (viewModel.isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (viewModel.battles.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'No active battles yet. Create your first battle to get started.',
                              style: TextStyle(color: Colors.white60),
                            ),
                          )
                        else
                          ...viewModel.battles.map((battle) => _battleCard(battle, viewModel)),
                        const SizedBox(height: 24),
                        LeaderboardHeader(),
                        const SizedBox(height: 16),
                        const LeaderboardItem(
                          rank: 1,
                          name: 'Alex Johnson',
                          role: 'Captain',
                          points: 485,
                          progress: 0.95,
                          color: AppColors.yellow,
                        ),
                        const SizedBox(height: 14),
                        const LeaderboardItem(
                          rank: 2,
                          name: 'You',
                          role: 'All-Star',
                          points: 375,
                          progress: 0.75,
                          color: Colors.pinkAccent,
                          isYou: true,
                        ),
                        const SizedBox(height: 14),
                        const LeaderboardItem(
                          rank: 3,
                          name: 'Sarah Williams',
                          role: 'Starter',
                          points: 340,
                          progress: 0.65,
                          color: Colors.lightBlue,
                        ),
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

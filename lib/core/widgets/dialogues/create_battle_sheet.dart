import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/battle_model.dart';
import '../../../features/battle/viewmodel/battle_viewmodel.dart';
import '../../../features/management/viewmodel/academy_provider.dart';

/// Richer "schedule session" flow: title, format, roster size, notes, quick time presets.
/// Use [scaffoldMessenger] from the screen that opened the sheet (not the sheet context) for snackbars after close.
/// Pass [existing] to edit a scheduled game.
String _staffNotesFromBattle(BattleModel? existing) {
  if (existing == null) return '';
  final desc = existing.description?.trim() ?? '';
  if (desc.isEmpty) return '';
  return desc
      .split('\n')
      .where((line) => !line.trim().toLowerCase().startsWith('title:'))
      .join('\n')
      .trim();
}

Future<void> showCreateBattleSheet(
  BuildContext context, {
  required ScaffoldMessengerState scaffoldMessenger,
  BattleModel? existing,
}) async {
  final editing = existing != null;
  const primaryColor = Color(0xFFFFD900);
  const bgColor = Color(0xFF131313);
  const surfaceHigh = Color(0xFF2A2A2A);
  const outlineColor = Color(0xFF9D8F79);

  final titleCtrl = TextEditingController(text: existing?.metadata?['sessionTitle']?.toString() ?? '');
  final locationCtrl = TextEditingController(text: existing?.location ?? '');
  final notesCtrl = TextEditingController(text: _staffNotesFromBattle(existing));
  DateTime sessionTime = existing?.dateTime ?? DateTime.now().add(const Duration(hours: 2));
  String battleType = existing?.battleType ?? 'scrimmage_5v5';
  int maxParticipants = existing?.maxParticipants ?? 10;
  final tagState = <String, bool>{
    'League': false,
    'Scrimmage': true,
    'Home': false,
    'Film': false,
  };

  final formats = <Map<String, dynamic>>[
    {'id': 'scrimmage_5v5', 'label': '5v5 scrimmage', 'icon': Icons.groups_outlined},
    {'id': 'scrimmage_3v3', 'label': '3v3', 'icon': Icons.groups_2_outlined},
    {'id': '1v1', 'label': '1v1', 'icon': Icons.person_outline},
    {'id': 'drills', 'label': 'Drill block', 'icon': Icons.fitness_center_outlined},
  ];

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          void bumpTime(Duration d) {
            setModalState(() {
              sessionTime = sessionTime.add(d);
            });
          }

          void presetTonight() {
            final now = DateTime.now();
            setModalState(() {
              sessionTime = DateTime(now.year, now.month, now.day, 19, 0).add(
                now.hour >= 19 ? const Duration(days: 1) : Duration.zero,
              );
            });
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.92,
              ),
              decoration: const BoxDecoration(
                color: surfaceHigh,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: outlineColor.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                      children: [
                        const Text(
                          'SCHEDULE GAME',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Space Grotesk',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Session name, format, and time — clearer for players and staff.',
                          style: TextStyle(color: outlineColor.withOpacity(0.95), fontSize: 12, height: 1.35),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: titleCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'SESSION TITLE (OPTIONAL)',
                            labelStyle: const TextStyle(color: outlineColor, fontSize: 11, fontWeight: FontWeight.bold),
                            hintText: 'e.g. Varsity vs East scrimmage',
                            hintStyle: TextStyle(color: outlineColor.withOpacity(0.45)),
                            filled: true,
                            fillColor: bgColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: locationCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'LOCATION',
                            labelStyle: const TextStyle(color: outlineColor, fontSize: 11, fontWeight: FontWeight.bold),
                            hintText: 'Main gym, Court 2…',
                            hintStyle: TextStyle(color: outlineColor.withOpacity(0.45)),
                            filled: true,
                            fillColor: bgColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'FORMAT',
                          style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: formats.map((f) {
                            final sel = battleType == f['id'];
                            return ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(f['icon'] as IconData?, size: 16, color: sel ? Colors.black : outlineColor),
                                  const SizedBox(width: 6),
                                  Text(f['label'] as String),
                                ],
                              ),
                              selected: sel,
                              selectedColor: primaryColor,
                              backgroundColor: bgColor,
                              labelStyle: TextStyle(
                                color: sel ? Colors.black : Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              onSelected: (_) => setModalState(() => battleType = f['id'] as String),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Roster cap', style: TextStyle(color: outlineColor, fontSize: 12)),
                            Expanded(
                              child: Slider(
                                value: maxParticipants.toDouble(),
                                min: 2,
                                max: 24,
                                divisions: 22,
                                label: '$maxParticipants',
                                activeColor: primaryColor,
                                onChanged: (v) => setModalState(() => maxParticipants = v.round()),
                              ),
                            ),
                            Text('$maxParticipants', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${sessionTime.year}-${sessionTime.month.toString().padLeft(2, '0')}-${sessionTime.day.toString().padLeft(2, '0')}  '
                            '${sessionTime.hour.toString().padLeft(2, '0')}:${sessionTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Tap to pick date & time', style: TextStyle(color: outlineColor.withOpacity(0.85))),
                          trailing: const Icon(Icons.calendar_month, color: primaryColor),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: sessionTime,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date == null || !context.mounted) return;
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(sessionTime),
                            );
                            if (time == null) return;
                            setModalState(() {
                              sessionTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ActionChip(
                              label: const Text('+1 h'),
                              onPressed: () => bumpTime(const Duration(hours: 1)),
                              backgroundColor: bgColor,
                            ),
                            ActionChip(
                              label: const Text('+3 h'),
                              onPressed: () => bumpTime(const Duration(hours: 3)),
                              backgroundColor: bgColor,
                            ),
                            ActionChip(
                              label: const Text('Tonight 7p'),
                              onPressed: presetTonight,
                              backgroundColor: bgColor,
                            ),
                            ActionChip(
                              label: const Text('+1 day'),
                              onPressed: () => bumpTime(const Duration(days: 1)),
                              backgroundColor: bgColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: notesCtrl,
                          maxLines: 3,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'NOTES FOR STAFF',
                            labelStyle: const TextStyle(color: outlineColor, fontSize: 11, fontWeight: FontWeight.bold),
                            hintText: 'Opponent, focus, jerseys…',
                            hintStyle: TextStyle(color: outlineColor.withOpacity(0.45)),
                            filled: true,
                            fillColor: bgColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('TAGS', style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: tagState.keys.map((k) {
                            return FilterChip(
                              label: Text(k),
                              selected: tagState[k]!,
                              onSelected: (v) => setModalState(() => tagState[k] = v),
                              selectedColor: primaryColor.withOpacity(0.35),
                              checkmarkColor: primaryColor,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () async {
                          if (locationCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Add a location'), backgroundColor: Colors.redAccent),
                            );
                            return;
                          }
                          if (sessionTime.isBefore(DateTime.now())) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Pick a time in the future'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }
                          final vm = context.read<BattleViewmodel>();
                          final academyVm = context.read<AcademyProvider>();
                          final tags = tagState.entries.where((e) => e.value).map((e) => e.key.toLowerCase()).toList();
                          Navigator.pop(context);
                          try {
                            final meta = {
                              'sessionTitle': titleCtrl.text.trim(),
                              'formatLabel': formats.firstWhere((e) => e['id'] == battleType, orElse: () => formats[0])['label'],
                            };
                            final description = notesCtrl.text.trim();
                            if (editing) {
                              await vm.updateBattle(
                                existing.id,
                                location: locationCtrl.text.trim(),
                                dateTime: sessionTime,
                                battleType: battleType,
                                maxParticipants: maxParticipants,
                                description: description,
                                tags: tags,
                                metadata: meta,
                              );
                            } else {
                              await vm.createBattle(
                                location: locationCtrl.text.trim(),
                                dateTime: sessionTime,
                                battleType: battleType,
                                maxParticipants: maxParticipants,
                                description: description,
                                tags: tags,
                                metadata: meta,
                              );
                            }
                            await vm.loadBattles();
                            await academyVm.loadCoachDashboard(force: true);
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  editing ? 'Game updated' : 'Game scheduled',
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                ),
                                backgroundColor: primaryColor,
                              ),
                            );
                          } catch (e) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
                            );
                          }
                        },
                        child: Text(
                          editing ? 'SAVE CHANGES' : 'SCHEDULE GAME',
                          style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

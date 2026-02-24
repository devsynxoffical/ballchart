import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/widgets/completeProfile_Player/ExperienceSelector.dart';
import '../../../../../core/widgets/completeProfile_Player/selectable_goal_tile.dart';
import '../../../../../routes/routes_names.dart';
import '../../viewmodel/profile_setup_viewmodel.dart';

class CompleteProfilePlayerScreen extends StatefulWidget {
  const CompleteProfilePlayerScreen({super.key});

  @override
  State<CompleteProfilePlayerScreen> createState() => _ProfilePlayerScreenState();
}

class _ProfilePlayerScreenState extends State<CompleteProfilePlayerScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Consumer<ProfileSetupViewmodel>(
            builder: (context, vm, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Complete Your Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Help us personalize your BallChart experience',
                          style: TextStyle(color: Colors.white60),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// Position
                  _label('Position *'),
                  _dropdown(
                    value: vm.position,
                    hint: 'Select your position',
                    items: const ['Forward', 'Guard', 'Mid fielder'],
                    onChanged: (v) => vm.position = v,
                  ),

                  const SizedBox(height: 20),

                  /// Age Range
                  _label('Age Range *'),
                  _dropdown(
                    value: vm.ageRange,
                    hint: 'Select age range',
                    items: const ['10 - 15', '15 - 20', '20+'],
                    onChanged: (v) => vm.ageRange = v,
                  ),

                  const SizedBox(height: 20),

                  /// Experience
                  _label('Experience Level *'),
                  ExperienceSelector(
                    selected: vm.playerExperienceLevel ?? 'Beginner',
                    onSelect: (v) => vm.playerExperienceLevel = v,
                  ),

                  const SizedBox(height: 24),

                  /// Goals
                  _label('Select Your Goals (Optional)'),
                  _goal('Improve Shooting', vm),
                  _goal('Build Stamina', vm),
                  _goal('Mental Toughness', vm),
                  _goal('Teamwork', vm),
                  _goal('Leadership', vm),

                  const SizedBox(height: 20),

                  /// Additional Goals
                  _label('Additional Personal Goals (Optional)'),
                  TextField(
                    controller: vm.playerAdditionalGoalsController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText:
                      'E.g. Master three-point shots, improve defensive skills...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// Button
                  vm.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => vm.completePlayerProfile(context),
                      child: const Text('Complete Profile',style: TextStyle(
                        color: Colors.white
                      ),),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Helpers
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(color: Colors.white)),
  );

  Widget _dropdown({
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? value,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF1E293B),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      hint: Text(hint),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _goal(String title, ProfileSetupViewmodel vm) {
    final selected = vm.goals.contains(title);
    return SelectableGoalTile(
      title: title,
      selected: selected,
      onTap: () => vm.toggleGoal(title),
    );
  }
}

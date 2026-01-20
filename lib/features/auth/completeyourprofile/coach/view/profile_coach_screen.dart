import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/widgets/completeProfile_Coach/selectable_chip.dart';
import '../../../../../core/widgets/completeProfile_Coach/selectable_tile.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../../../../routes/routes_names.dart';
import '../../viewmodel/profile_setup_viewmodel.dart';

class CompleteProfileScreenCoach extends StatefulWidget {
  const CompleteProfileScreenCoach({super.key});

  @override
  State<CompleteProfileScreenCoach> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreenCoach> {

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
                  // Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: AppColors.yellow,
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
                          'Help us personalize your CourtIQ experience',
                          style: TextStyle(color: Colors.white60),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Experience Level
                  const Text('Experience Level *', style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: vm.experienceLevel,
                    hint: const Text(
                      'Select experience level',
                      style: TextStyle(color: Colors.white70),
                    ),
                    dropdownColor: const Color(0xFF1E293B),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: '1-3 Years', child: Text('1 - 3 Years')),
                      DropdownMenuItem(value: '4-7 Years', child: Text('4 - 7 Years')),
                      DropdownMenuItem(value: '8+ Years', child: Text('8+ Years')),
                    ],
                    onChanged: (value) => vm.experienceLevel = value,
                  ),

                  const SizedBox(height: 24),

                  // Sports
                  const Text('Sport Categories *', style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _sport('Basketball', Icons.sports_basketball, vm),
                      _sport('Football', Icons.sports_soccer, vm),
                      _sport('Volleyball', Icons.sports_volleyball, vm),
                      _sport('Cricket', Icons.sports_cricket, vm),
                      _sport('Baseball', Icons.sports_baseball, vm),
                      _sport('Tennis', Icons.sports_tennis, vm),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Achievements
                  const Text('Common Achievements (Optional)', style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 12),
                  _achievement('Certified Coach', vm),
                  _achievement('National Champion', vm),
                  _achievement('Regional Champion', vm),
                  _achievement('Youth Development Specialist', vm),
                  _achievement('Advanced Training Certificate', vm),

                  const SizedBox(height: 20),

                  // Additional
                  const Text('Additional Achievements (Optional)', style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: vm.coachAdditionalController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'E.g. Led Thunder Squad to State Championship...',
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

                  vm.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : CustomButton(
                          text: 'Complete Profile',
                          onPressed: () => vm.completeCoachProfile(context),
                        ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _sport(String label, IconData icon, ProfileSetupViewmodel vm) {
    final selected = vm.sports.contains(label);
    return SelectableChip(
      label: label,
      icon: icon,
      selected: selected,
      onTap: () => vm.toggleSport(label),
    );
  }

  Widget _achievement(String title, ProfileSetupViewmodel vm) {
    final selected = vm.achievements.contains(title);
    return SelectableTile(
      title: title,
      selected: selected,
      onTap: () => vm.toggleAchievement(title),
    );
  }
}

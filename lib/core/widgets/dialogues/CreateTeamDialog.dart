import 'package:flutter/material.dart';
import 'package:courtiq/core/constants/colors.dart';
import 'package:courtiq/core/widgets/custom_button.dart';
import 'package:courtiq/core/widgets/auth/custom_textfield_createaccount.dart';

class CreateTeamDialog extends StatefulWidget {
  final Function(String name, String ageGroup, Color color)? onTeamCreated;

  const CreateTeamDialog({super.key, this.onTeamCreated});

  @override
  State<CreateTeamDialog> createState() => _CreateTeamDialogState();
}

class _CreateTeamDialogState extends State<CreateTeamDialog> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedAgeGroup = 'Under 12';
  Color _selectedColor = Colors.blue;
  
  // Predefined age groups
  final List<String> _ageGroups = [
    'Under 12',
    'Under 14',
    'Under 16',
    'Under 19',
    'Open',
  ];

  // Predefined team colors
  final List<Color> _teamColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    const Color(0xFF1E293B), // Dark Slate
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxDialogHeight = MediaQuery.of(context).size.height * 0.84;
    return Dialog(
      backgroundColor: const Color(0xFF091020),
      insetPadding: const EdgeInsets.all(16),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.92, end: 1),
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutBack,
        builder: (_, value, child) => Transform.scale(scale: value, child: child),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxDialogHeight),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.yellow.withOpacity(0.18),
                  const Color(0xFF020617),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.yellow.withOpacity(0.28)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.yellow.withOpacity(0.16),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header
              Row(
                children: [
                   CircleAvatar(
                    backgroundColor: AppColors.yellow,
                    child: const Icon(Icons.add, color: Colors.black),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Create New Team',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const Text(
                'Design a beautiful team identity and launch instantly.',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 14),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      /// Logo Upload (Mock)
                      Center(
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeOutCubic,
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    _selectedColor.withOpacity(0.28),
                                    _selectedColor.withOpacity(0.08),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(color: _selectedColor, width: 2.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: _selectedColor.withOpacity(0.36),
                                    blurRadius: 14,
                                    spreadRadius: 1.5,
                                  ),
                                ],
                              ),
                              child: Icon(Icons.shield, color: _selectedColor, size: 46),
                            ),
                            const SizedBox(height: 10),
                            TextButton.icon(
                              onPressed: () {
                                // Implement Image Picker logic here
                              },
                              icon: const Icon(Icons.upload_file, size: 18, color: AppColors.yellow),
                              label: const Text('Upload Logo', style: TextStyle(color: AppColors.yellow)),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      /// Team Name
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Team Basics',
                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 10),
                      CustomTextFieldCreateAccount(
                        label: 'Team Name',
                        hintText: 'e.g. Thunder Squad',
                        controller: _nameController,
                      ),

                      const SizedBox(height: 16),

                      /// Age Group Dropdown
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Age Group',
                          style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedAgeGroup,
                            dropdownColor: const Color(0xFF0F172A),
                            style: const TextStyle(color: Colors.white),
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                            isExpanded: true,
                            items: _ageGroups.map((group) {
                              return DropdownMenuItem(
                                value: group,
                                child: Text(group),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) setState(() => _selectedAgeGroup = value);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      /// Team Color Picker
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Team Color',
                          style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _teamColors.map((color) {
                          final isSelected = _selectedColor == color;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = color),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 3)
                                    : Border.all(color: Colors.white24, width: 1),
                                boxShadow: isSelected
                                    ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 8, spreadRadius: 2)]
                                    : [],
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 24)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              /// Action Buttons
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancel',
                      backgroundColor: Colors.transparent,
                      textColor: Colors.white60,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: 'Create Team',
                      backgroundColor: AppColors.yellow,
                      textColor: Colors.black,
                      onPressed: () {
                          if (_nameController.text.isNotEmpty) {
                            widget.onTeamCreated?.call(
                              _nameController.text,
                              _selectedAgeGroup,
                              _selectedColor,
                            );
                          }
                          Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

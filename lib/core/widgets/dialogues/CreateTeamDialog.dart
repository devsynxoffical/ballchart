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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF020617),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 20),

              /// Logo Upload (Mock)
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: _selectedColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: _selectedColor, width: 2),
                      ),
                      child: Icon(Icons.shield, color: _selectedColor, size: 50),
                    ),
                    const SizedBox(height: 12),
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

              const SizedBox(height: 20),

              /// Team Name
              CustomTextFieldCreateAccount(
                label: 'Team Name',
                hintText: 'e.g. Thunder Squad',
                controller: _nameController,
              ),

              const SizedBox(height: 20),

              /// Age Group Dropdown
              const Text(
                'Age Group',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
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

              const SizedBox(height: 24),

              /// Team Color Picker
              const Text(
                'Team Color',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _teamColors.map((color) {
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
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

              const SizedBox(height: 32),

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
    );
  }
}

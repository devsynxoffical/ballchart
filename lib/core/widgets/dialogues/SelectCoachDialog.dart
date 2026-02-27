import 'package:flutter/material.dart';
import 'package:courtiq/core/constants/colors.dart';
import 'package:courtiq/core/widgets/custom_button.dart';
import 'package:courtiq/core/widgets/dialogues/CreateStaffDialog.dart';
import 'package:courtiq/features/staff/service/staff_service.dart';

class SelectCoachDialog extends StatefulWidget {
  final String role; // 'Coach' or 'Assistant Coach'
  final Function(Map<String, dynamic> coach) onCoachSelected;

  const SelectCoachDialog({
    super.key,
    required this.role,
    required this.onCoachSelected,
  });

  @override
  State<SelectCoachDialog> createState() => _SelectCoachDialogState();
}

class _SelectCoachDialogState extends State<SelectCoachDialog> {
  final StaffService _staffService = StaffService();
  List<Map<String, dynamic>> _availableStaff = [];
  bool _isLoading = true;

  String? _selectedCoachEmail;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    try {
      final staff = await _staffService.getStaffCredentials();
      _availableStaff = staff.map((s) {
        final role = (s['role'] ?? '').toString();
        return {
          'name': s['username'] ?? 'Staff',
          'email': s['email'] ?? '',
          'role': role == 'assistant_coach' ? 'Assistant' : 'Coach',
        };
      }).toList();
    } catch (_) {
      _availableStaff = [];
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addNewStaff(Map<String, dynamic> newStaff) {
    setState(() {
      _availableStaff.insert(0, newStaff); // Add to top
      _selectedCoachEmail = newStaff['email']; // Auto-select
    });
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header
            Row(
              children: [
                 CircleAvatar(
                  backgroundColor: AppColors.green,
                  child: const Icon(Icons.person_search, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Select ${widget.role}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available Staff',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => CreateStaffDialog(
                        initialRole: widget.role,
                        onStaffCreated: _addNewStaff,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 16, color: AppColors.green),
                  label: const Text('Add New', style: TextStyle(color: AppColors.green)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            /// Staff List
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: _availableStaff.length,
                itemBuilder: (context, index) {
                  final staff = _availableStaff[index];
                  final isSelected = _selectedCoachEmail == staff['email'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCoachEmail = staff['email'];
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.green.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.green : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.grey[800],
                            child: Text(staff['name']![0]),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  staff['name']!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  staff['role']!,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle, color: AppColors.green),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

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
                    text: 'Assign',
                    backgroundColor: AppColors.green,
                    textColor: Colors.white,
                    onPressed: _selectedCoachEmail == null
                        ? null
                        : () {
                            final selectedStaff = _availableStaff.firstWhere(
                              (s) => s['email'] == _selectedCoachEmail,
                            );
                            widget.onCoachSelected(selectedStaff);
                            Navigator.pop(context);
                          },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

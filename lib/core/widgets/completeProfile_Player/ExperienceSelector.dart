import 'package:flutter/material.dart';

class ExperienceSelector extends StatelessWidget {
  final String selected;
  final Function(String) onSelect;

  const ExperienceSelector({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  Widget _item(String label) {
    final isSelected = selected == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.white10,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.transparent,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _item('Beginner'),
        const SizedBox(width: 10),
        _item('Intermediate'),
        const SizedBox(width: 10),
        _item('Advanced'),
      ],
    );
  }
}

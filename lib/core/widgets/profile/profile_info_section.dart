import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../constants/colors.dart';

class ProfileInfoSection extends StatelessWidget {
  final UserModel user;

  const ProfileInfoSection({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (user.role == 'coach') ...[
          _buildInfoItem('Experience Level', user.experienceLevel ?? 'Not set'),
          const SizedBox(height: 16),
          _buildChipSection('Sports Coaching', user.sports ?? []),
          const SizedBox(height: 16),
          _buildChipSection('Achievements', user.achievements ?? []),
          if (user.additionalInfo != null && user.additionalInfo!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoItem('About', user.additionalInfo!),
          ],
        ] else ...[
          Row(
            children: [
              Expanded(child: _buildInfoItem('Position', user.position ?? 'Not set')),
              Expanded(child: _buildInfoItem('Age Range', user.ageRange ?? 'Not set')),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoItem('Experience', user.experienceLevel ?? 'Not set'),
          const SizedBox(height: 16),
          _buildChipSection('Goals', user.goals ?? []),
          if (user.additionalGoals != null && user.additionalGoals!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoItem('Additional Goals', user.additionalGoals!),
          ],
        ],
      ],
    );
  }

  Widget _buildInfoItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildChipSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.yellow.withOpacity(0.1),
              border: Border.all(color: AppColors.yellow.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item,
              style: const TextStyle(
                color: AppColors.yellow,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          )).toList(),
        ),
        if (items.isEmpty)
          const Text(
            'None specified',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
      ],
    );
  }
}

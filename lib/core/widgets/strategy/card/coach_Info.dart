import 'package:flutter/material.dart';
import 'package:courtiq/core/widgets/strategy/card/role_Badge.dart';

import '../../../constants/colors.dart';

class CoachInfo extends StatelessWidget {
  final String name;
  final String role;
  final String time;

  const CoachInfo(this.name, this.role, this.time);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.yellow,
            child: const Icon(Icons.person, color: Colors.black),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  RoleBadge(role),
                ],
              ),
              Text(
                time,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.more_vert, color: Colors.white38),
        ],
      ),
    );
  }
}

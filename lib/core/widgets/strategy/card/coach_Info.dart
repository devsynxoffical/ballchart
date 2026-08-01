import 'package:flutter/material.dart';
import 'package:ballchart/core/widgets/strategy/card/role_Badge.dart';
import 'package:ballchart/core/widgets/user_avatar.dart';

import '../../../constants/colors.dart';

class CoachInfo extends StatelessWidget {
  final String name;
  final String role;
  final String time;
  final String? avatarUrl;

  const CoachInfo(this.name, this.role, this.time, {this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          UserAvatar(
            name: name,
            imageUrl: avatarUrl,
            size: 40,
            usePersonIconFallback: true,
            accentColor: Colors.black,
            backgroundColor: AppColors.yellow,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    RoleBadge(role),
                  ],
                ),
                Text(
                  time,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

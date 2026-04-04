import 'package:flutter/material.dart';

class PasswordRulesWidget extends StatelessWidget {
  const PasswordRulesWidget({super.key});

  Widget _rule(String text) {
    return Row(
      children: [
        const Icon(Icons.circle, size: 6, color: Colors.white54),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(color: Colors.white60, fontSize: 13),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _rule('8–20 characters length'),
          const SizedBox(height: 6),
          _rule('At least one number (0-9)'),
          const SizedBox(height: 6),
          _rule('At least one special character (@, \$, !, %, *)'),
        ],
      ),
    );
  }
}

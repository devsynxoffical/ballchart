import 'package:flutter/material.dart';

class PasswordRules extends StatelessWidget {
  const PasswordRules({super.key});

  Widget _rule(String text) {
    return Row(
      children: [
        const Icon(Icons.close, color: Colors.white38, size: 16),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white60, fontSize: 12)),
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
          _rule('At least 8 characters'),
          _rule('At least one number (0-9)'),
          _rule('At least one special character (@, \$, !, %, *)'),
        ],
      ),
    );
  }
}

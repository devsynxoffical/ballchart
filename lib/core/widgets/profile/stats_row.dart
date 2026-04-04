import 'package:flutter/material.dart';

class StatsRow extends StatelessWidget {
  const StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _StatCard(title: 'Points', value: '375'),
        SizedBox(width: 12),
        _StatCard(title: 'Tasks Done', value: '28'),
        SizedBox(width: 12),
        _StatCard(title: 'Streak Days', value: '12'),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const SizedBox(height: 4),
            Text(title,
                style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

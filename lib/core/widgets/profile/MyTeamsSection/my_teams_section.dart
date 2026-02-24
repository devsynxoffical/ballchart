import 'package:flutter/material.dart';

class MyTeamsSection extends StatelessWidget {
  final List<String>? teams;
  const MyTeamsSection({super.key, this.teams});

  @override
  Widget build(BuildContext context) {
    if (teams == null || teams!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('My Teams',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...teams!.map((team) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _TeamTile(name: team, members: 'Active Squad'),
        )),
      ],
    );
  }
}

class _TeamTile extends StatelessWidget {
  final String name;
  final String members;

  const _TeamTile({required this.name, required this.members});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.orange,
            child: Icon(Icons.star, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
              Text(members,
                  style:
                  const TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Active',
              style: TextStyle(color: Colors.green, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class CardFooter extends StatelessWidget {
  final int likes;
  final int comments;

  const CardFooter(this.likes, this.comments);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.favorite_border, color: Colors.white38),
          const SizedBox(width: 6),
          Text('$likes', style: const TextStyle(color: Colors.white60)),
          const SizedBox(width: 16),
          Icon(Icons.comment, color: Colors.white38),
          const SizedBox(width: 6),
          Text('$comments', style: const TextStyle(color: Colors.white60)),
        ],
      ),
    );
  }
}

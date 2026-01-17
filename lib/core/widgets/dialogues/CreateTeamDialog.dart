import 'package:flutter/material.dart';

class CreateTeamDialog extends StatelessWidget {
  const CreateTeamDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF020617),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFF59E0B),
                  child: Icon(Icons.add, color: Colors.black),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Create New Team',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),

            const SizedBox(height: 6),
            const Text(
              'Set up your team profile',
              style: TextStyle(color: Colors.white60),
            ),

            const SizedBox(height: 24),

            /// Image placeholder
            Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFF59E0B),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.image, color: Colors.white54, size: 32),
              ),
            ),

            const SizedBox(height: 12),

            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Upload Photo',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Team name
            const Text(
              'Team Name *',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),

            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g., Thunder Squad',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Create Team',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

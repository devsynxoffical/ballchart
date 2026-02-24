import 'package:flutter/material.dart';
import 'package:courtiq/core/constants/colors.dart';
import 'package:courtiq/core/widgets/dialogues/CreatePlayerDialog.dart';
import 'package:courtiq/core/widgets/dialogues/SelectCoachDialog.dart';
import 'package:courtiq/features/staff/service/staff_service.dart';

class HierarchyManagementWidget extends StatefulWidget {
  final Function(Map<String, String> player)? onPlayerAdded;
  final String role;

  const HierarchyManagementWidget({super.key, this.onPlayerAdded, required this.role});

  @override
  State<HierarchyManagementWidget> createState() => _HierarchyManagementWidgetState();
}

class _HierarchyManagementWidgetState extends State<HierarchyManagementWidget> {
  // Local state for demo
  Map<String, dynamic>? _assignedCoach;
  Map<String, dynamic>? _assignedAsstCoach;

  @override
  Widget build(BuildContext context) {
    final bool isHC = widget.role == 'head_coach';
    
    return Column(
      children: [
        // Head Coach Node
        _buildNode('Head Coach', isRoot: true),
        
        CustomPaint(
          size: const Size(2, 40),
          painter: LinePainter(),
        ),

        // Staff Level
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNode(
              _assignedCoach?['name'] ?? 'Coach',
              isAssigned: _assignedCoach != null,
              onTap: isHC ? () => _showSelectCoachDialog(context, 'Coach') : null,
            ),
            _buildNode(
              _assignedAsstCoach?['name'] ?? 'Asst. Coach',
              isAssigned: _assignedAsstCoach != null,
              onTap: isHC ? () => _showSelectCoachDialog(context, 'Assistant Coach') : null,
            ),
          ],
        ),

        const SizedBox(height: 20),
        
        // Players Level (simplified visualization)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.groups, color: Colors.white70),
              const SizedBox(width: 8),
              const Text('Players Management', style: TextStyle(color: Colors.white)),
              const Spacer(),
              IconButton(
                 icon: const Icon(Icons.add_circle, color: AppColors.yellow),
                 onPressed: () => _showCreatePlayerDialog(context),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNode(String label, {bool isRoot = false, bool isAssigned = false, VoidCallback? onTap}) {
    final bool isActive = isRoot || isAssigned;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: isRoot ? 80 : 60,
            height: isRoot ? 80 : 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? (isRoot ? AppColors.yellow : AppColors.green) : const Color(0xFF334155),
              border: Border.all(color: isActive ? Colors.white : AppColors.yellow, width: 2),
              boxShadow: [
                BoxShadow(
                  color: isActive
                      ? (isRoot ? AppColors.yellow : AppColors.green).withValues(alpha: 0.4)
                      : Colors.black26,
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Icon(
              isActive ? Icons.person : Icons.add,
              color: isActive ? Colors.white : AppColors.yellow,
              size: isRoot ? 40 : 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? (isRoot ? AppColors.yellow : AppColors.green) : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showSelectCoachDialog(BuildContext context, String role) {
    showDialog(
      context: context,
      builder: (context) => SelectCoachDialog(
        role: role,
        onCoachSelected: (coach) {
          setState(() {
            if (role == 'Coach') {
              _assignedCoach = coach;
            } else {
              _assignedAsstCoach = coach;
            }
          });
        },
      ),
    );
  }

  void _showCreatePlayerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreatePlayerDialog(
        onPlayerCreated: (player) async {
          final staffService = StaffService();
          try {
             await staffService.createPlayer(
              name: player['name']!,
              email: player['email']!,
              password: player['tempPassword']!,
              number: player['number'],
              position: player['position'],
              height: player['height'],
              weight: player['weight'],
            );

            widget.onPlayerAdded?.call(player);

            if (context.mounted) {
              _showCredentialResult(
                context,
                player['name']!,
                player['email']!,
                player['tempPassword']!
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error creating player account: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showCredentialResult(BuildContext context, String name, String email, String password) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Account Created: $name', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Login Credentials:', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.yellow.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                   const Text('EMAIL', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.2)),
                  Text(email, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('PASSWORD', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.2)),
                  SelectableText(
                    password,
                    style: const TextStyle(
                      color: AppColors.yellow,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Share these credentials for immediate login.', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('DONE', style: TextStyle(color: AppColors.yellow, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
}

class LinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    // Vertical line from root
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width / 2, size.height / 2);
    
    // Horizontal details
    path.moveTo(size.width / 2 - 60, size.height / 2);
    path.lineTo(size.width / 2 + 60, size.height / 2);

    // Vertical connectors to children
    path.moveTo(size.width / 2 - 60, size.height / 2);
    path.lineTo(size.width / 2 - 60, size.height);

    path.moveTo(size.width / 2 + 60, size.height / 2);
    path.lineTo(size.width / 2 + 60, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

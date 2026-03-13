import 'package:flutter/material.dart';
import 'package:courtiq/core/constants/colors.dart';
import 'package:courtiq/core/widgets/dialogues/CreatePlayerDialog.dart';
import 'package:courtiq/core/widgets/dialogues/SelectCoachDialog.dart';

class HierarchyManagementWidget extends StatefulWidget {
  final Function(Map<String, String> player)? onPlayerAdded;
  final String role;
  final String teamId;
  final String? coachName;
  final String? assistantCoachName;

  const HierarchyManagementWidget({
    super.key,
    this.onPlayerAdded,
    required this.role,
    required this.teamId,
    this.coachName,
    this.assistantCoachName,
  });

  @override
  State<HierarchyManagementWidget> createState() => _HierarchyManagementWidgetState();
}

class _HierarchyManagementWidgetState extends State<HierarchyManagementWidget> {
  // Local state for demo
  Map<String, dynamic>? _assignedCoach;
  Map<String, dynamic>? _assignedAsstCoach;

  @override
  void initState() {
    super.initState();
    if (widget.coachName != null && widget.coachName!.trim().isNotEmpty) {
      _assignedCoach = {'name': widget.coachName!.trim()};
    }
    if (widget.assistantCoachName != null && widget.assistantCoachName!.trim().isNotEmpty) {
      _assignedAsstCoach = {'name': widget.assistantCoachName!.trim()};
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canManageLeads = widget.role == 'head_coach' || widget.role == 'admin';
    
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
              onTap: canManageLeads ? () => _showSelectCoachDialog(context, 'Coach') : null,
            ),
            _buildNode(
              _assignedAsstCoach?['name'] ?? 'Asst. Coach',
              isAssigned: _assignedAsstCoach != null,
              onTap: canManageLeads ? () => _showSelectCoachDialog(context, 'Assistant Coach') : null,
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
        teamId: widget.teamId,
        onPlayerCreated: (player) {
          widget.onPlayerAdded?.call(player);
        },
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

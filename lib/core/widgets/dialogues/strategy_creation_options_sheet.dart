import 'package:flutter/material.dart';

import 'strategy_creation_entry.dart';

/// Research-backed pattern: choose *intent* first (film vs board vs notes),
/// then open a form tuned to that path — similar to drill builders that
/// branch "add video" vs "diagram" vs "library link".
Future<StrategyCreationEntry?> showStrategyCreationOptionsSheet(
  BuildContext context,
) {
  const primaryColor = Color(0xFFFFD900);
  const bgColor = Color(0xFF131313);
  const surfaceHigh = Color(0xFF2A2A2A);
  const outlineColor = Color(0xFF9D8F79);

  return showModalBottomSheet<StrategyCreationEntry>(
    context: context,
    isScrollControlled: true,
    backgroundColor: bgColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: outlineColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'NEW STRATEGY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Space Grotesk',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pick how you want to build this entry',
                textAlign: TextAlign.center,
                style: TextStyle(color: outlineColor.withOpacity(0.95), fontSize: 12),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: StrategyCreationEntry.values.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: surfaceHigh,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.pop(ctx, e),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(e.icon, color: primaryColor, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        e.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        e.subtitle,
                                        style: TextStyle(
                                          color: outlineColor.withOpacity(0.9),
                                          fontSize: 11,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: outlineColor.withOpacity(0.6)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'CANCEL',
                  style: TextStyle(
                    color: outlineColor.withOpacity(0.9),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

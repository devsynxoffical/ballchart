import 'package:flutter/material.dart';
import 'package:ballchart/core/repositories/development_repository.dart';

/// Staff: set play recognition % and drill completion % (stored on academy training catalog).
Future<void> showStrategyKpisSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF2A2A2A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const _StrategyKpisBody(),
  );
}

class _StrategyKpisBody extends StatefulWidget {
  const _StrategyKpisBody();

  @override
  State<_StrategyKpisBody> createState() => _StrategyKpisBodyState();
}

class _StrategyKpisBodyState extends State<_StrategyKpisBody> {
  final _repo = DevelopmentRepository();
  bool _loading = true;
  bool _saving = false;
  double _formation = 70;
  double _drill = 70;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final c = await _repo.fetchCatalog();
      if (!mounted) return;
      setState(() {
        _formation = (c.formationEngagementPct ?? 70).toDouble();
        _drill = (c.drillCompletionPct ?? 70).toDouble();
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _repo.updateCatalog(
        formationEngagementPct: _formation.round(),
        drillCompletionPct: _drill.round(),
      );
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          const SnackBar(content: Text('Strategy KPIs saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clearAll() async {
    setState(() => _saving = true);
    try {
      await _repo.updateCatalog(
        clearFormationEngagementPct: true,
        clearDrillCompletionPct: true,
      );
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          const SnackBar(content: Text('KPIs cleared — players will see dashes until you set new targets')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFFFD900);
    const outline = Color(0xFF9D8F79);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: _loading
          ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: primary)))
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: outline.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'STRATEGY KPI TARGETS',
                  style: TextStyle(color: outline, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Shown to players on Strategy',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set squad targets (0–100%). Players see live values from your academy.',
                  style: TextStyle(color: outline.withValues(alpha: 0.95), fontSize: 13, height: 1.35),
                ),
                const SizedBox(height: 24),
                Text('Set recognition — ${_formation.round()}%', style: const TextStyle(color: primary, fontWeight: FontWeight.w700)),
                Slider(
                  value: _formation,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: '${_formation.round()}%',
                  activeColor: primary,
                  onChanged: (v) => setState(() => _formation = v),
                ),
                const SizedBox(height: 8),
                Text('Drill completion — ${_drill.round()}%', style: const TextStyle(color: primary, fontWeight: FontWeight.w700)),
                Slider(
                  value: _drill,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: '${_drill.round()}%',
                  activeColor: primary,
                  onChanged: (v) => setState(() => _drill = v),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : _clearAll,
                        child: const Text('Clear targets'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.black),
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

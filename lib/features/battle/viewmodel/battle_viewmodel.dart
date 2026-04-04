import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/repositories/battle_repository.dart';
import '../../../core/models/battle_model.dart';

class BattleViewmodel extends ChangeNotifier {
  final BattleRepository _battleRepository = BattleRepository();
  
  List<BattleModel> _battles = [];
  List<BattleModel> get battles => _battles;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  Timer? _pollingTimer;

  Future<void> loadBattles({bool silent = false}) async {
    if (!silent) {
      _setLoading(true);
    }
    try {
      _battles = await _battleRepository.getBattles();
      _errorMessage = null;
      if (!silent) {
        _setLoading(false);
      } else {
        notifyListeners();
      }
    } catch (e) {
      if (!silent) {
        _setLoading(false);
      }
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> createBattle(String location, DateTime dateTime) async {
    _setLoading(true);
    try {
      final battle = await _battleRepository.createBattle(location, dateTime);
      _battles.insert(0, battle);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString();
      notifyListeners();
      rethrow; // Allow UI to handle success/fail
    }
  }

  Future<void> joinBattle(String battleId) async {
    _setLoading(true);
    try {
      await _battleRepository.joinBattle(battleId);
      // Reload battles to update state (or manually update local list)
      await loadBattles();
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void startLiveUpdates() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      loadBattles(silent: true);
    });
  }

  void stopLiveUpdates() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    stopLiveUpdates();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
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

  Future<void> loadBattles() async {
    _setLoading(true);
    try {
      _battles = await _battleRepository.getBattles();
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
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

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

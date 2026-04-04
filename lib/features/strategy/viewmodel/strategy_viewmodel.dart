import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/models/strategy_model.dart';
import '../../../core/repositories/strategy_repository.dart';

class StrategyViewmodel extends ChangeNotifier {
  final StrategyRepository _repository = StrategyRepository();

  List<StrategyModel> _strategies = [];
  List<StrategyModel> get strategies => _strategies;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Timer? _liveTimer;

  Future<void> loadStrategies({bool silent = false}) async {
    if (!silent) {
      _setLoading(true);
    }
    try {
      _strategies = await _repository.getStrategies();
      _errorMessage = null;
      if (!silent) {
        _setLoading(false);
      } else {
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      if (!silent) {
        _setLoading(false);
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> createStrategy({
    required String title,
    required String category,
    required String sourceType,
    required String sourceText,
    required String videoUrl,
  }) async {
    final created = await _repository.createStrategy(
      title: title,
      category: category,
      sourceType: sourceType,
      sourceText: sourceText,
      videoUrl: videoUrl,
    );
    _strategies = [created, ..._strategies];
    notifyListeners();
  }

  void startLiveSync() {
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      loadStrategies(silent: true);
    });
  }

  void stopLiveSync() {
    _liveTimer?.cancel();
    _liveTimer = null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    stopLiveSync();
    super.dispose();
  }
}

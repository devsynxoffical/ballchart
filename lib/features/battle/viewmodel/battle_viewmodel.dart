import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/models/battle_model.dart';
import '../../../core/repositories/battle_repository.dart';

class BattleViewmodel extends ChangeNotifier {
  final BattleRepository _repository = BattleRepository();

  List<BattleModel> _battles = [];
  List<BattleModel> get battles => _battles;

  List<BattleModel> _myBattles = [];
  List<BattleModel> get myBattles => _myBattles;

  List<BattleModel> _upcomingBattles = [];
  List<BattleModel> get upcomingBattles => _upcomingBattles;

  List<BattleModel> _ongoingBattles = [];
  List<BattleModel> get ongoingBattles => _ongoingBattles;

  List<BattleModel> _finishedBattles = [];
  List<BattleModel> get finishedBattles => _finishedBattles;

  List<String> _locations = [];
  List<String> get locations => _locations;

  Map<String, dynamic> _stats = {};
  Map<String, dynamic> get stats => _stats;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _currentFilter = 'all';
  String get currentFilter => _currentFilter;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _selectedStatus = '';
  String get selectedStatus => _selectedStatus;

  String _selectedLocation = '';
  String get selectedLocation => _selectedLocation;

  String _sortBy = 'dateTime';
  String get sortBy => _sortBy;

  Timer? _liveTimer;

  // Load battles with optional filters
  Future<void> loadBattles({
    bool silent = false,
    String? status,
    String? battleType,
    String? location,
    String? sortBy,
    bool? myBattles,
  }) async {
    if (!silent) {
      _setLoading(true);
    }
    try {
      _battles = await _repository.getBattles(
        status: status ?? _selectedStatus,
        battleType: battleType,
        location: location ?? _selectedLocation,
        sortBy: sortBy ?? _sortBy,
        myBattles: myBattles,
      );
      await _autoFinishPastGames();
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

  // Load specialized battle lists
  Future<void> loadMyBattles() async {
    try {
      _myBattles = await _repository.getMyBattles();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> loadUpcomingBattles() async {
    try {
      _upcomingBattles = await _repository.getUpcomingBattles();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> loadOngoingBattles() async {
    try {
      _ongoingBattles = await _repository.getOngoingBattles();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> loadFinishedBattles() async {
    try {
      _finishedBattles = await _repository.getFinishedBattles();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // Load locations and stats
  Future<void> loadLocationsAndStats() async {
    try {
      final futures = await Future.wait([
        _repository.getLocations(),
        _repository.getBattleStats(),
      ]);
      _locations = futures[0] as List<String>;
      _stats = futures[1] as Map<String, dynamic>;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // Create battle with enhanced options
  Future<void> createBattle({
    required String location,
    required DateTime dateTime,
    String battleType = '1v1',
    int maxParticipants = 2,
    String? description,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) async {
    _setLoading(true);
    try {
      final created = await _repository.createBattle(
        location: location,
        dateTime: dateTime,
        battleType: battleType,
        maxParticipants: maxParticipants,
        description: description,
        tags: tags,
        metadata: metadata,
      );
      _battles = [created, ..._battles];
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> updateBattle(
    String id, {
    String? location,
    DateTime? dateTime,
    String? battleType,
    int? maxParticipants,
    String? description,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) async {
    _setLoading(true);
    try {
      final updated = await _repository.updateBattle(
        id,
        location: location,
        dateTime: dateTime,
        battleType: battleType,
        maxParticipants: maxParticipants,
        description: description,
        tags: tags,
        metadata: metadata,
      );
      final index = _battles.indexWhere((b) => b.id == id);
      if (index != -1) {
        _battles[index] = updated;
      }
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      rethrow;
    }
  }

  // Battle actions
  Future<void> joinBattle(String id) async {
    try {
      final updated = await _repository.joinBattle(id);
      final index = _battles.indexWhere((b) => b.id == id);
      if (index != -1) {
        _battles[index] = updated;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> leaveBattle(String id) async {
    try {
      final updated = await _repository.leaveBattle(id);
      final index = _battles.indexWhere((b) => b.id == id);
      if (index != -1) {
        _battles[index] = updated;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> startBattle(String id) async {
    try {
      final updated = await _repository.startBattle(id);
      final index = _battles.indexWhere((b) => b.id == id);
      if (index != -1) {
        _battles[index] = updated;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> finishBattle(String id, {String? result, String? winnerId}) async {
    try {
      final updated = await _repository.finishBattle(id, result: result, winnerId: winnerId);
      final index = _battles.indexWhere((b) => b.id == id);
      if (index != -1) {
        _battles[index] = updated;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> cancelBattle(String id) async {
    try {
      final updated = await _repository.cancelBattle(id);
      final index = _battles.indexWhere((b) => b.id == id);
      if (index != -1) {
        _battles[index] = updated;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // Set filters
  void setFilter(String filter) {
    _currentFilter = filter;
    switch (filter) {
      case 'all':
        _selectedStatus = '';
        break;
      case 'upcoming':
        _selectedStatus = 'pending';
        break;
      case 'ongoing':
        _selectedStatus = 'ongoing';
        break;
      case 'finished':
        _selectedStatus = 'finished';
        break;
      case 'mine':
        loadBattles(myBattles: true);
        return;
    }
    loadBattles();
  }

  // Start live sync
  void startLiveUpdates() {
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      loadBattles(silent: true);
    });
  }

  // Stop live sync
  void stopLiveUpdates() {
    _liveTimer?.cancel();
    _liveTimer = null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> _autoFinishPastGames() async {
    final now = DateTime.now();
    final overdue = _battles.where((b) => b.isPending && b.dateTime.isBefore(now)).toList();
    for (final b in overdue) {
      try {
        final updated = await _repository.updateBattle(b.id, status: 'finished');
        final index = _battles.indexWhere((x) => x.id == b.id);
        if (index != -1) _battles[index] = updated;
      } catch (_) {
        /* production API may not support update yet; UI still shows as finished */
      }
    }
  }

  @override
  void dispose() {
    stopLiveUpdates();
    super.dispose();
  }
}

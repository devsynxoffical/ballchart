import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/models/strategy_model.dart';
import '../../../core/repositories/strategy_repository.dart';

class StrategyViewmodel extends ChangeNotifier {
  final StrategyRepository _repository = StrategyRepository();

  List<StrategyModel> _strategies = [];
  List<StrategyModel> get strategies => _strategies;

  List<String> _categories = [];
  List<String> get categories => _categories;

  List<String> _tags = [];
  List<String> get tags => _tags;

  List<StrategyModel> _myStrategies = [];
  List<StrategyModel> get myStrategies => _myStrategies;

  List<StrategyModel> _popularStrategies = [];
  List<StrategyModel> get popularStrategies => _popularStrategies;

  List<StrategyModel> _recentStrategies = [];
  List<StrategyModel> get recentStrategies => _recentStrategies;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _currentFilter = 'all';
  String get currentFilter => _currentFilter;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _selectedCategory = '';
  String get selectedCategory => _selectedCategory;

  String _selectedTag = '';
  String get selectedTag => _selectedTag;

  String _sortBy = 'createdAt';
  String get sortBy => _sortBy;

  Timer? _liveTimer;

  // Load strategies with optional filters
  Future<void> loadStrategies({
    bool silent = false,
    String? category,
    String? tag,
    String? search,
    String? sortBy,
  }) async {
    if (!silent) {
      _setLoading(true);
    }
    try {
      _strategies = await _repository.getStrategies(
        category: category ?? _selectedCategory,
        tag: tag ?? _selectedTag,
        search: search ?? _searchQuery,
        sortBy: sortBy ?? _sortBy,
      );
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

  // Load categories and tags
  Future<void> loadCategoriesAndTags() async {
    try {
      final futures = await Future.wait([
        _repository.getCategories(),
        _repository.getTags(),
      ]);
      _categories = futures[0];
      _tags = futures[1];
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // Load user's strategies
  Future<void> loadMyStrategies() async {
    try {
      _myStrategies = await _repository.getMyStrategies();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // Load popular strategies
  Future<void> loadPopularStrategies() async {
    try {
      _popularStrategies = await _repository.getPopularStrategies();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // Load recent strategies
  Future<void> loadRecentStrategies() async {
    try {
      _recentStrategies = await _repository.getRecentStrategies();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // Create strategy with enhanced options
  Future<void> createStrategy({
    required String title,
    required String category,
    required String sourceType,
    required String sourceText,
    String? videoUrl,
    List<String>? tags,
    bool isPublic = true,
    Map<String, dynamic>? metadata,
  }) async {
    _setLoading(true);
    try {
      final created = await _repository.createStrategy(
        title: title,
        category: category,
        sourceType: sourceType,
        sourceText: sourceText,
        videoUrl: videoUrl ?? '',
        tags: tags,
        isPublic: isPublic,
        metadata: metadata,
      );
      _strategies = [created, ..._strategies];
      // Re-fetch once to avoid partial local state after creation.
      final latest = await _repository.getStrategies(
        category: _selectedCategory,
        tag: _selectedTag,
        search: _searchQuery,
        sortBy: _sortBy,
      );
      _strategies = latest;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      rethrow;
    }
  }

  // Update strategy
  Future<void> updateStrategy(String id, {
    String? title,
    String? category,
    String? sourceText,
    String? videoUrl,
    List<String>? tags,
    bool? isPublic,
    Map<String, dynamic>? metadata,
  }) async {
    _setLoading(true);
    try {
      final updated = await _repository.updateStrategy(id,
        title: title,
        category: category,
        sourceText: sourceText,
        videoUrl: videoUrl,
        tags: tags,
        isPublic: isPublic,
        metadata: metadata,
      );
      
      // Update in local list
      final index = _strategies.indexWhere((s) => s.id == id);
      if (index != -1) {
        _strategies[index] = updated;
      }
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      rethrow;
    }
  }

  // Delete strategy
  Future<void> deleteStrategy(String id) async {
    _setLoading(true);
    try {
      await _repository.deleteStrategy(id);
      _strategies.removeWhere((s) => s.id == id);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      rethrow;
    }
  }

  // Like strategy
  Future<void> likeStrategy(String id) async {
    try {
      final updated = await _repository.likeStrategy(id);
      final index = _strategies.indexWhere((s) => s.id == id);
      if (index != -1) {
        _strategies[index] = updated;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // Unlike strategy
  Future<void> unlikeStrategy(String id) async {
    try {
      final updated = await _repository.unlikeStrategy(id);
      final index = _strategies.indexWhere((s) => s.id == id);
      if (index != -1) {
        _strategies[index] = updated;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // Increment view count
  Future<void> incrementViewCount(String id) async {
    try {
      final updated = await _repository.incrementViewCount(id);
      final index = _strategies.indexWhere((s) => s.id == id);
      if (index != -1) {
        _strategies[index] = updated;
      }
      notifyListeners();
    } catch (e) {
      // Silently fail for view count
    }
  }

  // Set filters
  void setFilter(String filter) {
    _currentFilter = filter;
    switch (filter) {
      case 'all':
        _selectedCategory = '';
        _selectedTag = '';
        break;
      case 'popular':
        _sortBy = 'likeCount';
        break;
      case 'recent':
        _sortBy = 'createdAt';
        break;
      case 'mine':
        _selectedCategory = '';
        _selectedTag = '';
        break;
    }
    loadStrategies();
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    loadStrategies(silent: true);
  }

  // Set category filter
  void setCategory(String category) {
    _selectedCategory = category;
    loadStrategies();
  }

  // Set tag filter
  void setTag(String tag) {
    _selectedTag = tag;
    loadStrategies();
  }

  // Set sort order
  void setSortOrder(String sortBy) {
    _sortBy = sortBy;
    loadStrategies();
  }

  // Clear all filters
  void clearFilters() {
    _currentFilter = 'all';
    _searchQuery = '';
    _selectedCategory = '';
    _selectedTag = '';
    _sortBy = 'createdAt';
    loadStrategies();
  }

  // Start live sync
  void startLiveSync() {
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      loadStrategies(silent: true);
    });
  }

  // Stop live sync
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

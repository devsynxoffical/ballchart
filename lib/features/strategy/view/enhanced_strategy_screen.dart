import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/basketball_strategy.dart';
import '../../../core/models/strategy_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/video_thumbnail.dart';
import '../../../core/widgets/dialogues/CreateStrategyDialog.dart';
import '../../../core/widgets/dialogues/strategy_creation_options_sheet.dart';
import '../../../core/widgets/permission_wrapper.dart';
import 'package:ballchart/features/strategy/widgets/strategy_kpis_sheet.dart';

import '../../player_development/view/coach_training_assignment_screen.dart';
import '../../profile/viewmodel/profile_viewmodel.dart';
import '../../tactics/view/tactical_lab_screen.dart';
import '../viewmodel/strategy_viewmodel.dart';
import 'strategy_detail_screen.dart';

class EnhancedStrategyScreen extends StatefulWidget {
  const EnhancedStrategyScreen({super.key});

  @override
  State<EnhancedStrategyScreen> createState() => _EnhancedStrategyScreenState();
}

class _EnhancedStrategyScreenState extends State<EnhancedStrategyScreen> {
  String _currentView = 'grid'; // grid, list, detail
  String _selectedCategory = 'all';
  String _selectedSort = 'recent';
  final TextEditingController _searchController = TextEditingController();
  StrategyViewmodel? _strategyViewmodel;

  static const Color primaryColor = Color(0xFFFFD900);
  static const Color bgColor = Color(0xFF131313);
  static const Color surfaceHigh = Color(0xFF201F1F);
  static const Color surfaceContainer = Color(0xFF1C1B1B);
  static const Color outlineColor = Color(0xFF9D8F79);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataWithRetry();
    });
  }

  Future<void> _loadDataWithRetry({int retryCount = 3}) async {
    for (int i = 0; i < retryCount; i++) {
      try {
        final vm = context.read<StrategyViewmodel>();
        _strategyViewmodel = vm;
        
        // Load all data in parallel
        await Future.wait([
          vm.loadStrategies(),
          vm.loadCategoriesAndTags(),
          vm.loadPopularStrategies(),
          vm.loadRecentStrategies(),
        ]);
        
        vm.startLiveSync();
        
        final profileVm = context.read<ProfileViewmodel>();
        if (profileVm.user == null) {
          await profileVm.loadProfile(forceRefresh: true);
        }
        break;
      } catch (e) {
        if (i == retryCount - 1) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load strategies: ${e.toString().replaceAll('Exception: ', '')}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () => _loadDataWithRetry(),
                ),
              ),
            );
          }
        } else {
          await Future.delayed(Duration(milliseconds: 1000 * (i + 1)));
        }
      }
    }
  }

  @override
  void dispose() {
    _strategyViewmodel?.stopLiveSync();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // When the keyboard shrinks height (~300px), fixed header/search
            // would overflow — keep chrome scrollable and content flexible.
            final chromeMaxHeight = (constraints.maxHeight * 0.55).clamp(120.0, constraints.maxHeight);
            return Column(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: chromeMaxHeight),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(),
                        _buildSearchAndFilters(),
                        _buildViewToggle(),
                      ],
                    ),
                  ),
                ),
                Expanded(child: _buildContent()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<ProfileViewmodel>(
      builder: (context, profileVm, _) {
        final role = (profileVm.user?.role ?? '').toLowerCase();
        final isStaff = const {'admin', 'head_coach', 'coach', 'assistant_coach'}.contains(role);

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PLAYBOOK INTELLIGENCE', style: TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    SizedBox(height: 4),
                    Text('BASKETBALL PLAYBOOK', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk')),
                  ],
                ),
              ),
              if (isStaff) ...[
                IconButton(
                  tooltip: 'Playbook KPI targets (set recognition & drills)',
                  onPressed: () => showStrategyKpisSheet(context),
                  icon: const Icon(Icons.tune, color: primaryColor, size: 26),
                ),
                IconButton(
                  tooltip: 'Assign player training',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const CoachTrainingAssignmentScreen()),
                    );
                  },
                  icon: const Icon(Icons.assignment_turned_in_outlined, color: primaryColor, size: 26),
                ),
              ],
              IconButton(
                tooltip: 'Tactical lab (voice + animation)',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const TacticalLabScreen()),
                  );
                },
                icon: const Icon(Icons.grid_4x4_outlined, color: primaryColor, size: 26),
              ),
              PermissionWrapper(
                permission: 'createStrategy',
                child: GestureDetector(
                  onTap: () => _showCreateStrategyDialog(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: Colors.black, size: 24),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchAndFilters() {
    return Consumer<StrategyViewmodel>(
      builder: (context, vm, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: surfaceHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: outlineColor.withOpacity(0.2)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => vm.setSearchQuery(value),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search strategies...',
                    hintStyle: TextStyle(color: outlineColor.withOpacity(0.5)),
                    prefixIcon: Icon(Icons.search, color: outlineColor.withOpacity(0.7)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white70),
                            onPressed: () {
                              _searchController.clear();
                              vm.setSearchQuery('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Category and sort filters
              Row(
                children: [
                  Expanded(
                    child: _buildFilterDropdown(
                      'Category',
                      [
                        {'value': 'all', 'label': 'All'},
                        ...vm.categories.map(
                          (c) => {'value': c, 'label': BasketballStrategy.categoryLabel(c)},
                        ),
                      ],
                      _selectedCategory,
                      (value) {
                        _selectedCategory = value;
                        if (value == 'all') {
                          vm.clearFilters();
                        } else {
                          vm.setCategory(value);
                        }
                      },
                      isMap: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFilterDropdown(
                      'Sort by',
                      [
                        {'value': 'recent', 'label': 'Recent'},
                        {'value': 'popular', 'label': 'Popular'},
                        {'value': 'views', 'label': 'Most Viewed'},
                        {'value': 'likes', 'label': 'Most Liked'},
                      ],
                      _selectedSort,
                      (value) {
                        _selectedSort = value;
                        vm.setSortOrder(value);
                      },
                      isMap: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterDropdown(
    String label,
    dynamic items,
    String selectedValue,
    Function(String) onChanged, {
    bool isMap = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outlineColor.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: outlineColor.withOpacity(0.7)),
          items: items.map<DropdownMenuItem<String>>((item) {
            final value = isMap ? item['value'] : item;
            final displayText = isMap ? item['label'] : item;
            return DropdownMenuItem<String>(
              value: value,
              child: Text(displayText, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: (String? value) {
  if (value != null) onChanged(value);
},
          dropdownColor: const Color(0xFF1C1B1B),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          const Text('View:', style: TextStyle(color: outlineColor, fontSize: 12)),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: surfaceHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildViewToggleItem('Grid', 'grid', Icons.grid_view),
                _buildViewToggleItem('List', 'list', Icons.list),
                _buildViewToggleItem('Analytics', 'analytics', Icons.analytics),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleItem(String label, String value, IconData icon) {
    final isSelected = _currentView == value;
    return GestureDetector(
      onTap: () => setState(() => _currentView = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.black : outlineColor),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: isSelected ? Colors.black : outlineColor, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_currentView == 'analytics') {
      return _buildAnalyticsView();
    }
    
    return Consumer<StrategyViewmodel>(
      builder: (context, vm, _) {
        if (vm.isLoading && vm.strategies.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: primaryColor),
                SizedBox(height: 16),
                Text('Loading Strategies...', style: TextStyle(color: Colors.white70)),
              ],
            ),
          );
        }

        if (vm.errorMessage != null && vm.strategies.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Error Loading Strategies',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vm.errorMessage!,
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _loadDataWithRetry(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('RETRY'),
                  ),
                ],
              ),
            ),
          );
        }

        if (vm.strategies.isEmpty) {
          return _buildEmptyState();
        }

        if (_currentView == 'grid') {
          return _buildGridView(vm.strategies);
        } else {
          return _buildListView(vm.strategies);
        }
      },
    );
  }

  Widget _buildGridView(List<StrategyModel> strategies) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: strategies.length,
        itemBuilder: (context, index) => _strategyCard(strategies[index]),
      ),
    );
  }

  Widget _buildListView(List<StrategyModel> strategies) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView.builder(
        itemCount: strategies.length,
        itemBuilder: (context, index) => _strategyListItem(strategies[index]),
      ),
    );
  }

  Widget _buildAnalyticsView() {
    return Consumer<StrategyViewmodel>(
      builder: (context, vm, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('STRATEGY ANALYTICS', style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              // Overview cards
              Row(
                children: [
                  Expanded(child: _analyticsCard('Total Strategies', '${vm.strategies.length}', Icons.library_books, Colors.blue)),
                  const SizedBox(width: 16),
                  Expanded(child: _analyticsCard('Categories', '${vm.categories.length}', Icons.category, Colors.green)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _analyticsCard('Your Strategies', '${vm.myStrategies.length}', Icons.person, Colors.orange)),
                  const SizedBox(width: 16),
                  Expanded(child: _analyticsCard('Popular', '${vm.popularStrategies.length}', Icons.trending_up, Colors.red)),
                ],
              ),
              
              const SizedBox(height: 32),
              const Text('RECENT ACTIVITY', style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Recent strategies list
              ...vm.recentStrategies.take(5).map((strategy) => _analyticsListItem(strategy)).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _analyticsCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: surfaceHigh, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: outlineColor, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _analyticsListItem(StrategyModel strategy) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surfaceHigh, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: primaryColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.play_arrow, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strategy.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(BasketballStrategy.categoryLabel(strategy.category), style: const TextStyle(color: outlineColor, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${strategy.viewCount} views', style: const TextStyle(color: outlineColor, fontSize: 10)),
              Text('${strategy.likeCount} likes', style: const TextStyle(color: primaryColor, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _strategyCard(StrategyModel strategy) {
    final thumb = resolveStrategyThumbnailDisplay(strategy);
    final hasThumb = thumb.trim().isNotEmpty;
    return GestureDetector(
      onTap: () => _showStrategyDetails(strategy),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: outlineColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video thumbnail
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  color: surfaceContainer,
                  image: hasThumb
                      ? DecorationImage(
                          image: NetworkImage(thumb),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: !hasThumb
                    ? const Center(
                        child: Icon(Icons.play_circle_outline, color: outlineColor, size: 48),
                      )
                    : Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                color: Colors.black.withOpacity(0.3),
                              ),
                            ),
                          ),
                          const Center(
                            child: Icon(Icons.play_circle_filled, color: primaryColor, size: 48),
                          ),
                        ],
                      ),
              ),
            ),
            
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strategy.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      BasketballStrategy.categoryLabel(strategy.category),
                      style: const TextStyle(color: primaryColor, fontSize: 10),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.visibility, color: outlineColor, size: 12),
                        const SizedBox(width: 4),
                        Text('${strategy.viewCount}', style: const TextStyle(color: outlineColor, fontSize: 10)),
                        const SizedBox(width: 12),
                        Icon(Icons.favorite, color: Colors.red, size: 12),
                        const SizedBox(width: 4),
                        Text('${strategy.likeCount}', style: const TextStyle(color: outlineColor, fontSize: 10)),
                        const Spacer(),
                        _buildLikeButton(strategy),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _strategyListItem(StrategyModel strategy) {
    final thumb = resolveStrategyThumbnailDisplay(strategy);
    final hasThumb = thumb.trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surfaceHigh, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 80,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: surfaceContainer,
              image: hasThumb
                  ? DecorationImage(
                      image: NetworkImage(thumb),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: !hasThumb
                ? const Center(child: Icon(Icons.play_arrow, color: outlineColor))
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.black.withValues(alpha: 0.25),
                        ),
                      ),
                      const Center(child: Icon(Icons.play_arrow_rounded, color: primaryColor, size: 28)),
                    ],
                  ),
          ),
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strategy.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${BasketballStrategy.categoryLabel(strategy.category)} • ${strategy.createdByName}',
                  style: const TextStyle(color: outlineColor, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.visibility, color: outlineColor, size: 12),
                    const SizedBox(width: 4),
                    Text('${strategy.viewCount}', style: const TextStyle(color: outlineColor, fontSize: 10)),
                    const SizedBox(width: 12),
                    Icon(Icons.favorite, color: Colors.red, size: 12),
                    const SizedBox(width: 4),
                    Text('${strategy.likeCount}', style: const TextStyle(color: outlineColor, fontSize: 10)),
                    const Spacer(),
                    Text(
                      _formatDate(strategy.createdAt),
                      style: const TextStyle(color: outlineColor, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Actions
          Column(
            children: [
              _buildLikeButton(strategy),
              const SizedBox(height: 8),
              IconButton(
                icon: const Icon(Icons.more_vert, color: outlineColor, size: 16),
                onPressed: () => _showStrategyOptions(strategy),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLikeButton(StrategyModel strategy) {
    final isLiked = strategy.likedBy.isNotEmpty;
    return GestureDetector(
      onTap: () {
        if (isLiked) {
          context.read<StrategyViewmodel>().unlikeStrategy(strategy.id);
        } else {
          context.read<StrategyViewmodel>().likeStrategy(strategy.id);
        }
      },
      child: Icon(
        isLiked ? Icons.favorite : Icons.favorite_border,
        color: isLiked ? Colors.red : outlineColor,
        size: 16,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library_outlined, color: outlineColor, size: 64),
            const SizedBox(height: 16),
            const Text(
              'No Strategies Yet',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start by creating your first tactical strategy',
              style: TextStyle(color: outlineColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PermissionWrapper(
              permission: 'createStrategy',
              child: ElevatedButton(
                onPressed: () => _showCreateStrategyDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.black,
                ),
                child: const Text('CREATE STRATEGY'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStrategyDetails(StrategyModel strategy) {
    // Increment view count
    context.read<StrategyViewmodel>().incrementViewCount(strategy.id);
    
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StrategyDetailScreen(strategy: strategy),
      ),
    );
  }

  void _showStrategyOptions(StrategyModel strategy) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceContainer,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StrategyOptionsSheet(strategy: strategy),
    );
  }

  Future<void> _showCreateStrategyDialog(BuildContext context) async {
    final vm = context.read<StrategyViewmodel>();
    final entry = await showStrategyCreationOptionsSheet(context);
    if (!context.mounted || entry == null) return;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => CreateStrategyDialog(
        entry: entry,
        onStrategyCreated:
            (title, description, category, sourceTypeForApi, plays, imagePath, videoUrl, tags, referenceUrl) async {
          try {
            await vm.createStrategy(
                  title: title,
                  category: category,
                  sourceType: sourceTypeForApi,
                  sourceText: description,
                  videoUrl: (videoUrl ?? '').trim().isEmpty ? null : videoUrl!.trim(),
                  tags: tags,
                  metadata: {
                    'playSteps': plays,
                    'revisionState': 'draft',
                    'creationEntry': entry.name,
                    if (referenceUrl != null && referenceUrl.trim().isNotEmpty) 'referenceUrl': referenceUrl.trim(),
                    if (imagePath != null && imagePath.isNotEmpty) 'localDiagramPath': imagePath,
                  },
                );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Strategy created successfully!'), backgroundColor: Colors.green),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to create strategy: $e'), backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// Supporting widgets

class StrategyOptionsSheet extends StatelessWidget {
  final StrategyModel strategy;
  
  const StrategyOptionsSheet({super.key, required this.strategy});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: const Color(0xFF9D8F79), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          
          Text(
            strategy.title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          ListTile(
            leading: const Icon(Icons.edit, color: Color(0xFFFFD900)),
            title: const Text('Edit Strategy', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              // Edit functionality
            },
          ),
          ListTile(
            leading: const Icon(Icons.share, color: Color(0xFFFFD900)),
            title: const Text('Share Strategy', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              // Share functionality
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Strategy', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirm(context, strategy);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, StrategyModel strategy) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF201F1F),
        title: const Text('Delete Strategy', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${strategy.title}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<StrategyViewmodel>().deleteStrategy(strategy.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

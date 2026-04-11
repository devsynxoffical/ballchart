import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ballchart/core/services/api_service.dart';
import '../../management/viewmodel/academy_provider.dart';

class PlayerStatsTab extends StatefulWidget {
  const PlayerStatsTab({super.key});

  @override
  State<PlayerStatsTab> createState() => _PlayerStatsTabState();
}

class _PlayerStatsTabState extends State<PlayerStatsTab> {
  // BallChart Redesign Tokens - Same as Admin Panel
  static const Color primaryColor = Color(0xFFFFD900);
  static const Color bgColor = Color(0xFF131313);
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color surfaceHigh = Color(0xFF2A2A2A);
  static const Color surfaceHighest = Color(0xFF353534);
  static const Color outlineColor = Color(0xFF9D8F79);

  @override
  void initState() {
    super.initState();
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataWithRetry();
    });
  }

  Future<void> _loadDataWithRetry({int retryCount = 3}) async {
    for (int i = 0; i < retryCount; i++) {
      try {
        await context.read<AcademyProvider>().loadPlayerDashboard();
        break; // Success, exit retry loop
      } catch (e) {
        if (i == retryCount - 1) {
          // Last retry failed, show error
          if (mounted) {
            String errorMessage = e.toString();
            
            // Handle specific error cases
            if (errorMessage.contains('401') || errorMessage.contains('Unauthorized')) {
              errorMessage = 'Authentication failed. Please log in again.';
            } else if (errorMessage.contains('403') || errorMessage.contains('Forbidden')) {
              errorMessage = 'Access denied. You do not have permission to view player data.';
            } else if (errorMessage.contains('Cannot read properties of undefined')) {
              errorMessage = 'Connection error. Please check your internet connection.';
            } else if (errorMessage.contains('Network')) {
              errorMessage = 'Network error. Please check your connection and try again.';
            } else if (errorMessage.contains('timeout')) {
              errorMessage = 'Request timeout. Please try again.';
            } else {
              errorMessage = errorMessage.replaceAll('Exception: ', '');
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load player data: $errorMessage'),
                backgroundColor: Colors.redAccent,
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
          // Wait before retrying
          await Future.delayed(Duration(milliseconds: 1000 * (i + 1)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AcademyProvider>(
      builder: (context, provider, child) {
        // Show loading state
        if (provider.isPlayerLoading) {
          return const SizedBox(
            height: 400,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  SizedBox(height: 16),
                  Text('Loading Player Dashboard...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          );
        }

        // Show error state
        if (provider.error != null) {
          return SizedBox(
            height: 400,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: surfaceHigh,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: outlineColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Error Loading Data',
                            style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 20, 
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Space Grotesk',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            provider.error!,
                            style: const TextStyle(color: outlineColor, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () => _loadDataWithRetry(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: const Text(
                                'RETRY',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900, 
                                  letterSpacing: 2,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Show empty state
        if (provider.playerDashboard == null) {
          return const SizedBox(
            height: 400,
            child: Center(
              child: Text(
                'No player data available',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        final dashboard = provider.playerDashboard!;
        final playerData = dashboard['player'] as Map<String, dynamic>? ?? {};

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Player Performance Header
              const Text(
                'PLAYER PERFORMANCE // 04.24',
                style: TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const SizedBox(height: 4),
              const Text(
                'ATHLETE OVERVIEW',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk'),
              ),
              const SizedBox(height: 24),
              _buildPlayerIdentityRow(playerData),
              const SizedBox(height: 32),

              // Player Stats Cards
              _buildPlayerStatsRow(playerData),
              const SizedBox(height: 24),
              
              // Performance Chart
              _buildPerformanceChart(playerData),
              const SizedBox(height: 24),
              
              // Recent Games
              _buildRecentGames(playerData),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayerIdentityRow(Map<String, dynamic> playerData) {
    final raw = playerData['profileImageUrl']?.toString().trim();
    final url = (raw != null && raw.isNotEmpty) ? ApiService.resolveMediaUrl(raw) : '';
    final hasImg = url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('data:'));
    final name = (playerData['username'] ?? 'Athlete').toString();
    final pos = (playerData['position'] ?? '').toString();
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'P';

    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: primaryColor.withOpacity(0.35), width: 2),
            color: surfaceHigh,
          ),
          child: ClipOval(
            child: hasImg
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    width: 72,
                    height: 72,
                    errorBuilder: (_, __, ___) => Center(child: Text(initial, style: const TextStyle(color: primaryColor, fontSize: 28, fontWeight: FontWeight.w900))),
                  )
                : Center(child: Text(initial, style: const TextStyle(color: primaryColor, fontSize: 28, fontWeight: FontWeight.w900))),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (pos.isNotEmpty)
                Text(
                  pos.toUpperCase(),
                  style: const TextStyle(color: outlineColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerStatsRow(Map<String, dynamic> playerData) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('PPG', playerData['ppg']?.toString() ?? '0.0', primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('APG', playerData['apg']?.toString() ?? '0.0', const Color(0xFF28D8FF)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('RPG', playerData['rpg']?.toString() ?? '0.0', const Color(0xFF8B5CF6)),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color, 
              fontSize: 24, 
              fontWeight: FontWeight.w900,
              fontFamily: 'Space Grotesk',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: outlineColor, 
              fontSize: 12, 
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart(Map<String, dynamic> playerData) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: outlineColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PERFORMANCE TREND',
            style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 16),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Performance Chart\n(Coming Soon)',
                textAlign: TextAlign.center,
                style: TextStyle(color: outlineColor, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentGames(Map<String, dynamic> playerData) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: outlineColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RECENT GAMES',
            style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 16),
          _buildGameItem('VS Kings', 'W', '24 PTS, 8 AST, 6 REB'),
          _buildGameItem('VS Eagles', 'L', '18 PTS, 5 AST, 4 REB'),
          _buildGameItem('VS Lions', 'W', '22 PTS, 7 AST, 5 REB'),
        ],
      ),
    );
  }

  Widget _buildGameItem(String opponent, String result, String stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: result == 'W' ? primaryColor.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                result,
                style: TextStyle(
                  color: result == 'W' ? primaryColor : Colors.red,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opponent,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  stats,
                  style: const TextStyle(color: outlineColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

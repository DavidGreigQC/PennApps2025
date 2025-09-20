import 'package:shared_preferences/shared_preferences.dart';

class LocalStatsService {
  static const String _totalUsersKey = 'total_users';
  static const String _totalMenusKey = 'total_menus';
  static const String _totalOptimizationsKey = 'total_optimizations';

  static LocalStatsService? _instance;
  static LocalStatsService get instance => _instance ??= LocalStatsService._();

  LocalStatsService._();

  /// Initialize with default values if first time
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Set default values if not exists
    if (!prefs.containsKey(_totalUsersKey)) {
      await prefs.setInt(_totalUsersKey, 3); // Start with 3 users as requested
    }
    if (!prefs.containsKey(_totalMenusKey)) {
      await prefs.setInt(_totalMenusKey, 0);
    }
    if (!prefs.containsKey(_totalOptimizationsKey)) {
      await prefs.setInt(_totalOptimizationsKey, 0);
    }
  }

  /// Get community insights
  Future<Map<String, dynamic>> getCommunityInsights() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'total_users': prefs.getInt(_totalUsersKey) ?? 3,
      'total_menus': prefs.getInt(_totalMenusKey) ?? 0,
      'total_optimizations': prefs.getInt(_totalOptimizationsKey) ?? 0,
    };
  }

  /// Increment menu count when files are uploaded
  Future<void> incrementMenuCount([int count = 1]) async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_totalMenusKey) ?? 0;
    await prefs.setInt(_totalMenusKey, currentCount + count);
  }

  /// Increment optimization count when optimization starts
  Future<void> incrementOptimizationCount([int count = 1]) async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_totalOptimizationsKey) ?? 0;
    await prefs.setInt(_totalOptimizationsKey, currentCount + count);
  }

  /// Get current stats for debugging
  Future<void> logCurrentStats() async {
    final stats = await getCommunityInsights();
    print('📊 Community Stats: $stats');
  }

  /// Reset stats (for testing purposes)
  Future<void> resetStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_totalUsersKey, 3);
    await prefs.setInt(_totalMenusKey, 0);
    await prefs.setInt(_totalOptimizationsKey, 0);
  }
}
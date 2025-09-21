import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class OptimizationProgressService {
  static const String _progressKey = 'optimization_progress_data';
  static const int _maxHistoryLength = 10;

  static OptimizationProgressService? _instance;
  static OptimizationProgressService get instance => _instance ??= OptimizationProgressService._();

  OptimizationProgressService._();

  /// Get the last 10 highest optimization percentages
  Future<List<double>> getOptimizationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString(_progressKey);

      if (progressJson == null) {
        return []; // Return empty list if no history exists
      }

      final List<dynamic> progressData = json.decode(progressJson);
      return progressData.map((e) => e as double).toList();
    } catch (e) {
      return []; // Return empty list on error
    }
  }

  /// Add a new highest optimization percentage to the history
  Future<void> addOptimizationResult(double optimizationPercentage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<double> currentHistory = await getOptimizationHistory();

      // Add new result to the end
      currentHistory.add(optimizationPercentage);

      // Keep only the last 10 results
      if (currentHistory.length > _maxHistoryLength) {
        currentHistory = currentHistory.sublist(currentHistory.length - _maxHistoryLength);
      }

      // Save updated history
      final progressJson = json.encode(currentHistory);
      await prefs.setString(_progressKey, progressJson);
    } catch (e) {
      print('Error saving optimization result: $e');
    }
  }

  /// Calculate highest optimization percentage from results
  /// Returns the best (highest) optimization score as a percentage
  double calculateOptimizationPercentage(List<dynamic> results) {
    if (results.isEmpty) return 0.0;

    // Find the highest optimization score and convert to percentage
    // Assuming optimization scores are between 0 and 1
    double highestScore = 0.0;
    for (var result in results) {
      if (result != null && result.optimizationScore != null) {
        if (result.optimizationScore > highestScore) {
          highestScore = result.optimizationScore;
        }
      }
    }

    // Convert to percentage (multiply by 100)
    return (highestScore * 100).clamp(0.0, 100.0);
  }

  /// Reset optimization history (for testing purposes)
  Future<void> resetHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_progressKey);
    } catch (e) {
      print('Error resetting optimization history: $e');
    }
  }

  /// Get statistics about the optimization history
  Future<Map<String, double>> getOptimizationStats() async {
    final history = await getOptimizationHistory();

    if (history.isEmpty) {
      return {
        'average': 0.0,
        'best': 0.0,
        'latest': 0.0,
      };
    }

    double average = history.reduce((a, b) => a + b) / history.length;
    double best = history.reduce((a, b) => a > b ? a : b);
    double latest = history.last;

    return {
      'average': average,
      'best': best,
      'latest': latest,
    };
  }
}
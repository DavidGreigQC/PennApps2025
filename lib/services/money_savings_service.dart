import 'package:shared_preferences/shared_preferences.dart';
import '../models/optimization_result.dart';
import '../models/menu_item.dart';

class MoneySavingsService {
  static const String _totalSavingsKey = 'total_money_saved';
  static const String _savingsHistoryKey = 'savings_history';

  static MoneySavingsService? _instance;
  static MoneySavingsService get instance => _instance ??= MoneySavingsService._();

  MoneySavingsService._();

  /// Get total estimated money saved across all optimizations
  Future<double> getTotalSavings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_totalSavingsKey) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Calculate and add savings from a new optimization session
  Future<double> addOptimizationSavings(List<OptimizationResult> results, List<MenuItem> originalItems) async {
    if (results.isEmpty || originalItems.isEmpty) return 0.0;

    try {
      // Calculate savings using AI-based estimation
      double sessionSavings = _calculateOptimizationSavings(results, originalItems);

      // Add to total savings
      double currentTotal = await getTotalSavings();
      double newTotal = currentTotal + sessionSavings;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_totalSavingsKey, newTotal);

      return sessionSavings;
    } catch (e) {
      return 0.0;
    }
  }

  /// Simple price-per-calorie based savings calculation
  double _calculateOptimizationSavings(List<OptimizationResult> results, List<MenuItem> originalItems) {
    if (results.isEmpty) return 0.0;

    // Pre-coded average: $0.015 per calorie (typical restaurant pricing)
    const double averagePricePerCalorie = 0.015;

    // Find the highest scoring optimized item
    OptimizationResult bestResult = results.reduce((a, b) =>
        a.optimizationScore > b.optimizationScore ? a : b);

    MenuItem bestItem = bestResult.menuItem;

    // Skip if item doesn't have valid calories data
    if (bestItem.calories == null || bestItem.calories! <= 0) return 0.0;

    // Calculate what this item "should" cost based on average pricing
    double expectedPrice = bestItem.calories! * averagePricePerCalorie;

    // Calculate savings: what you'd expect to pay - what you actually pay
    double savings = expectedPrice - bestItem.price;

    // Only add positive savings (don't subtract money if item is expensive)
    return savings > 0 ? savings : 0.0;
  }


  /// Reset savings (for testing purposes)
  Future<void> resetSavings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_totalSavingsKey);
      await prefs.remove(_savingsHistoryKey);
    } catch (e) {
      // Silent fail
    }
  }

  /// Get savings statistics
  Future<Map<String, double>> getSavingsStats() async {
    double total = await getTotalSavings();

    return {
      'total': total,
      'monthly_estimate': total > 0 ? total * 0.8 : 0.0, // Assume current total represents ~1.25 months
      'yearly_projection': total > 0 ? total * 9.6 : 0.0, // Project to full year
    };
  }
}
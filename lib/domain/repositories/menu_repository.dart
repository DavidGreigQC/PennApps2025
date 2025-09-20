import '../entities/menu_item.dart';
import '../entities/optimization_result.dart';
import '../entities/optimization_criteria.dart';

/// Repository interface for menu-related operations
/// This defines the contract that data layer must implement
abstract class MenuRepository {
  /// Process uploaded menu files and extract menu items
  Future<List<MenuItem>> processMenuFiles(List<String> filePaths);

  /// Get nutritional data for menu items
  Future<List<MenuItem>> enrichWithNutritionalData(List<MenuItem> items);

  /// Perform optimization based on criteria
  Future<List<OptimizationResult>> optimizeMenu(
    List<MenuItem> items,
    OptimizationRequest criteria,
  );

  /// Save user preferences and optimization history
  Future<void> saveUserSession(String userId, OptimizationResult result);

  /// Get user's optimization history
  Future<List<OptimizationResult>> getUserHistory(String userId);

  /// Cache processed menu data
  Future<void> cacheMenuData(String restaurantId, List<MenuItem> items);

  /// Get cached menu data
  Future<List<MenuItem>?> getCachedMenuData(String restaurantId);
}
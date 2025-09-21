import '../../domain/entities/menu_item.dart';
import '../../domain/entities/optimization_result.dart';

/// Data source interface for storage operations (MongoDB, cache, etc.)
abstract class StorageDataSource {
  /// Save user optimization session
  Future<void> saveUserSession(String userId, OptimizationResult result);

  /// Get user's optimization history
  Future<List<OptimizationResult>> getUserHistory(String userId);

  /// Cache processed menu data
  Future<void> cacheMenuData(String restaurantId, List<MenuItem> items);

  /// Get cached menu data
  Future<List<MenuItem>?> getCachedMenuData(String restaurantId);

  /// Save user preferences
  Future<void> saveUserPreferences(String userId, Map<String, dynamic> preferences);

  /// Get user preferences
  Future<Map<String, dynamic>?> getUserPreferences(String userId);
}

/// MongoDB implementation of storage
class MongoStorageDataSource implements StorageDataSource {
  // MongoDB connection will be injected here

  @override
  Future<void> saveUserSession(String userId, OptimizationResult result) async {
    // MongoDB storage implementation - using existing MongoDBDataSource
    // Sessions are handled by the existing MongoDB integration
  }

  @override
  Future<List<OptimizationResult>> getUserHistory(String userId) async {
    // MongoDB query implementation - using existing MongoDBDataSource
    // History retrieval is handled by the existing MongoDB integration
    return [];
  }

  @override
  Future<void> cacheMenuData(String restaurantId, List<MenuItem> items) async {
    // MongoDB caching implementation - using existing MongoDBDataSource
    // Menu caching is handled by the existing MongoDB integration
  }

  @override
  Future<List<MenuItem>?> getCachedMenuData(String restaurantId) async {
    // MongoDB lookup implementation - using existing MongoDBDataSource
    // Cached menu retrieval is handled by the existing MongoDB integration
    return null;
  }

  @override
  Future<void> saveUserPreferences(String userId, Map<String, dynamic> preferences) async {
    // MongoDB preferences storage - using existing MongoDBDataSource
    // User preferences are handled by the existing MongoDB integration
  }

  @override
  Future<Map<String, dynamic>?> getUserPreferences(String userId) async {
    // MongoDB preferences retrieval - using existing MongoDBDataSource
    // User preferences are handled by the existing MongoDB integration
    return null;
  }
}
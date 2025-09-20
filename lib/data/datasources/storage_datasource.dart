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
    // TODO: Implement MongoDB save
    print('Saving user session to MongoDB: $userId');
  }

  @override
  Future<List<OptimizationResult>> getUserHistory(String userId) async {
    // TODO: Implement MongoDB query
    print('Getting user history from MongoDB: $userId');
    return [];
  }

  @override
  Future<void> cacheMenuData(String restaurantId, List<MenuItem> items) async {
    // TODO: Implement MongoDB cache
    print('Caching menu data to MongoDB: $restaurantId with ${items.length} items');
  }

  @override
  Future<List<MenuItem>?> getCachedMenuData(String restaurantId) async {
    // TODO: Implement MongoDB lookup
    print('Getting cached menu data from MongoDB: $restaurantId');
    return null;
  }

  @override
  Future<void> saveUserPreferences(String userId, Map<String, dynamic> preferences) async {
    // TODO: Implement MongoDB save
    print('Saving user preferences to MongoDB: $userId');
  }

  @override
  Future<Map<String, dynamic>?> getUserPreferences(String userId) async {
    // TODO: Implement MongoDB query
    print('Getting user preferences from MongoDB: $userId');
    return null;
  }
}
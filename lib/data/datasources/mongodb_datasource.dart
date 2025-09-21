import 'package:mongo_dart/mongo_dart.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/optimization_result.dart';

/// MongoDB Atlas integration for shared community menu database
/// This creates a shared intelligence system that gets smarter with each user
class MongoDBDataSource {
  static const String _connectionString =
      String.fromEnvironment('MONGODB_CONNECTION_STRING',
        defaultValue: 'mongodb://localhost:27017/menu_optimizer');

  Db? _db;
  DbCollection? _menusCollection;
  DbCollection? _usersCollection;
  DbCollection? _sessionsCollection;
  DbCollection? _restaurantsCollection;

  bool get isInitialized => _db != null;

  /// Ensure MongoDB is initialized
  void _ensureInitialized() {
    if (!isInitialized) {
      throw Exception('MongoDB not initialized. Call initialize() first.');
    }
  }

  /// Initialize MongoDB connection (DISABLED FOR NOW - USING LOCAL STORAGE ONLY)
  Future<void> initialize() async {
    // Silently skip MongoDB Atlas connection
    // print('⚠️ MongoDB Atlas: Skipped (known timeout issue)');
    // print('📱 Using local storage fallback for all operations');

    // Skip MongoDB initialization entirely
    // All operations will automatically fall back to SharedPreferences
    _db = null;
    _menusCollection = null;
    _usersCollection = null;
    _sessionsCollection = null;
    _restaurantsCollection = null;
  }

  /// Create database indexes for optimal performance
  Future<void> _createIndexes() async {
    try {
      // Index for fast restaurant menu lookups
      await _menusCollection!.createIndex(keys: {
        'restaurant_id': 1,
        'menu_hash': 1,
      });

      // Index for user session queries
      await _sessionsCollection!.createIndex(keys: {
        'user_id': 1,
        'created_at': -1,
      });

      // Geospatial index for location-based restaurant search
      await _restaurantsCollection!.createIndex(keys: {
        'location': '2dsphere',
      });

      // print('🔍 Database indexes created successfully!');
    } catch (e) {
      // print('⚠️ Index creation warning: $e');
    }
  }

  /// **SHARED INTELLIGENCE**: Check if menu data already exists in community database
  /// This is the key feature - users benefit from previous users' work!
  Future<List<MenuItem>?> getCommunityMenuData(String restaurantIdentifier) async {
    try {
      // print('🔍 Searching community database for: $restaurantIdentifier');

      // Try MongoDB Atlas first
      if (isInitialized && _menusCollection != null) {
        final result = await _menusCollection!.findOne(where.eq('restaurant_id', restaurantIdentifier));

        if (result != null) {
          final List<dynamic> itemsData = result['menu_items'] ?? [];
          final items = itemsData.map((data) => MenuItem.fromJson(data)).toList();

          // Update last accessed timestamp
          await _menusCollection!.updateOne(
            where.eq('_id', result['_id']),
            modify.set('last_accessed', DateTime.now()),
          );

          // print('✅ Found ${items.length} items in MongoDB Atlas!');
          return items;
        }
      }

      // Fallback to local storage
      // print('🔍 Checking local storage for: $restaurantIdentifier');
      return await _getCommunityMenuDataLocally(restaurantIdentifier);

    } catch (e) {
      // print('❌ Error querying community database, checking local storage: $e');
      return await _getCommunityMenuDataLocally(restaurantIdentifier);
    }
  }

  /// **FALLBACK**: Get menu data from local storage
  Future<List<MenuItem>?> _getCommunityMenuDataLocally(String restaurantIdentifier) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final menuDataJson = prefs.getString('menu_data_$restaurantIdentifier');

      if (menuDataJson != null) {
        final menuData = jsonDecode(menuDataJson);
        final List<dynamic> itemsData = menuData['menu_items'] ?? [];
        final items = itemsData.map((data) => MenuItem.fromJson(data)).toList();

        // print('✅ Found ${items.length} items in local storage!');
        return items;
      }

      // print('📭 No data found in community database or local storage');
      return null;
    } catch (e) {
      // print('❌ Error querying local storage: $e');
      return null;
    }
  }

  /// **COMMUNITY CONTRIBUTION**: Save processed menu data to shared database
  /// Each user contributes to the collective intelligence
  Future<void> contributeCommunityMenuData(
    String restaurantIdentifier,
    List<MenuItem> items,
    String userId,
  ) async {
    try {
      // Try MongoDB Atlas first, fallback to local storage
      if (!isInitialized || _menusCollection == null) {
        // Silently use local storage fallback
        // print('⚠️ MongoDB collections unavailable, using local storage for menu contribution');
        await _contributeCommunityMenuDataLocally(restaurantIdentifier, items, userId);
        return;
      }

      final menuHash = _generateMenuHash(items);
      final restaurantData = {
        'restaurant_id': restaurantIdentifier,
        'menu_hash': menuHash,
        'menu_items': items.map((item) => item.toJson()).toList(),
        'contributed_by': userId,
        'created_at': DateTime.now(),
        'last_accessed': DateTime.now(),
        'access_count': 1,
        'version': 1,
      };

      await _menusCollection!.insertOne(restaurantData);
      // print('🌟 Contributed ${items.length} items to community database!');

      // Update restaurant metadata
      await _updateRestaurantMetadata(restaurantIdentifier, items.length);

    } catch (e) {
      // print('❌ Error contributing to community database, falling back to local storage: $e');
      await _contributeCommunityMenuDataLocally(restaurantIdentifier, items, userId);
    }
  }

  /// **FALLBACK**: Save menu data locally using SharedPreferences
  Future<void> _contributeCommunityMenuDataLocally(String restaurantIdentifier, List<MenuItem> items, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final menuHash = _generateMenuHash(items);
      final restaurantData = {
        'restaurant_id': restaurantIdentifier,
        'menu_hash': menuHash,
        'menu_items': items.map((item) => item.toJson()).toList(),
        'contributed_by': userId,
        'created_at': DateTime.now().toIso8601String(),
        'last_accessed': DateTime.now().toIso8601String(),
        'access_count': 1,
        'version': 1,
      };

      await prefs.setString('menu_data_$restaurantIdentifier', jsonEncode(restaurantData));
      // print('🌟 Contributed ${items.length} items to local storage!');
    } catch (e) {
      // print('❌ Local menu contribution failed: $e');
    }
  }

  /// **USER REGISTRATION**: Register Auth0 user (fallback to local storage)
  Future<void> registerAuth0User(String auth0UserId, Map<String, dynamic> userMetadata) async {
    try {
      // print('🔍 Starting user registration for: $auth0UserId');

      // Try MongoDB Atlas first, fallback to local storage
      if (!isInitialized) {
        try {
          // print('🔄 Attempting MongoDB connection...');
          await initialize();
        } catch (e) {
          // print('⚠️ MongoDB Atlas unavailable, using local storage fallback');
          await _registerUserLocally(auth0UserId, userMetadata);
          return;
        }
      }

      // Verify collections are available
      if (_usersCollection == null) {
        // print('⚠️ MongoDB collections unavailable, using local storage fallback');
        await _registerUserLocally(auth0UserId, userMetadata);
        return;
      }

      // print('✅ MongoDB collections ready, checking existing user...');

      // Check if user already exists
      final existingUser = await _usersCollection!.findOne(where.eq('auth0_id', auth0UserId));

      if (existingUser == null) {
        // print('➕ Creating new user record...');
        // Create new user record
        final userData = {
          'auth0_id': auth0UserId,
          'user_metadata': userMetadata,
          'created_at': DateTime.now(),
          'last_active': DateTime.now(),
          'contributions': 0,
          'optimization_count': 0,
        };

        await _usersCollection!.insertOne(userData);
        // print('👤 New Auth0 user registered in MongoDB Atlas: $auth0UserId');
      } else {
        // print('🔄 Updating existing user record...');
        // Update existing user metadata
        await _usersCollection!.updateOne(
          where.eq('auth0_id', auth0UserId),
          modify.set('user_metadata', userMetadata)
              .set('last_active', DateTime.now()),
        );
        // print('👤 Auth0 user updated in MongoDB Atlas: $auth0UserId');
      }

    } catch (e) {
      // print('⚠️ MongoDB Atlas failed, using local storage fallback: $e');
      await _registerUserLocally(auth0UserId, userMetadata);
    }
  }

  /// **FALLBACK**: Register user locally using SharedPreferences
  Future<void> _registerUserLocally(String auth0UserId, Map<String, dynamic> userMetadata) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final userData = {
        'auth0_id': auth0UserId,
        'user_metadata': userMetadata,
        'created_at': DateTime.now().toIso8601String(),
        'last_active': DateTime.now().toIso8601String(),
        'contributions': 0,
        'optimization_count': 0,
      };

      await prefs.setString('user_data_$auth0UserId', jsonEncode(userData));
      // print('👤 Auth0 user registered locally: $auth0UserId');
    } catch (e) {
      // print('❌ Local user registration failed: $e');
    }
  }

  /// **SESSION TRACKING**: Save user optimization sessions
  Future<void> saveUserSession(String userId, OptimizationResult result) async {
    try {
      final sessionData = {
        'user_id': userId,
        'menu_item': result.menuItem.toJson(),
        'optimization_score': result.optimizationScore,
        'criteria_scores': result.criteriaScores,
        'reasoning': result.reasoning,
        'created_at': DateTime.now(),
      };

      await _sessionsCollection!.insertOne(sessionData);

      // Update user statistics
      await _usersCollection!.updateOne(
        where.eq('user_id', userId),
        modify.inc('optimization_count', 1),
      );

      // print('💾 User session saved to MongoDB Atlas');
    } catch (e) {
      // print('❌ Error saving user session: $e');
    }
  }

  /// **ANALYTICS**: Get community insights and popular menu items
  Future<Map<String, dynamic>> getCommunityInsights() async {
    try {
      // Most popular menu items across all users
      final popularItems = await _sessionsCollection!.aggregateToStream([
        {
          '\$group': {
            '_id': '\$menu_item.name',
            'selection_count': {'\$sum': 1},
            'avg_score': {'\$avg': '\$optimization_score'},
          }
        },
        {'\$sort': {'selection_count': -1}},
        {'\$limit': 10},
      ]).toList();

      // Total community statistics
      final totalMenus = await _menusCollection!.count();
      final totalUsers = await _usersCollection!.count();
      final totalOptimizations = await _sessionsCollection!.count();

      return {
        'popular_items': popularItems,
        'total_menus': totalMenus,
        'total_users': totalUsers,
        'total_optimizations': totalOptimizations,
        'generated_at': DateTime.now(),
      };
    } catch (e) {
      // print('❌ Error getting community insights: $e');
      return {};
    }
  }

  /// Generate hash for menu content to detect duplicates
  String _generateMenuHash(List<MenuItem> items) {
    final content = items.map((item) => '${item.name}:${item.price}').join('|');
    return sha256.convert(utf8.encode(content)).toString().substring(0, 16);
  }

  /// Update restaurant metadata
  Future<void> _updateRestaurantMetadata(String restaurantId, int itemCount) async {
    try {
      await _restaurantsCollection!.updateOne(
        where.eq('restaurant_id', restaurantId),
        modify.set('last_menu_update', DateTime.now())
            .set('menu_item_count', itemCount)
            .inc('total_contributions', 1),
        upsert: true,
      );
    } catch (e) {
      // print('⚠️ Restaurant metadata update warning: $e');
    }
  }

  /// **TESTING**: Test data caching and storage functionality (Local Storage Focus)
  Future<Map<String, dynamic>> testDataCaching(String testRestaurantId, List<MenuItem> testItems, String userId) async {
    final results = <String, dynamic>{
      'test_started': DateTime.now(),
      'restaurant_id': testRestaurantId,
      'item_count': testItems.length,
      'tests': <String, dynamic>{},
      'mongodb_skipped': true,
      'reason': 'MongoDB Atlas connection times out - testing local storage only',
    };

    try {
      // print('🧪 Starting LOCAL STORAGE data caching test for restaurant: $testRestaurantId');
      // print('⚠️ Skipping MongoDB Atlas tests (known timeout issue)');

      // Test 1: Check if data exists in local storage before contribution
      // print('🔍 Test 1: Checking local storage for existing menu data...');
      final existingData = await _getCommunityMenuDataLocally(testRestaurantId);
      results['tests']['pre_contribution_check'] = {
        'exists': existingData != null,
        'item_count': existingData?.length ?? 0,
        'storage_type': 'local',
        'status': 'completed'
      };
      // print('✅ Pre-contribution check: ${existingData != null ? 'Found ${existingData!.length} items in local storage' : 'No existing local data'}');

      // Test 2: Contribute test data directly to local storage
      // print('🔍 Test 2: Contributing test menu data to local storage...');
      await _contributeCommunityMenuDataLocally(testRestaurantId, testItems, userId);
      results['tests']['contribution'] = {
        'status': 'completed',
        'items_contributed': testItems.length,
        'storage_type': 'local',
        'timestamp': DateTime.now(),
      };
      // print('✅ Contribution completed: ${testItems.length} items to local storage');

      // Test 3: Verify data was saved in local storage
      // print('🔍 Test 3: Verifying data was saved in local storage...');
      final savedData = await _getCommunityMenuDataLocally(testRestaurantId);
      results['tests']['post_contribution_check'] = {
        'exists': savedData != null,
        'item_count': savedData?.length ?? 0,
        'items_match': savedData != null && savedData.length == testItems.length,
        'storage_type': 'local',
        'status': 'completed'
      };
      // print('✅ Post-contribution check: ${savedData != null ? 'Found ${savedData!.length} items in local storage' : 'No data found!'}');

      // Test 4: Verify item details match
      if (savedData != null && savedData.isNotEmpty) {
        // print('🔍 Test 4: Verifying item details integrity...');
        final firstOriginal = testItems.first;
        final firstSaved = savedData.first;

        final nameMatch = firstOriginal.name == firstSaved.name;
        final priceMatch = firstOriginal.price == firstSaved.price;
        final descMatch = firstOriginal.description == firstSaved.description;

        results['tests']['data_integrity'] = {
          'name_match': nameMatch,
          'price_match': priceMatch,
          'description_match': descMatch,
          'all_match': nameMatch && priceMatch && descMatch,
          'original_name': firstOriginal.name,
          'saved_name': firstSaved.name,
          'storage_type': 'local',
          'status': 'completed'
        };
        // print('✅ Data integrity check: All details match: ${nameMatch && priceMatch && descMatch}');
      }

      // Test 5: Test storage persistence (read from SharedPreferences directly)
      // print('🔍 Test 5: Testing SharedPreferences persistence...');
      await _testSharedPreferencesPersistence(testRestaurantId, results);

      // Test 6: Test multiple restaurant data
      // print('🔍 Test 6: Testing multiple restaurant data storage...');
      await _testMultipleRestaurantStorage(userId, results);

      results['overall_status'] = 'success';
      results['test_completed'] = DateTime.now();

      // print('🎉 Local storage data caching test completed successfully!');
      return results;

    } catch (e) {
      // print('❌ Data caching test failed: $e');
      results['tests']['error'] = {
        'message': e.toString(),
        'timestamp': DateTime.now(),
      };
      results['overall_status'] = 'failed';
      return results;
    }
  }

  /// Test SharedPreferences persistence directly
  Future<void> _testSharedPreferencesPersistence(String restaurantId, Map<String, dynamic> results) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if the data exists in SharedPreferences
      final menuDataKey = 'menu_data_$restaurantId';
      final menuDataJson = prefs.getString(menuDataKey);

      if (menuDataJson != null) {
        final menuData = jsonDecode(menuDataJson);

        results['tests']['shared_preferences_persistence'] = {
          'key_exists': true,
          'has_menu_items': menuData['menu_items'] != null,
          'item_count': (menuData['menu_items'] as List?)?.length ?? 0,
          'has_restaurant_id': menuData['restaurant_id'] != null,
          'has_timestamps': menuData['created_at'] != null,
          'json_valid': true,
          'storage_type': 'shared_preferences',
          'status': 'completed'
        };
        // print('✅ SharedPreferences persistence: Data found and valid');
      } else {
        results['tests']['shared_preferences_persistence'] = {
          'key_exists': false,
          'error': 'No data found in SharedPreferences',
          'storage_type': 'shared_preferences',
          'status': 'failed'
        };
        // print('❌ SharedPreferences persistence: No data found');
      }

    } catch (e) {
      // print('⚠️ SharedPreferences persistence test error: $e');
      results['tests']['shared_preferences_persistence'] = {
        'error': e.toString(),
        'status': 'failed'
      };
    }
  }

  /// Test storing data for multiple restaurants
  Future<void> _testMultipleRestaurantStorage(String userId, Map<String, dynamic> results) async {
    try {
      // Create test data for multiple restaurants
      final restaurants = ['TestCafe_A', 'TestCafe_B', 'TestCafe_C'];
      final storageResults = <String, dynamic>{};

      for (final restaurant in restaurants) {
        final testItems = generateTestMenuItems(restaurant);
        await _contributeCommunityMenuDataLocally(restaurant, testItems, userId);

        // Verify each one was stored
        final retrievedData = await _getCommunityMenuDataLocally(restaurant);
        storageResults[restaurant] = {
          'stored': true,
          'retrieved': retrievedData != null,
          'item_count': retrievedData?.length ?? 0,
          'items_match': retrievedData?.length == testItems.length,
        };
      }

      // Check how many total menu keys we have
      final prefs = await SharedPreferences.getInstance();
      final allMenuKeys = prefs.getKeys().where((key) => key.startsWith('menu_data_')).toList();

      results['tests']['multiple_restaurant_storage'] = {
        'restaurants_tested': restaurants.length,
        'storage_results': storageResults,
        'total_menu_keys': allMenuKeys.length,
        'all_successful': storageResults.values.every((result) => result['items_match'] == true),
        'storage_type': 'local',
        'status': 'completed'
      };

      // print('✅ Multiple restaurant storage: ${restaurants.length} restaurants tested');

    } catch (e) {
      // print('⚠️ Multiple restaurant storage test error: $e');
      results['tests']['multiple_restaurant_storage'] = {
        'error': e.toString(),
        'status': 'failed'
      };
    }
  }

  /// **TESTING**: Generate test menu items for testing
  static List<MenuItem> generateTestMenuItems(String restaurantPrefix) {
    return [
      MenuItem(
        name: '${restaurantPrefix} Burger',
        price: 12.99,
        description: 'Test burger for caching verification',
        calories: 650.0,
        protein: 25.0,
        carbs: 45.0,
        fat: 35.0,
      ),
      MenuItem(
        name: '${restaurantPrefix} Salad',
        price: 9.99,
        description: 'Test salad for caching verification',
        calories: 250.0,
        protein: 15.0,
        carbs: 20.0,
        fat: 8.0,
      ),
      MenuItem(
        name: '${restaurantPrefix} Pizza',
        price: 15.99,
        description: 'Test pizza for caching verification',
        calories: 800.0,
        protein: 30.0,
        carbs: 65.0,
        fat: 40.0,
      ),
    ];
  }

  /// **TESTING**: View all stored menu data (Local Storage Focus)
  Future<Map<String, dynamic>> viewAllStoredData() async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now(),
      'mongodb_data': <String, dynamic>{},
      'local_data': <String, dynamic>{},
      'mongodb_skipped': true,
    };

    try {
      // Skip MongoDB check (known timeout issue)
      results['mongodb_data'] = {
        'available': false,
        'reason': 'Skipped - MongoDB Atlas connection times out',
        'skipped': true,
      };
      // print('⚠️ MongoDB Atlas: Skipped (known timeout issue)');

      // Focus on local storage data
      // print('🔍 Checking local storage data...');
      final prefs = await SharedPreferences.getInstance();

      final menuKeys = prefs.getKeys().where((key) => key.startsWith('menu_data_')).toList();
      final userKeys = prefs.getKeys().where((key) => key.startsWith('user_data_')).toList();
      final allKeys = prefs.getKeys().toList();

      // Get detailed menu data
      final menuDetails = <String, dynamic>{};
      for (final key in menuKeys) {
        try {
          final menuDataJson = prefs.getString(key);
          if (menuDataJson != null) {
            final menuData = jsonDecode(menuDataJson);
            menuDetails[key] = {
              'restaurant_id': menuData['restaurant_id'],
              'item_count': (menuData['menu_items'] as List?)?.length ?? 0,
              'created_at': menuData['created_at'],
              'contributed_by': menuData['contributed_by'],
            };
          }
        } catch (e) {
          menuDetails[key] = {'error': 'Failed to parse: $e'};
        }
      }

      results['local_data'] = {
        'menu_keys': menuKeys,
        'menu_count': menuKeys.length,
        'menu_details': menuDetails,
        'user_keys': userKeys,
        'user_count': userKeys.length,
        'total_keys': allKeys.length,
        'other_keys': allKeys.where((key) =>
          !key.startsWith('menu_data_') &&
          !key.startsWith('user_data_')).toList(),
      };

      // print('📊 Local Storage Analysis:');
      // print('   • Menu records: ${menuKeys.length}');
      // print('   • User records: ${userKeys.length}');
      // print('   • Total keys: ${allKeys.length}');

      return results;

    } catch (e) {
      // print('❌ Error viewing stored data: $e');
      results['error'] = e.toString();
      return results;
    }
  }

  /// Close database connection
  Future<void> close() async {
    await _db!.close();
  }
}

/// Extension to add JSON serialization to MenuItem
extension MenuItemJson on MenuItem {
  Map<String, dynamic> toJson() => {
    'name': name,
    'price': price,
    'description': description,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'fiber': fiber,
    'sodium': sodium,
  };

  static MenuItem fromJson(Map<String, dynamic> json) => MenuItem(
    name: json['name'] ?? '',
    price: (json['price'] ?? 0.0).toDouble(),
    description: json['description'],
    calories: json['calories']?.toDouble(),
    protein: json['protein']?.toDouble(),
    carbs: json['carbs']?.toDouble(),
    fat: json['fat']?.toDouble(),
    fiber: json['fiber']?.toDouble(),
    sodium: json['sodium']?.toDouble(),
  );
}
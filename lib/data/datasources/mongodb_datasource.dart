import 'package:mongo_dart/mongo_dart.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/optimization_result.dart';

/// MongoDB Atlas integration for shared community menu database
/// This creates a shared intelligence system that gets smarter with each user
class MongoDBDataSource {
  static const String _connectionString =
      String.fromEnvironment('MONGODB_CONNECTION_STRING',
        defaultValue: 'mongodb://localhost:27017/menu_optimizer'); // Fallback for development

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

  /// Initialize MongoDB connection
  Future<void> initialize() async {
    try {
      _db = await Db.create(_connectionString);
      await _db!.open();

      _menusCollection = _db!.collection('community_menus');
      _usersCollection = _db!.collection('users');
      _sessionsCollection = _db!.collection('user_sessions');
      _restaurantsCollection = _db!.collection('restaurants');

      print('🍃 MongoDB Atlas connected successfully!');
      await _createIndexes();
    } catch (e) {
      print('❌ MongoDB connection failed: $e');
      rethrow;
    }
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

      print('🔍 Database indexes created successfully!');
    } catch (e) {
      print('⚠️ Index creation warning: $e');
    }
  }

  /// **SHARED INTELLIGENCE**: Check if menu data already exists in community database
  /// This is the key feature - users benefit from previous users' work!
  Future<List<MenuItem>?> getCommunityMenuData(String restaurantIdentifier) async {
    try {
      print('🔍 Searching community database for: $restaurantIdentifier');

      final result = await _menusCollection!.findOne(where.eq('restaurant_id', restaurantIdentifier));

      if (result != null) {
        final List<dynamic> itemsData = result['menu_items'] ?? [];
        final items = itemsData.map((data) => MenuItem.fromJson(data)).toList();

        // Update last accessed timestamp
        await _menusCollection!.updateOne(
          where.eq('_id', result['_id']),
          modify.set('last_accessed', DateTime.now()),
        );

        print('✅ Found ${items.length} items in community database!');
        return items;
      }

      print('📭 No community data found, will contribute after processing');
      return null;
    } catch (e) {
      print('❌ Error querying community database: $e');
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
      print('🌟 Contributed ${items.length} items to community database!');

      // Update restaurant metadata
      await _updateRestaurantMetadata(restaurantIdentifier, items.length);

    } catch (e) {
      print('❌ Error contributing to community database: $e');
    }
  }

  /// **USER REGISTRATION**: Register Auth0 user in MongoDB
  Future<void> registerAuth0User(String auth0UserId, Map<String, dynamic> userMetadata) async {
    try {
      // Check if user already exists
      final existingUser = await _usersCollection!.findOne(where.eq('auth0_id', auth0UserId));

      if (existingUser == null) {
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
        print('👤 New Auth0 user registered: $auth0UserId');
      } else {
        // Update existing user metadata
        await _usersCollection!.updateOne(
          where.eq('auth0_id', auth0UserId),
          modify.set('user_metadata', userMetadata)
              .set('last_active', DateTime.now()),
        );
        print('👤 Auth0 user updated: $auth0UserId');
      }

    } catch (e) {
      print('❌ User registration error: $e');
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

      print('💾 User session saved to MongoDB Atlas');
    } catch (e) {
      print('❌ Error saving user session: $e');
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
      print('❌ Error getting community insights: $e');
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
      print('⚠️ Restaurant metadata update warning: $e');
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
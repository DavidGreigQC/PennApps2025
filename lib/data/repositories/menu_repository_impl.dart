import '../../domain/entities/menu_item.dart';
import '../../domain/entities/optimization_result.dart';
import '../../domain/entities/optimization_criteria.dart';
import '../../domain/repositories/menu_repository.dart';
import '../datasources/ocr_datasource.dart';
import '../datasources/nutrition_datasource.dart';
import '../datasources/optimization_datasource.dart';
import '../datasources/storage_datasource.dart';
import '../datasources/mongodb_datasource.dart';
import '../datasources/gemini_vision_datasource.dart';

/// Implementation of MenuRepository
/// Coordinates between different data sources to fulfill business requirements
class MenuRepositoryImpl implements MenuRepository {
  final OCRDataSource _ocrDataSource;
  final NutritionDataSource _nutritionDataSource;
  final OptimizationDataSource _optimizationDataSource;
  final StorageDataSource _storageDataSource;
  final MongoDBDataSource _mongoDataSource;
  final GeminiVisionDataSource _geminiVisionDataSource;

  MenuRepositoryImpl({
    required OCRDataSource ocrDataSource,
    required NutritionDataSource nutritionDataSource,
    required OptimizationDataSource optimizationDataSource,
    required StorageDataSource storageDataSource,
    required MongoDBDataSource mongoDataSource,
    required GeminiVisionDataSource geminiVisionDataSource,
  })  : _ocrDataSource = ocrDataSource,
        _nutritionDataSource = nutritionDataSource,
        _optimizationDataSource = optimizationDataSource,
        _storageDataSource = storageDataSource,
        _mongoDataSource = mongoDataSource,
        _geminiVisionDataSource = geminiVisionDataSource;

  @override
  Future<List<MenuItem>> processMenuFiles(List<String> filePaths, {String? restaurantId}) async {
    // COMMUNITY INTELLIGENCE: Check if menu data already exists in shared database
    if (restaurantId != null) {
      final communityData = await _mongoDataSource.getCommunityMenuData(restaurantId);
      if (communityData != null && communityData.isNotEmpty) {
        print('🌟 Using community shared menu data (${communityData.length} items)');
        return communityData;
      }
    }

    final List<MenuItem> allItems = [];

    for (final filePath in filePaths) {
      try {
        // Check if it's an image file for Gemini Vision OCR
        if (filePath.toLowerCase().endsWith('.jpg') ||
            filePath.toLowerCase().endsWith('.jpeg') ||
            filePath.toLowerCase().endsWith('.png')) {

          print('📸 Using Gemini Vision AI for image OCR...');
          final items = await _geminiVisionDataSource.extractMenuFromFile(filePath);
          allItems.addAll(items);
        } else {
          // Use traditional OCR for PDFs and other files
          final items = await _ocrDataSource.extractMenuItems(filePath);
          allItems.addAll(items);
        }
      } catch (e) {
        // Log error but continue processing other files
        print('Error processing file $filePath: $e');
      }
    }

    return allItems;
  }

  @override
  Future<List<MenuItem>> enrichWithNutritionalData(List<MenuItem> items) async {
    return await _nutritionDataSource.enrichMenuItems(items);
  }

  @override
  Future<List<OptimizationResult>> optimizeMenu(
    List<MenuItem> items,
    OptimizationRequest criteria,
  ) async {
    return await _optimizationDataSource.optimize(items, criteria);
  }

  @override
  Future<void> saveUserSession(String userId, OptimizationResult result) async {
    // Save locally
    await _storageDataSource.saveUserSession(userId, result);

    // Save to MongoDB Atlas for analytics and community insights
    await _mongoDataSource.saveUserSession(userId, result);
  }

  @override
  Future<List<OptimizationResult>> getUserHistory(String userId) async {
    return await _storageDataSource.getUserHistory(userId);
  }

  @override
  Future<void> cacheMenuData(String restaurantId, List<MenuItem> items, {String? userId}) async {
    // Cache locally
    await _storageDataSource.cacheMenuData(restaurantId, items);

    // COMMUNITY CONTRIBUTION: Share with shared database
    if (userId != null && items.isNotEmpty) {
      await _mongoDataSource.contributeCommunityMenuData(restaurantId, items, userId);
      print('🌟 Contributed ${items.length} items to community database!');
    }
  }

  @override
  Future<List<MenuItem>?> getCachedMenuData(String restaurantId) async {
    return await _storageDataSource.getCachedMenuData(restaurantId);
  }

  /// CAMERA OCR: Process camera image with Gemini Vision
  Future<List<MenuItem>> processMenuFromCamera(dynamic cameraImage, {String? userId}) async {
    try {
      _geminiVisionDataSource.initialize();
      final items = await _geminiVisionDataSource.extractMenuFromCamera(cameraImage);
      print('📸 Extracted ${items.length} items using Gemini Vision');
      return items;
    } catch (e) {
      print('❌ Camera OCR error: $e');
      return [];
    }
  }

  /// USER REGISTRATION: Register Auth0 user in MongoDB
  Future<void> registerAuth0User(String auth0UserId, Map<String, dynamic> userMetadata) async {
    await _mongoDataSource.initialize();
    await _mongoDataSource.registerAuth0User(auth0UserId, userMetadata);
  }

  /// COMMUNITY INSIGHTS: Get analytics and popular items
  Future<Map<String, dynamic>> getCommunityInsights() async {
    return await _mongoDataSource.getCommunityInsights();
  }

  /// SMART MENU CONVERSATION: Ask questions about menu
  Future<String> askAboutMenu(dynamic imageBytes, String question) async {
    return await _geminiVisionDataSource.askAboutMenu(imageBytes, question);
  }
}
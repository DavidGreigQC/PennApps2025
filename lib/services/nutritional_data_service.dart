import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/menu_item.dart';

class NutritionalDataService {
  final Map<String, Map<String, dynamic>> _nutritionCache = {};
  late GenerativeModel? _geminiModel;

  /// Initialize Gemini AI model for nutritional estimation
  NutritionalDataService() {
    try {
      // Get API key from environment or dart-define
      const String? apiKey = String.fromEnvironment('GEMINI_API_KEY');

      if (apiKey != null && apiKey.isNotEmpty && apiKey != 'YOUR_GEMINI_API_KEY') {
        _geminiModel = GenerativeModel(
          model: 'gemini-pro',
          apiKey: apiKey,
        );
        debugPrint('✅ Gemini AI initialized for nutrition estimation');
      } else {
        _geminiModel = null;
        debugPrint('⚠️  Gemini API key not found. Nutritional AI estimation disabled. Use --dart-define=GEMINI_API_KEY=your_key');
      }
    } catch (e) {
      _geminiModel = null;
      debugPrint('Warning: Gemini AI initialization failed: $e');
    }
  }

  /// CRITICAL: Only enrich existing menu items, never add new ones

  Future<void> enrichMenuItems(
    List<MenuItem> items,
    String? restaurantName,
    String? websiteUrl,
  ) async {
    // CRITICAL: Store original items for validation
    List<MenuItem> originalItems = List<MenuItem>.from(items);

    for (int i = 0; i < items.length; i++) {
      MenuItem enrichedItem = await _enrichMenuItem(items[i], restaurantName, websiteUrl);

      // CRITICAL: Ensure the enriched item is still the same menu item
      if (_isSameOriginalItem(originalItems[i], enrichedItem)) {
        items[i] = enrichedItem;
      } else {
        // If enrichment changed the core identity, keep original
        debugPrint('WARNING: Enrichment changed item identity, keeping original: ${originalItems[i].name}');
        items[i] = originalItems[i];
      }
    }

    debugPrint('Nutritional enrichment completed for ${items.length} menu items');
  }

  Future<MenuItem> _enrichMenuItem(
    MenuItem item,
    String? restaurantName,
    String? websiteUrl,
  ) async {
    String cacheKey = '${item.name}_${restaurantName ?? 'generic'}';

    if (_nutritionCache.containsKey(cacheKey)) {
      return _applyNutritionData(item, _nutritionCache[cacheKey]!);
    }

    Map<String, dynamic>? nutritionData;

    if (restaurantName != null && websiteUrl != null) {
      nutritionData = await _scrapeRestaurantWebsite(item.name, websiteUrl);
    }

    if (nutritionData == null) {
      nutritionData = await _searchNutritionAPI(item.name, restaurantName);
    }

    if (nutritionData == null) {
      nutritionData = await _searchGenericFoodDatabase(item.name);
    }

    // If item has no price, attempt to look it up online
    if (item.price == 0.0) {
      double? lookedUpPrice = await _lookupPrice(item.name, restaurantName);
      if (lookedUpPrice != null) {
        // Create a copy with the found price
        item = item.copyWith(price: lookedUpPrice);
        debugPrint('PRICE LOOKUP: Found ${item.name} = \$${lookedUpPrice}');
      } else {
        // Set estimated price based on item type if still 0
        double estimatedPrice = _estimatePrice(item.name, restaurantName);
        item = item.copyWith(price: estimatedPrice);
        debugPrint('PRICE ESTIMATE: ${item.name} = \$${estimatedPrice} (estimated)');
      }
    }

    if (nutritionData != null) {
      _nutritionCache[cacheKey] = nutritionData;
      return _applyNutritionData(item, nutritionData);
    }

    // FORCE ESTIMATION: Use AI to estimate nutritional information when no online data found
    nutritionData = await _estimateNutritionWithAI(item.name, restaurantName);
    if (nutritionData != null) {
      _nutritionCache[cacheKey] = nutritionData;
      debugPrint('AI NUTRITION ESTIMATE: ${item.name} = $nutritionData (AI estimated)');
      return _applyNutritionData(item, nutritionData);
    }

    return item;
  }

  Future<Map<String, dynamic>?> _scrapeRestaurantWebsite(
    String itemName,
    String websiteUrl,
  ) async {
    try {
      final response = await http.get(Uri.parse(websiteUrl));
      if (response.statusCode == 200) {
        String html = response.body;
        return _parseNutritionFromHTML(html, itemName);
      }
    } catch (e) {
      print('Website scraping failed: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _searchNutritionAPI(
    String itemName,
    String? restaurantName,
  ) async {
    try {
      String query = restaurantName != null
          ? '$restaurantName $itemName'
          : itemName;

      final response = await http.get(
        Uri.parse('https://api.nal.usda.gov/fdc/v1/foods/search')
            .replace(queryParameters: {
          'query': query,
          'api_key': 'DEMO_KEY',
          'pageSize': '5',
        }),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        List foods = data['foods'] ?? [];

        if (foods.isNotEmpty) {
          Map<String, dynamic> bestMatch = _findBestFoodMatch(foods, itemName);
          return _extractNutritionFromUSDA(bestMatch);
        }
      }
    } catch (e) {
      print('USDA API search failed: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _searchGenericFoodDatabase(String itemName) async {
    Map<String, Map<String, dynamic>> genericDatabase = {
      'burger': {
        'calories': 540.0,
        'protein': 25.0,
        'carbs': 40.0,
        'fat': 31.0,
        'fiber': 3.0,
        'sodium': 1040.0,
        'sugar': 5.0,
      },
      'pizza': {
        'calories': 285.0,
        'protein': 12.0,
        'carbs': 36.0,
        'fat': 10.0,
        'fiber': 2.0,
        'sodium': 640.0,
        'sugar': 4.0,
      },
      'salad': {
        'calories': 150.0,
        'protein': 8.0,
        'carbs': 15.0,
        'fat': 8.0,
        'fiber': 5.0,
        'sodium': 300.0,
        'sugar': 8.0,
      },
      'sandwich': {
        'calories': 350.0,
        'protein': 20.0,
        'carbs': 35.0,
        'fat': 15.0,
        'fiber': 4.0,
        'sodium': 800.0,
        'sugar': 3.0,
      },
      'chicken': {
        'calories': 250.0,
        'protein': 30.0,
        'carbs': 0.0,
        'fat': 14.0,
        'fiber': 0.0,
        'sodium': 400.0,
        'sugar': 0.0,
      },
    };

    String normalizedName = itemName.toLowerCase();

    for (String key in genericDatabase.keys) {
      if (normalizedName.contains(key) ||
          ratio(normalizedName, key) > 70) {
        return genericDatabase[key];
      }
    }

    return null;
  }

  Map<String, dynamic>? _parseNutritionFromHTML(String html, String itemName) {
    RegExp caloriesRegex = RegExp(r'(\d+)\s*cal', caseSensitive: false);
    RegExp proteinRegex = RegExp(r'(\d+)g?\s*protein', caseSensitive: false);
    RegExp fatRegex = RegExp(r'(\d+)g?\s*fat', caseSensitive: false);
    RegExp carbsRegex = RegExp(r'(\d+)g?\s*carb', caseSensitive: false);

    Map<String, dynamic> nutrition = {};

    Match? caloriesMatch = caloriesRegex.firstMatch(html);
    if (caloriesMatch != null) {
      nutrition['calories'] = double.tryParse(caloriesMatch.group(1)!);
    }

    Match? proteinMatch = proteinRegex.firstMatch(html);
    if (proteinMatch != null) {
      nutrition['protein'] = double.tryParse(proteinMatch.group(1)!);
    }

    Match? fatMatch = fatRegex.firstMatch(html);
    if (fatMatch != null) {
      nutrition['fat'] = double.tryParse(fatMatch.group(1)!);
    }

    Match? carbsMatch = carbsRegex.firstMatch(html);
    if (carbsMatch != null) {
      nutrition['carbs'] = double.tryParse(carbsMatch.group(1)!);
    }

    return nutrition.isNotEmpty ? nutrition : null;
  }

  Map<String, dynamic> _findBestFoodMatch(List foods, String itemName) {
    Map<String, dynamic> bestMatch = foods[0];
    int bestScore = 0;

    for (Map<String, dynamic> food in foods) {
      String foodDescription = food['description'] ?? '';
      int score = ratio(itemName.toLowerCase(), foodDescription.toLowerCase());

      if (score > bestScore) {
        bestScore = score;
        bestMatch = food;
      }
    }

    return bestMatch;
  }

  Map<String, dynamic> _extractNutritionFromUSDA(Map<String, dynamic> foodData) {
    Map<String, dynamic> nutrition = {};
    List foodNutrients = foodData['foodNutrients'] ?? [];

    for (Map<String, dynamic> nutrient in foodNutrients) {
      int nutrientId = nutrient['nutrientId'] ?? 0;
      double amount = (nutrient['value'] ?? 0.0).toDouble();

      switch (nutrientId) {
        case 1008:
          nutrition['calories'] = amount;
          break;
        case 1003:
          nutrition['protein'] = amount;
          break;
        case 1004:
          nutrition['fat'] = amount;
          break;
        case 1005:
          nutrition['carbs'] = amount;
          break;
        case 1079:
          nutrition['fiber'] = amount;
          break;
        case 1093:
          nutrition['sodium'] = amount;
          break;
        case 2000:
          nutrition['sugar'] = amount;
          break;
      }
    }

    return nutrition;
  }

  MenuItem _applyNutritionData(MenuItem item, Map<String, dynamic> nutritionData) {
    return item.copyWith(
      calories: nutritionData['calories']?.toDouble(),
      protein: nutritionData['protein']?.toDouble(),
      fat: nutritionData['fat']?.toDouble(),
      carbs: nutritionData['carbs']?.toDouble(),
      fiber: nutritionData['fiber']?.toDouble(),
      sodium: nutritionData['sodium']?.toDouble(),
      sugar: nutritionData['sugar']?.toDouble(),
    );
  }

  /// CRITICAL: Validates that enriched item is still the same original menu item
  bool _isSameOriginalItem(MenuItem original, MenuItem enriched) {
    // Core identity must match: name
    if (original.name != enriched.name) {
      return false;
    }

    // Allow price changes only if original price was 0.0 (missing price)
    if (original.price != enriched.price && original.price != 0.0) {
      return false;
    }

    // Description should not change dramatically (if it existed originally)
    if (original.description != null &&
        enriched.description != null &&
        original.description != enriched.description) {
      // Allow description changes during enrichment, but log them
      debugPrint('INFO: Description changed during enrichment for ${original.name}');
    }

    return true;
  }

  /// Look up menu item price online (placeholder for future API integration)
  Future<double?> _lookupPrice(String itemName, String? restaurantName) async {
    try {
      // For now, return null to use estimation
      // In the future, this could call external price APIs
      return null;
    } catch (e) {
      debugPrint('Price lookup failed for $itemName: $e');
      return null;
    }
  }

  /// Estimate reasonable price based on item type and restaurant
  double _estimatePrice(String itemName, String? restaurantName) {
    String lowerName = itemName.toLowerCase();
    String lowerRestaurant = (restaurantName ?? '').toLowerCase();

    // Domino's specific pricing
    if (lowerRestaurant.contains('domino')) {
      if (lowerName.contains('bread')) {
        if (lowerName.contains('bites')) return 6.99;
        if (lowerName.contains('stuffed')) return 7.99;
        return 5.99;
      }
      if (lowerName.contains('pizza')) {
        if (lowerName.contains('large')) return 13.99;
        if (lowerName.contains('medium')) return 11.99;
        return 9.99;
      }
    }

    // Generic fast food pricing
    if (lowerName.contains('bread') || lowerName.contains('bites')) return 5.99;
    if (lowerName.contains('pizza')) return 12.99;
    if (lowerName.contains('burger') || lowerName.contains('sandwich')) return 8.99;
    if (lowerName.contains('salad')) return 7.99;
    if (lowerName.contains('drink') || lowerName.contains('soda')) return 2.99;
    if (lowerName.contains('fries') || lowerName.contains('side')) return 3.99;

    // Default price for unknown items
    return 6.99;
  }

  /// FORCE ESTIMATION: Use Gemini AI to estimate nutritional information
  Future<Map<String, dynamic>?> _estimateNutritionWithAI(String itemName, String? restaurantName) async {
    // If Gemini AI is not available, fall back to enhanced generic estimation
    if (_geminiModel == null) {
      debugPrint('⚠️  Gemini AI not available, using enhanced generic estimation for $itemName');
      return _enhancedGenericNutritionEstimate(itemName, restaurantName);
    }

    try {
      String context = restaurantName != null
          ? 'This is a menu item from $restaurantName restaurant'
          : 'This is a generic menu item';

      final prompt = '''
You are a nutritional expert. Analyze the menu item "$itemName" and provide estimated nutritional information.

$context

Please provide realistic nutritional estimates in JSON format:
{
  "calories": <number>,
  "protein": <number in grams>,
  "carbs": <number in grams>,
  "fat": <number in grams>,
  "fiber": <number in grams>,
  "sodium": <number in milligrams>,
  "sugar": <number in grams>
}

Base your estimates on:
1. Typical serving sizes for this type of food
2. Common ingredients and preparation methods
3. Restaurant vs. homemade preparation differences
4. The specific restaurant's style if mentioned

Return ONLY the JSON object, no explanations.
''';

      final content = [Content.text(prompt)];
      final response = await _geminiModel!.generateContent(content);
      final responseText = response.text?.trim() ?? '';

      debugPrint('🤖 Gemini nutrition estimation for $itemName: $responseText');

      return _parseNutritionResponse(responseText);

    } catch (e) {
      debugPrint('❌ Gemini nutrition estimation error for $itemName: $e');

      // Fallback to enhanced generic estimation
      return _enhancedGenericNutritionEstimate(itemName, restaurantName);
    }
  }

  /// Parse Gemini's nutrition response
  Map<String, dynamic>? _parseNutritionResponse(String responseText) {
    try {
      // Clean the response
      String cleanedResponse = responseText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Extract JSON if there's extra text
      if (cleanedResponse.contains('{')) {
        final jsonStart = cleanedResponse.indexOf('{');
        final jsonEnd = cleanedResponse.lastIndexOf('}') + 1;
        cleanedResponse = cleanedResponse.substring(jsonStart, jsonEnd);
      }

      final Map<String, dynamic> nutritionData = json.decode(cleanedResponse);

      // Validate that we have reasonable values
      if (nutritionData['calories'] != null && nutritionData['calories'] > 0) {
        return nutritionData;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error parsing Gemini nutrition response: $e');
      return null;
    }
  }

  /// Enhanced generic nutrition estimation as final fallback
  Map<String, dynamic> _enhancedGenericNutritionEstimate(String itemName, String? restaurantName) {
    String lowerName = itemName.toLowerCase();
    String lowerRestaurant = (restaurantName ?? '').toLowerCase();

    // Enhanced estimation based on restaurant type and item type
    Map<String, dynamic> baseNutrition = {};

    // Fast food vs. casual dining adjustments
    double calorieMultiplier = 1.0;
    double sodiumMultiplier = 1.0;
    double fatMultiplier = 1.0;

    if (lowerRestaurant.contains('mcdonald') ||
        lowerRestaurant.contains('burger king') ||
        lowerRestaurant.contains('taco bell')) {
      calorieMultiplier = 1.2;
      sodiumMultiplier = 1.4;
      fatMultiplier = 1.3;
    }

    // Item-specific estimations
    if (lowerName.contains('salad')) {
      baseNutrition = {
        'calories': (180 * calorieMultiplier).round(),
        'protein': 12.0,
        'carbs': 18.0,
        'fat': (8 * fatMultiplier).round(),
        'fiber': 6.0,
        'sodium': (450 * sodiumMultiplier).round(),
        'sugar': 9.0,
      };
    } else if (lowerName.contains('pizza')) {
      baseNutrition = {
        'calories': (320 * calorieMultiplier).round(),
        'protein': 14.0,
        'carbs': 38.0,
        'fat': (12 * fatMultiplier).round(),
        'fiber': 3.0,
        'sodium': (720 * sodiumMultiplier).round(),
        'sugar': 6.0,
      };
    } else if (lowerName.contains('burger') || lowerName.contains('sandwich')) {
      baseNutrition = {
        'calories': (580 * calorieMultiplier).round(),
        'protein': 28.0,
        'carbs': 42.0,
        'fat': (32 * fatMultiplier).round(),
        'fiber': 4.0,
        'sodium': (1100 * sodiumMultiplier).round(),
        'sugar': 6.0,
      };
    } else if (lowerName.contains('chicken')) {
      baseNutrition = {
        'calories': (280 * calorieMultiplier).round(),
        'protein': 35.0,
        'carbs': 2.0,
        'fat': (15 * fatMultiplier).round(),
        'fiber': 0.0,
        'sodium': (480 * sodiumMultiplier).round(),
        'sugar': 0.0,
      };
    } else if (lowerName.contains('drink') || lowerName.contains('soda') || lowerName.contains('beverage')) {
      baseNutrition = {
        'calories': 150.0,
        'protein': 0.0,
        'carbs': 39.0,
        'fat': 0.0,
        'fiber': 0.0,
        'sodium': 45.0,
        'sugar': 39.0,
      };
    } else {
      // Generic food item
      baseNutrition = {
        'calories': (380 * calorieMultiplier).round(),
        'protein': 18.0,
        'carbs': 32.0,
        'fat': (20 * fatMultiplier).round(),
        'fiber': 3.0,
        'sodium': (680 * sodiumMultiplier).round(),
        'sugar': 5.0,
      };
    }

    debugPrint('📊 Enhanced generic nutrition estimate for $itemName: $baseNutrition');
    return baseNutrition;
  }
}
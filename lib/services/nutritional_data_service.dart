import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import '../models/menu_item.dart';

class NutritionalDataService {
  final Map<String, Map<String, dynamic>> _nutritionCache = {};

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

    if (nutritionData != null) {
      _nutritionCache[cacheKey] = nutritionData;
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
    // Core identity must match: name and price
    if (original.name != enriched.name || original.price != enriched.price) {
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
}
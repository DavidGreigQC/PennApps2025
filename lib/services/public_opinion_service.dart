import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'dart:async';
import '../models/menu_item.dart';

/// Service for gathering and analyzing public opinion data about menu items
class PublicOpinionService {
  static const String _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  static PublicOpinionService? _instance;
  GenerativeModel? _geminiModel;

  static PublicOpinionService get instance {
    _instance ??= PublicOpinionService._();
    return _instance!;
  }

  PublicOpinionService._() {
    _initializeGemini();
  }

  void _initializeGemini() {
    try {
      if (_geminiApiKey.isNotEmpty) {
        _geminiModel = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: _geminiApiKey,
        );
        debugPrint('✅ Gemini AI initialized for public opinion analysis');
      } else {
        debugPrint('⚠️ GEMINI_API_KEY not found in environment variables');
      }
    } catch (e) {
      debugPrint('⚠️ Gemini AI initialization failed: $e');
    }
  }

  /// Get public opinion score for a menu item (0.0 to 1.0)
  Future<double> getPublicOpinionScore(MenuItem item, String? restaurantName) async {
    try {
      // Quick AI-based popularity assessment
      final popularityData = await _getQuickPopularityAssessment(item, restaurantName);

      if (popularityData != null) {
        return popularityData['score'] ?? 0.5;
      }

      // Fallback to rule-based estimation
      return _estimatePopularityByRules(item, restaurantName);

    } catch (e) {
      debugPrint('❌ Public opinion analysis failed: $e');
      return _estimatePopularityByRules(item, restaurantName);
    }
  }

  /// Quick AI-based popularity assessment (optimized for speed)
  Future<Map<String, dynamic>?> _getQuickPopularityAssessment(MenuItem item, String? restaurantName) async {
    if (_geminiModel == null) return null;

    try {
      final restaurantContext = restaurantName != null ? 'from $restaurantName' : '';

      // Optimized prompt for quick response
      String prompt = '''
Analyze the popularity of "${item.name}" $restaurantContext.

Consider:
- General popularity of this type of food
- Restaurant reputation (if known)
- Typical customer appeal
- Food trends and preferences

Respond with ONLY a JSON object:
{
  "score": 0.85,
  "reasoning": "Brief explanation"
}

Score scale: 0.0 (unpopular) to 1.0 (very popular)
Keep reasoning under 20 words.
''';

      // Set a short timeout to ensure speed
      final response = await _geminiModel!.generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 5));

      final text = response.text?.trim();
      if (text != null) {
        // Extract JSON from response
        final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(text);
        if (jsonMatch != null) {
          final jsonData = jsonDecode(jsonMatch.group(0)!);

          // Validate score
          final score = jsonData['score'];
          if (score is num && score >= 0.0 && score <= 1.0) {
            debugPrint('🔍 AI Opinion: ${item.name} = ${score.toStringAsFixed(2)} (${jsonData['reasoning']})');
            return {
              'score': score.toDouble(),
              'reasoning': jsonData['reasoning'] ?? 'AI analysis',
              'source': 'ai_quick'
            };
          }
        }
      }

    } catch (e) {
      if (e is TimeoutException) {
        debugPrint('⏱️ AI opinion analysis timed out for ${item.name}');
      } else {
        debugPrint('❌ AI opinion analysis error: $e');
      }
    }

    return null;
  }

  /// Rule-based popularity estimation as fallback
  double _estimatePopularityByRules(MenuItem item, String? restaurantName) {
    String lowerName = item.name.toLowerCase();
    String lowerRestaurant = (restaurantName ?? '').toLowerCase();

    double baseScore = 0.5; // Neutral starting point

    // Restaurant-specific adjustments
    if (lowerRestaurant.contains('mcdonald')) {
      if (lowerName.contains('big mac') || lowerName.contains('quarter pounder')) {
        baseScore = 0.9; // Iconic items
      } else if (lowerName.contains('nugget')) {
        baseScore = 0.85;
      } else if (lowerName.contains('fries')) {
        baseScore = 0.95; // Very popular
      }
    } else if (lowerRestaurant.contains('domino')) {
      if (lowerName.contains('pizza')) {
        baseScore = 0.8; // Pizza is popular
      } else if (lowerName.contains('bread')) {
        baseScore = 0.7;
      }
    }

    // General food type popularity
    if (lowerName.contains('pizza')) baseScore = Math.max(baseScore, 0.8);
    if (lowerName.contains('burger')) baseScore = Math.max(baseScore, 0.75);
    if (lowerName.contains('fries')) baseScore = Math.max(baseScore, 0.85);
    if (lowerName.contains('chicken') && lowerName.contains('nugget')) baseScore = Math.max(baseScore, 0.8);
    if (lowerName.contains('ice cream') || lowerName.contains('dessert')) baseScore = Math.max(baseScore, 0.7);
    if (lowerName.contains('salad')) baseScore = Math.max(baseScore, 0.6);
    if (lowerName.contains('wrap') || lowerName.contains('sandwich')) baseScore = Math.max(baseScore, 0.65);

    // Negative adjustments
    if (lowerName.contains('diet') || lowerName.contains('light')) baseScore *= 0.8;
    if (lowerName.contains('spicy') && !lowerName.contains('chicken')) baseScore *= 0.9;

    // Price influence on popularity
    if (item.price > 0) {
      if (item.price < 5.0) baseScore += 0.1; // Cheap items are popular
      if (item.price > 20.0) baseScore -= 0.1; // Expensive items less popular
    }

    // Ensure score is within bounds
    return Math.max(0.0, Math.min(1.0, baseScore));
  }

  /// Get detailed popularity insights for display
  Future<Map<String, dynamic>> getPopularityInsights(MenuItem item, String? restaurantName) async {
    try {
      final score = await getPublicOpinionScore(item, restaurantName);

      String category;
      String description;
      Color color;

      if (score >= 0.8) {
        category = 'Very Popular';
        description = 'Highly rated and frequently ordered';
        color = Colors.green;
      } else if (score >= 0.6) {
        category = 'Popular';
        description = 'Well-liked by customers';
        color = Colors.blue;
      } else if (score >= 0.4) {
        category = 'Moderate';
        description = 'Mixed customer opinions';
        color = Colors.orange;
      } else {
        category = 'Niche Appeal';
        description = 'Appeals to specific tastes';
        color = Colors.grey;
      }

      return {
        'score': score,
        'category': category,
        'description': description,
        'color': color,
        'confidence': score > 0.5 ? 'High' : 'Medium',
      };

    } catch (e) {
      debugPrint('❌ Error getting popularity insights: $e');
      return {
        'score': 0.5,
        'category': 'Unknown',
        'description': 'Unable to assess popularity',
        'color': Colors.grey,
        'confidence': 'Low',
      };
    }
  }

  /// Batch process multiple items for efficiency
  Future<Map<String, double>> getBatchOpinionScores(List<MenuItem> items, String? restaurantName) async {
    Map<String, double> scores = {};

    // Process in smaller batches to avoid overwhelming the AI
    const batchSize = 5;

    for (int i = 0; i < items.length; i += batchSize) {
      final batch = items.skip(i).take(batchSize).toList();

      for (final item in batch) {
        scores[item.name] = await getPublicOpinionScore(item, restaurantName);
      }

      // Small delay between batches to be respectful to the API
      if (i + batchSize < items.length) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    return scores;
  }
}

// Extension to add math functions
extension Math on double {
  static double max(double a, double b) => a > b ? a : b;
  static double min(double a, double b) => a < b ? a : b;
}
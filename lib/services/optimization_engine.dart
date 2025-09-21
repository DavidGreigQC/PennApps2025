import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/menu_item.dart';
import '../models/optimization_criteria.dart';
import '../models/optimization_result.dart';
import 'public_opinion_service.dart';

class OptimizationEngine {
  // Cache for public opinion scores to avoid repeated API calls
  final Map<String, double> _opinionCache = {};
  String? _currentRestaurantName;
  Future<ParetoFrontier> optimize(
    List<MenuItem> items,
    OptimizationRequest request,
  ) async {
    // Store restaurant name for opinion analysis
    _currentRestaurantName = request.restaurantName;
    _opinionCache.clear(); // Clear cache for new optimization
    // CRITICAL: Validate input - only process items that were provided
    if (items.isEmpty) {
      throw Exception('No menu items provided for optimization');
    }

    debugPrint('OPTIMIZATION: Starting optimization with ${items.length} menu items');

    List<OptimizationResult> results = [];

    for (MenuItem item in items) {
      if (!_passesFilters(item, request)) continue;

      double score = _calculateOptimizationScore(item, request.criteria);
      Map<String, double> criteriaScores = _calculateCriteriaScores(item, request.criteria);
      String reasoning = _generateReasoning(item, request.criteria, criteriaScores);

      results.add(OptimizationResult(
        menuItem: item,
        optimizationScore: score,
        criteriaScores: criteriaScores,
        reasoning: reasoning,
      ));
    }

    results.sort((a, b) => b.optimizationScore.compareTo(a.optimizationScore));

    debugPrint('OPTIMIZATION: Generated ${results.length} optimization results');

    Map<String, List<double>> frontierPoints = _calculateParetoFrontier(results, request.criteria);

    return ParetoFrontier(
      results: results,
      frontierPoints: frontierPoints,
    );
  }

  bool _passesFilters(MenuItem item, OptimizationRequest request) {
    if (request.maxPrice != null && item.price > request.maxPrice!) {
      return false;
    }

    if (request.allergenRestrictions != null && item.allergens != null) {
      for (String allergen in request.allergenRestrictions!) {
        if (item.allergens!.contains(allergen)) {
          return false;
        }
      }
    }

    return true;
  }

  double _calculateOptimizationScore(MenuItem item, List<OptimizationCriteria> criteria) {
    double totalScore = 0.0;
    double totalWeight = 0.0;

    for (OptimizationCriteria criterion in criteria) {
      double value = _getCriterionValue(item, criterion.name);
      double normalizedValue = _normalizeValue(value, criterion.name);

      if (!criterion.isMaximize) {
        normalizedValue = 1.0 - normalizedValue;
      }

      totalScore += normalizedValue * criterion.weight;
      totalWeight += criterion.weight;
    }

    return totalWeight > 0 ? totalScore / totalWeight : 0.0;
  }

  /// Get cached public opinion score (async operation made sync through caching)
  double _getCachedOpinionScore(MenuItem item) {
    final key = '${item.name}_${_currentRestaurantName ?? ""}';
    return _opinionCache[key] ?? 0.5; // Default neutral score if not cached
  }

  /// Pre-populate opinion scores for all items (call before optimization)
  Future<void> preloadOpinionScores(List<MenuItem> items, String? restaurantName) async {
    try {
      debugPrint('🔍 Preloading public opinion scores for ${items.length} items...');

      final opinionService = PublicOpinionService.instance;
      final scores = await opinionService.getBatchOpinionScores(items, restaurantName);

      // Cache the scores
      for (final item in items) {
        final key = '${item.name}_${restaurantName ?? ""}';
        _opinionCache[key] = scores[item.name] ?? 0.5;
      }

      debugPrint('✅ Cached ${_opinionCache.length} opinion scores');
    } catch (e) {
      debugPrint('⚠️ Failed to preload opinion scores: $e');
      // Fill cache with default values
      for (final item in items) {
        final key = '${item.name}_${restaurantName ?? ""}';
        _opinionCache[key] = 0.5;
      }
    }
  }

  Map<String, double> _calculateCriteriaScores(MenuItem item, List<OptimizationCriteria> criteria) {
    Map<String, double> scores = {};

    for (OptimizationCriteria criterion in criteria) {
      double value = _getCriterionValue(item, criterion.name);
      scores[criterion.name] = value;
    }

    return scores;
  }

  double _getCriterionValue(MenuItem item, String criterionName) {
    switch (criterionName.toLowerCase()) {
      case 'protein_per_dollar':
        return item.calculateProteinPerDollar();
      case 'calories_per_dollar':
        return item.calculateCaloriesPerDollar();
      case 'protein':
        return item.protein ?? 0.0;
      case 'calories':
        return item.calories ?? 0.0;
      case 'price':
        return item.price;
      case 'health_score':
        return item.calculateHealthScore();
      case 'nutrient_density':
        return item.calculateNutrientDensity();
      case 'fiber':
        return item.fiber ?? 0.0;
      case 'fat':
        return item.fat ?? 0.0;
      case 'carbs':
        return item.carbs ?? 0.0;
      case 'sodium':
        return item.sodium ?? 0.0;
      case 'sugar':
        return item.sugar ?? 0.0;
      case 'public_opinion':
        return _getCachedOpinionScore(item);
      default:
        return 0.0;
    }
  }

  double _normalizeValue(double value, String criterionName) {
    Map<String, Map<String, double>> ranges = {
      'protein_per_dollar': {'min': 0.0, 'max': 20.0},
      'calories_per_dollar': {'min': 0.0, 'max': 500.0},
      'protein': {'min': 0.0, 'max': 60.0},
      'calories': {'min': 0.0, 'max': 1000.0},
      'price': {'min': 1.0, 'max': 30.0},
      'health_score': {'min': 0.0, 'max': 1.0},
      'nutrient_density': {'min': 0.0, 'max': 100.0},
      'fiber': {'min': 0.0, 'max': 20.0},
      'fat': {'min': 0.0, 'max': 50.0},
      'carbs': {'min': 0.0, 'max': 100.0},
      'sodium': {'min': 0.0, 'max': 3000.0},
      'sugar': {'min': 0.0, 'max': 50.0},
    };

    Map<String, double>? range = ranges[criterionName.toLowerCase()];
    if (range == null) return 0.0;

    double min = range['min']!;
    double max = range['max']!;

    if (max == min) return 0.0;

    double normalized = (value - min) / (max - min);
    return normalized.clamp(0.0, 1.0);
  }

  String _generateReasoning(
    MenuItem item,
    List<OptimizationCriteria> criteria,
    Map<String, double> scores,
  ) {
    List<String> reasons = [];

    if (scores.containsKey('protein_per_dollar')) {
      double proteinPerDollar = scores['protein_per_dollar']!;
      if (proteinPerDollar > 10) {
        reasons.add('Excellent protein value at ${proteinPerDollar.toStringAsFixed(1)}g/\$');
      } else if (proteinPerDollar > 5) {
        reasons.add('Good protein value at ${proteinPerDollar.toStringAsFixed(1)}g/\$');
      }
    }

    if (scores.containsKey('health_score')) {
      double healthScore = scores['health_score']!;
      if (healthScore > 0.7) {
        reasons.add('High nutritional quality');
      } else if (healthScore > 0.4) {
        reasons.add('Moderate nutritional quality');
      }
    }

    if (item.price < 10) {
      reasons.add('Budget-friendly option');
    }

    if (reasons.isEmpty) {
      reasons.add('Meets basic optimization criteria');
    }

    return reasons.join('. ') + '.';
  }

  Map<String, List<double>> _calculateParetoFrontier(
    List<OptimizationResult> results,
    List<OptimizationCriteria> criteria,
  ) {
    Map<String, List<double>> frontierPoints = {};

    if (criteria.length >= 2) {
      String xAxis = criteria[0].name;
      String yAxis = criteria[1].name;

      List<double> xValues = [];
      List<double> yValues = [];

      for (OptimizationResult result in results.take(20)) {
        double xValue = result.criteriaScores[xAxis] ?? 0.0;
        double yValue = result.criteriaScores[yAxis] ?? 0.0;

        xValues.add(xValue);
        yValues.add(yValue);
      }

      frontierPoints[xAxis] = xValues;
      frontierPoints[yAxis] = yValues;
    }

    return frontierPoints;
  }

  List<OptimizationResult> _applyGeneticAlgorithm(
    List<MenuItem> items,
    List<OptimizationCriteria> criteria,
  ) {
    // Simplified genetic algorithm implementation
    Random random = Random();
    int populationSize = min(50, items.length);
    int generations = 20;

    List<MenuItem> population = List.from(items)..shuffle(random);
    population = population.take(populationSize).toList();

    for (int gen = 0; gen < generations; gen++) {
      population.sort((a, b) {
        double scoreA = _calculateOptimizationScore(a, criteria);
        double scoreB = _calculateOptimizationScore(b, criteria);
        return scoreB.compareTo(scoreA);
      });

      List<MenuItem> newPopulation = population.take(populationSize ~/ 2).toList();

      while (newPopulation.length < populationSize) {
        int idx = random.nextInt(items.length);
        newPopulation.add(items[idx]);
      }

      population = newPopulation;
    }

    return population.map((item) {
      double score = _calculateOptimizationScore(item, criteria);
      Map<String, double> scores = _calculateCriteriaScores(item, criteria);
      String reasoning = _generateReasoning(item, criteria, scores);

      return OptimizationResult(
        menuItem: item,
        optimizationScore: score,
        criteriaScores: scores,
        reasoning: reasoning,
      );
    }).toList();
  }
}
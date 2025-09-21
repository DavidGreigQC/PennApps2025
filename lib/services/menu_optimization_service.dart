import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../models/optimization_criteria.dart';
import '../models/optimization_result.dart';
import 'ocr_service.dart';
import 'nutritional_data_service.dart';
import 'optimization_engine.dart';
import 'optimization_progress_service.dart';
import 'money_savings_service.dart';

class MenuOptimizationService extends ChangeNotifier {
  bool _isProcessing = false;
  String _status = '';
  List<MenuItem> _extractedItems = [];
  List<MenuItem> _originalExtractedItems = []; // Store original extracted items for validation
  List<OptimizationResult> _results = [];
  ParetoFrontier? _paretoFrontier;

  bool get isProcessing => _isProcessing;
  String get status => _status;
  List<MenuItem> get extractedItems => _extractedItems;
  List<OptimizationResult> get results => _results;
  ParetoFrontier? get paretoFrontier => _paretoFrontier;

  final OCRService _ocrService = OCRService();
  final NutritionalDataService _nutritionalService = NutritionalDataService();
  final OptimizationEngine _optimizationEngine = OptimizationEngine();

  Future<void> processMenuFiles(
    List<String> filePaths,
    OptimizationRequest request,
  ) async {
    _isProcessing = true;
    _status = 'Starting menu analysis...';
    notifyListeners();

    try {
      _status = 'Analyzing uploaded files...';
      notifyListeners();

      List<MenuItem> allItems = [];
      for (String filePath in filePaths) {
        String fileName = filePath.split('/').last;
        bool isPdf = fileName.toLowerCase().endsWith('.pdf');

        if (isPdf) {
          _status = 'Processing PDF: $fileName (using sample McDonald\'s data)';
          notifyListeners();
        } else {
          _status = 'Reading text from: $fileName';
          notifyListeners();
        }

        List<MenuItem> items = await _ocrService.extractMenuItems(filePath);
        allItems.addAll(items);
      }

      // Store original extracted items for validation
      _originalExtractedItems = List<MenuItem>.from(allItems);
      _extractedItems = allItems;
      _status = 'Found ${allItems.length} menu items. Validating menu items...';
      notifyListeners();

      // CRITICAL: Validate that we only work with items extracted from uploaded menus
      List<MenuItem> validatedItems = _validateMenuItems(allItems);
      if (validatedItems.isEmpty) {
        throw Exception('No valid menu items found in uploaded files. Please check that your files contain readable menu text.');
      }

      _status = 'Validated ${validatedItems.length} menu items. Enriching with nutritional data...';
      notifyListeners();

      await _nutritionalService.enrichMenuItems(
        validatedItems,
        request.restaurantName,
        request.websiteUrl,
      );

      // CRITICAL: Re-validate after nutritional enrichment to ensure no external items were added
      List<MenuItem> finalValidatedItems = _validateMenuItems(validatedItems);

      _status = 'Running optimization analysis on ${finalValidatedItems.length} validated menu items...';
      notifyListeners();

      // Check if public opinion is included in criteria, and preload if needed
      bool hasPublicOpinion = request.criteria.any((c) => c.name.toLowerCase() == 'public_opinion');
      if (hasPublicOpinion) {
        _status = 'Analyzing public opinion and reviews...';
        notifyListeners();
        await _optimizationEngine.preloadOpinionScores(finalValidatedItems, request.restaurantName);
      }

      _status = 'Finalizing optimization analysis...';
      notifyListeners();

      _paretoFrontier = await _optimizationEngine.optimize(finalValidatedItems, request);
      _results = _paretoFrontier!.getTopResults(10);

      // FINAL VALIDATION: Ensure all recommended items are from the original menu
      _results = _validateRecommendations(_results);

      _status = 'Analysis complete! Found ${_results.length} optimal recommendations.';

      // Track optimization progress and calculate savings
      await _trackOptimizationProgress();
      await _calculateAndTrackSavings();

      notifyListeners();

    } catch (e) {
      _status = 'Error during analysis: ${e.toString()}';
      _results.clear();
      _paretoFrontier = null;
      notifyListeners();

      // Log error for debugging
      debugPrint('Menu optimization error: $e');

      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void clearResults() {
    _extractedItems.clear();
    _originalExtractedItems.clear();
    _results.clear();
    _paretoFrontier = null;
    _status = '';
    notifyListeners();
  }

  /// CRITICAL: Validates that menu items are from the original extracted menu
  List<MenuItem> _validateMenuItems(List<MenuItem> items) {
    List<MenuItem> validItems = [];

    for (MenuItem item in items) {
      // Check if this item exists in the original extracted items
      bool isFromOriginalMenu = _originalExtractedItems.any((originalItem) =>
        _isSameMenuItem(originalItem, item)
      );

      if (isFromOriginalMenu) {
        validItems.add(item);
      } else {
        debugPrint('WARNING: Filtered out item not from original menu: ${item.name}');
      }
    }

    debugPrint('Validation: ${validItems.length} out of ${items.length} items validated as from original menu');
    return validItems;
  }

  /// CRITICAL: Validates that all recommendations are from the original menu
  List<OptimizationResult> _validateRecommendations(List<OptimizationResult> recommendations) {
    List<OptimizationResult> validRecommendations = [];

    for (OptimizationResult result in recommendations) {
      // Double-check that the recommended item is from the original menu
      bool isFromOriginalMenu = _originalExtractedItems.any((originalItem) =>
        _isSameMenuItem(originalItem, result.menuItem)
      );

      if (isFromOriginalMenu) {
        validRecommendations.add(result);
      } else {
        debugPrint('CRITICAL WARNING: Filtered out recommendation not from original menu: ${result.menuItem.name}');
      }
    }

    debugPrint('Final validation: ${validRecommendations.length} out of ${recommendations.length} recommendations validated');
    return validRecommendations;
  }

  /// Helper method to determine if two menu items are the same
  bool _isSameMenuItem(MenuItem item1, MenuItem item2) {
    // Primary check: exact name match
    if (item1.name == item2.name) {
      return true;
    }

    // Secondary check: normalized name comparison (handles enrichment changes)
    String normalizedName1 = _normalizeMenuItemName(item1.name);
    String normalizedName2 = _normalizeMenuItemName(item2.name);

    // Names must match closely - allow price changes during enrichment
    if (normalizedName1 == normalizedName2) {
      // Allow price changes only if original price was 0.0 (missing price)
      if (item1.price == 0.0 || item2.price == 0.0) {
        return true;
      }
      // If both have non-zero prices, they must match
      return item1.price == item2.price;
    }

    return false;
  }

  /// Normalizes menu item names for comparison
  String _normalizeMenuItemName(String name) {
    return name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
  }

  /// Track optimization progress for the graph
  Future<void> _trackOptimizationProgress() async {
    try {
      if (_results.isNotEmpty) {
        // Find the highest optimization score from results
        double highestScore = 0.0;
        for (OptimizationResult result in _results) {
          if (result.optimizationScore > highestScore) {
            highestScore = result.optimizationScore;
          }
        }
        double optimizationPercentage = (highestScore * 100).clamp(0.0, 100.0);

        // Save to optimization progress service
        await OptimizationProgressService.instance.addOptimizationResult(optimizationPercentage);

        debugPrint('📈 Optimization progress tracked (highest): ${optimizationPercentage.toStringAsFixed(1)}%');
      }
    } catch (e) {
      debugPrint('Error tracking optimization progress: $e');
    }
  }

  /// Calculate and track estimated money savings
  Future<void> _calculateAndTrackSavings() async {
    try {
      if (_results.isNotEmpty && _extractedItems.isNotEmpty) {
        // Calculate savings from this optimization session
        double sessionSavings = await MoneySavingsService.instance.addOptimizationSavings(_results, _extractedItems);

        debugPrint('💰 Estimated savings from this optimization: \$${sessionSavings.toStringAsFixed(2)}');

        // Get total savings for logging
        double totalSavings = await MoneySavingsService.instance.getTotalSavings();
        debugPrint('💰 Total estimated savings: \$${totalSavings.toStringAsFixed(2)}');
      }
    } catch (e) {
      debugPrint('Error calculating savings: $e');
    }
  }
}
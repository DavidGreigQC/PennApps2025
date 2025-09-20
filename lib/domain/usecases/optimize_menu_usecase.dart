import '../entities/menu_item.dart';
import '../entities/optimization_result.dart';
import '../entities/optimization_criteria.dart';
import '../repositories/menu_repository.dart';

/// Use case for menu optimization workflow
/// Encapsulates the complete business logic for menu optimization
class OptimizeMenuUseCase {
  final MenuRepository _menuRepository;

  OptimizeMenuUseCase(this._menuRepository);

  /// Execute the complete menu optimization workflow
  Future<OptimizeMenuResult> execute(OptimizeMenuParams params) async {
    try {
      // Step 1: Process uploaded files
      final extractedItems = await _menuRepository.processMenuFiles(params.filePaths);

      if (extractedItems.isEmpty) {
        throw MenuOptimizationException('No menu items could be extracted from the uploaded files');
      }

      // Step 2: Enrich with nutritional data
      final enrichedItems = await _menuRepository.enrichWithNutritionalData(extractedItems);

      // Step 3: Perform optimization
      final optimizationResults = await _menuRepository.optimizeMenu(
        enrichedItems,
        params.criteria,
      );

      // Step 4: Save user session (if user ID provided)
      if (params.userId != null && optimizationResults.isNotEmpty) {
        await _menuRepository.saveUserSession(params.userId!, optimizationResults.first);
      }

      // Step 5: Cache menu data for future use
      if (params.restaurantId != null) {
        await _menuRepository.cacheMenuData(params.restaurantId!, enrichedItems);
      }

      return OptimizeMenuResult.success(
        originalItems: extractedItems,
        enrichedItems: enrichedItems,
        optimizationResults: optimizationResults,
      );

    } catch (e) {
      return OptimizeMenuResult.failure(error: e.toString());
    }
  }
}

/// Parameters for menu optimization
class OptimizeMenuParams {
  final List<String> filePaths;
  final OptimizationRequest criteria;
  final String? userId;
  final String? restaurantId;

  OptimizeMenuParams({
    required this.filePaths,
    required this.criteria,
    this.userId,
    this.restaurantId,
  });
}

/// Result of menu optimization
class OptimizeMenuResult {
  final bool isSuccess;
  final List<MenuItem>? originalItems;
  final List<MenuItem>? enrichedItems;
  final List<OptimizationResult>? optimizationResults;
  final String? error;

  OptimizeMenuResult._({
    required this.isSuccess,
    this.originalItems,
    this.enrichedItems,
    this.optimizationResults,
    this.error,
  });

  factory OptimizeMenuResult.success({
    required List<MenuItem> originalItems,
    required List<MenuItem> enrichedItems,
    required List<OptimizationResult> optimizationResults,
  }) {
    return OptimizeMenuResult._(
      isSuccess: true,
      originalItems: originalItems,
      enrichedItems: enrichedItems,
      optimizationResults: optimizationResults,
    );
  }

  factory OptimizeMenuResult.failure({required String error}) {
    return OptimizeMenuResult._(
      isSuccess: false,
      error: error,
    );
  }
}

class MenuOptimizationException implements Exception {
  final String message;
  MenuOptimizationException(this.message);

  @override
  String toString() => 'MenuOptimizationException: $message';
}
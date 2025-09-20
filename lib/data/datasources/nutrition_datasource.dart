import '../../domain/entities/menu_item.dart';

/// Data source interface for nutritional data operations
abstract class NutritionDataSource {
  /// Enrich menu items with nutritional information
  Future<List<MenuItem>> enrichMenuItems(List<MenuItem> items);
}

/// Implementation that wraps existing nutrition service
class NutritionDataSourceImpl implements NutritionDataSource {
  // We'll inject the existing nutrition service here
  final dynamic _nutritionService; // Replace with actual service type

  NutritionDataSourceImpl(this._nutritionService);

  @override
  Future<List<MenuItem>> enrichMenuItems(List<MenuItem> items) async {
    // Delegate to existing nutrition service
    return await _nutritionService.enrichMenuItems(items);
  }
}
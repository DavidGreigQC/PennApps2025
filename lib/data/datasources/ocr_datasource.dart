import '../../domain/entities/menu_item.dart';

/// Data source interface for OCR operations
abstract class OCRDataSource {
  /// Extract menu items from file using OCR
  Future<List<MenuItem>> extractMenuItems(String filePath);
}

/// Implementation that wraps existing OCR service
class OCRDataSourceImpl implements OCRDataSource {
  // We'll inject the existing OCR service here
  final dynamic _ocrService; // Replace with actual service type

  OCRDataSourceImpl(this._ocrService);

  @override
  Future<List<MenuItem>> extractMenuItems(String filePath) async {
    // Delegate to existing OCR service
    return await _ocrService.extractMenuItems(filePath);
  }
}
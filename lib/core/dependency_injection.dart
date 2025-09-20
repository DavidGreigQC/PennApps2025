import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

// Domain
import '../domain/repositories/menu_repository.dart';
import '../domain/usecases/optimize_menu_usecase.dart';

// Data
import '../data/repositories/menu_repository_impl.dart';
import '../data/datasources/ocr_datasource.dart';
import '../data/datasources/nutrition_datasource.dart';
import '../data/datasources/optimization_datasource.dart';
import '../data/datasources/storage_datasource.dart';
import '../data/datasources/mongodb_datasource.dart';
import '../data/datasources/gemini_vision_datasource.dart';
import '../data/datasources/auth0_datasource.dart';

// Presentation
import '../presentation/controllers/menu_optimization_controller.dart';

// Legacy services (to be wrapped)
import '../services/ocr_service.dart';
import '../services/nutritional_data_service.dart';
import '../services/optimization_engine.dart';
import '../services/menu_optimization_service.dart';

/// Dependency injection setup for the application
/// This is where we wire up all our dependencies
class DependencyInjection {
  static List<SingleChildWidget> get providers => [
        // Data Sources
        Provider<OCRDataSource>(
          create: (context) => OCRDataSourceImpl(OCRService()),
        ),
        Provider<NutritionDataSource>(
          create: (context) => NutritionDataSourceImpl(NutritionalDataService()),
        ),
        Provider<OptimizationDataSource>(
          create: (context) => OptimizationDataSourceImpl(OptimizationEngine()),
        ),
        Provider<StorageDataSource>(
          create: (context) => MongoStorageDataSource(),
        ),

        // MongoDB Atlas Community Database
        Provider<MongoDBDataSource>(
          create: (context) => MongoDBDataSource(),
        ),

        // Gemini Vision OCR
        Provider<GeminiVisionDataSource>(
          create: (context) => GeminiVisionDataSource(),
        ),

        // Repository
        Provider<MenuRepository>(
          create: (context) => MenuRepositoryImpl(
            ocrDataSource: context.read<OCRDataSource>(),
            nutritionDataSource: context.read<NutritionDataSource>(),
            optimizationDataSource: context.read<OptimizationDataSource>(),
            storageDataSource: context.read<StorageDataSource>(),
            mongoDataSource: context.read<MongoDBDataSource>(),
            geminiVisionDataSource: context.read<GeminiVisionDataSource>(),
          ),
        ),

        // Use Cases
        Provider<OptimizeMenuUseCase>(
          create: (context) => OptimizeMenuUseCase(
            context.read<MenuRepository>(),
          ),
        ),

        // Legacy Services
        ChangeNotifierProvider<MenuOptimizationService>(
          create: (context) => MenuOptimizationService(),
        ),

        // Controllers
        ChangeNotifierProvider<MenuOptimizationController>(
          create: (context) => MenuOptimizationController(
            context.read<OptimizeMenuUseCase>(),
          ),
        ),
      ];
}

/// Service locator for getting dependencies outside of widget tree
class ServiceLocator {
  static MenuOptimizationController? _controller;
  static MenuRepository? _repository;

  static void initialize(MenuOptimizationController controller, MenuRepository repository) {
    _controller = controller;
    _repository = repository;
  }

  static MenuOptimizationController get controller {
    if (_controller == null) {
      throw Exception('ServiceLocator not initialized. Call initialize() first.');
    }
    return _controller!;
  }

  static MenuRepository get repository {
    if (_repository == null) {
      throw Exception('ServiceLocator not initialized. Call initialize() first.');
    }
    return _repository!;
  }
}
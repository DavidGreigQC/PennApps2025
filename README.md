# Menu Optimizer App

A Flutter application that optimizes menu selections using weighted multi-objective optimization algorithms.

## Features

### Core Functionality
- **File Upload**: Upload PDF menus or multiple menu images
- **OCR Processing**: Extract menu items, prices, and descriptions from uploaded files
- **Nutritional Data Enhancement**: Automatically enrich menu items with nutritional information
- **Multi-Objective Optimization**: Find optimal menu items based on customizable criteria
- **Pareto Frontier Analysis**: Visualize trade-offs between different optimization objectives

### Optimization Criteria
- Protein per dollar
- Calories per dollar
- Health score (based on nutrition quality)
- Price minimization
- Protein maximization
- Fiber content
- Nutrient density

### Advanced Features
- **Fuzzy String Matching**: Match menu items with nutritional databases
- **Web Scraping**: Extract nutritional data from restaurant websites
- **Genetic Algorithm**: Advanced optimization for complex multi-constraint scenarios
- **Interactive Charts**: Pareto frontier visualization with fl_chart
- **Constraint Filtering**: Filter by price, allergens, and dietary restrictions

## Architecture

### Models
- `MenuItem`: Core data model with nutritional information
- `OptimizationCriteria`: Defines optimization objectives and weights
- `OptimizationResult`: Contains optimization scores and reasoning

### Services
- `OCRService`: Text extraction from menu images using Google ML Kit
- `NutritionalDataService`: Data enrichment via APIs and web scraping
- `OptimizationEngine`: Weighted multi-objective optimization algorithms
- `MenuOptimizationService`: Main service orchestrating the optimization pipeline

### UI Components
- `FileUploadWidget`: Drag-and-drop file upload interface
- `OptimizationFormWidget`: Criteria configuration and constraints
- `ResultsDisplayWidget`: Rankings and Pareto frontier visualization

## Algorithms

### Data Extraction
- **OCR Pipeline**: Google ML Kit for menu text extraction
- **NLP Processing**: Named Entity Recognition for food items and prices
- **Pattern Matching**: Regex-based price and item identification

### Nutritional Data Enhancement
- **API Integration**: USDA Food Data Central API
- **Web Scraping**: Restaurant website nutritional information extraction
- **Fuzzy Matching**: FuzzyWuzzy for menu item to database matching
- **Fallback Hierarchy**: Restaurant site → Nutrition APIs → Generic databases

### Optimization
- **Weighted Scoring**: Multi-criteria decision analysis
- **Pareto Frontier**: Non-dominated solution identification
- **Genetic Algorithm**: Population-based optimization for complex scenarios
- **Constraint Handling**: Price, allergen, and dietary restriction filtering

## Getting Started

### Prerequisites
- Flutter SDK (>=3.9.0)
- Android Studio / Xcode for mobile development
- Internet connection for nutritional data APIs

### Installation
```bash
# Install dependencies
flutter pub get

# Generate JSON serialization code
flutter packages pub run build_runner build

# Run the app
flutter run
```

### Configuration
- Replace `DEMO_KEY` in `nutritional_data_service.dart` with actual USDA API key
- Configure web scraping targets in the nutritional service
- Adjust optimization algorithm parameters in `optimization_engine.dart`

## Usage

1. **Upload Menu Files**: Select PDF or image files of restaurant menus
2. **Set Restaurant Info** (Optional): Enter restaurant name, location, and website
3. **Configure Optimization**:
   - Add optimization criteria (protein/dollar, health score, etc.)
   - Set weights for each criterion
   - Choose maximize or minimize for each objective
   - Set constraints (max price, allergen restrictions)
4. **Run Analysis**: Process files and view optimized recommendations
5. **View Results**:
   - Ranked list of optimal menu items
   - Detailed nutritional breakdown
   - Pareto frontier visualization
   - Optimization reasoning

## Technical Implementation

### Weighted Multi-Objective Optimization
The app uses a weighted sum approach where each criterion is:
1. Normalized to a 0-1 scale
2. Multiplied by user-defined weights
3. Combined into a single optimization score
4. Ranked to find optimal solutions

### Pareto Frontier Analysis
- Identifies non-dominated solutions across multiple objectives
- Visualizes trade-offs between competing criteria
- Helps users understand optimization constraints

## Dependencies

Key Flutter packages used:
- `google_ml_kit`: OCR and text recognition
- `file_picker`: File upload functionality
- `fl_chart`: Data visualization
- `fuzzywuzzy`: String matching
- `http`/`dio`: API calls and web scraping
- `provider`: State management
- `json_annotation`: Data serialization

## License

This project is created for educational purposes as part of PennApps 2025.

# MenuMax 🍽️✨

**AI-powered menu optimization that transforms any restaurant menu photo into personalized recommendations using computer vision, nutritional data, and multi-criteria optimization algorithms.**

*Eat smart, spend less.*

## 🚀 Features

### 🤖 AI-Powered Vision
- **Gemini Pro Vision OCR**: Advanced computer vision for menu extraction from photos
- **Smart Menu Analysis**: Understands complex menu layouts, fonts, and formatting
- **Conversational AI**: Ask questions about menu items and get intelligent responses
- **Camera Integration**: Real-time menu scanning with live camera feed

### 🔬 Advanced Optimization
- **Multi-Objective Optimization**: Weighted scoring and Pareto frontier analysis
- **Nutritional Intelligence**: Automatic enrichment with comprehensive nutritional data
- **Constraint Satisfaction**: Filter by budget, allergens, and dietary preferences
- **Public Opinion Integration**: AI-powered sentiment analysis for menu items

### 📊 Optimization Criteria
- Protein per dollar ratio
- Calories per dollar efficiency
- Health score (nutritional quality)
- Nutrient density optimization
- Price minimization
- Fiber, fat, carb, sodium optimization
- Public opinion scoring

### 🏗️ Advanced Features
- **Clean Architecture**: Domain-driven design with proper separation of concerns
- **MongoDB Integration**: Community-driven menu database with deduplication
- **Auth0 Authentication**: Enterprise-grade secure user management
- **Real-time Processing**: Efficient mobile optimization algorithms
- **Interactive Visualizations**: Pareto frontier charts and detailed analytics

## 🏗️ Architecture

MenuMax follows **Clean Architecture** principles with clear separation of concerns:

### 🎯 Domain Layer
- `MenuItem`: Core business entity with nutritional calculations
- `OptimizationCriteria`: Value objects defining optimization objectives
- `OptimizationResult`: Results with scores and reasoning
- `OptimizeMenuUseCase`: Business logic orchestration

### 📊 Data Layer
- `GeminiVisionDataSource`: AI-powered menu OCR using Gemini Pro Vision
- `NutritionDataSource`: Nutritional data enrichment APIs
- `OptimizationDataSource`: Mathematical optimization algorithms
- `MongoDBDataSource`: Community menu database
- `Auth0DataSource`: User authentication

### 🎨 Presentation Layer
- `MenuOptimizationController`: State management with Provider
- `CameraOCRWidget`: Live camera menu scanning
- `FileUploadWidget`: Multi-format file upload
- `OptimizationFormWidget`: Criteria and constraints configuration
- `ResultsDisplayWidget`: Interactive charts and recommendations

### 🔧 Services
- `OptimizationEngine`: Multi-criteria decision algorithms
- `MoneySavingsService`: Cost analysis and tracking
- `PublicOpinionService`: Sentiment analysis integration
- `LocalStatsService`: User analytics and caching

## 🧠 AI & Algorithms

### 🤖 Computer Vision (Gemini Pro Vision)
```dart
final prompt = TextPart('''
Analyze this menu image and extract ALL menu items with prices in JSON format.
Return ONLY a JSON array: [{"name": "Item Name", "price": 5.99}]
''');
```
- **Smart OCR**: Understands complex menu layouts and formatting
- **Structured Extraction**: Converts images to structured JSON data
- **Conversational AI**: Answer questions about menu content
- **Fallback Parsing**: Regex-based extraction when JSON parsing fails

### 🔬 Multi-Criteria Optimization
```dart
double _calculateOptimizationScore(MenuItem item, List<OptimizationCriteria> criteria) {
  double totalScore = 0.0;
  for (OptimizationCriteria criterion in criteria) {
    double normalizedValue = _normalizeValue(_getCriterionValue(item, criterion.name));
    totalScore += normalizedValue * criterion.weight;
  }
  return totalScore / totalWeight;
}
```
- **Weighted Scoring**: Multi-criteria decision analysis (MCDA)
- **Normalization**: 0-1 scaling across different value ranges
- **Pareto Frontier**: Non-dominated solution identification
- **Constraint Satisfaction**: Budget, allergen, and dietary filtering

### 📈 Data Enrichment
- **Nutritional APIs**: Nutritionix and Edamam integration
- **Fuzzy Matching**: String similarity for database matching
- **Opinion Mining**: AI-powered sentiment analysis
- **Caching Strategy**: Hash-based deduplication for performance

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
```bash
# Set environment variables for API keys
flutter run --dart-define=GEMINI_API_KEY=your_gemini_key
flutter run --dart-define=NUTRITIONIX_API_KEY=your_nutritionix_key
flutter run --dart-define=MONGODB_URI=your_mongodb_connection
```

- **Gemini API**: Computer vision for menu OCR
- **Nutritionix API**: Nutritional data enrichment
- **MongoDB Atlas**: Community menu database
- **Auth0**: User authentication (configure domain/client ID)

## 📱 Usage

### 📸 Quick Start
1. **Scan Menu**: Use camera to capture menu or upload image/PDF
2. **AI Processing**: Gemini Vision extracts items automatically
3. **Set Preferences**: Choose optimization goals (health, budget, protein, etc.)
4. **Get Recommendations**: View ranked results with detailed reasoning

### 🎯 Advanced Features
1. **Multi-Criteria Optimization**:
   - Weight different goals (50% health, 30% budget, 20% taste)
   - Set hard constraints (under $15, no nuts, high protein)
   - View Pareto frontier for trade-off analysis

2. **AI Conversations**:
   - Ask: "What's the healthiest option under $12?"
   - Get: Intelligent responses based on menu analysis

3. **Community Intelligence**:
   - Benefit from shared menu database
   - Contribute to collective optimization knowledge

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

## 📦 Dependencies

### 🤖 AI & Vision
- `google_generative_ai`: Gemini Pro Vision API integration
- `camera`: Real-time menu scanning
- `google_ml_kit`: Fallback OCR processing

### 🗄️ Backend & Data
- `mongo_dart`: MongoDB Atlas integration
- `auth0_flutter`: Enterprise authentication
- `http`/`dio`: API communication
- `crypto`: Data hashing and security

### 📊 UI & Visualization
- `fl_chart`: Interactive Pareto frontier charts
- `provider`: Reactive state management
- `file_picker`: Multi-format file upload
- `syncfusion_flutter_pdf`: PDF processing

### 🔧 Utilities
- `fuzzywuzzy`: Intelligent string matching
- `json_annotation`: Type-safe serialization
- `shared_preferences`: Local data persistence
- `vector_math`: Mathematical computations

## 🏆 Technical Achievements

### 🤖 Advanced AI Integration
- **Gemini Pro Vision**: State-of-the-art computer vision for menu understanding
- **Prompt Engineering**: Sophisticated prompts for reliable structured data extraction
- **Conversational AI**: Natural language interaction with menu content

### 🧮 Mathematical Rigor
- **Multi-Objective Optimization**: Implements weighted MCDA with Pareto analysis
- **Normalization Algorithms**: Robust scaling across diverse value ranges
- **Constraint Satisfaction**: Complex filtering with multiple simultaneous constraints

### 🏗️ Software Engineering Excellence
- **Clean Architecture**: Proper separation of domain, data, and presentation layers
- **SOLID Principles**: Maintainable, testable, and extensible codebase
- **Type Safety**: Comprehensive use of Dart's type system with code generation

### 🚀 Performance & Scalability
- **Mobile Optimization**: Efficient algorithms designed for mobile constraints
- **Intelligent Caching**: Hash-based deduplication and opinion score caching
- **Asynchronous Processing**: Non-blocking UI with concurrent API calls

### 🌐 Real-World Integration
- **Enterprise Auth**: Auth0 integration for production-ready authentication
- **Cloud Database**: MongoDB Atlas for scalable community data
- **API Orchestration**: Multiple external services (Nutritionix, Edamam, Gemini)

## 📊 Code Statistics

```dart
// Core algorithm example - Multi-criteria optimization
Future<ParetoFrontier> optimize(List<MenuItem> items, OptimizationRequest request) async {
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

  return ParetoFrontier(results: results.sorted(), frontierPoints: _calculateParetoFrontier(results));
}
```

## 🎯 Impact & Innovation

**MenuMax** represents a convergence of cutting-edge AI, mathematical optimization, and mobile engineering to solve a real-world problem that affects millions of people daily. By combining computer vision, multi-criteria decision analysis, and community intelligence, we've created a tool that doesn't just recommend food—it empowers users to make mathematically optimal decisions aligned with their personal goals.

## 📄 License

This project was created for **PennApps 2025** and demonstrates advanced integration of generative AI, optimization algorithms, and mobile development best practices.

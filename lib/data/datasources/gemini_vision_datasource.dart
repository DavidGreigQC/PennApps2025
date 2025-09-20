import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:camera/camera.dart';
import '../../domain/entities/menu_item.dart';

/// Gemini Vision API integration for superior OCR capabilities
/// This replaces traditional OCR with AI-powered vision understanding
class GeminiVisionDataSource {
  static const String _apiKey = 'YOUR_GEMINI_API_KEY'; // Replace with actual API key
  late GenerativeModel _model;

  /// Initialize Gemini Vision model
  void initialize() {
    _model = GenerativeModel(
      model: 'gemini-pro-vision',
      apiKey: _apiKey,
    );
    print('🤖 Gemini Vision initialized successfully!');
  }

  /// **CAMERA OCR**: Extract menu items from camera image using Gemini Vision
  /// This is the prize-winning feature - AI-powered menu scanning!
  Future<List<MenuItem>> extractMenuFromCamera(XFile imageFile) async {
    try {
      print('📸 Processing camera image with Gemini Vision...');

      final imageBytes = await imageFile.readAsBytes();
      final result = await _analyzeMenuImage(imageBytes);

      print('✅ Gemini Vision extracted ${result.length} menu items');
      return result;

    } catch (e) {
      print('❌ Gemini Vision camera OCR error: $e');
      return [];
    }
  }

  /// **FILE OCR**: Extract menu items from uploaded image using Gemini Vision
  Future<List<MenuItem>> extractMenuFromFile(String filePath) async {
    try {
      print('📄 Processing uploaded image with Gemini Vision...');

      final file = File(filePath);
      final imageBytes = await file.readAsBytes();
      final result = await _analyzeMenuImage(imageBytes);

      print('✅ Gemini Vision extracted ${result.length} menu items');
      return result;

    } catch (e) {
      print('❌ Gemini Vision file OCR error: $e');
      return [];
    }
  }

  /// **AI MENU ANALYSIS**: Core Gemini Vision processing
  Future<List<MenuItem>> _analyzeMenuImage(Uint8List imageBytes) async {
    try {
      final prompt = TextPart('''
Analyze this menu image and extract ALL menu items with their prices in JSON format.

Instructions:
1. Look for food/drink items with prices
2. Extract the exact item names and prices
3. Include descriptions if visible
4. Ignore headers, restaurant info, and non-food text
5. Format prices as numbers (e.g., 5.99 not "\$5.99")

Return ONLY a JSON array in this exact format:
[
  {
    "name": "Item Name",
    "price": 5.99,
    "description": "Optional description if visible"
  }
]

If no menu items are found, return an empty array: []
''');

      final imagePart = DataPart('image/jpeg', imageBytes);
      final content = [Content.multi([prompt, imagePart])];

      final response = await _model.generateContent(content);
      final responseText = response.text?.trim() ?? '';

      print('🤖 Gemini Vision raw response: $responseText');

      return _parseGeminiResponse(responseText);

    } catch (e) {
      print('❌ Gemini Vision analysis error: $e');
      return [];
    }
  }

  /// **SMART MENU CONVERSATION**: Ask Gemini questions about the menu
  /// Bonus feature for enhanced user experience
  Future<String> askAboutMenu(Uint8List imageBytes, String question) async {
    try {
      final prompt = TextPart('''
You are a helpful menu assistant. Look at this menu image and answer the user's question: "$question"

Provide a helpful, concise answer about the menu items, prices, or recommendations based on what you can see in the image.
''');

      final imagePart = DataPart('image/jpeg', imageBytes);
      final content = [Content.multi([prompt, imagePart])];

      final response = await _model.generateContent(content);
      return response.text?.trim() ?? 'I could not analyze the menu image.';

    } catch (e) {
      print('❌ Gemini menu conversation error: $e');
      return 'Sorry, I encountered an error analyzing the menu.';
    }
  }

  /// **ENHANCED DESCRIPTION**: Get AI-generated descriptions for menu items
  Future<String> enhanceMenuItemDescription(String itemName, Uint8List imageBytes) async {
    try {
      final prompt = TextPart('''
Look at this menu image and find the item "$itemName".
Provide a detailed, appetizing description of this menu item based on what you can see.
Include ingredients, preparation style, and what makes it appealing.
Keep it under 50 words and food-focused.
''');

      final imagePart = DataPart('image/jpeg', imageBytes);
      final content = [Content.multi([prompt, imagePart])];

      final response = await _model.generateContent(content);
      return response.text?.trim() ?? '';

    } catch (e) {
      print('❌ Gemini description enhancement error: $e');
      return '';
    }
  }

  /// Parse Gemini's JSON response into MenuItem objects
  List<MenuItem> _parseGeminiResponse(String responseText) {
    try {
      // Clean the response - remove markdown formatting if present
      String cleanedResponse = responseText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Handle case where Gemini returns explanation + JSON
      if (cleanedResponse.contains('[')) {
        final jsonStart = cleanedResponse.indexOf('[');
        final jsonEnd = cleanedResponse.lastIndexOf(']') + 1;
        cleanedResponse = cleanedResponse.substring(jsonStart, jsonEnd);
      }

      final List<dynamic> jsonList = json.decode(cleanedResponse);

      return jsonList.map((item) {
        final Map<String, dynamic> itemMap = item as Map<String, dynamic>;

        return MenuItem(
          name: itemMap['name']?.toString() ?? '',
          price: _parsePrice(itemMap['price']),
          description: itemMap['description']?.toString(),
        );
      }).where((item) => item.name.isNotEmpty && item.price > 0).toList();

    } catch (e) {
      print('❌ Error parsing Gemini response: $e');
      print('Raw response: $responseText');

      // Fallback: try to extract items manually using regex
      return _fallbackParseResponse(responseText);
    }
  }

  /// Fallback parsing if JSON parsing fails
  List<MenuItem> _fallbackParseResponse(String text) {
    try {
      List<MenuItem> items = [];

      // Look for patterns like "Item Name - $5.99" or "Item Name $5.99"
      final itemPattern = RegExp(r'([A-Z][^$\n]*?)\s*[-–]?\s*\$?(\d+\.?\d*)',
                               caseSensitive: false);

      final matches = itemPattern.allMatches(text);

      for (final match in matches) {
        final name = match.group(1)?.trim() ?? '';
        final priceStr = match.group(2) ?? '0';
        final price = double.tryParse(priceStr) ?? 0.0;

        if (name.isNotEmpty && price > 0) {
          items.add(MenuItem(name: name, price: price));
        }
      }

      return items;
    } catch (e) {
      print('❌ Fallback parsing failed: $e');
      return [];
    }
  }

  /// Parse price from various formats
  double _parsePrice(dynamic priceValue) {
    if (priceValue is num) {
      return priceValue.toDouble();
    }

    if (priceValue is String) {
      // Remove currency symbols and parse
      final cleanPrice = priceValue.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleanPrice) ?? 0.0;
    }

    return 0.0;
  }
}

/// Camera service for live menu scanning
class CameraMenuScanner {
  CameraController? _controller;
  List<CameraDescription>? _cameras;

  /// Initialize camera
  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras!.first,
          ResolutionPreset.high,
        );
        await _controller!.initialize();
        print('📷 Camera initialized successfully!');
      }
    } catch (e) {
      print('❌ Camera initialization error: $e');
    }
  }

  /// Capture image for menu scanning
  Future<XFile?> captureMenuImage() async {
    try {
      if (_controller != null && _controller!.value.isInitialized) {
        return await _controller!.takePicture();
      }
      return null;
    } catch (e) {
      print('❌ Image capture error: $e');
      return null;
    }
  }

  /// Get camera controller for preview
  CameraController? get controller => _controller;

  /// Dispose camera resources
  void dispose() {
    _controller?.dispose();
  }
}
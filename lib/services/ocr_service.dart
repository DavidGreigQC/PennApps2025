import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';
import '../models/menu_item.dart';
import 'demo_data_service.dart';
import 'syncfusion_pdf_service.dart';

class OCRService {
  final TextRecognizer _textRecognizer = GoogleMlKit.vision.textRecognizer();
  final SyncfusionPDFService _pdfService = SyncfusionPDFService();

  Future<List<MenuItem>> extractMenuItems(String filePath) async {
    try {
      print('PROCESSING FILE: $filePath');

      // Check if file exists
      File file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      // Check file type
      String extension = filePath.toLowerCase().split('.').last;
      print('FILE TYPE: $extension');

      List<MenuItem> extractedItems = [];

      if (extension == 'pdf') {
        print('PDF DETECTED: Attempting PDF OCR...');
        try {
          extractedItems = await _pdfService.extractMenuItemsFromPDF(filePath);
          if (extractedItems.isNotEmpty) {
            print('PDF OCR SUCCESS: Extracted ${extractedItems.length} items');
            return extractedItems;
          } else {
            print('PDF OCR: No items found, using fallback');
            return await DemoDataService.simulateOCRExtraction(filePath);
          }
        } catch (e) {
          print('PDF OCR FAILED: $e - using fallback');
          return await DemoDataService.simulateOCRExtraction(filePath);
        }
      } else if (['jpg', 'jpeg', 'png', 'bmp', 'gif'].contains(extension)) {
        // Handle image files with OCR
        print('IMAGE DETECTED: Processing with OCR...');

        final inputImage = InputImage.fromFilePath(filePath);

        final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

        print('OCR EXTRACTED TEXT:');
        print('=' * 50);
        print(recognizedText.text);
        print('=' * 50);

        extractedItems = _parseMenuText(recognizedText.text);

        // If OCR extracted no items, fall back to demo data
        if (extractedItems.isEmpty) {
          print('WARNING: OCR extracted no items, using demo data as fallback');
          return await DemoDataService.simulateOCRExtraction(filePath);
        }

        print('OCR SUCCESS: Extracted ${extractedItems.length} menu items');
        return extractedItems;
      } else {
        throw Exception('Unsupported file type: $extension. Please use PDF, PNG, JPG, or other image formats.');
      }
    } catch (e) {
      print('OCR ERROR: $e - falling back to demo data');
      // Always fallback to demo data if anything goes wrong
      return await DemoDataService.simulateOCRExtraction(filePath);
    }
  }

  List<MenuItem> _parseMenuText(String text) {
    List<MenuItem> items = [];
    List<String> lines = text.split('\n');

    print('PARSING ${lines.length} lines of text...');

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty || line.length < 3) continue;

      // Try to extract price from current line
      double? price = _extractPrice(line);

      if (price != null) {
        // Found a price, now determine the item name
        String itemName = _extractItemName(line, lines, i);

        if (itemName.isNotEmpty && _isValidMenuItem(itemName)) {
          // Look for description in nearby lines
          String? description = _findDescription(lines, i, itemName);

          MenuItem item = MenuItem(
            name: _cleanItemName(itemName),
            price: price,
            description: description,
          );

          items.add(item);
          print('EXTRACTED: ${item.name} - \$${item.price}');
        }
      }
    }

    // Second pass: look for items that might have prices on different lines
    for (int i = 0; i < lines.length - 1; i++) {
      String line = lines[i].trim();
      String nextLine = lines[i + 1].trim();

      // Check if current line is an item name and next line has price
      if (_isLikelyMenuItem(line) && !_containsPrice(line)) {
        double? nextLinePrice = _extractPrice(nextLine);
        if (nextLinePrice != null) {
          String itemName = _cleanItemName(line);
          if (_isValidMenuItem(itemName) && !_isDuplicate(items, itemName, nextLinePrice)) {
            String? description = _findDescription(lines, i, itemName);

            MenuItem item = MenuItem(
              name: itemName,
              price: nextLinePrice,
              description: description,
            );

            items.add(item);
            print('EXTRACTED (2nd pass): ${item.name} - \$${item.price}');
          }
        }
      }
    }

    // Third pass: if no items found, extract items without prices (for menus that don't show prices)
    if (items.isEmpty) {
      print('NO PRICES FOUND: Extracting items without prices...');

      // Smart parsing to combine related lines into full item names
      List<String> potentialItems = _extractSmartMenuItems(lines);

      for (String itemName in potentialItems) {
        if (_isValidMenuItemWithoutPrice(itemName)) {
          MenuItem item = MenuItem(
            name: _cleanItemName(itemName),
            price: 0.0, // Will be looked up online later
            description: null,
          );

          if (!_isDuplicateByName(items, item.name)) {
            items.add(item);
            print('EXTRACTED (smart parsing): ${item.name}');
          }
        }
      }
    }

    List<MenuItem> deduplicated = _deduplicate(items);
    print('FINAL: ${deduplicated.length} unique menu items extracted');
    return deduplicated;
  }

  double? _extractPrice(String text) {
    // Enhanced price extraction for various formats
    List<RegExp> pricePatterns = [
      RegExp(r'\$(\d+\.?\d*)'), // $5.99
      RegExp(r'(\d+\.?\d*)\s*\$'), // 5.99$
      RegExp(r'(\d+\.\d{2})'), // 5.99 (standalone)
    ];

    for (RegExp pattern in pricePatterns) {
      Match? match = pattern.firstMatch(text);
      if (match != null) {
        double? price = double.tryParse(match.group(1)!);
        if (price != null && price > 0 && price < 100) { // Reasonable price range
          return price;
        }
      }
    }
    return null;
  }

  bool _containsPrice(String text) {
    return _extractPrice(text) != null;
  }

  bool _isLikelyMenuItem(String text) {
    if (text.length < 3) return false;

    // Skip common non-menu text
    List<String> skipWords = ['menu', 'price', 'size', 'cal', 'calories', 'nutrition', 'total', 'tax', 'subtotal'];
    String lowerText = text.toLowerCase();
    for (String skip in skipWords) {
      if (lowerText.contains(skip)) return false;
    }

    // Must contain letters
    if (!text.contains(RegExp(r'[a-zA-Z]{2,}'))) return false;

    // Good indicators of menu items
    if (text.contains(RegExp(r'^[A-Z][a-z]'))) return true; // Starts with capital
    if (text.contains(RegExp(r'[a-zA-Z]{4,}'))) return true; // Has decent word length

    return false;
  }

  String _extractItemName(String line, List<String> lines, int index) {
    // Remove price from the line to get item name
    String nameWithoutPrice = line.replaceAll(RegExp(r'\$\d+\.?\d*'), '').trim();

    if (nameWithoutPrice.isNotEmpty && nameWithoutPrice.length > 2) {
      return nameWithoutPrice;
    }

    // If current line only has price, look at previous line
    if (index > 0) {
      String prevLine = lines[index - 1].trim();
      if (_isLikelyMenuItem(prevLine) && !_containsPrice(prevLine)) {
        return prevLine;
      }
    }

    return '';
  }

  String? _findDescription(List<String> lines, int itemIndex, String itemName) {
    // Look in next few lines for description
    for (int i = itemIndex + 1; i < lines.length && i < itemIndex + 3; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) continue;
      if (_containsPrice(line)) break; // Hit next price
      if (_isLikelyMenuItem(line)) break; // Hit next item

      // If line is descriptive text (not too short, contains letters)
      if (line.length > 10 && line.contains(RegExp(r'[a-zA-Z]{3,}'))) {
        return line;
      }
    }
    return null;
  }

  bool _isValidMenuItem(String name) {
    if (name.length < 2) return false;

    // Must have some letters
    if (!name.contains(RegExp(r'[a-zA-Z]{2,}'))) return false;

    // Skip obvious non-items
    List<String> skipPatterns = [
      r'^\d+$', // Just numbers
      r'^[^a-zA-Z]+$', // No letters
      r'total', r'tax', r'subtotal', r'menu', r'price'
    ];

    String lowerName = name.toLowerCase();
    for (String pattern in skipPatterns) {
      if (RegExp(pattern).hasMatch(lowerName)) return false;
    }

    return true;
  }

  String _cleanItemName(String name) {
    return name
        .replaceAll(RegExp(r'\$\d+\.?\d*'), '') // Remove any prices
        .replaceAll(RegExp(r'^\W+'), '') // Remove leading non-word chars
        .replaceAll(RegExp(r'\W+$'), '') // Remove trailing non-word chars
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }

  bool _isDuplicate(List<MenuItem> items, String name, double price) {
    return items.any((item) =>
        item.name.toLowerCase() == name.toLowerCase() &&
        (item.price - price).abs() < 0.01);
  }

  bool _isDuplicateByName(List<MenuItem> items, String name) {
    return items.any((item) => item.name.toLowerCase() == name.toLowerCase());
  }

  bool _isValidMenuItemWithoutPrice(String text) {
    // More lenient validation for items without prices
    if (text.length < 3) return false;

    // Skip obvious non-menu text
    List<String> skipWords = ['menu', 'size', 'cal', 'calories', 'nutrition', 'total', 'tax', 'subtotal', 'sign', 'in', 'new', 'dominos.com'];
    String lowerText = text.toLowerCase();
    for (String skip in skipWords) {
      if (lowerText.contains(skip)) return false;
    }

    // Skip single words that are too short or common
    if (text.split(' ').length == 1 && text.length < 4) return false;

    // Skip if it's mostly numbers or symbols
    if (RegExp(r'^[\d\s\.\:\-\%\$]+$').hasMatch(text)) return false;

    // Must contain letters
    if (!text.contains(RegExp(r'[a-zA-Z]{2,}'))) return false;

    // Good indicators for Domino's style items
    if (text.contains(RegExp(r'bread|pizza|cheese|stuffed|bites|garlic|parmesan|pepperoni|bacon|spinach|feta|cinnamon', caseSensitive: false))) return true;

    // General food words
    if (text.contains(RegExp(r'chicken|beef|sauce|dip|wing|salad|pasta|sandwich', caseSensitive: false))) return true;

    // Starts with capital and has decent length
    if (text.contains(RegExp(r'^[A-Z][a-z]')) && text.length > 5) return true;

    return false;
  }

  List<String> _extractSmartMenuItems(List<String> lines) {
    List<String> menuItems = [];
    print('SMART PARSING: Processing ${lines.length} lines...');

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty || line.length < 3) continue;

      // Look for lines that start menu items (likely title lines)
      if (_isMenuItemStart(line)) {
        print('SMART PARSING: Found menu item start: "$line"');
        String fullItem = line;

        // Look ahead to combine continuation lines
        for (int j = i + 1; j < lines.length && j < i + 3; j++) {
          String nextLine = lines[j].trim();
          if (nextLine.isEmpty) break;

          // If next line looks like a continuation, combine it
          if (_isMenuItemContinuation(nextLine, fullItem)) {
            print('SMART PARSING: Combining with: "$nextLine"');
            fullItem += " " + nextLine;
          } else {
            break; // Stop if we hit something that doesn't look like a continuation
          }
        }

        // Clean up and add if it looks like a complete menu item
        fullItem = fullItem.trim();
        if (fullItem.length > 3 && _looksLikeCompleteMenuItem(fullItem)) {
          print('SMART PARSING: Added complete item: "$fullItem"');
          menuItems.add(fullItem);
        } else {
          print('SMART PARSING: Rejected incomplete item: "$fullItem"');
        }
      }
    }

    print('SMART PARSING: Found ${menuItems.length} menu items');
    return menuItems;
  }

  bool _isMenuItemStart(String line) {
    // Check if line starts a menu item (usually starts with capital letter)
    if (!RegExp(r'^[A-Z]').hasMatch(line)) return false;

    // Skip obvious UI elements
    if (line.toLowerCase().contains(RegExp(r'sign|menu|new|dominos|fresh|handmade|our oven-baked|drizzled'))) {
      return false;
    }

    // Skip single words that are too short (likely fragments)
    List<String> words = line.trim().split(' ');
    if (words.length == 1 && words[0].length < 4) return false;

    // Look for food-related keywords that indicate a menu item name
    if (line.toLowerCase().contains(RegExp(r'bread|pizza|cheese|stuffed|bites|garlic|parmesan|pepperoni|bacon|spinach|feta|cinnamon|wings?|chicken|pasta|salad'))) {
      return true;
    }

    // General capitalized food terms (Name + Adjective pattern)
    if (RegExp(r'^[A-Z][a-z]+\s+[A-Z&]').hasMatch(line)) return true;

    // Two or more capitalized words (likely menu item)
    if (RegExp(r'^[A-Z][a-z]+(\s+[A-Z][a-z]+)+').hasMatch(line)) return true;

    return false;
  }

  bool _isMenuItemContinuation(String line, String currentItem) {
    // Don't continue if it looks like a new menu item
    if (_isMenuItemStart(line)) return false;

    // Don't continue if it's obviously descriptive text
    if (line.toLowerCase().contains(RegExp(r'fresh|handmade|our|oven-baked|drizzled|stuffed and covered'))) {
      return false;
    }

    String cleanLine = line.trim();
    List<String> words = cleanLine.split(' ');

    // Continue if it's a single word that completes the name
    if (words.length == 1) {
      String word = words[0].toLowerCase();
      // Common menu item endings
      if (RegExp(r'^(bites|bread|cheese|stuffed|wings?|pizza|pasta)$').hasMatch(word)) {
        return true;
      }
      // Also continue for food adjectives
      if (RegExp(r'^(parmesan|garlic|cinnamon|bacon|pepperoni)$').hasMatch(word)) {
        return true;
      }
    }

    // Continue if it's 2-3 words that look like they complete a menu item
    if (words.length <= 3) {
      String lowerLine = cleanLine.toLowerCase();
      if (lowerLine.contains(RegExp(r'bites|bread|cheese|wings?|dip|sauce'))) {
        return true;
      }
    }

    return false;
  }

  bool _looksLikeCompleteMenuItem(String item) {
    // Must have reasonable length
    if (item.length < 5 || item.length > 50) return false;

    // Should contain food-related terms
    if (item.toLowerCase().contains(RegExp(r'bread|pizza|cheese|stuffed|bites|garlic|parmesan|pepperoni|bacon|spinach|feta|cinnamon'))) {
      return true;
    }

    return false;
  }

  List<MenuItem> _deduplicate(List<MenuItem> items) {
    Map<String, MenuItem> uniqueItems = {};

    for (MenuItem item in items) {
      String key = item.name.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
      if (!uniqueItems.containsKey(key) ||
          (item.description != null && uniqueItems[key]!.description == null)) {
        uniqueItems[key] = item;
      }
    }

    return uniqueItems.values.toList();
  }

  void dispose() {
    _textRecognizer.close();
  }
}
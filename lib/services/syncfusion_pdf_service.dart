import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/menu_item.dart';

class SyncfusionPDFService {
  Future<List<MenuItem>> extractMenuItemsFromPDF(String pdfPath) async {
    try {
      print('SYNCFUSION PDF: Starting extraction from $pdfPath');

      // Read the PDF file
      final File file = File(pdfPath);
      final List<int> bytes = await file.readAsBytes();

      // Load the PDF document
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      StringBuffer allText = StringBuffer();

      // Extract text from all pages
      for (int i = 0; i < document.pages.count; i++) {
        print('SYNCFUSION PDF: Processing page ${i + 1}/${document.pages.count}');

        try {
          // Extract text from current page
          final PdfTextExtractor extractor = PdfTextExtractor(document);
          final String pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);

          if (pageText.isNotEmpty) {
            allText.writeln(pageText);
            print('SYNCFUSION PDF: Extracted ${pageText.length} chars from page ${i + 1}');
          }
        } catch (e) {
          print('SYNCFUSION PDF: Error processing page ${i + 1}: $e');
          continue; // Skip problematic pages
        }
      }

      // Dispose the document
      document.dispose();

      String extractedText = allText.toString();
      print('SYNCFUSION PDF: Total text length: ${extractedText.length} characters');

      // Debug: Print first 500 characters of extracted text
      print('SYNCFUSION PDF: Sample extracted text:');
      print('=' * 50);
      print(extractedText.length > 500 ? extractedText.substring(0, 500) + '...' : extractedText);
      print('=' * 50);

      if (extractedText.trim().isEmpty) {
        throw Exception('No text extracted from PDF');
      }

      // Parse the extracted text for menu items
      List<MenuItem> items = _parseMenuText(extractedText);

      print('SYNCFUSION PDF: Successfully extracted ${items.length} menu items');
      return items;

    } catch (e) {
      print('SYNCFUSION PDF: Error - $e');
      throw Exception('Failed to extract text from PDF: $e');
    }
  }

  List<MenuItem> _parseMenuText(String text) {
    List<MenuItem> items = [];
    List<String> lines = text.split('\n');

    print('SYNCFUSION PDF: Parsing ${lines.length} lines of text...');

    // Debug: Print first 10 lines to see structure
    print('SYNCFUSION PDF: First 10 lines:');
    for (int i = 0; i < lines.length && i < 10; i++) {
      print('Line $i: "${lines[i].trim()}"');
    }

    // First pass: look for lines with prices
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty || line.length < 3) continue;

      // Try to extract price from current line
      double? price = _extractPrice(line);

      if (price != null) {
        print('SYNCFUSION PDF: Found price $price in line: "$line"');
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
          print('SYNCFUSION PDF: Found item - ${item.name} (\$${item.price})');
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
            print('SYNCFUSION PDF: Found item (2nd pass) - ${item.name} (\$${item.price})');
          }
        }
      }
    }

    // Third pass: if no prices found, extract menu items with estimated prices
    if (items.isEmpty) {
      print('SYNCFUSION PDF: No prices found, extracting items with estimated prices...');
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i].trim();
        if (line.isEmpty || line.length < 3) continue;

        if (_isLikelyMenuItem(line)) {
          String itemName = _cleanItemName(line);
          if (_isValidMenuItem(itemName) && !_isDuplicateByName(items, itemName)) {
            // Estimate price based on McDonald's typical pricing
            double estimatedPrice = _estimateMcDonaldsPrice(itemName);

            MenuItem item = MenuItem(
              name: itemName,
              price: estimatedPrice,
              description: 'Price estimated based on typical McDonald\'s pricing',
            );

            items.add(item);
            print('SYNCFUSION PDF: Found item (estimated price) - ${item.name} (\$${item.price})');
          }
        }
      }
    }

    List<MenuItem> deduplicated = _deduplicateItems(items);
    print('SYNCFUSION PDF: Final result: ${deduplicated.length} unique menu items');
    return deduplicated;
  }

  double? _extractPrice(String text) {
    // Enhanced price extraction for various formats including McDonald's
    List<RegExp> pricePatterns = [
      RegExp(r'\$(\d+\.\d{2})'), // $5.99 (exact format)
      RegExp(r'\$(\d+)'), // $5 (whole dollar)
      RegExp(r'(\d+\.\d{2})\s*\$'), // 5.99$
      RegExp(r'(\d+)\s*\$'), // 5$
      RegExp(r'(\d+\.\d{2})(?!\d)'), // 5.99 (standalone, not part of larger number)
      RegExp(r'\b(\d+\.\d{2})\b'), // 5.99 with word boundaries
      RegExp(r'(\d{1,2}\.\d{2})(?=\s|$)'), // 1-2 digits with 2 decimal places
    ];

    for (RegExp pattern in pricePatterns) {
      Match? match = pattern.firstMatch(text);
      if (match != null) {
        double? price = double.tryParse(match.group(1)!);
        if (price != null && price > 0.50 && price < 50) { // McDonald's typical price range
          return price;
        }
      }
    }
    return null;
  }

  bool _containsPrice(String text) => _extractPrice(text) != null;

  bool _isLikelyMenuItem(String text) {
    if (text.length < 3) return false;

    String lowerText = text.toLowerCase();

    // Skip common non-menu text
    List<String> skipWords = [
      'menu', 'price', 'size', 'cal', 'calories', 'nutrition', 'total',
      'tax', 'subtotal', 'page', 'mcdonald', 'limited', 'time', 'offer',
      'available', 'participating', 'restaurants', 'prices', 'may', 'vary',
      'copyright', 'reserved', 'rights', 'corp', 'company'
    ];

    for (String skip in skipWords) {
      if (lowerText.contains(skip)) return false;
    }

    // Must contain letters
    if (!text.contains(RegExp(r'[a-zA-Z]{2,}'))) return false;

    // McDonald's specific positive indicators
    List<String> mcdonaldsItems = [
      'big mac', 'quarter pounder', 'mcchicken', 'filet-o-fish', 'nuggets',
      'fries', 'mccafe', 'shake', 'pie', 'hash brown', 'mcmuffin', 'hotcakes',
      'burger', 'sandwich', 'chicken', 'beef', 'crispy', 'deluxe', 'spicy'
    ];

    for (String item in mcdonaldsItems) {
      if (lowerText.contains(item)) return true;
    }

    // Good indicators of menu items
    if (text.contains(RegExp(r'^[A-Z][a-z]'))) return true; // Starts with capital
    if (text.contains(RegExp(r'[a-zA-Z]{4,}'))) return true; // Has decent word length

    return false;
  }

  String _extractItemName(String line, List<String> lines, int index) {
    // Remove price from the line to get item name (enhanced patterns)
    String nameWithoutPrice = line
        .replaceAll(RegExp(r'\$\d+\.\d{2}'), '') // $5.99
        .replaceAll(RegExp(r'\$\d+'), '') // $5
        .replaceAll(RegExp(r'\d+\.\d{2}\s*\$'), '') // 5.99$
        .replaceAll(RegExp(r'\d+\s*\$'), '') // 5$
        .replaceAll(RegExp(r'\b\d+\.\d{2}\b'), '') // standalone 5.99
        .trim();

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
      r'total', r'tax', r'subtotal', r'menu', r'price', r'page'
    ];

    String lowerName = name.toLowerCase();
    for (String pattern in skipPatterns) {
      if (RegExp(pattern).hasMatch(lowerName)) return false;
    }

    return true;
  }

  String _cleanItemName(String name) {
    return name
        .replaceAll(RegExp(r'\$\d+\.\d{2}'), '') // Remove $5.99
        .replaceAll(RegExp(r'\$\d+'), '') // Remove $5
        .replaceAll(RegExp(r'\d+\.\d{2}\s*\$'), '') // Remove 5.99$
        .replaceAll(RegExp(r'\d+\s*\$'), '') // Remove 5$
        .replaceAll(RegExp(r'\b\d+\.\d{2}\b'), '') // Remove standalone 5.99
        .replaceAll(RegExp(r'^\W+'), '') // Remove leading non-word chars
        .replaceAll(RegExp(r'\W+$'), '') // Remove trailing non-word chars
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .replaceAll(RegExp(r'^\d+'), '') // Remove leading numbers
        .trim();
  }

  bool _isDuplicate(List<MenuItem> items, String name, double price) {
    return items.any((item) =>
        item.name.toLowerCase() == name.toLowerCase() &&
        (item.price - price).abs() < 0.01);
  }

  bool _isDuplicateByName(List<MenuItem> items, String name) {
    return items.any((item) =>
        item.name.toLowerCase() == name.toLowerCase());
  }

  double _estimateMcDonaldsPrice(String itemName) {
    String lowerName = itemName.toLowerCase();

    // Big items and premium sandwiches
    if (lowerName.contains('big mac') || lowerName.contains('quarter pounder')) {
      return 6.99;
    }
    if (lowerName.contains('double quarter')) {
      return 8.99;
    }
    if (lowerName.contains('premium') || lowerName.contains('prem.') ||
        lowerName.contains('grilled chicken') || lowerName.contains('crispy chicken')) {
      return 7.49;
    }

    // Specialty items
    if (lowerName.contains('filet-o-fish') || lowerName.contains('mcrib')) {
      return 5.99;
    }
    if (lowerName.contains('mcchicken')) {
      return 4.99;
    }

    // Basic burgers
    if (lowerName.contains('double cheeseburger')) {
      return 3.99;
    }
    if (lowerName.contains('cheeseburger')) {
      return 2.99;
    }
    if (lowerName.contains('hamburger')) {
      return 2.49;
    }

    // Nuggets and sides
    if (lowerName.contains('nuggets')) {
      return 5.49;
    }
    if (lowerName.contains('fries')) {
      return 2.99;
    }

    // Default price for other items
    return 5.99;
  }

  List<MenuItem> _deduplicateItems(List<MenuItem> items) {
    Map<String, MenuItem> uniqueItems = {};

    for (MenuItem item in items) {
      String key = '${item.name.toLowerCase()}_${item.price.toStringAsFixed(2)}';
      if (!uniqueItems.containsKey(key)) {
        uniqueItems[key] = item;
      }
    }

    return uniqueItems.values.toList();
  }
}
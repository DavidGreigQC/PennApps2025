import '../models/menu_item.dart';

class DemoDataService {
  static List<MenuItem> getSampleMenuItems() {
    // McDonald's-style menu items for realistic fallback
    return [
      MenuItem(
        name: "Big Mac",
        price: 5.99,
        description: "Two all-beef patties, special sauce, lettuce, cheese, pickles, onions on a sesame seed bun",
        protein: 25.0,
        calories: 550.0,
        carbs: 45.0,
        fat: 33.0,
        fiber: 3.0,
        sodium: 1010.0,
        sugar: 9.0,
        category: "Burgers",
      ),
      MenuItem(
        name: "Quarter Pounder with Cheese",
        price: 6.49,
        description: "Quarter pound of 100% beef, cheese, pickles, onions, ketchup, mustard",
        protein: 30.0,
        calories: 520.0,
        carbs: 40.0,
        fat: 26.0,
        fiber: 3.0,
        sodium: 1120.0,
        sugar: 10.0,
        category: "Burgers",
      ),
      MenuItem(
        name: "McChicken",
        price: 4.29,
        description: "Crispy chicken patty with lettuce and mayo on a bun",
        protein: 14.0,
        calories: 400.0,
        carbs: 40.0,
        fat: 22.0,
        fiber: 2.0,
        sodium: 560.0,
        sugar: 5.0,
        category: "Chicken",
      ),
      MenuItem(
        name: "10 Piece Chicken McNuggets",
        price: 4.49,
        description: "Tender white meat chicken in a crispy coating",
        protein: 23.0,
        calories: 470.0,
        carbs: 30.0,
        fat: 30.0,
        fiber: 2.0,
        sodium: 900.0,
        sugar: 0.0,
        category: "Chicken",
      ),
      MenuItem(
        name: "Medium French Fries",
        price: 2.89,
        description: "Golden crispy fries with a hint of salt",
        protein: 4.0,
        calories: 320.0,
        carbs: 43.0,
        fat: 15.0,
        fiber: 4.0,
        sodium: 260.0,
        sugar: 0.0,
        category: "Sides",
      ),
      MenuItem(
        name: "Egg McMuffin",
        price: 4.19,
        description: "English muffin with egg, Canadian bacon, and cheese",
        protein: 17.0,
        calories: 310.0,
        carbs: 30.0,
        fat: 13.0,
        fiber: 2.0,
        sodium: 820.0,
        sugar: 3.0,
        category: "Breakfast",
      ),
      MenuItem(
        name: "McCafe Premium Roast Coffee (Medium)",
        price: 1.00,
        description: "100% Arabica beans roasted to perfection",
        protein: 1.0,
        calories: 5.0,
        carbs: 0.0,
        fat: 0.0,
        fiber: 0.0,
        sodium: 5.0,
        sugar: 0.0,
        category: "Beverages",
      ),
      MenuItem(
        name: "Apple Slices",
        price: 1.29,
        description: "Fresh apple slices with caramel dip",
        protein: 0.0,
        calories: 15.0,
        carbs: 4.0,
        fat: 0.0,
        fiber: 0.0,
        sodium: 0.0,
        sugar: 3.0,
        category: "Sides",
      ),
    ];
  }

  static Future<List<MenuItem>> simulateOCRExtraction(String filePath) async {
    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 2));

    // FALLBACK: Return McDonald's-style menu items when OCR fails or for PDFs
    List<MenuItem> extractedItems = getSampleMenuItems();

    String fileName = filePath.split('/').last;
    bool isPdf = fileName.toLowerCase().endsWith('.pdf');

    if (isPdf) {
      print('PDF FALLBACK: $fileName - PDF OCR requires additional setup');
      print('PDF FALLBACK: For now, using McDonald\'s menu items as example');
      print('PDF FALLBACK: Try uploading PNG/JPG images for real OCR');
    } else {
      print('OCR FALLBACK: Failed to extract items from: $fileName');
      print('OCR FALLBACK: Using ${extractedItems.length} McDonald\'s-style menu items instead');
      print('OCR FALLBACK: Try a clearer image or different format');
    }

    return extractedItems;
  }
}
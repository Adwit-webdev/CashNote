import 'package:shared_preferences/shared_preferences.dart';

class HistoryService {
  // Save an item to history
  static Future<void> saveItem(String name, double price) async {
    if (name.isEmpty || price <= 0) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Save Price Memory: "Maggi" -> 14.0
    await prefs.setDouble('price_$name', price);

    // 2. Add to Recent List (Set ensures uniqueness)
    List<String> history = prefs.getStringList('recent_items') ?? [];
    history.remove(name); // Remove duplicate if exists
    history.insert(0, name); // Add to top
    if (history.length > 10) history = history.sublist(0, 10); // Keep only top 10
    
    await prefs.setStringList('recent_items', history);
  }

  // Get remembered price
  static Future<double> getPrice(String name) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('price_$name') ?? 0.0;
  }

  // Get quick-add suggestions
  static Future<List<String>> getRecents() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('recent_items') ?? [];
  }
}
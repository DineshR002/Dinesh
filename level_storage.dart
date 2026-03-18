import 'package:shared_preferences/shared_preferences.dart';

class LevelStorage {
  static const String _key = "highest_unlocked_level";

  // Save highest unlocked level
  static Future<void> saveLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    int currentLevel = prefs.getInt(_key) ?? 1;

    // Only update if new level is higher
    if (level > currentLevel) {
      await prefs.setInt(_key, level);
    }
  }

  // Get highest unlocked level
  static Future<int> getLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 1;
  }

  // Reset (optional)
  static Future<void> resetLevel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, 1);
  }
}
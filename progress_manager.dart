import 'package:shared_preferences/shared_preferences.dart';

class ProgressManager {

  // -----------------------------
  // 🔑 STORAGE KEYS
  // -----------------------------
  static const String _unlockedLevelKey = "unlocked_level";
  static const String _currentGroupKey = "current_group";
  static const String _learningPhaseKey = "learning_phase";
  static const String _tapAssessmentKey = "tap_assessment";
  static const String _flipGameKey = "flip_game_unlocked";

  // =====================================================
  // 🔓 LEVEL UNLOCK SYSTEM (FIXED)
  // =====================================================

  static Future<int> getUnlockedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_unlockedLevelKey) ?? 1;
  }

  /// 🔥 SAFE UNLOCK (NO SKIPPING LEVELS)
  static Future<void> unlockNextLevel(int completedLevel) async {
    final prefs = await SharedPreferences.getInstance();

    int unlocked = prefs.getInt(_unlockedLevelKey) ?? 1;

    // Only unlock next if the completed level is the current unlocked level
    if (completedLevel == unlocked && unlocked < 5) {
      await prefs.setInt(_unlockedLevelKey, unlocked + 1);
    }
  }

  static Future<void> unlockLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_unlockedLevelKey) ?? 1;

    if (level == current + 1 && level <= 5) {
      await prefs.setInt(_unlockedLevelKey, level);
    }
  }

  static Future<bool> isLevelUnlocked(int level) async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_unlockedLevelKey) ?? 1;
    return level <= current;
  }

  static Future<void> resetLevels() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_unlockedLevelKey, 1);
  }

  // =====================================================
  // 📍 CURRENT GROUP SAVE / LOAD
  // =====================================================

  static Future<void> saveCurrentGroup(int group) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentGroupKey, group);
  }

  static Future<int> getCurrentGroup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentGroupKey) ?? 1;
  }

  // =====================================================
  // 📘 LEARNING PHASE SAVE / LOAD
  // =====================================================

  static Future<void> saveLearningPhase(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_learningPhaseKey, value);
  }

  static Future<bool> getLearningPhase() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_learningPhaseKey) ?? true;
  }

  // =====================================================
  // 📝 TAP ASSESSMENT SAVE / LOAD
  // =====================================================

  static Future<void> saveTapAssessment(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tapAssessmentKey, value);
  }

  static Future<bool> getTapAssessment() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tapAssessmentKey) ?? true;
  }

  // =====================================================
  // 🎮 FLIP GAME SAVE / LOAD
  // =====================================================

  static Future<void> saveFlipGameUnlocked(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_flipGameKey, value);
  }

  static Future<bool> getFlipGameUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_flipGameKey) ?? false;
  }

  // =====================================================
  // 🔄 RESET EVERYTHING
  // =====================================================

  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
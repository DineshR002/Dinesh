import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PerformanceManager {
  static const String _key = "premium_performance_data";
  static Map<String, dynamic>? _cachedData;

  /// ==============================
  /// PRIVATE: SAVE ANY ATTEMPT
  /// ==============================
  static Future<void> _saveAttempt({
    required int group,
    required String type, // "learning", "tap", "drag"
    required List<String> achievedLetters,
    List<String>? unsatisfiedLetters,
    required int timeTaken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final Map<String, dynamic> data =
    raw != null ? jsonDecode(raw) : {"assessments": {}};

    data["assessments"] ??= {};
    data["assessments"]["$group"] ??= {};
    data["assessments"]["$group"][type] ??= [];

    final List<Map<String, dynamic>> attempts =
    List<Map<String, dynamic>>.from(data["assessments"]["$group"][type]);

    attempts.add({
      "achievedLetters": achievedLetters,
      "unsatisfiedLetters": unsatisfiedLetters ?? [],
      "time": timeTaken,
      "attempt": attempts.length + 1,
    });

    data["assessments"]["$group"][type] = attempts;
    _cachedData = data;
    await prefs.setString(_key, jsonEncode(data));
  }

  /// ==============================
  /// SAVE LEARNING PERFORMANCE
  /// ==============================
  static Future<void> saveLearningPerformance({
    required int group,
    required List<String> achievedLetters,
    required int timeTaken,
  }) async =>
      _saveAttempt(
        group: group,
        type: 'learning',
        achievedLetters: achievedLetters,
        unsatisfiedLetters: [],
        timeTaken: timeTaken,
      );

  /// ==============================
  /// SAVE TAP / DRAG ATTEMPT
  /// ==============================
  static Future<void> saveAttempt({
    required int group,
    required String type,
    required List<String> achievedLetters,
    required List<String> unsatisfiedLetters,
    required int timeTaken,
  }) async =>
      _saveAttempt(
        group: group,
        type: type,
        achievedLetters: achievedLetters,
        unsatisfiedLetters: unsatisfiedLetters,
        timeTaken: timeTaken,
      );

  /// ==============================
  /// 🔹 ADDED: GET OVERALL STATS (FOR UI)
  /// ==============================
  static Future<Map<String, dynamic>> getOverallStats(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final Map<String, dynamic> data =
        _cachedData ?? (raw != null ? jsonDecode(raw) : {"assessments": {}});

    double totalTime = 0;
    int totalAttempts = 0;
    int groupsAttempted = 0;

    if (data["assessments"] != null) {
      data["assessments"].forEach((group, value) {
        final List attempts = value[type] ?? [];
        if (attempts.isNotEmpty) groupsAttempted++;
        for (var a in attempts) {
          totalTime += (a["time"] ?? 0).toDouble();
          totalAttempts++;
        }
      });
    }

    int progressPercentage = ((groupsAttempted / 5) * 100).round();
    double avgTime = totalAttempts > 0 ? totalTime / totalAttempts : 0;

    return {
      "progress": progressPercentage,
      "averageTime": avgTime,
    };
  }

  /// ==============================
  /// 🔹 ADDED: GET GROUP STATS (FOR UI)
  /// ==============================
  static Future<Map<String, dynamic>> getGroupStats(int group, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final Map<String, dynamic> data =
        _cachedData ?? (raw != null ? jsonDecode(raw) : {"assessments": {}});

    final groupData = data["assessments"]?["$group"]?[type] ?? [];

    if (groupData.isEmpty) {
      return {
        "achieved": 0,
        "unsatisfied": 0,
        "time": 0,
        "averageTime": 0,
        "accuracy": "0"
      };
    }

    final latest = groupData.last;
    List achieved = latest["achievedLetters"] ?? [];
    List unsatisfied = latest["unsatisfiedLetters"] ?? [];
    int time = (latest["time"] as num).toInt();

    int totalCount = achieved.length + unsatisfied.length;
    double accuracy = totalCount > 0 ? (achieved.length / totalCount) * 100 : 0;

    return {
      "achieved": achieved.length,
      "unsatisfied": unsatisfied.length,
      "time": time,
      "averageTime": totalCount > 0 ? time / totalCount : 0,
      "accuracy": accuracy.toStringAsFixed(1),
    };
  }

  /// ==============================
  /// GET ASSESSMENT ATTEMPTS
  /// ==============================
  static Future<List<Map<String, dynamic>>> getAttempts(
      int group, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final Map<String, dynamic> data =
        _cachedData ?? (raw != null ? jsonDecode(raw) : {"assessments": {}});

    if (data["assessments"]?[group.toString()]?[type] == null) return [];

    final List attempts = data["assessments"][group.toString()][type];

    return attempts.map<Map<String, dynamic>>((a) {
      final List<String> achieved = List<String>.from(a["achievedLetters"] ?? []);
      final List<String> unsatisfied = List<String>.from(a["unsatisfiedLetters"] ?? []);
      final int time = (a["time"] as num).toInt();
      final int attempt = (a["attempt"] as num).toInt();
      final int totalLetters = achieved.length + unsatisfied.length;
      final double accuracy =
      totalLetters == 0 ? 0 : (achieved.length / totalLetters) * 100;

      return {
        "achievedLetters": achieved,
        "unsatisfiedLetters": unsatisfied,
        "achieved": achieved.length,
        "unsatisfied": unsatisfied.length,
        "time": time,
        "attempt": attempt,
        "accuracy": accuracy.toStringAsFixed(1),
      };
    }).toList();
  }

  /// ==============================
  /// GET OVERALL LEARNING PERFORMANCE
  /// ==============================
  static Future<Map<String, dynamic>> getOverallLearning() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final Map<String, dynamic> data =
        _cachedData ?? (raw != null ? jsonDecode(raw) : {"assessments": {}});

    Set<String> learnedLetters = {};
    int totalTime = 0;
    int totalAttempts = 0;

    if (data["assessments"] != null) {
      data["assessments"].forEach((group, value) {
        final learningAttempts =
            (value as Map<String, dynamic>)["learning"] as List? ?? [];
        for (var a in learningAttempts) {
          final List<String> letters = List<String>.from(a["achievedLetters"]);
          learnedLetters.addAll(letters); // track all letters learned
          totalTime += (a["time"] as num).toInt();
          totalAttempts++;
        }
      });
    }

    final double averageTime =
    totalAttempts == 0 ? 0 : totalTime / totalAttempts;

    final int totalLetters = 26; // always 26 letters total
    final double accuracy =
    totalLetters == 0 ? 0 : (learnedLetters.length / totalLetters) * 100;

    return {
      "letters": "${learnedLetters.length}/$totalLetters",
      "achieved": learnedLetters.length,
      "time": totalTime,
      "averageTime": averageTime.toStringAsFixed(1),
      "accuracy": accuracy.toStringAsFixed(1),
    };
  }

  /// ==============================
  /// GET ASSESSMENT STATS PER SET
  /// ==============================
  static Future<Map<String, dynamic>> getAssessmentStats(
      int group, String type, {int? totalLettersInSet}) async {
    final attempts = await getAttempts(group, type);

    Set<String> achievedLetters = {};
    Set<String> unsatisfiedLetters = {};
    int totalTime = 0;

    for (var a in attempts) {
      achievedLetters.addAll(List<String>.from(a["achievedLetters"] ?? []));
      unsatisfiedLetters.addAll(List<String>.from(a["unsatisfiedLetters"] ?? []));
      totalTime += a["time"] as int;
    }

    final int totalLetters =
        totalLettersInSet ?? achievedLetters.length + unsatisfiedLetters.length;
    final double averageTime = attempts.isEmpty ? 0 : totalTime / attempts.length;
    final double accuracy =
    totalLetters == 0 ? 0 : (achievedLetters.length / totalLetters) * 100;

    return {
      "letters": "${achievedLetters.length}/$totalLetters",
      "achieved": achievedLetters.length,
      "unsatisfied": unsatisfiedLetters.length,
      "time": totalTime,
      "averageTime": averageTime.toStringAsFixed(1),
      "accuracy": accuracy.toStringAsFixed(1),
    };
  }

  /// ==============================
  /// GET LEARNING PROGRESS FOR CHART
  /// ==============================
  static Future<List<Map<String, dynamic>>> getLearningProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final Map<String, dynamic> data =
        _cachedData ?? (raw != null ? jsonDecode(raw) : {"assessments": {}});

    List<Map<String, dynamic>> progress = [];

    if (data["assessments"] != null) {
      data["assessments"].forEach((group, value) {
        final List learningAttempts =
            (value as Map<String, dynamic>)["learning"] ?? [];
        for (var a in learningAttempts) {
          progress.add({
            "group": group,
            "attempt": a["attempt"],
            "achieved": (a["achievedLetters"] as List).length,
            "time": a["time"]
          });
        }
      });
    }

    return progress;
  }

  /// ==============================
  /// CLEAR ALL DATA
  /// ==============================
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedData = null;
    await prefs.remove(_key);
  }
}
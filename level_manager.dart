import 'package:flutter/material.dart';
import 'progress_manager.dart';
import 'learning_page_group.dart';
import 'assessment_page.dart';
import 'dragdrop_page.dart';

class LevelManager {

  /// -----------------------------
  /// 🔹 CURRENT STATE
  /// -----------------------------
  static int currentGroup = 1;
  static bool inLearningPhase = true;
  static bool isTapAssessment = true;
  static bool flipGameUnlocked = false;

  /// -----------------------------
  /// 🔹 NAVIGATION CONTROLLER
  /// -----------------------------
  static void goToPhase(BuildContext context) {
    if (inLearningPhase) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LearningPageGroup(
            groupIndex: currentGroup,
          ),
        ),
      );
      return;
    }

    if (isTapAssessment) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AssessmentPageGroup1(
            groupIndex: currentGroup,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DragDropAssessment(
            level: currentGroup,
          ),
        ),
      );
    }
  }

  /// -----------------------------
  /// 🔹 TAP → DRAGDROP
  /// -----------------------------
  static Future<void> moveToNextAssessment() async {
    isTapAssessment = false;
    await saveState(); // ✅ SAVE HERE
  }

  /// -----------------------------
  /// 🔹 NEXT GROUP (CRITICAL FIX)
  /// -----------------------------
  static Future<void> nextGroup() async {
    if (currentGroup < 5) {
      currentGroup++;
      inLearningPhase = true;
      isTapAssessment = true;
    } else {
      flipGameUnlocked = true;
    }

    await saveState(); // ✅ VERY IMPORTANT
  }

  static bool isLastGroup() {
    return currentGroup >= 5;
  }

  /// -----------------------------
  /// 🔹 SAVE STATE
  /// -----------------------------
  static Future<void> saveState() async {
    await ProgressManager.saveCurrentGroup(currentGroup);
    await ProgressManager.saveLearningPhase(inLearningPhase);
    await ProgressManager.saveTapAssessment(isTapAssessment);
    await ProgressManager.saveFlipGameUnlocked(flipGameUnlocked);
  }

  /// -----------------------------
  /// 🔹 LOAD STATE
  /// -----------------------------
  static Future<void> loadSavedProgress() async {
    currentGroup = await ProgressManager.getCurrentGroup();
    inLearningPhase = await ProgressManager.getLearningPhase();
    isTapAssessment = await ProgressManager.getTapAssessment();
    flipGameUnlocked = await ProgressManager.getFlipGameUnlocked();
  }

  /// -----------------------------
  /// 🔹 RESET EVERYTHING
  /// -----------------------------
  static Future<void> reset() async {
    currentGroup = 1;
    inLearningPhase = true;
    isTapAssessment = true;
    flipGameUnlocked = false;

    await ProgressManager.resetAll();
  }
}
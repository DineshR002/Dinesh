import 'package:flutter/material.dart';
import 'level_manager.dart';
import 'intro.dart';
import 'progress_manager.dart';
import 'completed_set_page.dart'; // ✅ import the separate page

class CelebrationPage extends StatefulWidget {
  final int level;
  final int correctAnswers;
  final int totalQuestions;
  final String assessmentType;

  // NEW RESULT DATA
  final int achieved;
  final int unsatisfactory;
  final int timeTaken;

  const CelebrationPage({
    super.key,
    required this.level,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.assessmentType,
    required this.achieved,
    required this.unsatisfactory,
    required this.timeTaken,
  });

  @override
  State<CelebrationPage> createState() => _CelebrationPageState();
}

class _CelebrationPageState extends State<CelebrationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> scaleAnim;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    scaleAnim = CurvedAnimation(
      parent: controller,
      curve: Curves.elasticOut,
    );

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// Format time in minutes and seconds
  String formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    if (minutes > 0 && seconds > 0) {
      return "$minutes min $seconds sec";
    } else if (minutes > 0 && seconds == 0) {
      return "$minutes min";
    } else {
      return "$seconds sec";
    }
  }

  /// Returns completed set letters for a level
  String getCompletedSetForLevel(int level) {
    switch (level) {
      case 1:
        return "A–E";
      case 2:
        return "F–J";
      case 3:
        return "K–O";
      case 4:
        return "P–T";
      case 5:
        return "U–Z";
      default:
        return "";
    }
  }

  /// Navigate to next phase or completed set page
  void goNext() async {
    if (widget.assessmentType == "tap") {
      LevelManager.inLearningPhase = false;
      LevelManager.isTapAssessment = false;
      LevelManager.goToPhase(context);
      return;
    }

    await ProgressManager.unlockNextLevel(LevelManager.currentGroup);
    await LevelManager.saveState();

    final completedSet = getCompletedSetForLevel(LevelManager.currentGroup);

    // Navigate to Completed Set Page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CompletedSetPage(
          completedSet: completedSet,
          isLastGroup: LevelManager.isLastGroup(),
          nextLevel: LevelManager.currentGroup,
        ),
      ),
    );
  }

  void retry() {
    LevelManager.goToPhase(context);
  }

  @override
  Widget build(BuildContext context) {
    final passed = widget.correctAnswers >= (widget.totalQuestions * 0.6);
    final accuracy =
    ((widget.achieved / widget.totalQuestions) * 100).toStringAsFixed(1);
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              isPortrait
                  ? "assets/portrait/cele.png" // your celebration background
                  : "assets/background/but.png",
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: scaleAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    passed ? "Great Job!" : "Not Bad, Try Again",
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  /// ROW 1
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        "Achieved: ${widget.achieved}",
                        style: const TextStyle(fontSize: 20, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  /// ROW 2
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cancel, color: Colors.red),
                      const SizedBox(width: 6),
                      Text(
                        "unsatisfactory: ${widget.unsatisfactory}",
                        style: const TextStyle(fontSize: 20, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  /// ROW 3
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.percent, color: Colors.yellow),
                      const SizedBox(width: 6),
                      Text(
                        "Accuracy: $accuracy%",
                        style: const TextStyle(fontSize: 20, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  /// ROW 4
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text(
                        "Time: ${formatTime(widget.timeTaken)}",
                        style: const TextStyle(fontSize: 20, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  /// BUTTONS
                  /// BUTTONS

                  if (widget.achieved > widget.unsatisfactory)
                    ElevatedButton(
                      onPressed: goNext,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        "NEXT",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),

                  if (widget.achieved < widget.unsatisfactory)
                    ElevatedButton(
                      onPressed: retry,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        "Reinforcement",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
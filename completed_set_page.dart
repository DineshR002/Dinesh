import 'package:flutter/material.dart';
import 'level_manager.dart';
import 'intro.dart';

class CompletedSetPage extends StatelessWidget {
  final String completedSet;
  final bool isLastGroup;
  final int nextLevel;

  const CompletedSetPage({
    super.key,
    required this.completedSet,
    required this.isLastGroup,
    required this.nextLevel,
  });

  void goNext(BuildContext context) {
    if (isLastGroup) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => IntroPage(level: nextLevel),
        ),
      );
    } else {
      LevelManager.nextGroup();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => IntroPage(level: LevelManager.currentGroup),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Single background image
          Positioned.fill(
            child: Image.asset(
              "assets/background/monk2.png",
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 30),
                  const Text(
                    "Assessment Completed",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Completed letters set
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      completedSet,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  ElevatedButton(
                    onPressed: () => goNext(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      "NEXT",
                      style: TextStyle(fontSize: 16),
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
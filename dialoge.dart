import 'package:flutter/material.dart';
import 'level_manager.dart';

class LearningCompletePage extends StatelessWidget {
  final int group;

  const LearningCompletePage({
    super.key,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {

    final groups = [
      ['A', 'B', 'C', 'D', 'E'],
      ['F', 'G', 'H', 'I', 'J'],
      ['K', 'L', 'M', 'N', 'O'],
      ['P', 'Q', 'R', 'S', 'T'],
      ['U', 'V', 'W', 'X', 'Y', 'Z'],
    ];

    final letters = groups[group - 1];

    return Scaffold(
      body: Stack(
        children: [

          /// Background
          Positioned.fill(
            child: Image.asset(
              "assets/background/but.png",
              fit: BoxFit.cover,
            ),
          ),

          /// Content
          Align(
            alignment: const Alignment(0, -0.10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                /// TEXT BOX
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 26, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 8,
                      )
                    ],
                  ),
                  child: Column(
                    children: [

                      /// A-E Learning
                      Text(
                        "${letters.first}-${letters.last} Learning",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 8),

                      /// Completed
                      const Text(
                        "Completed",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                /// Button (unchanged)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    elevation: 10,
                    shadowColor: Colors.deepOrangeAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 34, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    LevelManager.goToPhase(context);
                  },
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  label: const Text(
                    "START ASSESSMENT",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
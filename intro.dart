import 'package:flutter/material.dart';
import 'progress_manager.dart';
import 'level_manager.dart';
import 'learning_page.dart';
import 'memory_flip_game.dart';
import 'performance_page.dart';

class IntroPage extends StatefulWidget {
  final int level;

  const IntroPage({
    super.key,
    required this.level,
  });

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  int unlockedLevel = 1;
  bool flipUnlocked = false;
  bool isLoading = true; // ✅ important

  @override
  void initState() {
    super.initState();
    loadProgress();
  }

  Future<void> loadProgress() async {
    final level = await ProgressManager.getUnlockedLevel();
    final flip = await ProgressManager.getFlipGameUnlocked();

    if (!mounted) return;

    setState(() {
      unlockedLevel = level;
      flipUnlocked = flip;
      LevelManager.flipGameUnlocked = flip;
      isLoading = false; // ✅ UI builds only after loading
    });
  }

  void _openLearning(BuildContext context, int group) {
    LevelManager.currentGroup = group;
    LevelManager.inLearningPhase = true;
    LevelManager.isTapAssessment = true;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LearningPageGroup(),
      ),
    ).then((_) => loadProgress());
  }

  Widget buildGridItem(String path, int level, double height) {
    bool isGame = level == 6;
    bool isPerformance = level == 7;

    bool unlocked;

    if (isPerformance) {
      unlocked = true;
    } else if (isGame) {
      unlocked = flipUnlocked;
    } else {
      unlocked = level <= unlockedLevel;
    }

    return SizedBox(
      height: height,
      child: GestureDetector(
        onTap: unlocked
            ? () {
          if (isPerformance) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PerformancePage(),
              ),
            );
          } else if (isGame) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FinalMemoryFlipGame(),
              ),
            );
          } else {
            _openLearning(context, level);
          }
        }
            : null,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              path,
              height: height * 0.90,
              fit: BoxFit.contain,
            ),
            if (!unlocked)
              const Icon(
                Icons.lock,
                size: 40,
                color: Colors.white,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final orientation = MediaQuery.of(context).orientation;

    return Scaffold(
      body: Stack(
        children: [

          Positioned.fill(
            child: Image.asset(
              orientation == Orientation.landscape
                  ? "assets/background/blurma.png"
                  : "assets/por/intro.png",
              fit: BoxFit.cover,
            ),
          ),

          // ✅ CENTER BOAT IMAGE
          Center(
            child: Image.asset(
              "assets/background/ls.png", // your boat png path
              width: MediaQuery.of(context).size.width * 0.32,
              fit: BoxFit.contain,
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {

                double screenHeight = constraints.maxHeight;
                double rowHeight = screenHeight / 4;

                return Column(
                  children: [

                    SizedBox(
                      height: rowHeight,
                      child: Row(
                        children: [
                          Expanded(
                            child: buildGridItem(
                                "assets/background/e.png",
                                1,
                                rowHeight),
                          ),
                          Expanded(
                            child: buildGridItem(
                                "assets/background/p.png",
                                4,
                                rowHeight),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(
                      height: rowHeight,
                      child: Row(
                        children: [
                          Expanded(
                            child: buildGridItem(
                                "assets/background/f.png",
                                2,
                                rowHeight),
                          ),
                          Expanded(
                            child: buildGridItem(
                                "assets/background/u.png",
                                5,
                                rowHeight),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(
                      height: rowHeight,
                      child: Row(
                        children: [
                          Expanded(
                            child: buildGridItem(
                                "assets/background/k.png",
                                3,
                                rowHeight),
                          ),
                          Expanded(
                            child: buildGridItem(
                                "assets/background/gam.png",
                                6,
                                rowHeight),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(
                      height: rowHeight,
                      child: Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.6,
                          child: buildGridItem(
                              "assets/background/per.png",
                              7,
                              rowHeight),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'level_manager.dart';

class FinalMemoryFlipGame extends StatefulWidget {
  const FinalMemoryFlipGame({super.key});

  @override
  State<FinalMemoryFlipGame> createState() => _FinalMemoryFlipGameState();
}

class _FinalMemoryFlipGameState extends State<FinalMemoryFlipGame> {
  final AudioPlayer player = AudioPlayer();

  int level = 1;
  int score = 0;
  bool soundOn = true;
  bool lock = false;

  late List<String> cards;
  List<int> opened = [];
  List<int> matched = [];

  final Map<int, List<String>> levelLetters = {
    1: ['A', 'B'],
    2: ['C', 'D', 'M'],
    3: ['P', 'G', 'O', 'S', 'L', 'T'],
  };

  final Map<String, String> pairMap = {
    'A': 'apple',
    'B': 'banana',
    'C': 'cherry',
    'D': 'dragonfruit',
    'M': 'mango',
    'P': 'pineapple',
    'G': 'grapes',
    'O': 'orange',
    'S': 'strawberry',
    'L': 'lychee',
    'T': 'tayberry',
  };

  @override
  void initState() {
    super.initState();
    loadLevel();
  }

  void loadLevel() {
    List<String> letters = levelLetters[level]!;
    List<String> fruits = letters.map((l) => pairMap[l]!).toList();

    cards = [...letters, ...fruits];
    cards.shuffle();

    opened.clear();
    matched.clear();
    lock = false;

    setState(() {});
  }

  bool isMatch(String a, String b) {
    return pairMap[a] == b || pairMap[b] == a;
  }

  Future<void> playSound(String file) async {
    if (!soundOn) return;
    await player.play(AssetSource("audio/$file"));
  }

  Future<void> onTap(int index) async {
    if (lock || opened.contains(index) || matched.contains(index)) return;

    await playSound("flip.mp3");

    setState(() {
      opened.add(index);
    });

    if (opened.length < 2) return;

    lock = true;

    int first = opened[0];
    int second = opened[1];

    if (isMatch(cards[first], cards[second])) {
      await playSound("correct.mp3");

      setState(() {
        matched.addAll([first, second]);
        opened.clear();
      });

      if (matched.length == cards.length) {
        await Future.delayed(const Duration(milliseconds: 600));
        levelComplete();
      }
    } else {
      await playSound("incorrect.mp3");
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() {
        opened.clear();
      });
    }

    lock = false;
  }

  Future<void> levelComplete() async {
    await LevelManager.saveState();
    if (level == 1) score = 20;
    if (level == 2) score = 40;
    if (level == 3) score = 100;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              "assets/portrait/end.gif", // 🔥 YOUR GIF HERE
              height: 120,
            ),
            const SizedBox(height: 15),
            Text(
              level < 3
                  ? "LEVEL $level COMPLETED "
                  : "GAME COMPLETED 🏆",
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Score: $score",
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),

            if (level < 3)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  level++;
                  loadLevel();
                },
                child: const Text("COMPLETED"),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background/fish.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              const SizedBox(height: 10),

// TITLE BOX
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "KIDS FLIP GAME",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 2,
                  ),
                ),
              ),

              const SizedBox(height: 15),

// LEVEL + SCORE ROW
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    // LEVEL BOX
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "LEVEL $level",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),

                    // SCORE BOX
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "SCORE $score",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: Center(
                  child: SizedBox(
                    width: isLandscape ? 420 : 300,
                    child: GridView.builder(
                      physics:
                      const NeverScrollableScrollPhysics(),
                      itemCount: cards.length,
                      gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                        level == 1 ? 2 : 3,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () => onTap(index),
                          child: FlipCard(
                            open: opened.contains(index) ||
                                matched.contains(index),
                            matched:
                            matched.contains(index),
                            text: cards[index],
                            isLetter:
                            pairMap.containsKey(
                                cards[index]),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FlipCard extends StatefulWidget {
  final bool open;
  final bool matched;
  final String text;
  final bool isLetter;

  const FlipCard({
    super.key,
    required this.open,
    required this.matched,
    required this.text,
    required this.isLetter,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  final List<List<Color>> gradients = [
    [Color(0xFFE3F2FD), Color(0xFFD0E8FF)],
    [Color(0xFFE8F5E9), Color(0xFFD0F0D6)],

  ];

  late List<Color> selectedGradient;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400));
    animation =
        Tween(begin: 0.0, end: pi).animate(controller);

    selectedGradient =
    gradients[Random().nextInt(gradients.length)];
  }

  @override
  void didUpdateWidget(covariant FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open) {
      controller.forward();
    } else {
      controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        double angle = animation.value;
        bool showFront = angle > pi / 2;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: showFront
              ? Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..rotateY(pi),
            child: Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: selectedGradient,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(2, 3),
                    )
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    widget.isLetter
                        ? "assets/letters/${widget.text}.png"
                        : "assets/fruits/${widget.text}.png",
                    width: 85,
                    height: 85,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          )
              : ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              "assets/background/cg.png",
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

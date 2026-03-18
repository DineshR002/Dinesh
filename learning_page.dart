import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'level_manager.dart';
import 'performance_manager.dart';
import 'progress_manager.dart';
import 'dialoge.dart';
// ✅ ADDED



class LearningPageGroup extends StatefulWidget {
  const LearningPageGroup({super.key});

  @override
  State<LearningPageGroup> createState() => _LearningPageGroupState();
}

class _LearningPageGroupState extends State<LearningPageGroup>
    with SingleTickerProviderStateMixin {
  final FlutterTts tts = FlutterTts();

  late AnimationController _bounceController;
  late Animation<Offset> _bounceAnimation;

  final List<List<String>> letterGroups = [
    ['A', 'B', 'C', 'D', 'E'],
    ['F', 'G', 'H', 'I', 'J'],
    ['K', 'L', 'M', 'N', 'O'],
    ['P', 'Q', 'R', 'S', 'T'],
    ['U', 'V', 'W', 'X', 'Y', 'Z'],
  ];

  final Map<String, String> fruits = {
    'A': 'apple',
    'B': 'banana',
    'C': 'cherry',
    'D': 'dragonfruit',
    'E': 'elderberry',
    'F': 'fig',
    'G': 'grapes',
    'H': 'honeydew',
    'I': 'iceapple',
    'J': 'jackfruit',
    'K': 'kiwi',
    'L': 'lychee',
    'M': 'mango',
    'N': 'nance',
    'O': 'orange',
    'P': 'pineapple',
    'Q': 'quince',
    'R': 'raspberry',
    'S': 'strawberry',
    'T': 'tayberry',
    'U': 'ugli',
    'V': 'vanilla',
    'W': 'watermelon',
    'X': 'xingzi',
    'Y': 'yuzu',
    'Z': 'ziziphus',
  };

  int index = 0;
  bool showFruit = false;
  int tapCount = 0;
  Timer? waitTimer;

  // ✅ PERFORMANCE VARIABLES
  int participatedLetters = 0;
  int achievedLetters = 0;
  late DateTime letterStartTime;
  int totalTimeSpent = 0;

  List<String> get letters =>
      letterGroups[LevelManager.currentGroup - 1];

  @override
  void initState() {
    super.initState();

    tts.setLanguage("en-US");          // more stable voice
    tts.setSpeechRate(0.45);           // normal speed (0.38 is slightly slow)
    tts.setPitch(1.0);                 // natural pitch
    tts.setVolume(1.0);                // full volume
    tts.awaitSpeakCompletion(true);    // prevents overlap

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<Offset>(
      begin: const Offset(0, -0.05),
      end: const Offset(0, 0.05),
    ).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // ✅ START TIMER
    letterStartTime = DateTime.now();
  }

  @override
  void dispose() {
    waitTimer?.cancel();
    _bounceController.dispose();
    tts.stop();
    super.dispose();
  }

  Future<void> speak(String text) async {
    await tts.stop();              // stop previous speech
    await tts.speak(text);         // speak
  }

  Future<void> handleTap(String letter, String fruitName) async {
    if (showFruit) return;

    waitTimer?.cancel();

    setState(() {
      showFruit = true;
      tapCount++;
    });

    await speak("$letter is for $fruitName");

    waitTimer = Timer(const Duration(seconds: 5), () async {
      if (tapCount < 3) {
        setState(() {
          showFruit = false;
        });
      } else {
        tapCount = 0;
        nextLetter();
      }
    });
  }

  Future<void> nextLetter() async {
    waitTimer?.cancel();

    // ✅ CALCULATE TIME PER LETTER
    int timeSpent =
        DateTime.now().difference(letterStartTime).inSeconds;

    totalTimeSpent += timeSpent;
    participatedLetters++;
    achievedLetters++;

    if (index < letters.length - 1) {
      setState(() {
        index++;
        showFruit = false;
      });

      // restart timer
      letterStartTime = DateTime.now();
    } else {
      // 🔥 UNLOCK NEXT LEVEL PERMANENTLY
      await ProgressManager.unlockNextLevel(LevelManager.currentGroup);

      // ✅ SAVE LEARNING PERFORMANCE
      List<String> achievedLetters = letters; // save real letters of group

      await PerformanceManager.saveLearningPerformance(
        group: LevelManager.currentGroup,
        achievedLetters: achievedLetters,
        timeTaken: totalTimeSpent,
      );

      LevelManager.inLearningPhase = false;
      await LevelManager.saveState();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LearningCompletePage(
            group: LevelManager.currentGroup,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;

    return orientation == Orientation.landscape
        ? _buildLandscape(context)
        : _buildPortrait(context);
  }

  Widget _buildLandscape(BuildContext context) {
    final letter = letters[index];
    final fruitName = fruits[letter]!;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "${letters.first}–${letters.last}  LEARNING",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background/fall.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 80),
            _progressDots(),
            Expanded(
              child: Center(
                child: _learningContent(
                  bigLetter: size.width * 0.18,
                  fruitSize: size.width * 0.16,
                  letter: letter,
                  fruitName: fruitName,
                ),
              ),
            ),
            _nextButton(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPortrait(BuildContext context) {
    final letter = letters[index];
    final fruitName = fruits[letter]!;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/portrait/learn.png",
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _progressDots(),
                Expanded(
                  child: Center(
                    child: _learningContent(
                      bigLetter: size.width * 0.35,
                      fruitSize: size.width * 0.30,
                      letter: letter,
                      fruitName: fruitName,
                    ),
                  ),
                ),
                _nextButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        letters.length,
            (i) => Container(
          margin: const EdgeInsets.all(6),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i == index ? Colors.orange : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  Widget _learningContent({
    required double bigLetter,
    required double fruitSize,
    required String letter,
    required String fruitName,
  }) {
    return GestureDetector(
      onTap: () => handleTap(letter, fruitName),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: showFruit
            ? Column(
          key: const ValueKey("fruit"),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
        Image.asset(
        "assets/letters/${letter.toUpperCase()}.png",
        height: bigLetter,
      ),

                const SizedBox(width: 16),
                Image.asset(
                  "assets/fruits/$fruitName.png",
                  height: fruitSize,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              "$letter is for ${fruitName.toUpperCase()}",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
                letterSpacing: 2,
              ),
            ),
          ],
        )
            : SlideTransition(
          key: const ValueKey("letter"),
          position: _bounceAnimation,
          child: Image.asset(
            "assets/letters/${letter.toLowerCase()}.png",
            height: bigLetter,
          ),
        ),
      ),
    );
  }

  Widget _nextButton() {
    return SizedBox(
      width: 160,
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepOrange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: nextLetter,
        icon: const Icon(Icons.arrow_forward),
        label: const Text(
          "NEXT",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
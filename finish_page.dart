import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'celebration_page.dart';
import 'progress_manager.dart';

class DragDropAssessment extends StatefulWidget {
  const DragDropAssessment({super.key});

  @override
  State<DragDropAssessment> createState() => _DragDropAssessmentState();
}

class _DragDropAssessmentState extends State<DragDropAssessment>
    with TickerProviderStateMixin {
  final FlutterTts tts = FlutterTts();
  final AudioPlayer audioPlayer = AudioPlayer();

  final Map<String, String> fruitMap = {
    'F': 'fig',
    'G': 'grapes',
    'H': 'honeydew',
    'I': 'iceapple',
    'J': 'jackfruit',
  };

  late List<String> letters;
  late List<String> shuffledFruits;

  int currentIndex = 0;
  String feedbackText = "";
  Color feedbackColor = Colors.transparent;

  late AnimationController popController;
  late AnimationController shakeController;
  late AnimationController confettiController;

  late Animation<double> popAnim;
  late Animation<double> shakeAnim;

  @override
  void initState() {
    super.initState();

    popController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    shakeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    confettiController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));

    popAnim = Tween<double>(begin: 1.0, end: 1.25)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(popController);

    shakeAnim = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(shakeController);

    tts.setLanguage("en-GB");
    tts.setSpeechRate(0.35);

    letters = fruitMap.keys.toList();
    shuffledFruits = fruitMap.values.toList()..shuffle(Random());
  }

  Future<void> speak(String text) async {
    await tts.stop();
    await tts.speak(text);
  }

  Future<void> checkMatch(String fruit) async {
    String currentLetter = letters[currentIndex];
    String correctFruit = fruitMap[currentLetter]!;

    if (fruit == correctFruit) {
      popController.forward(from: 0);
      setState(() {
        feedbackText = "✅ Correct! $currentLetter is for $correctFruit";
        feedbackColor = Colors.green;
      });

      await audioPlayer.play(AssetSource("audio/correct.mp3"));
      await speak("Correct! $currentLetter is for $correctFruit");

      currentIndex++;
      if (currentIndex >= letters.length) {
        confettiController.forward(from: 0);
        await Future.delayed(const Duration(milliseconds: 800));
        await ProgressManager.unlockLevel(3);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CelebrationPage(
              level: 2,
              correctAnswers: letters.length,
              totalQuestions: letters.length,
              assessmentType: "dragdrop",

              achieved: letters.length,
              unsatisfactory: 0,
              timeTaken: 0, // change later if you add timer
            ),
          ),
        );

      } else {
        setState(() {
          feedbackText = "";
          feedbackColor = Colors.transparent;
        });
      }
    } else {
      setState(() {
        feedbackText = "❌ Wrong! Try again.";
        feedbackColor = Colors.red;
      });
      shakeController.forward(from: 0);
      await audioPlayer.play(AssetSource("audio/incorrect.mp3"));
      await speak("Wrong! Try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // ✅ define sizes here
    final double letterSize = size.width * 0.18;
    final double fruitSize = size.width * 0.20;
    final String currentLetter = letters[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Match The Fruits"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Stack(
          children: [
            // Background
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/background/drag_bg.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Confetti
            IgnorePointer(
              child: AnimatedBuilder(
                animation: confettiController,
                builder: (context, child) {
                  if (!confettiController.isAnimating) return const SizedBox();
                  return CustomPaint(
                    size: MediaQuery.of(context).size,
                    painter: ConfettiPainter(confettiController.value),
                  );
                },
              ),
            ),

            // Main UI
            Column(
              children: [
                const SizedBox(height: 20),

                // Letter drag target
                Expanded(
                  child: Center(
                    child: DragTarget<String>(
                      onAccept: (fruit) => checkMatch(fruit),
                      builder: (context, candidateData, rejectedData) {
                        return ScaleTransition(
                          scale: popAnim,
                          child: AnimatedBuilder(
                            animation: shakeAnim,
                            builder: (context, child) {
                              double dx = shakeController.isAnimating
                                  ? sin(shakeAnim.value) * 6
                                  : 0;
                              return Transform.translate(
                                offset: Offset(dx, 0),
                                child: Container(
                                  width: letterSize + 40,
                                  height: letterSize + 40,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.blueAccent, width: 3),
                                    borderRadius: BorderRadius.circular(16),
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      "assets/letters/${currentLetter.toLowerCase()}.png",
                                      height: letterSize,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Fruits to drag
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    padding: const EdgeInsets.all(20),
                    children: shuffledFruits.map((fruit) {
                      return Draggable<String>(
                        data: fruit,
                        feedback: Image.asset(
                          "assets/fruits/$fruit.png",
                          height: fruitSize,
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.4,
                          child: Image.asset(
                            "assets/fruits/$fruit.png",
                            height: fruitSize,
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () => speak(fruit),
                          child: Image.asset(
                            "assets/fruits/$fruit.png",
                            height: fruitSize,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Feedback
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: feedbackColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: feedbackColor, width: 2),
                    ),
                    child: Text(
                      feedbackText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: feedbackColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    popController.dispose();
    shakeController.dispose();
    confettiController.dispose();
    super.dispose();
  }
}

// Confetti painter
class ConfettiPainter extends CustomPainter {
  final double progress;
  ConfettiPainter(this.progress);
  final Random rnd = Random();

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 120; i++) {
      final paint =
      Paint()..color = Colors.primaries[i % Colors.primaries.length];
      final x = rnd.nextDouble() * size.width;
      final y = progress * size.height * rnd.nextDouble();
      canvas.drawCircle(Offset(x, y), 4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
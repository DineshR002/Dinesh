import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'level_manager.dart';
import 'celebration_page.dart';
import 'progress_manager.dart';
import 'performance_manager.dart';
import 'package:confetti/confetti.dart';
import 'completed_set_page.dart';

class DragDropAssessment extends StatefulWidget {
  final int level;
  const DragDropAssessment({super.key, required this.level});

  @override
  State<DragDropAssessment> createState() => _DragDropAssessmentState();
}

class _DragDropAssessmentState extends State<DragDropAssessment>
    with TickerProviderStateMixin {
  late ConfettiController confettiController;
  bool showCelebration = false;
  Stopwatch stopwatch = Stopwatch();
  final FlutterTts tts = FlutterTts();
  final AudioPlayer player = AudioPlayer();

  late Map<String, String> fruitMap;
  late List<String> fruits;
  late Map<String, bool> matched;

  String feedbackText = "";
  String popupText = "";

  late AnimationController shakeController;
  late AnimationController handController;
  late AnimationController popupController;

  Offset handStart = Offset.zero;
  Offset handEnd = Offset.zero;
  bool showHand = false;
  bool showPopup = false;

  late String demoLetter;
  late String demoFruit;

  final Map<String, GlobalKey> fruitKeys = {};
  final Map<String, GlobalKey> letterKeys = {};

  bool isProcessing = false;

  late DateTime assessmentStartTime;
  List<String> achievedLetters = [];
  List<String> unsatisfiedLetters = [];

  // ✅ NEW: freeze matched fruits
  late Map<String, bool> fruitMatched;

  @override
  void initState() {
    super.initState();
    stopwatch.start();
    confettiController =
        ConfettiController(duration: const Duration(seconds: 4));

    assessmentStartTime = DateTime.now();

    switch (widget.level) {
      case 1:
        fruitMap = {'A':'apple','B':'banana','C':'cherry','D':'dragonfruit','E':'elderberry'};
        demoLetter = 'A';
        demoFruit = 'apple';
        break;
      case 2:
        fruitMap = {'F':'fig','G':'grapes','H':'honeydew','I':'iceapple','J':'jackfruit'};
        demoLetter = 'F';
        demoFruit = 'fig';
        break;
      case 3:
        fruitMap = {'K':'kiwi','L':'lychee','M':'mango','N':'nance','O':'orange'};
        demoLetter = 'K';
        demoFruit = 'kiwi';
        break;
      case 4:
        fruitMap = {'P':'pineapple','Q':'quince','R':'raspberry','S':'strawberry','T':'tayberry'};
        demoLetter = 'P';
        demoFruit = 'pineapple';
        break;
      case 5:
        fruitMap = {'U':'ugli','V':'vanilla','W':'watermelon','X':'xingzi','Y':'yuzu','Z':'ziziphus'};
        demoLetter = 'U';
        demoFruit = 'ugli';
        break;
      default:
        fruitMap = {};
        demoLetter = '';
        demoFruit = '';
    }

    fruits = fruitMap.values.toList()..shuffle();
    matched = {for (var k in fruitMap.keys) k: false};
    fruitMatched = {for (var f in fruitMap.values) f: false};

    for (var f in fruits) fruitKeys[f] = GlobalKey();
    for (var l in fruitMap.keys) letterKeys[l] = GlobalKey();

    shakeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    handController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));

    popupController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

    // ✅ Stable normal voice
    tts.setLanguage("en-US");
    tts.setSpeechRate(0.45);
    tts.setPitch(1.0);
    tts.setVolume(1.0);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await speak("Drag the fruit to the correct letter");
      _startHandDemo();
    });
  }

  void _startHandDemo() async {
    await Future.delayed(const Duration(milliseconds: 600));

    final fruitBox =
    fruitKeys[demoFruit]?.currentContext?.findRenderObject() as RenderBox?;
    final letterBox =
    letterKeys[demoLetter]?.currentContext?.findRenderObject() as RenderBox?;

    if (fruitBox == null || letterBox == null) return;

    final fruitPos = fruitBox.localToGlobal(fruitBox.size.center(Offset.zero));
    final letterPos = letterBox.localToGlobal(letterBox.size.center(Offset.zero));

    setState(() {
      handStart = fruitPos;
      handEnd = letterPos;
      showHand = true;
    });

    await handController.forward(from: 0);

    setState(() {
      showHand = false;
    });
  }

  Future<void> speak(String text) async {
    await tts.stop();
    await tts.awaitSpeakCompletion(true);
    await tts.speak(text);
  }

  void checkMatch(String letter, String fruit) async {
    if (isProcessing) return;
    isProcessing = true;

    String correctFruit = fruitMap[letter]!;

    if (fruit == correctFruit) {

      fruitMatched[fruit] = true; // ✅ freeze fruit
      matched[letter] = true;

      setState(() {
        showCelebration = true;
      });

      confettiController.play();

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            showCelebration = false;
          });
        }
      });

      achievedLetters.add(letter);

      setState(() {
        feedbackText = "Correct! $letter is for $correctFruit";
      });

      await player.play(AssetSource("audio/correct.mp3"));
      await player.onPlayerComplete.first;

      await speak("Correct! $letter is for $correctFruit");

      if (matched.values.every((e) => e)) {
        int timeTaken = DateTime.now().difference(assessmentStartTime).inSeconds;
        unsatisfiedLetters = fruitMap.keys.where((l) => !achievedLetters.contains(l)).toList();

        await PerformanceManager.saveAttempt(
          group: widget.level,
          type: "drag",
          achievedLetters: achievedLetters,
          unsatisfiedLetters: unsatisfiedLetters,
          timeTaken: timeTaken,
        );

        if (LevelManager.isLastGroup()) {
          LevelManager.flipGameUnlocked = true;
          await ProgressManager.saveFlipGameUnlocked(true);
        } else {
          await ProgressManager.unlockNextLevel(widget.level);
        }

        if (matched.values.every((e) => e)) {

          stopwatch.stop();
          int timeTaken = stopwatch.elapsed.inSeconds;

          unsatisfiedLetters =
              fruitMap.keys.where((l) => !achievedLetters.contains(l)).toList();

          await PerformanceManager.saveAttempt(
            group: widget.level,
            type: "drag",
            achievedLetters: achievedLetters,
            unsatisfiedLetters: unsatisfiedLetters,
            timeTaken: timeTaken,
          );

          if (LevelManager.isLastGroup()) {
            LevelManager.flipGameUnlocked = true;
            await ProgressManager.saveFlipGameUnlocked(true);
          } else {
            await ProgressManager.unlockNextLevel(widget.level);
          }

          await LevelManager.saveState();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CelebrationPage(
                level: widget.level,
                correctAnswers: achievedLetters.length,
                totalQuestions: fruitMap.length,
                assessmentType: "dragdrop",
                achieved: achievedLetters.length,
                unsatisfactory: fruitMap.length - achievedLetters.length,
                timeTaken: timeTaken,
              ),
            ),
          );
        }
      }

    } else {
      shakeController.forward(from: 0);

      setState(() {
        feedbackText = "Oops! Try again.";
      });

      await player.play(AssetSource("audio/incorrect.mp3"));
      await player.onPlayerComplete.first;

      await speak("Oops! Try again.");

      setState(() {
        matched[letter] = true;
      });
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        if (!achievedLetters.contains(letter)) matched[letter] = false;
      });
    }

    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() {
        feedbackText = "";
      });
    }

    isProcessing = false;
  }

  Widget box({Key? key, required Widget child, bool green = false}) {
    return Container(
      key: key,
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: green ? Colors.greenAccent.shade100 : Colors.white,
        border: Border.all(color: Colors.grey, width: 3),
      ),
      child: child,
    );
  }

  Widget columnBoard(List<Widget> children) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: children
          .map((e) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: e,
      ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          if (showCelebration)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                emissionFrequency: 0.02,
                numberOfParticles: 40,
                maxBlastForce: 20,
                minBlastForce: 10,
                gravity: 0.9,
                colors: const [
                  Colors.red,
                  Colors.green,
                  Colors.blue,
                  Colors.orange,
                  Colors.purple
                ],
              ),
            ),

          Positioned.fill(
            child: Image.asset(
              widget.level == 5
                  ? "assets/background/one.png"
                  : "assets/background/five.png",
              fit: BoxFit.cover,
            ),
          ),

          // center feedback text (green/red)
          if (feedbackText.isNotEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: feedbackText.startsWith("Correct")
                      ? Colors.green
                      : Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  feedbackText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          Positioned(
            top: 30,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 28, color: Colors.black),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),

                IconButton(
                  icon: const Icon(Icons.home, size: 28, color: Colors.black),
                  onPressed: () {
                    LevelManager.reset();
                    LevelManager.goToPhase(context);
                  },
                ),
              ],
            ),
          ),

          Positioned(
            top: -35,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                "assets/background/fruit.png",
                width: MediaQuery.of(context).size.width * 0.25,
                fit: BoxFit.contain,
              ),
            ),
          ),

          Align(
            alignment: Alignment(
              -0.45,
              widget.level == 5 ? -0.4 : -0.1,
            ),
            child: columnBoard(
              fruits.map((fruit) {

                bool isGreen = fruitMatched[fruit]!;

                return fruitMatched[fruit]!
                    ? box(
                  key: fruitKeys[fruit],
                  green: true,
                  child: Align(
                    alignment: const Alignment(0.7, 0),
                    child: Image.asset("assets/fruits/$fruit.png"),
                  ),
                )
                    : Draggable<String>(
                  data: fruit,
                  feedback: box(
                    child: Align(
                      alignment: const Alignment(0.7, 0),
                      child: Image.asset("assets/fruits/$fruit.png"),
                    ),
                  ),
                  child: box(
                    key: fruitKeys[fruit],
                    green: isGreen,
                    child: Align(
                      alignment: const Alignment(0.7, 0),
                      child: Image.asset("assets/fruits/$fruit.png"),
                    ),
                  ),
                  childWhenDragging: box(child: const SizedBox()),
                );
              }).toList(),
            ),
          ),

          Align(
            alignment: Alignment(
              0.45,
              widget.level == 5 ? -0.4 : -0.1,
            ),
            child: columnBoard(
              fruitMap.keys.map((letter) {
                return DragTarget<String>(
                  onAccept: (fruit) => checkMatch(letter, fruit),
                  builder: (_, __, ___) {
                    return box(
                      key: letterKeys[letter],
                      green: matched[letter]!,
                      child: Image.asset(
                        "assets/letters/${letter.toLowerCase()}.png",
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),

          if (showHand)
            AnimatedBuilder(
              animation: handController,
              builder: (_, __) {
                final t = Curves.easeInOut.transform(handController.value);
                final pos = Offset.lerp(handStart, handEnd, t)!;
                return Positioned(
                  left: pos.dx - 65,
                  top: pos.dy - 65,
                  child: Image.asset(
                    "assets/background/hand.png",
                    width: 130,
                  ),
                );
              },
            ),

          if (showCelebration)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                emissionFrequency: 0.02,
                numberOfParticles: 40,
                maxBlastForce: 20,
                minBlastForce: 10,
                gravity: 0.6,
                colors: const [
                  Colors.red,
                  Colors.green,
                  Colors.blue,
                  Colors.orange,
                  Colors.purple
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    confettiController.dispose();
    shakeController.dispose();
    handController.dispose();
    popupController.dispose();
    tts.stop();
    player.dispose();
    super.dispose();
  }
}
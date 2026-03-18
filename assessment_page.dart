import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'level_manager.dart';
import 'celebration_page.dart';
import 'performance_manager.dart';
import 'progress_manager.dart';

class AssessmentPageGroup1 extends StatefulWidget {
  final int groupIndex;
  const AssessmentPageGroup1({super.key, required this.groupIndex});

  @override
  State<AssessmentPageGroup1> createState() => _AssessmentPageGroup1State();
}

enum OptionState { idle, correct, wrong }

class _AssessmentPageGroup1State extends State<AssessmentPageGroup1>
    with TickerProviderStateMixin {
  final FlutterTts tts = FlutterTts();
  final AudioPlayer audioPlayer = AudioPlayer();
  Stopwatch stopwatch = Stopwatch();

  late List<Map<String, String>> questions;
  late List<String> allFruitImages;

  bool instructionPlaying = false;
  bool showCelebration = false;

  final Map<String, String> fruitMap = {
    'A': 'apple', 'B': 'banana', 'C': 'cherry', 'D': 'dragonfruit', 'E': 'elderberry',
    'F': 'fig', 'G': 'grapes', 'H': 'honeydew', 'I': 'iceapple', 'J': 'jackfruit',
    'K': 'kiwi', 'L': 'lychee', 'M': 'mango', 'N': 'nance', 'O': 'orange',
    'P': 'pineapple', 'Q': 'quince', 'R': 'raspberry', 'S': 'strawberry', 'T': 'tayberry',
    'U': 'ugli', 'V': 'vanilla', 'W': 'watermelon', 'X': 'xingzi', 'Y': 'yuzu', 'Z': 'ziziphus',
  };

  final List<List<String>> letterGroups = [
    ['A','B','C','D','E'],
    ['F','G','H','I','J'],
    ['K','L','M','N','O'],
    ['P','Q','R','S','T'],
    ['U','V','W','X','Y','Z'],
  ];

  int currentIndex = 0;
  int score = 0;
  bool locked = false;

  // ✅ REAL TIMER
  late DateTime assessmentStartTime;

  List<String> options = [];
  final Map<String, OptionState> optionStates = {};

  String resultText = "";
  Color resultColor = Colors.transparent;

  late AnimationController popController;
  late Animation<double> popAnim;
  late AnimationController shakeController;
  late Animation<double> shakeAnim;
  late ConfettiController confettiController;

  // ✅ TRACK LETTERS
  List<String> achievedLetters = [];
  List<String> unsatisfiedLetters = [];

  @override
  void initState() {
    super.initState();
    stopwatch.start();


    assessmentStartTime = DateTime.now(); // ✅ Start timer

    popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    popAnim = Tween<double>(begin: 1.0, end: 1.1)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(popController);

    shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    shakeAnim = Tween<double>(begin: 0, end: 12)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(shakeController);

    confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );

    tts.setLanguage("en-US");
    tts.setSpeechRate(0.5);
    tts.setPitch(1.0);
    tts.setVolume(1.0);

    _buildQuestions();
    _loadQuestion();
  }

  void _buildQuestions() {
    final groupLetters = letterGroups[widget.groupIndex - 1];
    questions = groupLetters.map((l) {
      final fruit = fruitMap[l]!;
      return {
        "letter": l,
        "answer": fruit,
        "image": "assets/fruits/$fruit.png",
      };
    }).toList();

    allFruitImages =
        fruitMap.values.map((f) => "assets/fruits/$f.png").toList();
  }

  Future<void> speak(String text) async {
    try {
      await tts.stop();
      await tts.speak(text);
    } catch (e) {
      print("TTS error: $e");
    }
  }
  void _loadQuestion() async {
    final correct = questions[currentIndex]["image"]!;
    final temp = List<String>.from(allFruitImages)..remove(correct)..shuffle();
    options = [correct, temp[0], temp[1]]..shuffle();

    locked = false;
    optionStates.clear();
    for (var o in options) optionStates[o] = OptionState.idle;

    resultText = "";
    resultColor = Colors.transparent;
    showCelebration = false;

    setState(() {});

    instructionPlaying = true;
    await speak("Tap the correct fruit for ${questions[currentIndex]["letter"]}");
    instructionPlaying = false;
  }

  void _onTap(String img) async {
    if (locked || instructionPlaying) return;

    locked = true;
    await tts.stop();

    final correctImg = questions[currentIndex]["image"]!;
    final letter = questions[currentIndex]["letter"]!;
    final answer = questions[currentIndex]["answer"]!;

    if (img == correctImg) {
      optionStates[img] = OptionState.correct;
      popController.forward(from: 0);

      resultText = "Correct!";
      resultColor = Colors.green;
      score++;

      achievedLetters.add(letter);

      showCelebration = true;
      confettiController.play();

      setState(() {});

      await audioPlayer.play(AssetSource("audio/correct.mp3"));
      await speak("Correct! $letter is for $answer");

    } else {
      optionStates[img] = OptionState.wrong;
      optionStates[correctImg] = OptionState.correct;

      shakeController.forward(from: 0);
      popController.forward(from: 0);

      resultText = "Wrong!";
      resultColor = Colors.red;

      unsatisfiedLetters.add(letter);

      showCelebration = false;

      setState(() {});

      await audioPlayer.play(AssetSource("audio/incorrect.mp3"));
      await speak("Wrong! $letter is for $answer");
    }

    await Future.delayed(const Duration(milliseconds: 600));

    if (currentIndex < questions.length - 1) {
      currentIndex++;
      _loadQuestion();
    } else {
      int timeTaken =
          DateTime.now().difference(assessmentStartTime).inSeconds;

      await PerformanceManager.saveAttempt(
        group: widget.groupIndex,
        type: "tap",
        achievedLetters: achievedLetters,
        unsatisfiedLetters: unsatisfiedLetters,
        timeTaken: timeTaken,
      );

      // 🔥 UNLOCK NEXT LEVEL PERMANENTLY
      await ProgressManager.unlockNextLevel(widget.groupIndex);

      LevelManager.inLearningPhase = false;
      await LevelManager.saveState();

      await PerformanceManager.saveAttempt(
        group: widget.groupIndex,
        type: "tap",
        achievedLetters: achievedLetters,
        unsatisfiedLetters: unsatisfiedLetters,
        timeTaken: timeTaken,
      );

// 🔥 UNLOCK NEXT LEVEL PERMANENTLY
      await ProgressManager.unlockNextLevel(widget.groupIndex);

      LevelManager.inLearningPhase = false;
      await LevelManager.saveState();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CelebrationPage(
            level: widget.groupIndex,
            correctAnswers: score,
            totalQuestions: questions.length,
            assessmentType: "tap",

            achieved: score,
            unsatisfactory: questions.length - score,
            timeTaken: timeTaken,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final boardWidth = size.width * 0.75;
    final letterSize = boardWidth * 0.19;
    final fruitSize = boardWidth * 0.11;
    final letter = questions[currentIndex]["letter"]!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/background/star2.png",
              fit: BoxFit.cover,
            ),
          ),

          Positioned(
            top:-5,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                "assets/background/ban.png",
                width: MediaQuery.of(context).size.width * 0.3,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Center(
            child: SizedBox(
              width: boardWidth,
              child: Column(
                children: [
                  const SizedBox(height: 160),
                  Image.asset(
                    "assets/letters/${letter.toLowerCase()}.png",
                    height: letterSize,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: options.map((img) {
                      final state = optionStates[img]!;
                      final isCorrect = state == OptionState.correct;
                      final isWrong = state == OptionState.wrong;

                      return GestureDetector(
                        onTap: () => _onTap(img),
                        child: ScaleTransition(
                          scale: isCorrect
                              ? popAnim
                              : const AlwaysStoppedAnimation(1),
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? Colors.greenAccent.withOpacity(0.6)
                                  : isWrong
                                  ? Colors.redAccent.withOpacity(0.6)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(1),
                            ),
                            child: Image.asset(img, height: fruitSize),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    resultText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: resultColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showCelebration)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                emissionFrequency: 0.01,
                numberOfParticles: 30,
                maxBlastForce: 20,
                minBlastForce: 10,
                gravity: 0.3,
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
    popController.dispose();
    shakeController.dispose();
    confettiController.dispose();
    tts.stop();
    audioPlayer.dispose();
    super.dispose();
  }
}
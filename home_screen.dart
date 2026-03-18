import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'intro.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  bool soundOn = true;
  late FlutterTts _tts;
  late AudioPlayer _player;

  // Boat animation
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // Plane animation
  late AnimationController _planeController;
  late Animation<double> _planeAnimation;

  bool _musicStarted = false; // ✅ important for chrome

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _tts.setLanguage("en-US");
    _tts.setPitch(1.0);
    _tts.setSpeechRate(0.45);

    Future.delayed(const Duration(milliseconds: 500), () {
      _tts.speak("Welcome to Kids Sound Hunt");
    });

    _player = AudioPlayer();

    // ❌ REMOVED _startMusic() from here (Chrome blocks autoplay)

    // Boat floating animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Plane animation
    _planeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _planeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _planeController, curve: Curves.linear),
    );
  }

  Future<void> _startMusic() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(1.0);

      if (soundOn) {
        await _player.play(
          AssetSource('audio/homemusic.mp3'),
        );
      }
    } catch (e) {
      print("Audio error: $e");
    }
  }

  Future<void> _toggleSound() async {
    setState(() {
      soundOn = !soundOn;
    });

    if (soundOn) {
      await _startMusic();
    } else {
      await _player.stop();
    }
  }

  @override
  void dispose() {

    _tts.stop();
    _player.dispose();
    _floatController.dispose();
    _scaleController.dispose();
    _planeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;

    final planeWidth = size.width * 0.55;

    final planeTop = orientation == Orientation.landscape
        ? size.height * -0.15
        : size.height * 0.01;

    return Scaffold(
      body: GestureDetector(
        onTap: () async {
          // ✅ Start music only after first user interaction (Chrome fix)
          if (!_musicStarted && soundOn) {
            _musicStarted = true;
            await _startMusic();
          }
        },
        child: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Image.asset(
                orientation == Orientation.landscape
                    ? 'assets/background/tabletpage.png'
                    : 'assets/portrait/home.png',
                fit: BoxFit.cover,
              ),
            ),

            // Plane animation
            AnimatedBuilder(
              animation: _planeAnimation,
              builder: (context, child) {
                final leftPos =
                    _planeAnimation.value * (size.width + planeWidth) -
                        planeWidth;
                return Positioned(
                  top: planeTop,
                  left: leftPos,
                  child: SizedBox(
                    width: planeWidth,
                    child: Image.asset(
                      'assets/background/cc.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),

            // Boat animation
            Center(
              child: AnimatedBuilder(
                animation: _floatController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatAnimation.value),
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: GestureDetector(
                        onTap: () async {
                          await _player.stop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const IntroPage(level: 1),
                            ),
                          );
                        },
                        child: Image.asset(
                          'assets/background/boat.png',
                          width: orientation == Orientation.landscape
                              ? size.width * 0.25
                              : size.width * 0.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Sound button
            Positioned(
              bottom: 24,
              right: 24,
              child: GestureDetector(
                onTap: _toggleSound,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: soundOn
                          ? [Colors.greenAccent, Colors.green]
                          : [Colors.grey, Colors.black45],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: soundOn
                            ? Colors.green.withOpacity(0.6)
                            : Colors.black26,
                        blurRadius: 15,
                      )
                    ],
                  ),
                  child: Icon(
                    soundOn ? Icons.volume_up : Icons.volume_off,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
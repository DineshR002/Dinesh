import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class KidsIntroPage extends StatefulWidget {
  const KidsIntroPage({super.key});

  @override
  State<KidsIntroPage> createState() => _KidsIntroPageState();
}

class _KidsIntroPageState extends State<KidsIntroPage>
    with TickerProviderStateMixin {
  late AnimationController _planeController;
  late AnimationController _cloudController;
  late AnimationController _textController;
  late AnimationController _glowController;

  late Animation<Offset> _planeAnimation;
  late Animation<double> _cloudFade;
  late Animation<double> _textScale;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    /// ✈ Plane animation
    _planeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _planeAnimation = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: const Offset(0, 0),
    ).animate(
      CurvedAnimation(parent: _planeController, curve: Curves.easeOut),
    );

    /// ☁ Cloud fade
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _cloudFade = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _cloudController, curve: Curves.easeInOut),
    );

    /// 🌈 Title scale
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _textScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.elasticOut),
    );

    /// ✨ Glow pulse
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    /// Start animation sequence
    _startSequence();
  }

  void _startSequence() async {
    await _planeController.forward();
    await _cloudController.forward();
    await _textController.forward();

    /// Auto navigate after delay
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _planeController.dispose();
    _cloudController.dispose();
    _textController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          /// 🌤 Background
          Positioned.fill(
            child: Image.asset(
              "assets/background/tabletpage.png",
              fit: BoxFit.cover,
            ),
          ),

          /// ☁ Premium Cloud Banner
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: size.height * 0.1),
              child: FadeTransition(
                opacity: _cloudFade,
                child: Image.asset(
                  "assets/background/cloud.png",
                  width: size.width * 0.85,
                ),
              ),
            ),
          ),

          /// ✈ Plane Animation
          Positioned(
            top: size.height * 0.17,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _planeAnimation,
              child: Transform.rotate(
                angle: -0.05,
                child: Image.asset(
                  "assets/background/plane.png",
                  width: size.width * 0.22,
                ),
              ),
            ),
          ),

          /// 🌈 Animated Title
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: size.height * 0.22),
              child: ScaleTransition(
                scale: _textScale,
                child: AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(_glowAnimation.value),
                            blurRadius: 40,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFFFF6FD8),
                            Color(0xFF3813C2),
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          "KIDS SOUND HUNT",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

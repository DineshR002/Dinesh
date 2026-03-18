import 'package:flutter/material.dart';
import 'dart:math';

class MatchFruitsPage extends StatefulWidget {
  const MatchFruitsPage({super.key});

  @override
  State<MatchFruitsPage> createState() => _MatchFruitsPageState();
}

class _MatchFruitsPageState extends State<MatchFruitsPage> {
  final Map<String, String> fruitMap = {
    'F': 'fig',
    'G': 'grapes',
    'H': 'jackfruit',
    'I': 'kiwi',
    'J': 'jamun',
  };

  late List<String> fruits;
  late Map<String, bool> matched;

  @override
  void initState() {
    super.initState();
    fruits = fruitMap.values.toList()..shuffle();
    matched = {for (var k in fruitMap.keys) k: false};
  }

  void checkMatch(String letter, String fruit) {
    if (fruitMap[letter] == fruit) {
      setState(() => matched[letter] = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Correct! $letter is for ${fruit[0].toUpperCase()}${fruit.substring(1)}"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Try again!"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Widget boardArea({
    required Alignment alignment,
    required List<Widget> children,
  }) {
    return Align(
      alignment: alignment,
      child: SizedBox(
        width: 260,
        height: 520,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: children,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 🌄 BACKGROUND
          Positioned.fill(
            child: Image.asset(
              "assets/background/dd.png",
              fit: BoxFit.cover,
            ),
          ),

          /// 🎯 LEFT BOARD (LETTERS)
          boardArea(
            alignment: const Alignment(-0.55, 0.05),
            children: fruitMap.keys.map((letter) {
              return DragTarget<String>(
                onAccept: (fruit) => checkMatch(letter, fruit),
                builder: (context, _, __) {
                  return Opacity(
                    opacity: matched[letter]! ? 0.3 : 1,
                    child: Image.asset(
                      "assets/letters/${letter.toLowerCase()}.png",
                      height: 85,
                    ),
                  );
                },
              );
            }).toList(),
          ),

          /// 🍎 RIGHT BOARD (FRUITS)
          boardArea(
            alignment: const Alignment(0.55, 0.05),
            children: fruits.map((fruit) {
              final alreadyUsed = matched.entries.any(
                    (e) => e.value && fruitMap[e.key] == fruit,
              );

              return Draggable<String>(
                data: fruit,
                feedback: Image.asset(
                  "assets/fruits/$fruit.png",
                  height: 80,
                ),
                childWhenDragging: Opacity(
                  opacity: 0.4,
                  child: Image.asset(
                    "assets/fruits/$fruit.png",
                    height: 80,
                  ),
                ),
                child: Opacity(
                  opacity: alreadyUsed ? 0.3 : 1,
                  child: Image.asset(
                    "assets/fruits/$fruit.png",
                    height: 80,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

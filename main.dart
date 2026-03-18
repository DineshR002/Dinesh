import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'learning_page.dart';
import 'level_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ LOAD EVERYTHING FROM SHARED PREFERENCES
  await LevelManager.loadSavedProgress();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),

      routes: {
        '/learn/group1': (context) => const LearningPageGroup(),
      },
    );
  }
}
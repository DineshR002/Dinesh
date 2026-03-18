import 'package:flutter/material.dart';
import 'assessment_page.dart';

class LearningPageGroup extends StatelessWidget {
  final int groupIndex;

  const LearningPageGroup({super.key, required this.groupIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Learning A–Z'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Learning Group $groupIndex',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AssessmentPageGroup1(
                      groupIndex: groupIndex,
                    ),
                  ),
                );
              },
              child: const Text(
                'START ASSESSMENT',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'performance_manager.dart';

class PerformancePage extends StatefulWidget {
  const PerformancePage({super.key});

  @override
  State<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends State<PerformancePage>
    with TickerProviderStateMixin {

  Map<String, dynamic> overallLearning = {};
  Map<String, dynamic> overallTap = {};
  Map<String, dynamic> overallDrag = {};

  List<Map<String, dynamic>> tapStats = [];
  List<Map<String, dynamic>> dragStats = [];

  bool isLoading = true;

  final Map<int, int> setLetterCount = {
    1: 5,
    2: 5,
    3: 5,
    4: 5,
    5: 6,
  };

  final Map<int, String> setNames = {
    1: "A–E",
    2: "F–J",
    3: "K–O",
    4: "P–T",
    5: "U–Z",
  };

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ✅ HELPER FUNCTION TO FORMAT SECONDS TO MINUTES AND SECONDS
  String formatTime(dynamic seconds) {
    if (seconds == null || seconds == 0 || seconds == "0.0" || seconds == "0") {
      return "0 sec";
    }
    double totalSeconds = double.tryParse(seconds.toString()) ?? 0;
    int mins = (totalSeconds / 60).floor();
    int secs = (totalSeconds % 60).round();

    if (mins > 0) {
      return "$mins min $secs sec";
    } else {
      return "$secs sec";
    }
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);

    overallLearning = await PerformanceManager.getOverallLearning();

    final tapFutures = List.generate(
        5,
            (g) => PerformanceManager.getAssessmentStats(
            g + 1, "tap",
            totalLettersInSet: setLetterCount[g + 1]));

    final dragFutures = List.generate(
        5,
            (g) => PerformanceManager.getAssessmentStats(
            g + 1, "drag",
            totalLettersInSet: setLetterCount[g + 1]));

    tapStats = await Future.wait(tapFutures);
    dragStats = await Future.wait(dragFutures);

    overallTap = calculateOverall(tapStats);
    overallDrag = calculateOverall(dragStats);

    setState(() => isLoading = false);
  }

  Map<String, dynamic> calculateOverall(
      List<Map<String, dynamic>> stats) {

    int achieved = 0;
    int unsatisfied = 0;
    int totalTime = 0;

    for (var s in stats) {
      achieved += int.tryParse("${s["achieved"]}") ?? 0;
      unsatisfied += int.tryParse("${s["unsatisfied"]}") ?? 0;
      totalTime += int.tryParse("${s["time"]}") ?? 0;
    }

    int totalLetters = achieved + unsatisfied;
    double accuracy =
    totalLetters == 0 ? 0 : (achieved / totalLetters) * 100;

    double avgTime =
    stats.isEmpty ? 0 : totalTime / stats.length;

    return {
      "achieved": achieved,
      "unsatisfied": unsatisfied,
      "letters": "$achieved/$totalLetters",
      "time": totalTime,
      "averageTime": avgTime.toStringAsFixed(1),
      "accuracy": accuracy.toStringAsFixed(1),
    };
  }

  Color softBlue = const Color(0xFFE3F2FD);
  Color softGreen = const Color(0xFFE8F5E9);
  Color softPurple = const Color(0xFFF3E5F5);
  Color softGrey = const Color(0xFFF8F9FA);

  Widget buildCard(String title, Widget child, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget buildAssessmentValues(Map<String, dynamic> stats) {

    int achieved = stats["achieved"] ?? 0;
    int unsatisfied = stats["unsatisfied"] ?? 0;
    int total = achieved + unsatisfied;
    double accuracy =
        double.tryParse(stats["accuracy"] ?? "0") ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearPercentIndicator(
          lineHeight: 18,
          percent: total == 0 ? 0 : achieved / total,
          backgroundColor: Colors.grey.shade300,
          progressColor: Colors.blue.shade300,
          center: Text("$achieved/$total"),
          barRadius: const Radius.circular(12),
          animation: true,
        ),
        const SizedBox(height: 10),
        Text("Achieved: $achieved"),
        Text("Unsatisfied: $unsatisfied"),
        Text("Total Time: ${formatTime(stats["time"])}"), // ✅ UPDATED
        Text("Average Time: ${formatTime(stats["averageTime"])}"), // ✅ UPDATED
        Text("Accuracy: ${accuracy.toStringAsFixed(1)}%"),
      ],
    );
  }

  Widget buildReinforcementIfNeeded(Map<String, dynamic> stats) {
    double accuracy =
        double.tryParse(stats["accuracy"] ?? "0") ?? 0;
    int unsatisfied = stats["unsatisfied"] ?? 0;

    if (accuracy < 50 || unsatisfied > 0) {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          "Reinforcement Required",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red),
        ),
      );
    }
    return const SizedBox();
  }

  Widget buildLearningPie() {
    int achieved = overallLearning["achieved"] ?? 0;
    int total = 26;
    int remaining = total - achieved;

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  value: achieved.toDouble(),
                  color: Colors.blue.shade300,
                  title: "$achieved",
                  radius: 50,
                ),
                PieChartSectionData(
                  value: remaining.toDouble(),
                  color: Colors.grey.shade300,
                  title: "",
                  radius: 45,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text("Letters Participated: $achieved / 26"),
        Text("Total Time: ${formatTime(overallLearning["time"])}"), // ✅ UPDATED
        Text("Average Time: ${formatTime(overallLearning["averageTime"])}"), // ✅ UPDATED
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Performance Analysis"),
        backgroundColor: Colors.blue.shade100,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [

          buildCard("Overall Learning",
              buildLearningPie(), softPurple),

          buildCard("Overall Assessment 1 (Tap)",
              buildAssessmentValues(overallTap),
              softBlue),

          buildCard("Overall Assessment 2 (Drag)",
              buildAssessmentValues(overallDrag),
              softGreen),

          const SizedBox(height: 20),

          for (int i = 0; i < 5; i++)
            buildCard(
                "Set ${i + 1} (${setNames[i + 1]})",
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text("Assessment 1",
                        style: TextStyle(
                            fontWeight: FontWeight.bold)),

                    const SizedBox(height: 6),

                    const Text("Appropriate Response",
                        style: TextStyle(
                            fontWeight: FontWeight.w600)),

                    const SizedBox(height: 8),

                    buildAssessmentValues(tapStats[i]),

                    buildReinforcementIfNeeded(tapStats[i]),

                    const SizedBox(height: 20),

                    const Text("Assessment 2",
                        style: TextStyle(
                            fontWeight: FontWeight.bold)),

                    const SizedBox(height: 6),

                    const Text("Appropriate Response",
                        style: TextStyle(
                            fontWeight: FontWeight.w600)),

                    const SizedBox(height: 8),

                    buildAssessmentValues(dragStats[i]),

                    buildReinforcementIfNeeded(dragStats[i]),
                  ],
                ),
                softGrey),
        ],
      ),
    );
  }
}
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';

class ExpensePieChart extends StatelessWidget {
  final List<TransactionModel> transactions;

  const ExpensePieChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    // 1. Filter only Expenses
    final expenses = transactions.where((t) => t.type == 'expense').toList();
    
    if (expenses.isEmpty) {
      return const Center(child: Text("Add an expense to see the chart!", style: TextStyle(color: Colors.grey)));
    }

    // 2. Group by Category (The Math Part)
    Map<String, double> categoryTotals = {};
    for (var t in expenses) {
      if (categoryTotals.containsKey(t.category)) {
        categoryTotals[t.category] = categoryTotals[t.category]! + t.amount;
      } else {
        categoryTotals[t.category] = t.amount;
      }
    }

    // 3. Define Colors for Categories
    final List<Color> colors = [
      Colors.yellow[700]!,
      Colors.green,
      Colors.blue,
      Colors.redAccent,
      Colors.purple,
      Colors.orange,
      Colors.teal,
    ];

    // 4. Create the Chart Sections
    int colorIndex = 0;
    List<PieChartSectionData> sections = [];
    
    categoryTotals.forEach((category, amount) {
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: amount,
          title: '${amount.toInt()}', // Show amount on the slice
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
          radius: 50,
        ),
      );
      colorIndex++;
    });

    return Row(
      children: [
        // The Chart
        Expanded(
          child: SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
        ),
        
        // The Legend (Labels on the right)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: categoryTotals.entries.map((entry) {
            int index = categoryTotals.keys.toList().indexOf(entry.key);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors[index % colors.length],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.key,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(width: 20),
      ],
    );
  }
}
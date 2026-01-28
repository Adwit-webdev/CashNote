import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../models/transaction_model.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final TextEditingController _budgetController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Budget & Analytics", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFFFFD700)),
            onPressed: _showSetBudgetDialog,
          )
        ],
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: FirestoreService().getTransactions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final transactions = snapshot.data!;
          final expenses = transactions.where((t) => t.type == 'expense').toList();

          return StreamBuilder<double>(
            stream: FirestoreService().getMonthlyBudget(),
            builder: (context, budgetSnap) {
              final double budgetLimit = budgetSnap.data ?? 0;
              
              // Logic: Filter Current Month
              final now = DateTime.now();
              final currentMonthExpenses = expenses.where((t) => 
                  t.date.month == now.month && t.date.year == now.year
              ).toList();

              double spentThisMonth = currentMonthExpenses.fold(0, (sum, item) => sum + item.amount);
              double progress = budgetLimit == 0 ? 0 : spentThisMonth / budgetLimit;
              bool isOverBudget = spentThisMonth > budgetLimit;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. BUDGET CARD
                    _buildBudgetCard(spentThisMonth, budgetLimit, progress, isOverBudget),
                    
                    const SizedBox(height: 25),
                    
                    // 2. WEEKLY SPENDING
                    const Text("Weekly Breakdown", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildWeeklyBreakdown(expenses),

                    const SizedBox(height: 25),

                    // 3. MONTHLY SPENDING
                    const Text("Monthly History", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildMonthlyBreakdown(expenses),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBudgetCard(double spent, double limit, double progress, bool isOver) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: isOver ? Border.all(color: Colors.red, width: 2) : null,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Monthly Budget", style: TextStyle(color: Colors.grey)),
              if (isOver) 
                const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 16),
                    SizedBox(width: 5),
                    Text("OVER BUDGET!", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("₹${spent.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              Text("/ ₹${limit.toStringAsFixed(0)}", style: const TextStyle(color: Colors.grey, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: progress > 1 ? 1 : progress,
            backgroundColor: Colors.white10,
            color: isOver ? Colors.red : (progress > 0.8 ? Colors.orange : Colors.green),
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 10),
          Text(
            isOver 
              ? "You exceeded your budget by ₹${(spent - limit).toStringAsFixed(0)}!" 
              : "You have ₹${(limit - spent).toStringAsFixed(0)} left.",
            style: TextStyle(color: isOver ? Colors.redAccent : Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBreakdown(List<TransactionModel> expenses) {
    Map<String, double> weeks = {};
    
    for (var t in expenses) {
      // Key: "Week 34"
      int weekNum = (t.date.day / 7).ceil(); 
      String key = "${DateFormat('MMM').format(t.date)} - Week $weekNum";
      weeks[key] = (weeks[key] ?? 0) + t.amount;
    }

    return Column(
      children: weeks.entries.map((e) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(e.key, style: const TextStyle(color: Colors.white)),
            Text("₹${e.value.toStringAsFixed(0)}", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildMonthlyBreakdown(List<TransactionModel> expenses) {
    Map<String, double> months = {};
    for (var t in expenses) {
      String key = DateFormat('MMMM yyyy').format(t.date);
      months[key] = (months[key] ?? 0) + t.amount;
    }

    return Column(
      children: months.entries.map((e) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.calendar_month, color: Colors.white)),
        title: Text(e.key, style: const TextStyle(color: Colors.white)),
        trailing: Text("₹${e.value.toStringAsFixed(0)}", style: const TextStyle(color: Colors.redAccent, fontSize: 16)),
      )).toList(),
    );
  }

  void _showSetBudgetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Set Monthly Budget", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _budgetController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter amount (e.g. 5000)",
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              final amt = double.tryParse(_budgetController.text) ?? 0;
              FirestoreService().setMonthlyBudget(amt);
              Navigator.pop(context);
            },
            child: const Text("Save", style: TextStyle(color: Color(0xFFFFD700))),
          ),
        ],
      ),
    );
  }
}
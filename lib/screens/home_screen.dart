import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';
import 'add_transaction_screen.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';
import '../widgets/expense_pie_chart.dart';
import '../services/emoji_service.dart';
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CashNote", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
       actions: [
  IconButton(
    icon: const Icon(Icons.calendar_month),
    onPressed: () {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const CalendarScreen()));
    },
  ),
  IconButton(
    icon: const Icon(Icons.settings),
    onPressed: () {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
    },
  ),
],
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: FirestoreService().getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final transactions = snapshot.data!;
          
          double income = 0;
          double expense = 0;
          for (var t in transactions) {
            if (t.type == 'income') income += t.amount;
            else expense += t.amount;
          }
          double total = income - expense;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildBalanceCard(total, income, expense),
                const SizedBox(height: 20),
                // Pie Chart can go here (omitted for brevity, keep your existing one if you have it)
                
                // 2. The Real Pie Chart
Container(
  height: 220,
  width: double.infinity,
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: const Color(0xFF1E1E1E),
    borderRadius: BorderRadius.circular(16),
  ),
  child: ExpensePieChart(transactions: transactions),
),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Recent Transactions", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
                  ),
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    return _buildTransactionItem(context, transactions[index]);
                  },
                ),
              ],
            ),
          );
        },
      ),
      // FIXED: Square-ish Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTransactionScreen()));
        },
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Square look
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long, size: 80, color: Colors.white24),
          const SizedBox(height: 10),
          const Text("No transactions yet!", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, TransactionModel transaction) {
    bool isIncome = transaction.type == 'income';
    return GestureDetector(
      // FIXED: Long Press to Delete
      onLongPress: () {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text("Delete?", style: TextStyle(color: Colors.white)),
      // LATEST: Using string interpolation with the service
      content: Text("Delete '${transaction.note.isEmpty ? transaction.category : EmojiService.addEmoji(transaction.note)}'?"),
      actions: [ // <-- This label was likely missing
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
        TextButton(
          onPressed: () {
            FirestoreService().deleteTransaction(transaction.id);
            Navigator.pop(context);
          },
          child: const Text("Delete", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
},
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isIncome ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30),
              radius: 25,
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.shopping_bag, 
                color: isIncome ? Colors.green : Colors.redAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.note.isEmpty ? transaction.category : transaction.note,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    DateFormat('MMM d, y').format(transaction.date),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              "${isIncome ? '+' : '-'} ₹${transaction.amount.toStringAsFixed(0)}",
              style: TextStyle(
                color: isIncome ? Colors.green : Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double total, double income, double expense) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          const Text("Total Balance", style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 10),
          Text(
            "₹ ${total.toStringAsFixed(2)}", 
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(Icons.arrow_downward, "Income", "₹ ${income.toStringAsFixed(0)}", Colors.greenAccent),
              Container(width: 1, height: 40, color: Colors.white12),
              _buildSummaryItem(Icons.arrow_upward, "Expense", "₹ ${expense.toStringAsFixed(0)}", Colors.redAccent),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String amount, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withAlpha(50), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        )
      ],
    );
  }
}
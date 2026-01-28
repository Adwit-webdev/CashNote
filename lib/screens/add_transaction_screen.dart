import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _selectedType = 'expense'; // 'expense' or 'income'
  String _selectedCategory = 'Food';

  final List<Map<String, dynamic>> expenseCategories = [
    {'name': 'Food', 'icon': Icons.lunch_dining},
    {'name': 'Shopping', 'icon': Icons.shopping_cart},
    {'name': 'Transport', 'icon': Icons.directions_bus},
    {'name': 'Bills', 'icon': Icons.receipt_long},
    {'name': 'Entertainment', 'icon': Icons.movie},
    {'name': 'Education', 'icon': Icons.book},
    {'name': 'Groceries', 'icon': Icons.local_grocery_store},
    {'name': 'Health', 'icon': Icons.medical_services},
    {'name': 'Fuel', 'icon': Icons.local_gas_station},
    {'name': 'Others', 'icon': Icons.category},
  ];

  final List<Map<String, dynamic>> incomeCategories = [
    {'name': 'Salary', 'icon': Icons.account_balance_wallet},
    {'name': 'Allowance', 'icon': Icons.attach_money},
    {'name': 'Bonus', 'icon': Icons.star},
    {'name': 'Investment', 'icon': Icons.trending_up},
    {'name': 'Part-time', 'icon': Icons.access_time},
    {'name': 'Gift', 'icon': Icons.card_giftcard},
    {'name': 'Selling', 'icon': Icons.store},
    {'name': 'Others', 'icon': Icons.category},
  ];

  void _saveTransaction() async {
    if (_amountController.text.isEmpty) return;

    final double amount = double.parse(_amountController.text);
    final String id = const Uuid().v4();

    final newTransaction = TransactionModel(
      id: id,
      amount: amount,
      category: _selectedCategory, // Use the selected icon name
      type: _selectedType,
      date: DateTime.now(),
      note: _noteController.text,
    );

    await FirestoreService().addTransaction(newTransaction);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final currentCategories = _selectedType == 'expense' ? expenseCategories : incomeCategories;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTypeButton("Expense", _selectedType == 'expense'),
            const SizedBox(width: 10),
            _buildTypeButton("Income", _selectedType == 'income'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Amount", style: TextStyle(color: Colors.grey)),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.currency_rupee, color: Color(0xFFFFD700), size: 30),
                    border: InputBorder.none,
                    hintText: "0",
                    hintStyle: TextStyle(color: Colors.white24),
                  ),
                ),
                TextField(
                  controller: _noteController,
                  style: const TextStyle(color: Colors.white70),
                  decoration: const InputDecoration(
                    hintText: "Add a note (e.g. Pizza)",
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    icon: Icon(Icons.edit_note, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),

          // White Container with Grid
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white, // White Sheet
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 15,
                        childAspectRatio: 0.8, // Make taller to fit text
                      ),
                      itemCount: currentCategories.length,
                      itemBuilder: (context, index) {
                        final cat = currentCategories[index];
                        final isSelected = _selectedCategory == cat['name'];
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = cat['name'];
                            });
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFFFD700) : Colors.grey[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  cat['icon'],
                                  color: Colors.black,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // 3. FIXED: Explicit Black Text
                              Text(
                                cat['name'],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected ? Colors.black : Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("SAVE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = text.toLowerCase();
          // Reset category when switching tabs so you don't save "Salary" as an Expense
          _selectedCategory = _selectedType == 'expense' ? 'Food' : 'Salary';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
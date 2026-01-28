import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;     
import 'dart:convert';                        
import '../models/note_model.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';
import 'barcode_scanner_screen.dart';
import '../services/notification_service.dart';

class AddNoteScreen extends StatefulWidget {
  final NoteModel? note;

  const AddNoteScreen({super.key, this.note});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final TextEditingController _titleController = TextEditingController();
  List<NoteItem> _items = [];
  
final Map<NoteItem, String> _scannedBarcodes = {}; 
  int _colorIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _items = List.from(widget.note!.items);
      _colorIndex = widget.note!.colorIndex;
    } else {
      _items.add(NoteItem(text: '')); 
    }
  }
  // Add this inside _AddNoteScreenState
  void _sortItems() {
    setState(() {
      _items.sort((a, b) {
        // 1. Done items go to bottom
        if (a.isDone && !b.isDone) return 1;
        if (!a.isDone && b.isDone) return -1;
        
        // 2. High Priority goes to top
        const priorityMap = {'High': 0, 'Medium': 1, 'Low': 2};
        int pA = priorityMap[a.priority] ?? 1;
        int pB = priorityMap[b.priority] ?? 1;
        return pA.compareTo(pB);
      });
    });
  }
  void _saveNote() async {
    _items.removeWhere((item) => item.text.isEmpty && item.price == 0);
    
    if (_titleController.text.isEmpty && _items.isEmpty) return;

    for (var item in _items) {
      if (_scannedBarcodes.containsKey(item)) {
        String barcode = _scannedBarcodes[item]!;
        await FirestoreService().saveProductKnowledge(barcode, item.text, item.price);
      }
    }

    final String id = widget.note?.id ?? const Uuid().v4();

    final newNote = NoteModel(
      id: id,
      title: _titleController.text,
      date: DateTime.now(),
      items: _items,
      colorIndex: _colorIndex,
    );
    
    if (widget.note == null) {
      await FirestoreService().addNote(newNote);
    } else {
      await FirestoreService().updateNote(newNote);
    }

    if (mounted) Navigator.pop(context);
  }

  void _deleteNote() async {
    if (widget.note != null) {
      await FirestoreService().deleteNote(widget.note!.id);
    }
    if (mounted) Navigator.pop(context);
  }
  // --- 📤 SHARE FEATURE ---
  void _shareNote() async {
    String text = "${_titleController.text}\n"; 
    if (_items.isNotEmpty) text += "------------------\n";
    
    for (var item in _items) {
      String status = item.isDone ? "[x]" : "[ ]";
      String price = item.price > 0 ? " (₹${item.price.toStringAsFixed(0)})" : "";
      text += "$status ${item.text}$price\n";
    }

    if (_totalCost > 0) {
      text += "------------------\n";
      text += "Total Est: ₹${_totalCost.toStringAsFixed(0)}";
    }

    // ✅ FIXED: Added '.instance' to satisfy version 12+
    await SharePlus.instance.share(
      ShareParams(
        text: text, 
        subject: "My Shopping List"
      )
    );
  }

  // --- 🕵️‍♂️ SCANNER FEATURE (UPDATED) ---
  void _scanBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (!mounted || result == null || result is! String) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Searching product info... 🔍")),
    );

    // 1. Check if we have "Learned" this product before
    Map<String, dynamic>? learnedData = await FirestoreService().getProductKnowledge(result);
    
    String name;
    double price;

    if (learnedData != null) {
      // ✅ FOUND: Use remembered name and price
      name = learnedData['name'];
      price = (learnedData['price'] as num).toDouble();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Price found! ₹$price")),
      );
    } else {
      // ❌ NEW: Fetch from API or default
      name = await _fetchProductName(result) ?? "Unknown Product";
      price = 0.0;
    }

    if (mounted) {
      setState(() {
        // Create the item
        final newItem = NoteItem(text: name, price: price);
        
        // Add to list
        _items.add(newItem);
        
        // Map this item to the barcode so we can update it later
        _scannedBarcodes[newItem] = result;
      });
    }
  }

  Future<String?> _fetchProductName(String barcode) async {
    try {
      final url = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) {
          return data['product']['product_name'];
        }
      }
    } catch (e) {
      print("Error fetching product: $e"); 
    }
    return null;
  }

  // --- ⏰ REMINDER FEATURE ---
  // Inside add_note_screen.dart

void _setReminder() async {
  final DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime.now(),
    lastDate: DateTime(2100),
  );
  if (pickedDate == null) return;

  if (!mounted) return;
  final TimeOfDay? pickedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
  );
  if (pickedTime == null) return;

  // Combine Date and Time
  final DateTime scheduledTime = DateTime(
    pickedDate.year,
    pickedDate.month,
    pickedDate.day,
    pickedTime.hour,
    pickedTime.minute,
  );
  
  // DEBUG: Check if time is in the past
  if (scheduledTime.isBefore(DateTime.now())) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Cannot set reminder in the past! ⚠️")),
    );
    return;
  }

  // Schedule it
  await NotificationService.scheduleNotification(
    id: DateTime.now().millisecondsSinceEpoch % 100000, 
    title: "Reminder: ${_titleController.text}",
    body: "Don't forget your shopping list! 🛒",
    scheduledTime: scheduledTime,
  );

  print("Reminder Scheduled for: $scheduledTime");

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Reminder set for ${pickedTime.format(context)}! ⏰"),
        backgroundColor: const Color(0xFFFFD700),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
  // --- ✅ HANDLE ITEM BOUGHT FEATURE (UPDATED) ---
  void _handleItemBought(NoteItem item) async {
    // Check if valid price exists and item is NOT already checked off
    if (item.price > 0 && !item.isDone) {
      
      // ✅ FIX: Multiply price by quantity
      final double totalAmount = item.price * item.quantity;

      final newTransaction = TransactionModel(
        id: const Uuid().v4(),
        amount: totalAmount, // Uses the calculated total
        category: 'Shopping', 
        type: 'expense',
        date: DateTime.now(),
        // ✅ Added quantity to the note for clarity
        note: "Bought: ${item.quantity}x ${item.text}", 
      );

      await FirestoreService().addTransaction(newTransaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Added ₹${totalAmount.toStringAsFixed(0)} to Expenses! 💸"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _updateTotal() {
    _sortItems();
    setState(() {});
  }

  double get _totalCost {
    double total = 0;
    for (var item in _items) {
      total += (item.price * item.quantity);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _saveNote,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            onPressed: _scanBarcode,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.white),
            onPressed: _setReminder,
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareNote,
          ),
          IconButton(
            icon: const Icon(Icons.color_lens, color: Colors.white),
            onPressed: () => setState(() => _colorIndex = (_colorIndex + 1) % 5),
          ),
          if (widget.note != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteNote,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'Title',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),

          if (_items.any((i) => i.price > 0))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Estimated Cost: ₹${_totalCost.toStringAsFixed(0)}",
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),

          Expanded(
            child: ListView.builder(
              itemCount: _items.length + 1,
              itemBuilder: (context, index) {
                if (index == _items.length) {
                  return TextButton.icon(
                    onPressed: () => setState(() => _items.add(NoteItem(text: ''))),
                    icon: const Icon(Icons.add, color: Colors.grey),
                    label: const Text("Add Item", style: TextStyle(color: Colors.grey)),
                  );
                }

                return NoteItemRow(
                  key: ObjectKey(_items[index]),
                  item: _items[index],
                  onChanged: _updateTotal,
                  onCheck: () => _handleItemBought(_items[index]),
                  onDelete: () {
                    setState(() {
                      _items.removeAt(index);
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveNote,
        backgroundColor: const Color(0xFFFFD700),
        child: const Icon(Icons.check, color: Colors.black),
      ),
    );
  }
}
class NoteItemRow extends StatefulWidget {
  final NoteItem item;
  final VoidCallback onChanged;
  final VoidCallback onDelete;
  final VoidCallback onCheck;

  const NoteItemRow({
    super.key, 
    required this.item, 
    required this.onChanged, 
    required this.onDelete,
    required this.onCheck,
  });

  @override
  State<NoteItemRow> createState() => _NoteItemRowState();
}

class _NoteItemRowState extends State<NoteItemRow> {
  late TextEditingController _textController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.item.text);
    _priceController = TextEditingController(text: widget.item.price == 0 ? '' : widget.item.price.toStringAsFixed(0));
  }
  void _editQuantity() {
    TextEditingController qtyController = TextEditingController(text: widget.item.quantity.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Set Quantity", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Input Field
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                prefixText: "x ",
                prefixStyle: TextStyle(color: Color(0xFFFFD700), fontSize: 24),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFD700))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFD700), width: 2)),
              ),
            ),
            const SizedBox(height: 20),
            // Quick Buttons (-1, +1)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.white54),
                  onPressed: () {
                    int current = int.tryParse(qtyController.text) ?? 1;
                    if (current > 1) {
                      qtyController.text = (current - 1).toString();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white54),
                  onPressed: () {
                    int current = int.tryParse(qtyController.text) ?? 1;
                    qtyController.text = (current + 1).toString();
                  },
                ),
              ],
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancel", style: TextStyle(color: Colors.white54))
          ),
          ElevatedButton(
            onPressed: () {
              int? val = int.tryParse(qtyController.text);
              if (val != null && val > 0) {
                setState(() {
                  widget.item.quantity = val;
                  widget.onChanged(); // Updates Total Cost
                });
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700)),
            child: const Text("Save", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 🔴 PRIORITY PICKER
  void _changePriority() {
    // Cycle: Medium -> High -> Low -> Medium
    setState(() {
      if (widget.item.priority == 'Medium') widget.item.priority = 'High';
      else if (widget.item.priority == 'High') widget.item.priority = 'Low';
      else widget.item.priority = 'Medium';
      widget.onChanged(); // Trigger sort
    });
  }

  // 🏷️ CATEGORY PICKER
  void _changeCategory() {
    final categories = ['Shopping', 'Work', 'Personal', 'Other'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => ListView(
        shrinkWrap: true,
        children: categories.map((cat) => ListTile(
          leading: Icon(_getCategoryIcon(cat), color: Colors.white),
          title: Text(cat, style: const TextStyle(color: Colors.white)),
          onTap: () {
            setState(() => widget.item.category = cat);
            Navigator.pop(context);
          },
        )).toList(),
      ),
    );
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'Shopping': return Icons.shopping_cart;
      case 'Work': return Icons.work;
      case 'Personal': return Icons.person;
      default: return Icons.label;
    }
  }

  Color _getPriorityColor() {
    switch (widget.item.priority) {
      case 'High': return Colors.redAccent;
      case 'Low': return Colors.blueAccent;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: _getPriorityColor(), width: 4)),
        ),
        child: Row(
          children: [
            // 1. CHECKBOX
            IconButton(
              icon: Icon(
                widget.item.isDone ? Icons.check_circle : Icons.circle_outlined,
                color: widget.item.isDone ? Colors.green : Colors.grey,
              ),
              onPressed: () {
                widget.onCheck();
                setState(() => widget.item.isDone = !widget.item.isDone);
                widget.onChanged();
              },
            ),

            // 2. TEXT & CATEGORY
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _textController,
                    onChanged: (val) => widget.item.text = val,
                    style: TextStyle(
                      color: widget.item.isDone ? Colors.grey : Colors.white,
                      decoration: widget.item.isDone ? TextDecoration.lineThrough : null,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Task Name',
                      hintStyle: TextStyle(color: Colors.white24),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                  // Small metadata row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _changeCategory,
                        child: Row(
                          children: [
                            Icon(_getCategoryIcon(widget.item.category), size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(widget.item.category, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _changePriority,
                        child: Text(
                          "${widget.item.priority} Priority", 
                          style: TextStyle(color: _getPriorityColor(), fontSize: 10, fontWeight: FontWeight.bold)
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),

            // 3. QUANTITY 
            GestureDetector(
            onTap: _editQuantity,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                "x${widget.item.quantity}",
                style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
            const SizedBox(width: 8),

            // 4. PRICE
             SizedBox(
            width: 60,
            child: TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              onChanged: (val) {
                widget.item.price = double.tryParse(val) ?? 0;
                widget.onChanged();
              },
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: '₹',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
              textAlign: TextAlign.right,
            ),
          ),

            // 5. DELETE
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white24, size: 18),
              onPressed: widget.onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart'; // REQUIRED
import 'package:http/http.dart' as http;      // For Scanner
import 'dart:convert';                        // For Scanner
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

  void _saveNote() async {
    _items.removeWhere((item) => item.text.isEmpty && item.price == 0);
    
    if (_titleController.text.isEmpty && _items.isEmpty) return;

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

  // --- 📤 SHARE FEATURE (FIXED) ---
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

  // --- 🕵️‍♂️ SCANNER FEATURE (FIXED) ---
  void _scanBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (!mounted) return;

    if (result != null && result is String) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Searching for product... 🔍")),
      );

      String? name = await _fetchProductName(result);
      
      if (mounted) {
        setState(() {
          _items.add(NoteItem(
            text: name ?? "Unknown Product ($result)", 
            price: 0 
          ));
        });
      }
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
      // ✅ FIXED: Switched to 'print' to avoid import errors
      print("Error fetching product: $e"); 
    }
    return null;
  }

  // --- ⏰ REMINDER FEATURE ---
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

    final DateTime scheduledTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    await NotificationService.scheduleNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000, 
      title: "Reminder: ${_titleController.text}",
      body: "Don't forget your shopping list! 🛒",
      scheduledTime: scheduledTime,
    );

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

  // --- 🧠 SMART CHECK ---
  void _handleItemBought(NoteItem item) async {
    if (item.price > 0 && !item.isDone) {
      final newTransaction = TransactionModel(
        id: const Uuid().v4(),
        amount: item.price,
        category: 'Shopping', 
        type: 'expense',
        date: DateTime.now(),
        note: "Bought: ${item.text}",
      );

      await FirestoreService().addTransaction(newTransaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Added ₹${item.price.toStringAsFixed(0)} to Expenses! 💸"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _updateTotal() {
    setState(() {});
  }

  double get _totalCost {
    double total = 0;
    for (var item in _items) {
      total += item.price;
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              widget.onCheck(); 
              setState(() {
                widget.item.isDone = !widget.item.isDone;
              });
              widget.onChanged();
            },
            child: Icon(
              widget.item.isDone ? Icons.check_box : Icons.check_box_outline_blank,
              color: widget.item.isDone ? const Color(0xFFFFD700) : Colors.grey,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _textController,
              onChanged: (val) {
                widget.item.text = val;
              },
              style: TextStyle(
                color: widget.item.isDone ? Colors.grey : Colors.white,
                decoration: widget.item.isDone ? TextDecoration.lineThrough : null,
              ),
              decoration: const InputDecoration(
                hintText: 'Item name',
                hintStyle: TextStyle(color: Colors.white24),
                border: InputBorder.none,
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              onChanged: (val) {
                widget.item.price = double.tryParse(val) ?? 0;
                widget.onChanged();
              },
              style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: '₹',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white24, size: 20),
            onPressed: widget.onDelete,
          ),
        ],
      ),
    );
  }
}
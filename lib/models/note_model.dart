import 'package:cloud_firestore/cloud_firestore.dart';

class NoteItem {
  String text;
  double price;
  bool isDone;
  int quantity;
  String priority; 
  String category; 

  NoteItem({
    required this.text, 
    this.price = 0, 
    this.isDone = false,
    this.quantity = 1,
    this.priority = 'Medium', // Default
    this.category = 'Other',  // Default
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'price': price,
      'isDone': isDone,
      'quantity': quantity,
      'priority': priority,
      'category': category,
    };
  }

  factory NoteItem.fromMap(Map<String, dynamic> map) {
    return NoteItem(
      text: map['text'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      isDone: map['isDone'] ?? false,
      quantity: map['quantity'] ?? 1,
      priority: map['priority'] ?? 'Medium',
      category: map['category'] ?? 'Other',
    );
  }
}

class NoteModel {
  String id;
  String title;
  DateTime date;
  List<NoteItem> items;
  int colorIndex;

  NoteModel({
    required this.id,
    required this.title,
    required this.date,
    required this.items,
    required this.colorIndex,
  });

  //Total Calculation: Price * Quantity
  double get totalCost {
    double total = 0;
    for (var item in items) {
      total += (item.price * item.quantity);
    }
    return total;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': Timestamp.fromDate(date),
      'items': items.map((x) => x.toMap()).toList(),
      'colorIndex': colorIndex,
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      items: List<NoteItem>.from(
        (map['items'] ?? []).map((x) => NoteItem.fromMap(x)),
      ),
      colorIndex: map['colorIndex'] ?? 0,
    );
  }
}
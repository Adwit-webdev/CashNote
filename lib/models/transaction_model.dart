import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  String id;
  double amount;
  String category;
  String type;
  DateTime date;
  String note;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
    required this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'type': type,
      'date': Timestamp.fromDate(date),
      'note': note,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      category: map['category'] ?? 'Other',
      type: map['type'] ?? 'expense',
      date: (map['date'] as Timestamp).toDate(),
      note: map['note'] ?? '',
    );
  }
}
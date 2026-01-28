import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note_model.dart';
import '../models/transaction_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- NOTES ---
  Stream<List<NoteModel>> getNotes() {
    return _db.collection('notes').orderBy('date', descending: true).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => NoteModel.fromMap({...doc.data(), 'id': doc.id})).toList());
  }

  Future<void> addNote(NoteModel note) async {
    await _db.collection('notes').doc(note.id).set(note.toMap());
  }

  Future<void> updateNote(NoteModel note) async {
    await _db.collection('notes').doc(note.id).update(note.toMap());
  }

  Future<void> deleteNote(String id) async {
    await _db.collection('notes').doc(id).delete();
  }

  // --- TRANSACTIONS ---
  Stream<List<TransactionModel>> getTransactions() {
    return _db.collection('transactions').orderBy('date', descending: true).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => TransactionModel.fromMap({...doc.data(), 'id': doc.id})).toList());
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await _db.collection('transactions').doc(transaction.id).set(transaction.toMap());
  }

  Future<void> deleteTransaction(String id) async {
    await _db.collection('transactions').doc(id).delete();
  }
  // lib/services/firestore_service.dart

// 1. Learn/Update the price for a barcode
Future<void> saveProductKnowledge(String barcode, String name, double price) async {
    try {
      await _db.collection('products').doc(barcode).set({
        'name': name,
        'price': price,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Merge ensures we don't delete other fields if we add them later
    } catch (e) {
      print("Error saving product knowledge: $e");
    }
  }
// 2. Fetch the remembered price for a barcode
Future<Map<String, dynamic>?> getProductKnowledge(String barcode) async {
    try {
      final doc = await _db.collection('products').doc(barcode).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print("Error getting product knowledge: $e");
      return null;
    }
  }
  // --- BUDGET FEATURE ---
  Future<void> setMonthlyBudget(double amount) async {
    await _db.collection('settings').doc('budget').set({
      'amount': amount, 
      'updatedAt': FieldValue.serverTimestamp()
    }, SetOptions(merge: true));
  }

  // Get the budget
  Stream<double> getMonthlyBudget() {
    return _db.collection('settings').doc('budget').snapshots().map(
      (doc) => doc.exists ? (doc.data()?['amount'] ?? 0.0).toDouble() : 0.0
    );
  }
}
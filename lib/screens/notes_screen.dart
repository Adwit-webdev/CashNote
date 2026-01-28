import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/note_model.dart';
import '../services/firestore_service.dart';
import 'add_note_screen.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Notes & Lists", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search, color: Colors.white)),
        ],
      ),
      body: StreamBuilder<List<NoteModel>>(
        stream: FirestoreService().getNotes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lightbulb_outline, size: 80, color: Colors.white24),
                  SizedBox(height: 10),
                  Text("Your ideas appear here", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final notes = snapshot.data!;

          // Pinterest-style Masonry Grid
          return MasonryGridView.count(
            padding: const EdgeInsets.all(10),
            crossAxisCount: 2, // 2 Columns
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            itemCount: notes.length,
            itemBuilder: (context, index) {
              return _buildNoteCard(context, notes[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddNoteScreen()));
        },
        backgroundColor: const Color(0xFFFFD700),
        child: const Icon(Icons.add, color: Colors.black, size: 30),
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, NoteModel note) {
    final List<Color> cardColors = [
      const Color(0xFF1E1E1E), // Default Dark
      const Color(0xFF2D2006), // Dark Yellow tint
      const Color(0xFF1A261C), // Dark Green tint
      const Color(0xFF2B1A1A), // Dark Red tint
      const Color(0xFF1A222E), // Dark Blue tint
    ];

    Color bgColor = cardColors[note.colorIndex % cardColors.length];

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => AddNoteScreen(note: note)));
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.title.isNotEmpty)
              Text(
                note.title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            if (note.title.isNotEmpty) const SizedBox(height: 8),
            
            // Show first 4 items of the checklist
            ...note.items.take(4).map((item) => Row(
              children: [
                Icon(
                  item.isDone ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 14,
                  color: item.isDone ? Colors.grey : Colors.white70,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    item.text,
                    style: TextStyle(
                      color: item.isDone ? Colors.grey : Colors.white70,
                      decoration: item.isDone ? TextDecoration.lineThrough : null,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )),
            
            if (note.items.length > 4)
              Padding(
                // ✅ FIXED HERE: using EdgeInsets.only(top: 5)
                padding: const EdgeInsets.only(top: 5),
                child: Text("+ ${note.items.length - 4} more items", style: const TextStyle(color: Colors.grey, fontSize: 10)),
              ),
              
            // Total Cost Badge
             if (note.totalCost > 0)
              Container(
                // ✅ FIXED HERE: using EdgeInsets.only(top: 10)
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Total: ₹${note.totalCost.toStringAsFixed(0)}",
                  style: const TextStyle(color: Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
import 'package:cash_note/services/emoji_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/note_model.dart';
import '../services/firestore_service.dart';
import 'add_note_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NoteModel>>(
      stream: FirestoreService().getNotes(),
      builder: (context, snapshot) {
        // ERROR RESOLVED: Extracting 'notes' here makes it available to the entire build method
        final List<NoteModel> notes = snapshot.data ?? [];

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text("Notes & Lists", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            actions: [
              // LATEST 2026: SearchAnchor is the modern way to handle search in Flutter
              SearchAnchor(
                builder: (context, controller) {
                  return IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () => controller.openView(),
                  );
                },
                suggestionsBuilder: (context, controller) {
                  final String keyword = controller.text.toLowerCase();
                  return notes
                      .where((note) => note.title.toLowerCase().contains(keyword))
                      .map((note) => ListTile(
                            title: Text(note.title, style: const TextStyle(color: Colors.white)),
                            onTap: () {
                              controller.closeView(note.title);
                              Navigator.push(context, MaterialPageRoute(builder: (context) => AddNoteScreen(note: note)));
                            },
                          ))
                      .toList();
                },
              ),
            ],
          ),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
              : notes.isEmpty
                  ? _buildEmptyState()
                  : MasonryGridView.count(
                      padding: const EdgeInsets.all(10),
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      itemCount: notes.length,
                      itemBuilder: (context, index) => _buildNoteCard(context, notes[index]),
                    ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddNoteScreen())),
            backgroundColor: const Color(0xFFFFD700),
            child: const Icon(Icons.add, color: Colors.black, size: 30),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
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

  Widget _buildNoteCard(BuildContext context, NoteModel note) {
    final List<Color> cardColors = [
      const Color(0xFF1E1E1E),
      const Color(0xFF2D2006),
      const Color(0xFF1A261C),
      const Color(0xFF2B1A1A),
      const Color(0xFF1A222E),
    ];
    Color bgColor = cardColors[note.colorIndex % cardColors.length];

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddNoteScreen(note: note))),
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
              Text(note.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            if (note.title.isNotEmpty) const SizedBox(height: 8),
            ...note.items.take(4).map((item) => Row(
                  children: [
                    Icon(item.isDone ? Icons.check_box : Icons.check_box_outline_blank,
                        size: 14, color: item.isDone ? Colors.grey : Colors.white70),
                    const SizedBox(width: 5),
                    Expanded(
  child: Text(
    // ✅ ADDED: Applying the Emoji Service here
    EmojiService.addEmoji(item.text), 
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
                padding: const EdgeInsets.only(top: 5), // REMOVED redundant 'const' here
                child: Text("+ ${note.items.length - 4} more items", style: const TextStyle(color: Colors.grey, fontSize: 10)),
              ),
            if (note.totalCost > 0)
              Container(
                margin: const EdgeInsets.only(top: 10), // REMOVED redundant 'const' here
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
                child: Text("Total: ₹${note.totalCost.toStringAsFixed(0)}",
                    style: const TextStyle(color: Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}
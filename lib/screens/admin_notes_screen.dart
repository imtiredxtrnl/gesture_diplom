import 'package:flutter/material.dart';
import '../services/note_service.dart';
import 'edit_note_screen.dart';

class AdminNotesScreen extends StatefulWidget {
  final String language;
  const AdminNotesScreen({Key? key, required this.language}) : super(key: key);

  @override
  State<AdminNotesScreen> createState() => _AdminNotesScreenState();
}

class _AdminNotesScreenState extends State<AdminNotesScreen> {
  List<dynamic> notes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotes();
  }

  Future<void> fetchNotes() async {
    final result = await NoteService.getAllNotes(widget.language);
    setState(() {
      notes = result;
      isLoading = false;
    });
  }

  void onDelete(String noteId) async {
    await NoteService.deleteNote(noteId);
    fetchNotes();
  }

  void onDuplicate(Map<String, dynamic> note) async {
    final duplicated = Map<String, dynamic>.from(note);
    duplicated.remove('id');
    duplicated['title'] = duplicated['title'] + ' (копія)';
    duplicated['language'] = widget.language == 'uk' ? 'en' : 'uk';
    duplicated['content'] = duplicated['content'];
    duplicated['imagePaths'] = List<String>.from(duplicated['imagePaths']);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditNoteScreen(note: duplicated, language: duplicated['language']),
      ),
    );
    fetchNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Адмін: Конспекти'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditNoteScreen(language: widget.language),
                ),
              );
              fetchNotes();
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return Card(
                  child: ListTile(
                    title: Text(note['title'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditNoteScreen(
                                  note: note,
                                  language: widget.language,
                                ),
                              ),
                            );
                            fetchNotes();
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.copy),
                          tooltip: 'Дублировать',
                          onPressed: () => onDuplicate(note),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => onDelete(note['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
} 
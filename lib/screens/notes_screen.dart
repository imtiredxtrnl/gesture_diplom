import 'package:flutter/material.dart';
import '../services/note_service.dart';
import 'package:sign_language_app/l10n/app_localizations.dart';
import 'note_detail_screen.dart';
import '../services/auth_service.dart';

class NotesScreen extends StatefulWidget {
  final String? userId;
  final List<String> completedNotes;
  const NotesScreen({Key? key, this.userId, required this.completedNotes}) : super(key: key);

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<dynamic> notes = [];
  bool isLoading = true;
  String language = 'uk';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    language = Localizations.localeOf(context).languageCode;
    fetchNotes();
  }

  Future<void> fetchNotes() async {
    setState(() { isLoading = true; });
    final result = await NoteService.getAllNotes(language);
    setState(() {
      notes = result;
      isLoading = false;
    });
  }

  void onNoteCompleted(String noteId) async {
    if (widget.userId != null) {
      await AuthService.saveCompletedNote(noteId);
      setState(() {
        widget.completedNotes.add(noteId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    language = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.notes)),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                final completed = widget.completedNotes.contains(note['id']);
                return Card(
                  color: completed ? Colors.green[100] : null,
                  child: ListTile(
                    title: Text(note['title'] ?? ''),
                    trailing: completed
                        ? Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NoteDetailScreen(
                            noteId: note['id'],
                            onCompleted: () => onNoteCompleted(note['id']),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class NoteDetailScreen extends StatefulWidget {
  final String noteId;
  final VoidCallback onCompleted;
  const NoteDetailScreen({Key? key, required this.noteId, required this.onCompleted}) : super(key: key);

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  Map<String, dynamic>? note;
  List<String> images = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNote();
  }

  Future<void> fetchNote() async {
    final result = await NoteService.getNote(widget.noteId);
    setState(() {
      note = result['note'];
      images = List<String>.from(result['images'] ?? []);
      isLoading = false;
    });
  }

  Widget buildContentWithImages(String content) {
    final regex = RegExp(r'\[img:(\d+)\]');
    final spans = <InlineSpan>[];
    int last = 0;
    for (final match in regex.allMatches(content)) {
      if (match.start > last) {
        spans.add(TextSpan(text: content.substring(last, match.start)));
      }
      final idx = int.tryParse(match.group(1)!);
      if (idx != null && idx < images.length) {
        spans.add(WidgetSpan(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Image.memory(
              NoteService.base64ToBytes(images[idx]),
              height: 180,
              fit: BoxFit.contain,
            ),
          ),
        ));
      }
      last = match.end;
    }
    if (last < content.length) {
      spans.add(TextSpan(text: content.substring(last)));
    }
    return RichText(text: TextSpan(style: TextStyle(color: Colors.black, fontSize: 16), children: spans));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(note?['title'] ?? '')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: buildContentWithImages(note?['content'] ?? ''),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      widget.onCompleted();
                      Navigator.pop(context);
                    },
                    child: Text('Перейти далі'),
                  ),
                ],
              ),
            ),
    );
  }
} 
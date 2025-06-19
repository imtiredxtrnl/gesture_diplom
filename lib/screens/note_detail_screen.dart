import 'package:flutter/material.dart';
import '../services/note_service.dart';

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
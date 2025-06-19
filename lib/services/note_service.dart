import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:io';

class NoteService {
  static WebSocketChannel _createChannel() {
    return WebSocketChannel.connect(
      Uri.parse(
        Platform.isAndroid ? 'ws://10.0.2.2:8765' : 'ws://localhost:8765'
      ),
    );
  }

  static Future<List<dynamic>> getAllNotes(String language) async {
    print('>>> NoteService: getAllNotes called for language: ' + language);
    final channel = _createChannel();
    final req = jsonEncode({'type': 'note', 'action': 'get_all', 'language': language});
    channel.sink.add(req);
    final resp = await channel.stream.first;
    channel.sink.close();
    final data = jsonDecode(resp);
    return data['notes'] ?? [];
  }

  static Future<Map<String, dynamic>> getNote(String noteId) async {
    print('>>> NoteService: getNote called for noteId: ' + noteId);
    final channel = _createChannel();
    final req = jsonEncode({'type': 'note', 'action': 'get', 'id': noteId});
    channel.sink.add(req);
    final resp = await channel.stream.first;
    channel.sink.close();
    return jsonDecode(resp);
  }

  static Future<void> createNote(Map<String, dynamic> data) async {
    final channel = _createChannel();
    final req = jsonEncode({'type': 'note', 'action': 'create', ...data});
    channel.sink.add(req);
    await channel.stream.first;
    channel.sink.close();
  }

  static Future<void> updateNote(String id, Map<String, dynamic> data) async {
    final channel = _createChannel();
    final req = jsonEncode({'type': 'note', 'action': 'update', 'id': id, ...data});
    channel.sink.add(req);
    await channel.stream.first;
    channel.sink.close();
  }

  static Future<void> deleteNote(String id) async {
    final channel = _createChannel();
    final req = jsonEncode({'type': 'note', 'action': 'delete', 'id': id});
    channel.sink.add(req);
    await channel.stream.first;
    channel.sink.close();
  }

  static Future<String> uploadImage(Uint8List bytes, String filename) async {
    final channel = _createChannel();
    final base64img = base64Encode(bytes);
    final req = jsonEncode({'type': 'note', 'action': 'upload_image', 'image': base64img, 'filename': filename});
    channel.sink.add(req);
    final resp = await channel.stream.first;
    channel.sink.close();
    final data = jsonDecode(resp);
    return data['path'] ?? '';
  }

  static Uint8List base64ToBytes(String base64str) {
    return base64Decode(base64str);
  }

  static Future<String> translateNoteText(String text, String srcLang, String destLang) async {
    final channel = _createChannel();
    final req = jsonEncode({
      'type': 'note_translate',
      'text': text,
      'src_lang': srcLang,
      'dest_lang': destLang,
    });
    channel.sink.add(req);
    final resp = await channel.stream.first;
    channel.sink.close();
    final data = jsonDecode(resp);
    if (data['status'] == 'success') {
      return data['translated'] ?? '';
    } else {
      throw Exception(data['message'] ?? 'Translation error');
    }
  }
} 
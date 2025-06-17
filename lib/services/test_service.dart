import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/test.dart';

class TestService {
  WebSocketChannel? _channel;
  final _tests = <Test>[];

  void initialize(WebSocketChannel channel) {
    _channel = channel;
  }

  Future<List<Test>> getAllTests() async {
    if (_channel == null) {
      throw Exception('WebSocket channel not initialized');
    }

    try {
      _channel!.sink.add(jsonEncode({
        'action': 'get_tests',
      }));

      final response = await _channel!.stream.first;
      final data = jsonDecode(response);

      if (data['status'] == 'success') {
        final List<dynamic> testsData = data['data'];
        _tests.clear();
        _tests.addAll(
          testsData.map((t) => Test.fromJson(t)).toList(),
        );
        return _tests;
      } else {
        throw Exception(data['message'] ?? 'Failed to load tests');
      }
    } catch (e) {
      throw Exception('Error loading tests: $e');
    }
  }

  Future<void> createTest(Test test) async {
    if (_channel == null) {
      throw Exception('WebSocket channel not initialized');
    }

    try {
      _channel!.sink.add(jsonEncode({
        'action': 'create_test',
        'data': test.toJson(),
      }));

      final response = await _channel!.stream.first;
      final data = jsonDecode(response);

      if (data['status'] != 'success') {
        throw Exception(data['message'] ?? 'Failed to create test');
      }
    } catch (e) {
      throw Exception('Error creating test: $e');
    }
  }

  Future<void> updateTest(Test test) async {
    if (_channel == null) {
      throw Exception('WebSocket channel not initialized');
    }

    try {
      _channel!.sink.add(jsonEncode({
        'action': 'update_test',
        'data': test.toJson(),
      }));

      final response = await _channel!.stream.first;
      final data = jsonDecode(response);

      if (data['status'] != 'success') {
        throw Exception(data['message'] ?? 'Failed to update test');
      }
    } catch (e) {
      throw Exception('Error updating test: $e');
    }
  }

  Future<void> deleteTest(String id) async {
    if (_channel == null) {
      throw Exception('WebSocket channel not initialized');
    }

    try {
      _channel!.sink.add(jsonEncode({
        'action': 'delete_test',
        'data': {'id': id},
      }));

      final response = await _channel!.stream.first;
      final data = jsonDecode(response);

      if (data['status'] != 'success') {
        throw Exception(data['message'] ?? 'Failed to delete test');
      }
    } catch (e) {
      throw Exception('Error deleting test: $e');
    }
  }
} 
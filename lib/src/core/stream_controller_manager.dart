import 'dart:async' show Stream, StreamController;
import 'package:monitor/src/models/api_log_entry.dart';

class StreamControllerManager {
  final StreamController<List<LogEntry>> _controller =
      StreamController<List<LogEntry>>.broadcast();

  Stream<List<LogEntry>> get stream => _controller.stream;

  void notify(List<LogEntry> logs) {
    if (_controller.hasListener) {
      _controller.add(logs);
    }
  }

  void dispose() {
    _controller.close();
  }
}

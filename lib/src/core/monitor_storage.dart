import 'package:monitor/src/models/api_log_entry.dart';
import 'package:monitor/src/models/config.dart';

class MonitorStorage {
  MonitorStorage(this._config);

  final MonitorConfig _config;
  final Map<String, LogEntry> _logsById = {};
  final List<String> _logOrder = [];
  final Map<String, Stopwatch> _activeStopwatches = {};

  void addLog(LogEntry entry) {
    if (!_config.enableLogStorage) return;
    _logsById[entry.id] = entry;
    _logOrder.add(entry.id);
    if (_logOrder.length > _config.maxLogs) {
      final String oldestId = _logOrder.removeAt(0);
      _logsById.remove(oldestId);
      _activeStopwatches.remove(oldestId);
    }
  }

  void updateLog(String id, LogEntry entry) {
    if (!_config.enableLogStorage) return;
    if (!_logsById.containsKey(id)) return;
    _logsById[id] = entry;
    _activeStopwatches.remove(id);
  }

  void clear() {
    _logsById.clear();
    _logOrder.clear();
    _activeStopwatches.clear();
  }

  LogEntry? getLog(String id) => _logsById[id];

  Stopwatch? getStopwatch(String id) => _activeStopwatches[id];

  void startStopwatch(String id) {
    final Stopwatch stopwatch = Stopwatch()..start();
    _activeStopwatches[id] = stopwatch;
  }

  void removeStopwatch(String id) {
    _activeStopwatches.remove(id);
  }

  List<LogEntry> get logs {
    return List.unmodifiable(
      _logOrder.reversed.map((id) => _logsById[id]!).toList(),
    );
  }

  List<HttpLogEntry> get httpLogs => logs.whereType<HttpLogEntry>().toList();

  List<MessageLogEntry> get messageLogs =>
      logs.whereType<MessageLogEntry>().toList();

  List<HttpLogEntry> getLogsByState(HttpLogState state) =>
      httpLogs.where((log) => log.state == state).toList();

  List<HttpLogEntry> getLogsByMethod(String method) =>
      httpLogs.where((log) => log.method == method).toList();

  List<LogEntry> get errorLogs => logs.where((log) {
    return switch (log) {
      HttpLogEntry entry => entry.isError,
      MessageLogEntry entry => entry.isError,
    };
  }).toList();

  List<HttpLogEntry> get successLogs =>
      httpLogs.where((log) => log.isSuccess).toList();

  List<HttpLogEntry> get pendingLogs =>
      httpLogs.where((log) => log.isPending).toList();

  List<LogEntry> search(String query) {
    final String lowerQuery = query.toLowerCase();
    return logs.where((log) {
      return switch (log) {
        HttpLogEntry entry =>
          entry.url.toLowerCase().contains(lowerQuery) ||
              entry.method.toLowerCase().contains(lowerQuery),
        MessageLogEntry entry =>
          entry.message.toLowerCase().contains(lowerQuery) ||
              (entry.url?.toLowerCase().contains(lowerQuery) ?? false),
      };
    }).toList();
  }
}

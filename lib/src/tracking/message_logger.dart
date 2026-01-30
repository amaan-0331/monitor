import 'package:monitor/src/core/monitor_storage.dart';
import 'package:monitor/src/core/stream_controller_manager.dart';
import 'package:monitor/src/models/api_log_entry.dart';
import 'package:monitor/src/output/console_printer.dart';
import 'package:monitor/src/utils/id_generator.dart';

class MessageLogger {
  MessageLogger({
    required this.storage,
    required this.printer,
    required this.streamManager,
  });

  final MonitorStorage storage;
  final ConsolePrinter printer;
  final StreamControllerManager streamManager;

  void log(
    String message, {
    MessageLevel level = MessageLevel.info,
    String? url,
  }) {
    final MessageLogEntry entry = MessageLogEntry(
      id: MonitorIdGenerator.generate('MSG'),
      timestamp: DateTime.now(),
      level: level,
      message: message,
      url: url,
    );
    storage.addLog(entry);
    streamManager.notify(storage.logs);
    Future.microtask(() => printer.printMessage(entry));
  }

  void info(String message) => log(message, level: MessageLevel.info);
  void warning(String message) => log(message, level: MessageLevel.warning);
  void error(String message) => log(message, level: MessageLevel.error);
}

<div align="center">

# Monitor

[![pub.dev](https://img.shields.io/pub/v/monitor.svg?label=pub.dev)](https://pub.dev/packages/monitor)
[![platforms](https://img.shields.io/badge/platforms-Android%20%7C%20iOS%20%7C%20Web%20%7C%20macOS%20%7C%20Windows%20%7C%20Linux-blue)](#)

</div>

Monitor is a Flutter package that captures and visualizes API activity in your app. It provides structured logging of HTTP lifecycles and app messages, in-memory storage with search and filters, console output with privacy-aware redaction, and a built-in viewer UI to explore requests and responses.

- Real-time table and list viewers with filters and search
- End-to-end HTTP lifecycle tracking (start, complete, fail/timeout)
- Message logging (info, warning, error) with optional context URL
- Structured in-memory storage and broadcast streams
- Console printing with ANSI colors and configurable verbosity
- Privacy-focused redaction of headers and body keys

## Installation

Add the dependency:

```yaml
dependencies:
  monitor: ^0.1.0
```

Alternatively:

```bash
flutter pub add monitor
```

Import the package:

```dart
import 'package:monitor/monitor.dart';
```

## Quick Start

Initialize the package once at app startup, providing an optional configuration:

```dart
import 'package:flutter/material.dart';
import 'package:monitor/monitor.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Monitor.init();

  runApp(const MyApp());
}

const navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: Monitor.navigatorKey = navigatorKey,
      home: const HomePage(),
    );
  }
}


```

Open the viewer anywhere:

```dart
import 'package:monitor/monitor.dart';

ElevatedButton(
  // Requires Monitor.navigatorKey set on MaterialApp
  onPressed: showMonitor,
  child: const Text('Open Monitor'),
);
```

Log messages:

```dart
Monitor.info('App started');
Monitor.warning('Cache miss for /users');
Monitor.error('Unhandled exception occurred');
Monitor.cacheHit(cacheKey: '/users?page=1');
```

Track HTTP lifecycle manually:

```dart
final id = Monitor.startRequest(
  method: 'GET',
  uri: Uri.parse('https://api.example.com/users'),
  headers: {'accept': 'application/json'},
);

try {
  // Perform your request with any HTTP client...
  // On success:
  Monitor.completeRequest(
    id: id,
    statusCode: 200,
    responseHeaders: {'content-type': 'application/json'},
    responseBody: '{"data":[]}',
    responseSize: 12,
  );
} catch (_) {
  Monitor.failRequest(
    id: id,
    errorMessage: 'Network error',
    isTimeout: false,
  );
}
```

Embed the viewer in a route:

```dart
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => const MonitorView()),
);
```

### Monitor

- `static void init({MonitorConfig? config})`
- `static void updateConfig(MonitorConfig newConfig)`
- `static GlobalKey<NavigatorState>? navigatorKey`
- `Stream<List<LogEntry>> get logStream`
- `List<LogEntry> get logs`
- `List<HttpLogEntry> get httpLogs`
- `List<MessageLogEntry> get messageLogs`
- `List<LogEntry> get errorLogs`
- `List<HttpLogEntry> get successLogs`
- `List<HttpLogEntry> get pendingLogs`
- `List<LogEntry> search(String query)`
- `void clearLogs()`
- `void dispose()`
- `static String startRequest({required String method, required Uri uri, Map<String, String>? headers, String? body, int? bodyBytes})`
- `static void completeRequest({required String id, required int statusCode, Map<String, String>? responseHeaders, String? responseBody, int? responseSize})`
- `static void failRequest({required String id, required String errorMessage, bool isTimeout = false})`
- `static void message(String msg, {MessageLevel level = MessageLevel.info, String? url})`
- `static void info(String msg)`
- `static void warning(String msg)`
- `static void error(String msg)`

### MonitorView and showMonitor

- `void showMonitor()` opens a new route using `Monitor.navigatorKey`
- `class MonitorView extends StatefulWidget` provides a dark-themed UI with:
  - List and Table views
  - Filters by HTTP state and method
  - Message vs HTTP toggles
  - Log details modal with tabs (Overview, Request, Response)

### Models

- `sealed class LogEntry` base type
- `final class HttpLogEntry extends LogEntry`
  - `method`, `url`, `requestHeaders`, `requestBody`, `requestSize`
  - `responseHeaders`, `responseBody`, `responseSize`, `statusCode`, `duration`
  - `errorMessage`, `state`
  - helpers: `isPending`, `isSuccess`, `isError`, `isCompleted`, `durationText`, `responseSizeText`, `prettyRequestBody`, `prettyResponseBody`
- `final class MessageLogEntry extends LogEntry`
  - `level`, `message`, `url`
- `enum HttpLogState { pending, success, error, timeout }`
- `enum MessageLevel { info, warning, error }`

### Configuration

`class MonitorConfig`:

- Storage: `maxLogs`, `enableLogStorage`
- Console: `consoleFormat` (`none` | `simple` | `verbose`)
- Truncation: `maxBodyLength`, `maxHeaderLength`
- Redaction: `headerRedactionKeys`, `bodyRedactionKeys`
- Feature toggles: `logRequestHeaders`, `logResponseHeaders`, `logRequestBody`, `logResponseBody`
- Methods: `copyWith(...)`, `truncateIfNeeded(text, maxLength)`

Example configuration:

```dart
final config = MonitorConfig(
  maxLogs: 1000,
  consoleFormat: ConsoleLogFormat.simple,
  maxBodyLength: 5000,
  headerRedactionKeys: const ['authorization', 'x-api-key', 'cookie'],
  bodyRedactionKeys: const ['password', 'token', 'secret'],
  logRequestHeaders: true,
  logRequestBody: true,
  logResponseHeaders: true,
  logResponseBody: true,
);

Monitor.updateConfig(config);
```

## Configuration & Customization

- Initialize with `Monitor.init(config: ...)` or update later via `Monitor.updateConfig(...)`.
- Set `navigatorKey` on `MaterialApp` to use `showMonitor()` from anywhere.
- Redaction keys protect sensitive data in headers and bodies before storage/printing.
- Console verbosity controls terminal output; disable via `ConsoleLogFormat.none`.
- Storage can be disabled (`enableLogStorage: false`) to use console-only printing.

## Changelog

Semantic versioning is used. See `CHANGELOG.md` for full history.

- 0.1.0: Initial release with HTTP tracking, message logs, viewer UI, console output, redaction.

## Contributing

- Fork the repository and create feature branches from `main`.
- Follow the code style and patterns used across the package.
- Format and analyze locally:

```bash
flutter pub get
flutter analyze
```

- Ensure any new UI uses `CustomColors`, const constructors where possible, and disposes controllers.
- Open a Pull Request with a clear description and screenshots when UI changes are involved.

## License

MIT License. See `LICENSE` for details.

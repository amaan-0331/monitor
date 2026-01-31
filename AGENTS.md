# AGENTS.md - Guidelines for AI Coding Agents

This is a Flutter package called `monitor` that provides API logging and network traffic visualization capabilities. It's a library package, not a standalone application.

## Project Structure

```
lib/
  monitor.dart              # Main entry point, exports public API
  src/
    monitor.dart            # Main facade delegating to components
    core/
      monitor_storage.dart              # In-memory log storage and queries
      stream_controller_manager.dart    # Broadcast stream management
    tracking/
      http_request_tracker.dart         # HTTP lifecycle tracking
      message_logger.dart               # Message logging
    privacy/
      monitor_redactor.dart             # Privacy & redaction logic
    output/
      console_printer.dart              # Console output formatting
    models/
      api_log_entry.dart    # Data model for log entries
      adapter.dart          # (Empty) Adapter interface placeholder
    ui/
      viewer.dart           # Main MonitorView widget
      table_viewer.dart     # Paginated table viewer
      theme.dart            # CustomColors theme constants
      log_details/
        details_sheet.dart                  # HTTP details sheet + tabs
        message_log_details_sheet.dart      # Message log details sheet
        response_preview.dart               # Raw/JSON/HTML preview component
        syntax_highlighter.dart             # JSON syntax highlighting
        widgets/
          shared_widgets.dart
          state_widgets.dart
    utils/
      formatters.dart       # Formatting utilities
      functions.dart        # Clipboard and misc functions
      id_generator.dart     # ID generation utility
      color_support.dart    # Terminal color detection
```

## Build, Lint Commands

### Dependencies

```bash
flutter pub get
```

### Analyze (Lint)

```bash
flutter analyze
```

### Build (Dry Run)

```bash
flutter pub publish --dry-run
```

## Code Style Guidelines

### Imports

1. Order imports in this sequence, separated by blank lines:
   - `dart:` core libraries
   - `package:flutter/` imports
   - `package:monitor/` (this package)
   - Third-party packages

2. Use package imports for internal files:
   ```dart
   import 'package:monitor/src/models/api_log_entry.dart';
   ```

### Details UI Architecture

- Entry API: `showLogDetails(BuildContext, {required LogEntry log})` opens a modal bottom sheet and dispatches to HTTP or Message sheets.
- HTTP details: `HttpLogDetailsSheet(entry)` with a tabbed layout:
  - Overview tab: status/duration/sizes, URL, error code block
  - Request tab: headers (JSON) and body (`prettyRequestBody` when available)
  - Response tab: headers + response preview, with pending/error handling
- Message details: `MessageLogDetailsSheet(entry)` single-page sheet showing level/time, message, and optional URL.
- Response preview: mode chips (Raw, JSON, conditional HTML), animated content switcher, async JSON formatting, configurable wrapping flags.
- Shared widgets for consistent styling: `HandleBar`, `Section`, `InfoGrid`, `CodeBlock`, `ModeChip`.
- State widgets: `EmptyState`, `PendingState`, `LoadingBlock`, `ErrorBlock`.

### Formatting

- Use `flutter format` or `dart format` with default settings

### Types

1. Always specify types explicitly for:
   - Class fields
   - Function return types
   - Function parameters
   - Generics (e.g., `List<ApiLogEntry>`, `Map<String, String>`)

2. Use `final` for immutable variables:

   ```dart
   final List<ApiLogEntry> _logs = [];
   ```

3. Use nullable types with `?` suffix:
   ```dart
   final String? method;
   final int? statusCode;
   ```

### Widget Patterns

1. Use `const` constructors when possible:

   ```dart
   const _Badge({required this.label, required this.color});
   ```

2. Private widgets use underscore prefix:

   ```dart
   class _LogEntryCard extends StatelessWidget
   ```

3. Use `super.key` in widget constructors:

   ```dart
   const MonitorView({super.key});
   ```

4. Dispose controllers in StatefulWidget:
   ```dart
   @override
   void dispose() {
     _searchController.dispose();
     _scrollController.dispose();
     super.dispose();
   }
   ```

### Error Handling

1. Use `on FormatException` for JSON parsing:

   ```dart
   try {
     return json.decode(responseBody!);
   } on FormatException {
     return responseBody;
   }
   ```

2. Use `on Exception` for general exception handling:
   ```dart
   try {
     return Platform.isAndroid;
   } on Exception {
     return false;
   }
   ```

### Color and Theme

Use the `CustomColors` abstract class for all colors:

```dart
color: CustomColors.primary
color: CustomColors.error
```

Available colors: `surface`, `surfaceContainer`, `surfaceContainerHigh`, `onSurface`, `onSurfaceVariant`, `outline`, `outlineVariant`, `primary`, `secondary`, `tertiary`, `error`, `success`, `warning`, `orange`, `teal`, `divider`

### Singleton Pattern

Use private constructor with static instance:

```dart
class Monitor {
  Monitor._();
  static final Monitor _instance = Monitor._();
  static Monitor get instance => _instance;
}
```

### Stream Management

Use broadcast StreamController for multiple listeners:

```dart
final _logStreamController = StreamController<List<ApiLogEntry>>.broadcast();
Stream<List<ApiLogEntry>> get logStream => _logStreamController.stream;
```

## Linting

This project uses `flutter_lints` package. The analysis_options.yaml extends:

```yaml
include: package:flutter_lints/flutter.yaml
```

## Common Patterns

### Immutable Return Lists

```dart
List<ApiLogEntry> get logs => List.unmodifiable(_logs.reversed.toList());
```

### copyWith Pattern

Implement `copyWith` for data classes with optional parameters.

### Getter-based Computed Properties

Use getters for derived values:

```dart
bool get isError => statusCode != null && statusCode! >= 400;
String get durationText => '${duration!.inMilliseconds}ms';
```

## Notes

- SDK constraint: `^3.10.4`
- Flutter constraint: `>=1.17.0`
- No test files exist currently - add tests in `test/` directory following `*_test.dart` naming
- Public API exports only: `Monitor` class and `MonitorView` widget
- Package exports: [lib/monitor.dart](lib/monitor.dart) re-exports `src/monitor.dart` (facade), `src/ui/viewer.dart`, and `src/models/config.dart`
- Internal UI should import the facade via `package:monitor/monitor.dart` instead of internal service paths
- Details UI APIs (showLogDetails, sheets, preview, widgets) are internal and not exported; they are invoked from MonitorView/Table viewer interactions.

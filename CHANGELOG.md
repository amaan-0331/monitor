## 1.1.0

### Features

- Add multipart/form-data parsing with part metadata and sizes
- Surface multipart summaries in request details UI and console output
- Support raw request bytes for accurate multipart inspection

## 1.0.0

- Initial stable release

## 0.0.14

### Documentation

- Add AGENTS.md update pubspec with repository

## 0.0.13

### Features

- Enhance demo with diverse API endpoints and authentication
- Add comprehensive example requests to showcase network monitoring capabilities
- Switch from JSONPlaceholder to DummyJSON API to access richer endpoints including products, users, posts, todos, quotes, and authentication flows
- Implement full CRUD operations, search, error simulation, and periodic requests cycling through multiple resources
- Provides a more realistic demonstration of the library's functionality across various HTTP methods and response scenarios

## 0.0.12

### Refactoring

- Restructure log details into modular components
- Split monolithic details.dart into separate feature-focused files
- Add syntax highlighting for JSON responses with color-coded tokens
- Create reusable widget components (HandleBar, Section, InfoGrid, etc.)
- Implement response preview with JSON/raw/HTML view modes
- Improve visual consistency with updated theme colors and spacing
- Maintain existing functionality while enhancing maintainability

## 0.0.11

### Refactoring

- Pass redactor to ConsolePrinter for body redaction

## 0.0.10

### Refactoring

- Restructure monitor library into modular architecture
- Split monolithic service.dart into focused modules for better separation of concerns
- Move core logic into monitor.dart as main entry point
- Extract storage management to monitor_storage.dart
- Create dedicated trackers for HTTP and message logging
- Add privacy redaction module for sensitive data
- Introduce console printer with color support
- Add utility classes for ID generation and color detection
- Update imports to use new modular structure

## 0.0.9

### Refactoring

- Centralize duration tracking and optimize logging
- Replace manual Stopwatch usage in example with centralized tracking in Monitor
- Add internal _activeStopwatches map to store stopwatches per request ID
- Cache color support check to avoid repeated platform detection
- Optimize redaction and truncation with single-pass processing
- Stream notifications only when listeners are present
- Use asynchronous printing to avoid blocking main thread
- Improve memory management by clearing stopwatches when logs are trimmed

## 0.0.8

### Features

- Add config model and refactor logging system
- Introduce MonitorConfig class for centralized configuration
- Implement configurable logging formats (simple/verbose)
- Add header/body redaction with customizable keys
- Support configurable truncation limits
- Simplify Monitor.init() interface

## 0.0.7

### Refactoring

- Update iOS AppDelegate and Info.plist for Flutter engine
- Replace debugPrint with dev.log

## 0.0.6

### Features

- Enhance network monitor UI and add periodic requests
- Refactor UI with cards for better organization and visual appeal
- Add periodic request functionality with toggle switch
- Improve error handling with request wrapper
- Update theme colors and app title
- Add loading states for action buttons

## 0.0.5

### Features

- Add column sorting functionality to log table
- Implement sorting for all columns in the log table by adding sort state variables and a sorting method
- Each column can now be sorted in ascending or descending order by clicking the column header

## 0.0.4

### Features

- Refactor log system to support HTTP lifecycle and message logs
- Replace ApiLogEntry with sealed LogEntry class hierarchy (HttpLogEntry, MessageLogEntry)
- Add HTTP request lifecycle tracking with startRequest/completeRequest/failRequest API
- Introduce message logging API with info/warning/error levels
- Redesign UI to display different log types with appropriate styling
- Improve console logging with colored output and better formatting
- Add detailed error handling and request state tracking

## 0.0.3

### Refactoring

- Restructure log viewer and utility functions
- Extract utility functions to separate files
- Simplify ApiLogType enum and model logic
- Add table view for logs
- Improve UI components and organization

## 0.0.2

### Features

- Add example app

## 0.0.1

### Initial Release

- Initial commit with basic implementation and UI

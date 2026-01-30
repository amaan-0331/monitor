import 'dart:developer' as dev show log;
import 'package:monitor/src/models/api_log_entry.dart';
import 'package:monitor/src/models/config.dart';
import 'package:monitor/src/utils/color_support.dart';
import 'package:monitor/src/utils/formatters.dart';

class ConsolePrinter {
  ConsolePrinter(this._config);
  final MonitorConfig _config;

  void printInitialization() {
    if (!_config.consoleFormat.isEnabled) return;
    final String timestamp = DateTime.now().toIso8601String();

    if (_config.consoleFormat == ConsoleLogFormat.simple) {
      final String message =
          'ℹ API Service Initialized | '
          'Storage: ${_config.enableLogStorage ? 'On' : 'Off'} | '
          'MaxLogs: ${_config.maxLogs}';
      if (ColorSupport.isSupported) {
        dev.log('${AnsiColors.white}[$timestamp] $message${AnsiColors.reset}');
      } else {
        dev.log('[$timestamp] $message');
      }
      return;
    }

    final String separator = '=' * 80;
    final List<String> lines = [
      '+$separator+',
      '| [SYSTEM] $timestamp',
      '| API Service Initialized',
      '| Console Format: ${_config.consoleFormat.name}',
      '| Log Storage: ${_config.enableLogStorage ? 'Enabled' : 'Disabled'}',
      '| Max Logs: ${_config.maxLogs}',
      '+$separator+',
    ];
    if (ColorSupport.isSupported) {
      dev.log(
        lines
            .map((line) => '${AnsiColors.white}$line${AnsiColors.reset}')
            .join('\n'),
      );
    } else {
      dev.log(lines.join('\n'));
    }
  }

  void printRequest(HttpLogEntry entry) {
    if (!_config.consoleFormat.isEnabled) return;
    final String timestamp = entry.timestamp.toIso8601String();

    if (_config.consoleFormat == ConsoleLogFormat.simple) {
      _printSimpleRequest(entry, timestamp);
      return;
    }

    final String separator = '=' * 80;
    final List<String> lines = [
      '+$separator+',
      '| [REQUEST] $timestamp',
      '| +- REQUEST [${entry.id}] ------------------------------------',
      '| | ${entry.method} ${entry.url}',
      if (entry.requestHeaders != null && entry.requestHeaders!.isNotEmpty) ...[
        '| | Headers:',
        ...prettyJson(
          entry.requestHeaders!,
        ).split('\n').map((line) => '| |   $line'),
      ],
      if (entry.requestBody != null && entry.requestBody!.isNotEmpty) ...[
        '| | Body (${formatBytes(entry.requestSize ?? 0)}):',
        ...entry.requestBody!.split('\n').map((line) => '| |   $line'),
      ],
      '| +------------------------------------------------------------',
      '+$separator+',
    ];
    if (ColorSupport.isSupported) {
      dev.log(
        lines
            .map((line) => '${AnsiColors.cyan}$line${AnsiColors.reset}')
            .join('\n'),
      );
    } else {
      dev.log(lines.join('\n'));
    }
  }

  void _printSimpleRequest(HttpLogEntry entry, String timestamp) {
    final String size = entry.requestSize != null
        ? formatBytes(entry.requestSize!)
        : '';
    final String message = '→ ${entry.method} ${entry.url} $size';
    if (ColorSupport.isSupported) {
      dev.log('${AnsiColors.cyan}[$timestamp] $message${AnsiColors.reset}');
    } else {
      dev.log('[$timestamp] $message');
    }
  }

  void printResponse(HttpLogEntry entry) {
    final String timestamp = DateTime.now().toIso8601String();
    if (_config.consoleFormat == ConsoleLogFormat.simple) {
      _printSimpleResponse(entry, timestamp);
      return;
    }

    final String separator = '=' * 80;
    final int status = entry.statusCode ?? 0;
    late final String statusCategory;
    late final String color;
    late final String statusIcon;
    if (status >= 200 && status < 300) {
      statusCategory = 'SUCCESS';
      color = AnsiColors.green;
      statusIcon = '✓';
    } else if (status == 204) {
      statusCategory = 'NO CONTENT';
      color = AnsiColors.blue;
      statusIcon = 'ø';
    } else if (status >= 400 && status < 500) {
      statusCategory = 'CLIENT ERROR';
      color = AnsiColors.yellow;
      statusIcon = '!';
    } else {
      statusCategory = 'SERVER ERROR';
      color = AnsiColors.red;
      statusIcon = '✗';
    }
    final List<String> lines = [
      '+$separator+',
      '| [RESPONSE] $timestamp',
      '| +- RESPONSE [${entry.id}] -----------------------------------',
      '| | URL: ${entry.url}',
      '| | Status: $statusIcon $status ($statusCategory) | ${entry.durationText} | ${entry.responseSizeText}',
      if (entry.responseBody != null && entry.responseBody!.isNotEmpty) ...[
        '| | Response:',
        ...entry.responseBody!.split('\n').map((line) => '| |   $line'),
      ],
      '| +------------------------------------------------------------',
      '+$separator+',
    ];
    if (ColorSupport.isSupported) {
      dev.log(lines.map((line) => '$color$line${AnsiColors.reset}').join('\n'));
    } else {
      dev.log(lines.join('\n'));
    }
  }

  void _printSimpleResponse(HttpLogEntry entry, String timestamp) {
    final int status = entry.statusCode ?? 0;
    final String color = status >= 200 && status < 400
        ? AnsiColors.green
        : AnsiColors.red;
    final String icon = status >= 200 && status < 400 ? '✓' : '✗';
    final String message =
        '← $icon $status ${entry.method} ${entry.url} ${entry.durationText} ${entry.responseSizeText}';
    if (ColorSupport.isSupported) {
      dev.log('$color[$timestamp] $message${AnsiColors.reset}');
    } else {
      dev.log('[$timestamp] $message');
    }
  }

  void printError(HttpLogEntry entry) {
    if (!_config.consoleFormat.isEnabled) return;
    final String timestamp = DateTime.now().toIso8601String();
    if (_config.consoleFormat == ConsoleLogFormat.simple) {
      final String message =
          '✗ ERROR ${entry.method} ${entry.url} - ${entry.errorMessage ?? entry.state.label}';
      if (ColorSupport.isSupported) {
        dev.log('${AnsiColors.red}[$timestamp] $message${AnsiColors.reset}');
      } else {
        dev.log('[$timestamp] $message');
      }
      return;
    }
    final String separator = '=' * 80;
    final List<String> lines = [
      '+$separator+',
      '| [ERROR] $timestamp',
      '| +- ERROR [${entry.id}] --------------------------------------',
      '| | URL: ${entry.url}',
      '| | State: ${entry.state.label}',
      if (entry.errorMessage != null) '| | Error: ${entry.errorMessage}',
      if (entry.duration != null) '| | Duration: ${entry.durationText}',
      '| +------------------------------------------------------------',
      '+$separator+',
    ];
    if (ColorSupport.isSupported) {
      dev.log(
        lines
            .map((line) => '${AnsiColors.red}$line${AnsiColors.reset}')
            .join('\n'),
      );
    } else {
      dev.log(lines.join('\n'));
    }
  }

  void printMessage(MessageLogEntry entry) {
    if (!_config.consoleFormat.isEnabled) return;
    final String timestamp = entry.timestamp.toIso8601String();
    late final String color;
    late final String icon;
    switch (entry.level) {
      case MessageLevel.info:
        color = AnsiColors.blue;
        icon = 'ℹ';
      case MessageLevel.warning:
        color = AnsiColors.yellow;
        icon = '⚠';
      case MessageLevel.error:
        color = AnsiColors.red;
        icon = '✗';
    }

    if (_config.consoleFormat == ConsoleLogFormat.simple) {
      final String message = '$icon ${entry.message}';
      if (ColorSupport.isSupported) {
        dev.log('$color[$timestamp] $message${AnsiColors.reset}');
      } else {
        dev.log('[$timestamp] $message');
      }
      return;
    }

    final String separator = '-' * 80;
    if (ColorSupport.isSupported) {
      dev.log(
        '\n$color+$separator+${AnsiColors.reset}\n'
        '$color| [${entry.level.label}] $timestamp${AnsiColors.reset}\n'
        '$color| ${entry.message}${AnsiColors.reset}\n'
        '$color+$separator+${AnsiColors.reset}',
      );
    } else {
      dev.log(
        '\n+$separator+\n'
        '| [${entry.level.label}] $timestamp\n'
        '| ${entry.message}\n'
        '+$separator+',
      );
    }
  }
}

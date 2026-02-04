import 'package:flutter/material.dart';
import 'package:monitor/monitor.dart';
import 'package:monitor/src/ui/settings/widgets/bool_setting.dart';
import 'package:monitor/src/ui/settings/widgets/enum_setting.dart';
import 'package:monitor/src/ui/settings/widgets/int_setting.dart';
import 'package:monitor/src/ui/settings/widgets/string_list_setting.dart';
import 'package:monitor/src/ui/theme.dart';

class MonitorSettingsPage extends StatefulWidget {
  const MonitorSettingsPage({super.key});

  @override
  State<MonitorSettingsPage> createState() => _MonitorSettingsPageState();
}

class _MonitorSettingsPageState extends State<MonitorSettingsPage> {
  late MonitorConfig _config;

  @override
  void initState() {
    super.initState();
    _config = Monitor.config;
  }

  void _save() {
    Monitor.updateConfig(_config);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuration updated'),
          backgroundColor: CustomColors.success,
          duration: Duration(seconds: 1),
        ),
      );
      Navigator.pop(context);
    }
  }

  void _reset() {
    setState(() => _config = const MonitorConfig());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reset to default values'),
        backgroundColor: CustomColors.primary,
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _reset,
            child: const Text('Reset'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              backgroundColor: CustomColors.primary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Save'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Storage'),
          BoolSetting(
            title: 'Enable Log Storage',
            subtitle: 'Store logs in memory for viewing',
            value: _config.enableLogStorage,
            onChanged: (v) => setState(
              () => _config = _config.copyWith(enableLogStorage: v),
            ),
          ),
          IntSetting(
            title: 'Max Logs',
            subtitle: 'Maximum number of logs to keep in memory',
            value: _config.maxLogs,
            onChanged: (v) {
              if (v != null) {
                setState(() => _config = _config.copyWith(maxLogs: v));
              }
            },
          ),

          const Divider(height: 32),
          _buildSectionHeader('Console Output'),
          EnumSetting<ConsoleLogFormat>(
            title: 'Console Format',
            subtitle: 'Format for logs printed to the debug console',
            value: _config.consoleFormat,
            values: ConsoleLogFormat.values,
            labelBuilder: (v) => v.name.toUpperCase(),
            onChanged: (v) =>
                setState(() => _config = _config.copyWith(consoleFormat: v)),
          ),

          const Divider(height: 32),
          _buildSectionHeader('Feature Toggles'),
          BoolSetting(
            title: 'Log Request Headers',
            value: _config.logRequestHeaders,
            onChanged: (v) => setState(
              () => _config = _config.copyWith(logRequestHeaders: v),
            ),
          ),
          BoolSetting(
            title: 'Log Response Headers',
            value: _config.logResponseHeaders,
            onChanged: (v) => setState(
              () => _config = _config.copyWith(logResponseHeaders: v),
            ),
          ),
          BoolSetting(
            title: 'Log Request Body',
            value: _config.logRequestBody,
            onChanged: (v) =>
                setState(() => _config = _config.copyWith(logRequestBody: v)),
          ),
          BoolSetting(
            title: 'Log Response Body',
            value: _config.logResponseBody,
            onChanged: (v) => setState(
              () => _config = _config.copyWith(logResponseBody: v),
            ),
          ),

          const Divider(height: 32),
          _buildSectionHeader('Truncation'),
          IntSetting(
            title: 'Max Body Length',
            subtitle: 'Maximum characters to log for bodies',
            value: _config.maxBodyLength,
            canBeNull: true,
            onChanged: (v) => setState(
              () => _config = _config.copyWith(
                maxBodyLength: v,
                forceMaxBodyLengthNull: v == null,
              ),
            ),
          ),
          IntSetting(
            title: 'Max Header Length',
            subtitle: 'Maximum characters to log for headers',
            value: _config.maxHeaderLength,
            canBeNull: true,
            onChanged: (v) => setState(
              () => _config = _config.copyWith(
                maxHeaderLength: v,
                forceMaxHeaderLengthNull: v == null,
              ),
            ),
          ),

          const Divider(height: 32),
          _buildSectionHeader('Privacy & Redaction'),
          StringListSetting(
            title: 'Header Redaction Keys',
            subtitle: 'Headers matching these keys will be redacted',
            value: _config.headerRedactionKeys,
            onChanged: (v) => setState(
              () => _config = _config.copyWith(headerRedactionKeys: v),
            ),
          ),
          const SizedBox(height: 16),
          StringListSetting(
            title: 'Body Redaction Keys',
            subtitle: 'JSON fields matching these keys will be redacted',
            value: _config.bodyRedactionKeys,
            onChanged: (v) => setState(
              () => _config = _config.copyWith(bodyRedactionKeys: v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: CustomColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

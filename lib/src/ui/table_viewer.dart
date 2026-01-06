import 'package:flutter/material.dart';

import 'package:monitor/src/logic/service.dart';
import 'package:monitor/src/models/api_log_entry.dart';
import 'package:monitor/src/ui/details.dart';
import 'package:monitor/src/ui/theme.dart';

class TableLogViewer extends StatefulWidget {
  const TableLogViewer({super.key});

  @override
  State<TableLogViewer> createState() => _TableLogViewerState();
}

class _TableLogViewerState extends State<TableLogViewer> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: CustomColors.surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: CustomColors.surface,
          foregroundColor: CustomColors.onSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        cardTheme: const CardThemeData(color: CustomColors.surfaceContainer),
        dividerTheme: const DividerThemeData(color: CustomColors.divider),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: CustomColors.primary),
        ),
      ),
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: CustomColors.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search logs...',
                  hintStyle: const TextStyle(
                    color: CustomColors.onSurfaceVariant,
                  ),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: CustomColors.surfaceContainerHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<LogEntry>>(
                stream: Monitor.instance.logStream,
                initialData: Monitor.instance.logs,
                builder: (context, snapshot) {
                  final logs = snapshot.data ?? [];
                  final filteredLogs = _searchQuery.isEmpty
                      ? logs
                      : Monitor.instance.search(_searchQuery);
                  return SingleChildScrollView(
                    child: PaginatedDataTable(
                      header: const Text('Logs'),
                      columns: const [
                        DataColumn(label: Text('Time')),
                        DataColumn(label: Text('State')),
                        DataColumn(label: Text('Method')),
                        DataColumn(label: Text('URL')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Duration')),
                        DataColumn(label: Text('Size')),
                      ],
                      source: LogDataSource(
                        logs: filteredLogs,
                        onRowTap: (log) {
                          showLogDetails(context, log: log);
                        },
                      ),
                      rowsPerPage: 10,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LogDataSource extends DataTableSource {
  LogDataSource({required this.logs, required this.onRowTap});

  final List<LogEntry> logs;
  final void Function(LogEntry log) onRowTap;

  @override
  DataRow getRow(int index) {
    final log = logs[index];

    return switch (log) {
      HttpLogEntry entry => _buildHttpRow(entry),
      MessageLogEntry entry => _buildMessageRow(entry),
    };
  }

  DataRow _buildHttpRow(HttpLogEntry entry) {
    DataCell clickableCell(Widget child) {
      return DataCell(child, onTap: () => onRowTap(entry));
    }

    return DataRow(
      color: WidgetStateProperty.resolveWith((states) {
        if (entry.isPending) return CustomColors.warning.withAlpha(20);
        if (entry.isError) return CustomColors.error.withAlpha(20);
        return null;
      }),
      cells: [
        clickableCell(Text(entry.timeText)),
        clickableCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: entry.state.color,
                ),
              ),
              const SizedBox(width: 6),
              Text(entry.state.label),
            ],
          ),
        ),
        clickableCell(Text(entry.method)),
        clickableCell(Text(entry.shortUrl)),
        clickableCell(Text(entry.statusCode?.toString() ?? '-')),
        clickableCell(
          Text(entry.durationText.isNotEmpty ? entry.durationText : '-'),
        ),
        clickableCell(
          Text(entry.responseSizeText.isNotEmpty ? entry.responseSizeText : '-'),
        ),
      ],
    );
  }

  DataRow _buildMessageRow(MessageLogEntry entry) {
    DataCell clickableCell(Widget child) {
      return DataCell(child, onTap: () => onRowTap(entry));
    }

    return DataRow(
      color: WidgetStateProperty.resolveWith((states) {
        if (entry.isError) return CustomColors.error.withAlpha(20);
        return null;
      }),
      cells: [
        clickableCell(Text(entry.timeText)),
        clickableCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: entry.level.color,
                ),
              ),
              const SizedBox(width: 6),
              Text(entry.level.label),
            ],
          ),
        ),
        clickableCell(const Text('-')),
        clickableCell(
          Text(
            entry.message.length > 40
                ? '${entry.message.substring(0, 40)}...'
                : entry.message,
          ),
        ),
        clickableCell(const Text('-')),
        clickableCell(const Text('-')),
        clickableCell(const Text('-')),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => logs.length;

  @override
  int get selectedRowCount => 0;
}

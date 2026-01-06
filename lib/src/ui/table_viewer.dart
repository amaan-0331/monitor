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
              child: StreamBuilder<List<ApiLogEntry>>(
                stream: Monitor.instance.logStream,
                initialData: Monitor.instance.logs,
                builder: (context, snapshot) {
                  final logs = snapshot.data ?? [];
                  final filteredLogs = _searchQuery.isEmpty
                      ? logs
                      : Monitor.instance.search(_searchQuery);
                  return PaginatedDataTable(
                    header: const Text('Logs'),
                    columns: const [
                      DataColumn(label: Text('Time')),
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

  final List<ApiLogEntry> logs;
  final void Function(ApiLogEntry log) onRowTap;

  @override
  DataRow getRow(int index) {
    final log = logs[index];

    DataCell clickableCell(String text) {
      return DataCell(Text(text), onTap: () => onRowTap(log));
    }

    return DataRow(
      cells: [
        clickableCell(log.timeText),
        clickableCell(log.method ?? ''),
        clickableCell(log.shortUrl),
        clickableCell(log.statusCode?.toString() ?? ''),
        clickableCell(log.durationText),
        clickableCell(log.sizeText),
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

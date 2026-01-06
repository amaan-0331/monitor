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
  int _sortColumnIndex = 0;
  bool _sortAscending = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _sort<T>(
    Comparable<T> Function(LogEntry log) getField,
    int columnIndex,
    bool ascending,
  ) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  List<LogEntry> _getSortedLogs(List<LogEntry> logs) {
    final sortedLogs = List<LogEntry>.from(logs);

    sortedLogs.sort((a, b) {
      int compare;
      switch (_sortColumnIndex) {
        case 0: // Time
          compare = a.timestamp.compareTo(b.timestamp);
          break;
        case 1: // State
          final aState = a is HttpLogEntry
              ? a.state.label
              : (a as MessageLogEntry).level.label;
          final bState = b is HttpLogEntry
              ? b.state.label
              : (b as MessageLogEntry).level.label;
          compare = aState.compareTo(bState);
          break;
        case 2: // Method
          final aMethod = a is HttpLogEntry ? a.method : '';
          final bMethod = b is HttpLogEntry ? b.method : '';
          compare = aMethod.compareTo(bMethod);
          break;
        case 3: // URL
          final aUrl = a is HttpLogEntry
              ? a.url
              : (a as MessageLogEntry).message;
          final bUrl = b is HttpLogEntry
              ? b.url
              : (b as MessageLogEntry).message;
          compare = aUrl.compareTo(bUrl);
          break;
        case 4: // Status
          final aStatus = a is HttpLogEntry ? (a.statusCode ?? 0) : 0;
          final bStatus = b is HttpLogEntry ? (b.statusCode ?? 0) : 0;
          compare = aStatus.compareTo(bStatus);
          break;
        case 5: // Duration
          final aDuration = a is HttpLogEntry
              ? (a.duration?.inMilliseconds ?? 0)
              : 0;
          final bDuration = b is HttpLogEntry
              ? (b.duration?.inMilliseconds ?? 0)
              : 0;
          compare = aDuration.compareTo(bDuration);
          break;
        case 6: // Size
          final aSize = a is HttpLogEntry ? (a.responseSize ?? 0) : 0;
          final bSize = b is HttpLogEntry ? (b.responseSize ?? 0) : 0;
          compare = aSize.compareTo(bSize);
          break;
        default:
          compare = 0;
      }
      return _sortAscending ? compare : -compare;
    });

    return sortedLogs;
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
                  final sortedLogs = _getSortedLogs(filteredLogs);

                  return SingleChildScrollView(
                    child: PaginatedDataTable(
                      header: const Text('Logs'),
                      sortColumnIndex: _sortColumnIndex,
                      sortAscending: _sortAscending,
                      columns: [
                        DataColumn(
                          label: const Text('Time'),
                          onSort: (columnIndex, ascending) {
                            _sort(
                              (log) => log.timestamp,
                              columnIndex,
                              ascending,
                            );
                          },
                        ),
                        DataColumn(
                          label: const Text('State'),
                          onSort: (columnIndex, ascending) {
                            _sort(
                              (log) {
                                return log is HttpLogEntry
                                    ? log.state.label
                                    : (log as MessageLogEntry).level.label;
                              },
                              columnIndex,
                              ascending,
                            );
                          },
                        ),
                        DataColumn(
                          label: const Text('Method'),
                          onSort: (columnIndex, ascending) {
                            _sort(
                              (log) {
                                return log is HttpLogEntry ? log.method : '';
                              },
                              columnIndex,
                              ascending,
                            );
                          },
                        ),
                        DataColumn(
                          label: const Text('URL'),
                          onSort: (columnIndex, ascending) {
                            _sort(
                              (log) {
                                return log is HttpLogEntry
                                    ? log.url
                                    : (log as MessageLogEntry).message;
                              },
                              columnIndex,
                              ascending,
                            );
                          },
                        ),
                        DataColumn(
                          label: const Text('Status'),
                          numeric: true,
                          onSort: (columnIndex, ascending) {
                            _sort(
                              (log) {
                                return log is HttpLogEntry
                                    ? (log.statusCode ?? 0)
                                    : 0;
                              },
                              columnIndex,
                              ascending,
                            );
                          },
                        ),
                        DataColumn(
                          label: const Text('Duration'),
                          numeric: true,
                          onSort: (columnIndex, ascending) {
                            _sort(
                              (log) {
                                return log is HttpLogEntry
                                    ? (log.duration?.inMilliseconds ?? 0)
                                    : 0;
                              },
                              columnIndex,
                              ascending,
                            );
                          },
                        ),
                        DataColumn(
                          label: const Text('Size'),
                          numeric: true,
                          onSort: (columnIndex, ascending) {
                            _sort(
                              (log) {
                                return log is HttpLogEntry
                                    ? (log.responseSize ?? 0)
                                    : 0;
                              },
                              columnIndex,
                              ascending,
                            );
                          },
                        ),
                      ],
                      source: LogDataSource(
                        logs: sortedLogs,
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
          Text(
            entry.responseSizeText.isNotEmpty ? entry.responseSizeText : '-',
          ),
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

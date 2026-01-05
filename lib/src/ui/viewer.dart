import 'package:flutter/material.dart';
import 'package:monitor/src/logic/service.dart';
import 'package:monitor/src/models/api_log_entry.dart';
import 'package:monitor/src/ui/details.dart';
import 'package:monitor/src/ui/theme.dart';

/// Global function to open API logs viewer from anywhere in the app
/// Requires [Monitor.navigatorKey] to be set in the app's MaterialApp
void showMonitor() {
  final navigator = Monitor.navigatorKey?.currentState;
  if (navigator != null) {
    navigator.push(
      MaterialPageRoute<void>(builder: (context) => const MonitorView()),
    );
  } else {
    debugPrint(
      'Monitor.navigatorKey is not set. '
      'Set it in your MaterialApp to use openApiLogs().',
    );
  }
}

/// API Logs Viewer Screen
class MonitorView extends StatefulWidget {
  const MonitorView({super.key});

  @override
  State<MonitorView> createState() => _MonitorViewState();
}

class _MonitorViewState extends State<MonitorView> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  final Set<ApiLogType> _selectedTypes = {};
  final Set<String> _selectedMethods = {};
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<ApiLogEntry> _filterLogs(List<ApiLogEntry> logs) {
    var filtered = logs;

    if (_searchQuery.isNotEmpty) {
      filtered = Monitor.instance.search(_searchQuery);
    }

    if (_selectedTypes.isNotEmpty) {
      filtered = filtered
          .where((log) => _selectedTypes.contains(log.type))
          .toList();
    }

    if (_selectedMethods.isNotEmpty) {
      filtered = filtered
          .where(
            (log) =>
                log.method != null && _selectedMethods.contains(log.method),
          )
          .toList();
    }

    return filtered;
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
        backgroundColor: CustomColors.surface,
        appBar: AppBar(
          title: const Text(
            'API Logs',
            style: TextStyle(color: CustomColors.onSurface),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: CustomColors.onSurface),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear logs',
              onPressed: () {
                Monitor.instance.clearLogs();
                setState(() {});
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: CustomColors.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search by URL, method, or message...',
                  hintStyle: const TextStyle(
                    color: CustomColors.onSurfaceVariant,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: CustomColors.onSurfaceVariant,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 20,
                            color: CustomColors.onSurfaceVariant,
                          ),
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ...[
                    ApiLogType.request,
                    ApiLogType.response,
                    ApiLogType.cacheHit,
                    ApiLogType.auth,
                    ApiLogType.error,
                  ].map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(
                        label: type.label,
                        selected: _selectedTypes.contains(type),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTypes.add(type);
                            } else {
                              _selectedTypes.remove(type);
                            }
                          });
                        },
                        color: _getTypeColor(type),
                      ),
                    ),
                  ),
                  ...['GET', 'POST', 'PUT', 'DELETE'].map(
                    (method) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(
                        label: method,
                        selected: _selectedMethods.contains(method),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedMethods.add(method);
                            } else {
                              _selectedMethods.remove(method);
                            }
                          });
                        },
                        color: CustomColors.tertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Logs list
            Expanded(
              child: StreamBuilder<List<ApiLogEntry>>(
                stream: Monitor.instance.logStream,
                initialData: Monitor.instance.logs,
                builder: (context, snapshot) {
                  final allLogs = snapshot.data ?? [];
                  final logs = _filterLogs(allLogs);

                  if (logs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: CustomColors.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            allLogs.isEmpty
                                ? 'No logs yet'
                                : 'No matching logs',
                            style: const TextStyle(
                              fontSize: 16,
                              color: CustomColors.outline,
                            ),
                          ),
                          if (allLogs.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedTypes.clear();
                                  _selectedMethods.clear();
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                              child: const Text('Clear filters'),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return _LogEntryCard(log: log);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
    required Color color,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: selected ? Colors.black : CustomColors.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w600 : null,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: color,
      backgroundColor: CustomColors.surfaceContainerHigh,
      checkmarkColor: Colors.black,
      side: BorderSide(color: selected ? color : CustomColors.outlineVariant),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }

  Color _getTypeColor(ApiLogType type) {
    switch (type) {
      case ApiLogType.request:
        return CustomColors.primary;
      case ApiLogType.response:
        return CustomColors.secondary;
      case ApiLogType.cache:
      case ApiLogType.cacheHit:
        return CustomColors.orange;
      case ApiLogType.auth:
        return CustomColors.teal;
      case ApiLogType.error:
        return CustomColors.error;
      case ApiLogType.warning:
        return CustomColors.warning;
      case ApiLogType.success:
        return CustomColors.success;
      case ApiLogType.info:
        return CustomColors.tertiary;
      case ApiLogType.system:
        return CustomColors.outline;
    }
  }
}

class _LogEntryCard extends StatelessWidget {
  const _LogEntryCard({required this.log});

  final ApiLogEntry log;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: CustomColors.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CustomColors.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showLogDetails(context, log: log),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  _buildTypeChip(),
                  if (log.method != null) ...[
                    const SizedBox(width: 8),
                    _buildMethodChip(),
                  ],
                  const Spacer(),
                  Text(
                    log.timeText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: CustomColors.outline,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),

              // URL or message
              if (log.url != null || log.message != null) ...[
                const SizedBox(height: 8),
                Text(
                  log.url ?? log.message ?? '',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: CustomColors.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Status and duration row
              if (log.statusCode != null || log.duration != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (log.statusCode != null) ...[
                      _buildStatusBadge(),
                      const SizedBox(width: 12),
                    ],
                    if (log.duration != null) ...[
                      const Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: CustomColors.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        log.durationText,
                        style: const TextStyle(
                          fontSize: 11,
                          color: CustomColors.outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (log.size != null) ...[
                      const Icon(
                        Icons.data_usage_outlined,
                        size: 14,
                        color: CustomColors.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        log.sizeText,
                        style: const TextStyle(
                          fontSize: 11,
                          color: CustomColors.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip() {
    final color = _getTypeColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        log.type.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMethodChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CustomColors.tertiary.withAlpha(40),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        log.method!,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: CustomColors.tertiary,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final isSuccess = log.isSuccess;
    final color = isSuccess ? CustomColors.success : CustomColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${log.statusCode}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor() {
    switch (log.type) {
      case ApiLogType.request:
        return CustomColors.primary;
      case ApiLogType.response:
        return CustomColors.secondary;
      case ApiLogType.cache:
      case ApiLogType.cacheHit:
        return CustomColors.orange;
      case ApiLogType.auth:
        return CustomColors.teal;
      case ApiLogType.error:
        return CustomColors.error;
      case ApiLogType.warning:
        return CustomColors.warning;
      case ApiLogType.success:
        return CustomColors.success;
      case ApiLogType.info:
        return CustomColors.tertiary;
      case ApiLogType.system:
        return CustomColors.outline;
    }
  }
}

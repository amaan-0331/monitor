import 'package:flutter/material.dart';
import 'package:monitor/src/logic/service.dart';
import 'package:monitor/src/models/api_log_entry.dart';
import 'package:monitor/src/ui/details.dart';
import 'package:monitor/src/ui/table_viewer.dart';
import 'package:monitor/src/ui/theme.dart';

/// Global function to open Monitor viewer from anywhere in the app.
/// Requires [Monitor.navigatorKey] to be set in the app's MaterialApp.
void showMonitor() {
  final navigator = Monitor.navigatorKey?.currentState;
  if (navigator != null) {
    navigator.push(
      MaterialPageRoute<void>(builder: (context) => const MonitorView()),
    );
  } else {
    debugPrint(
      'Monitor.navigatorKey is not set. '
      'Set it in your MaterialApp to use showMonitor().',
    );
  }
}

/// The main view displaying the list of intercepted network traffic.
class MonitorView extends StatefulWidget {
  const MonitorView({super.key});

  @override
  State<MonitorView> createState() => _MonitorViewState();
}

class _MonitorViewState extends State<MonitorView> {
  int _currentIndex = 0;

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
            'Monitor',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: CustomColors.onSurface,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear logs',
              onPressed: () {
                Monitor.instance.clearLogs();
                setState(() {});
              },
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            _ListView(),
            TableLogViewer(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: 'List',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.table_chart),
              label: 'Table',
            ),
          ],
        ),
      ),
    );
  }
}

class _ListView extends StatefulWidget {
  const _ListView();

  @override
  State<_ListView> createState() => _ListViewState();
}

class _ListViewState extends State<_ListView> {
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
    return Column(
      children: [
        _buildSearchBar(),
        _buildFilterBar(),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<List<ApiLogEntry>>(
            stream: Monitor.instance.logStream,
            initialData: Monitor.instance.logs,
            builder: (context, snapshot) {
              final allLogs = snapshot.data ?? [];
              final logs = _filterLogs(allLogs);

              if (logs.isEmpty) {
                return _buildEmptyState(allLogs.isEmpty);
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: logs.length,
                itemBuilder: (context, index) =>
                    _LogEntryCard(log: logs[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: CustomColors.onSurface),
        decoration: InputDecoration(
          hintText: 'URL, method, or message...',
          hintStyle: const TextStyle(color: CustomColors.onSurfaceVariant),
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
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ...ApiLogType.values.map(
            (type) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(
                label: type.label,
                selected: _selectedTypes.contains(type),
                onSelected: (selected) {
                  setState(
                    () => selected
                        ? _selectedTypes.add(type)
                        : _selectedTypes.remove(type),
                  );
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
                  setState(
                    () => selected
                        ? _selectedMethods.add(method)
                        : _selectedMethods.remove(method),
                  );
                },
                color: CustomColors.tertiary,
              ),
            ),
          ),
        ],
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
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: selected,
      onSelected: onSelected,
      selectedColor: color,
      checkmarkColor: Colors.black,
      backgroundColor: CustomColors.surfaceContainerHigh,
      labelStyle: TextStyle(
        color: selected ? Colors.black : CustomColors.onSurfaceVariant,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildEmptyState(bool isAbsoluteEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.blind, size: 48, color: CustomColors.outline),
          const SizedBox(height: 16),
          Text(
            isAbsoluteEmpty ? 'No logs captured yet' : 'No logs match filters',
            style: const TextStyle(color: CustomColors.outline),
          ),
        ],
      ),
    );
  }
}

class _LogEntryCard extends StatelessWidget {
  const _LogEntryCard({required this.log});
  final ApiLogEntry log;

  @override
  Widget build(BuildContext context) {
    final statusColor = log.isError ? CustomColors.error : CustomColors.success;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: log.isError
              ? CustomColors.error.withValues(alpha: .3)
              : CustomColors.outlineVariant,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showLogDetails(context, log: log),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Badge(label: log.type.label, color: _getTypeColor(log.type)),
                  if (log.method != null) ...[
                    const SizedBox(width: 6),
                    _Badge(label: log.method!, color: CustomColors.tertiary),
                  ],
                  const Spacer(),
                  Text(
                    log.timeText,
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: CustomColors.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                log.url ?? log.message ?? '',
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  color: CustomColors.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (log.statusCode != null || log.duration != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (log.statusCode != null)
                      _StatusIndicator(
                        code: log.statusCode!,
                        color: statusColor,
                      ),
                    const SizedBox(width: 12),
                    if (log.duration != null)
                      _InfoTag(
                        icon: Icons.timer_outlined,
                        label: log.durationText,
                      ),
                    const SizedBox(width: 12),
                    if (log.size != null)
                      _InfoTag(icon: Icons.data_usage, label: log.sizeText),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper Widgets for the Card
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final int code;
  final Color color;
  const _StatusIndicator({required this.code, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          code >= 400 ? Icons.error : Icons.check_circle,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          '$code',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: CustomColors.outline),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: CustomColors.outline, fontSize: 11),
        ),
      ],
    );
  }
}

Color _getTypeColor(ApiLogType type) {
  switch (type) {
    case ApiLogType.request:
      return CustomColors.primary;
    case ApiLogType.response:
      return CustomColors.secondary;
    case ApiLogType.error:
      return CustomColors.error;
    case ApiLogType.info:
      return CustomColors.tertiary;
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:monitor/src/models/api_log_entry.dart';
import 'package:monitor/src/models/multipart_info.dart';
import 'package:monitor/src/ui/log_details/message_log_details_sheet.dart';
import 'package:monitor/src/ui/log_details/response_preview.dart';
import 'package:monitor/src/ui/log_details/widgets/shared_widgets.dart';
import 'package:monitor/src/ui/log_details/widgets/state_widgets.dart';
import 'package:monitor/src/ui/theme.dart';
import 'package:monitor/src/utils/functions.dart';

void showLogDetails(BuildContext context, {required LogEntry log}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => switch (log) {
      final HttpLogEntry entry => HttpLogDetailsSheet(entry: entry),
      final MessageLogEntry entry => MessageLogDetailsSheet(entry: entry),
    },
  );
}

class HttpLogDetailsSheet extends StatelessWidget {
  const HttpLogDetailsSheet({required this.entry, super.key});
  final HttpLogEntry entry;

  static const _headerPadding = EdgeInsets.fromLTRB(16, 12, 8, 12);
  static const _tabBar = TabBar(
    tabs: [
      Tab(text: 'Overview'),
      Tab(text: 'Request'),
      Tab(text: 'Response'),
    ],
    labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    unselectedLabelStyle: TextStyle(fontSize: 13),
    labelColor: CustomColors.primary,
    unselectedLabelColor: CustomColors.onSurfaceVariant,
    indicatorColor: CustomColors.primary,
  );

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.95),
      decoration: const BoxDecoration(
        color: CustomColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: DefaultTabController(
        length: 3,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HandleBar(),
            _buildHeader(context),
            _tabBar,
            const Divider(height: 1, color: CustomColors.divider),
            Expanded(
              child: TabBarView(
                children: [
                  OverviewTab(entry: entry, bottomPadding: bottomPadding),
                  RequestTab(entry: entry, bottomPadding: bottomPadding),
                  ResponseTab(entry: entry, bottomPadding: bottomPadding),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: _headerPadding,
      child: Row(
        children: [
          StateBadge(entry: entry),
          const SizedBox(width: 10),
          Text(
            entry.method,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: CustomColors.onSurface,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.copy_outlined, size: 20),
            tooltip: 'Copy',
            onPressed: () => copyToClipboard(context, log: entry),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class StateBadge extends StatelessWidget {
  const StateBadge({
    required this.entry,
    super.key,
  });
  final HttpLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = entry.state.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (entry.isPending) ...[
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: color),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            entry.state.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class OverviewTab extends StatelessWidget {
  const OverviewTab({
    required this.entry,
    required this.bottomPadding,
    super.key,
  });
  final HttpLogEntry entry;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String)>[
      if (entry.statusCode != null)
        ('Status', '${entry.statusCode} ${entry.statusCategory}'),
      if (entry.duration != null) ('Duration', entry.durationText),
      if (entry.requestSize != null) ('Sent', entry.requestSizeText),
      if (entry.responseSize != null) ('Received', entry.responseSizeText),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (items.isNotEmpty) ...[
            InfoGrid(items: items),
            const SizedBox(height: 20),
          ],
          Section(
            title: 'URL',
            child: CodeBlock(code: entry.url),
          ),
          if (entry.errorMessage != null) ...[
            const SizedBox(height: 16),
            Section(
              title: 'Error',
              child: CodeBlock(code: entry.errorMessage!, isError: true),
            ),
          ],
          SizedBox(height: bottomPadding + 16),
        ],
      ),
    );
  }
}

class RequestTab extends StatelessWidget {
  const RequestTab({
    required this.entry,
    required this.bottomPadding,
    super.key,
  });
  final HttpLogEntry entry;
  final double bottomPadding;

  static const _encoder = JsonEncoder.withIndent('  ');

  @override
  Widget build(BuildContext context) {
    final hasHeaders = entry.requestHeaders?.isNotEmpty ?? false;
    final hasBody = entry.requestBody != null;
    final hasMultipart = entry.multipartInfo != null;

    if (!hasHeaders && !hasBody) {
      return const EmptyState(message: 'No request data');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasHeaders) ...[
            Section(
              title: 'Headers',
              child: CodeBlock(code: _encoder.convert(entry.requestHeaders)),
            ),
            if (hasBody || hasMultipart) const SizedBox(height: 16),
          ],
          // Display multipart info if present
          if (hasMultipart) ...[
            Section(
              title: 'Multipart Request · ${entry.multipartInfo!.summary}',
              child: _MultipartInfoWidget(info: entry.multipartInfo!),
            ),
          ] else if (hasBody)
            Section(
              title:
                  'Body${entry.requestSize != null ? ' · ${entry.requestSizeText}' : ''}',
              child: CodeBlock(
                code: entry.prettyRequestBody ?? entry.requestBody!,
              ),
            ),
          SizedBox(height: bottomPadding + 16),
        ],
      ),
    );
  }
}

/// Widget to display multipart request parts
class _MultipartInfoWidget extends StatelessWidget {
  const _MultipartInfoWidget({required this.info});
  final MultipartInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CustomColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final part in info.parts) _buildPartRow(part),
        ],
      ),
    );
  }

  Widget _buildPartRow(MultipartPartInfo part) {
    final icon = part.isFile ? Icons.attach_file : Icons.text_fields;
    final color = part.isFile
        ? CustomColors.primary
        : CustomColors.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              part.displayText,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: CustomColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ResponseTab extends StatelessWidget {
  const ResponseTab({
    required this.entry,
    required this.bottomPadding,
    super.key,
  });
  final HttpLogEntry entry;
  final double bottomPadding;

  static const _encoder = JsonEncoder.withIndent('  ');

  @override
  Widget build(BuildContext context) {
    if (entry.isPending) {
      return PendingState(url: entry.url);
    }

    if ((entry.state == HttpLogState.error ||
            entry.state == HttpLogState.timeout) &&
        entry.responseBody == null &&
        entry.errorMessage != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Section(
              title: 'Error',
              child: CodeBlock(code: entry.errorMessage!, isError: true),
            ),
            if (entry.duration != null) ...[
              const SizedBox(height: 16),
              InfoGrid(items: [('Duration', entry.durationText)]),
            ],
            SizedBox(height: bottomPadding + 16),
          ],
        ),
      );
    }

    final hasHeaders = entry.responseHeaders?.isNotEmpty ?? false;
    final hasBody = entry.responseBody != null;

    if (!hasHeaders && !hasBody) {
      return const EmptyState(message: 'No response data');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasHeaders) ...[
            Section(
              title: 'Headers',
              child: CodeBlock(code: _encoder.convert(entry.responseHeaders)),
            ),
            if (hasBody) const SizedBox(height: 16),
          ],
          if (hasBody) ...[
            Section(
              title:
                  'Body${entry.responseSize != null ? ' · ${entry.responseSizeText}' : ''}',
              child: ResponsePreview(entry: entry),
            ),
          ],
          SizedBox(height: bottomPadding + 16),
        ],
      ),
    );
  }
}

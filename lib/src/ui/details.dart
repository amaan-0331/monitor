import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:monitor/src/models/api_log_entry.dart';
import 'package:monitor/src/ui/theme.dart';
import 'package:monitor/src/utils/functions.dart';

void showLogDetails(BuildContext context, {required LogEntry log}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => switch (log) {
      HttpLogEntry entry => _HttpLogDetailsSheet(entry: entry),
      MessageLogEntry entry => _MessageLogDetailsSheet(entry: entry),
    },
  );
}

class _HttpLogDetailsSheet extends StatelessWidget {
  const _HttpLogDetailsSheet({required this.entry});
  final HttpLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.85),
      decoration: const BoxDecoration(
        color: CustomColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DefaultTabController(
        length: 3,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CustomColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header with state indicator
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: entry.state.color.withAlpha(40),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (entry.isPending) ...[
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          entry.state.label,
                          style: TextStyle(
                            color: entry.state.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.method,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CustomColors.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy, color: CustomColors.onSurface),
                    tooltip: 'Copy to clipboard',
                    onPressed: () => copyToClipboard(context, log: entry),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.close, color: CustomColors.onSurface),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Tab bar
            const TabBar(
              tabs: [
                Tab(text: 'General'),
                Tab(text: 'Request'),
                Tab(text: 'Response'),
              ],
              labelColor: CustomColors.primary,
              unselectedLabelColor: CustomColors.onSurfaceVariant,
              indicatorColor: CustomColors.primary,
            ),

            const Divider(height: 1, color: CustomColors.divider),

            // Tab content
            Expanded(
              child: TabBarView(
                children: [
                  _buildGeneralTab(mediaQuery),
                  _buildRequestTab(mediaQuery),
                  _buildResponseTab(mediaQuery),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralTab(MediaQueryData mediaQuery) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('Overview', [
            _buildDetailRow('ID', entry.id),
            _buildDetailRow('State', entry.state.label),
            _buildDetailRow('Method', entry.method),
            _buildDetailRow('Timestamp', entry.timestamp.toIso8601String()),
            if (entry.statusCode != null)
              _buildDetailRow(
                'Status',
                '${entry.statusCode} (${entry.statusCategory})',
              ),
            if (entry.duration != null)
              _buildDetailRow('Duration', entry.durationText),
            if (entry.requestSize != null)
              _buildDetailRow('Request Size', entry.requestSizeText),
            if (entry.responseSize != null)
              _buildDetailRow('Response Size', entry.responseSizeText),
          ]),
          const SizedBox(height: 16),
          _buildSection('URL', [_buildCodeBlock(entry.url)]),
          if (entry.errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildSection('Error', [
              _buildCodeBlock(entry.errorMessage!, isError: true),
            ]),
          ],
          SizedBox(height: mediaQuery.padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildRequestTab(MediaQueryData mediaQuery) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('URL', [_buildCodeBlock(entry.url)]),
          if (entry.requestHeaders != null &&
              entry.requestHeaders!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSection('Headers', [
              _buildCodeBlock(
                const JsonEncoder.withIndent('  ')
                    .convert(entry.requestHeaders),
              ),
            ]),
          ],
          if (entry.requestBody != null) ...[
            const SizedBox(height: 16),
            _buildSection(
              'Body${entry.requestSize != null ? ' (${entry.requestSizeText})' : ''}',
              [
                _buildCodeBlock(
                  entry.prettyRequestBody ?? entry.requestBody!,
                ),
              ],
            ),
          ],
          if (entry.requestHeaders == null && entry.requestBody == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No request data',
                  style: TextStyle(color: CustomColors.outline),
                ),
              ),
            ),
          SizedBox(height: mediaQuery.padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildResponseTab(MediaQueryData mediaQuery) {
    if (entry.isPending) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'Waiting for response...',
              style: TextStyle(color: CustomColors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              entry.url,
              style: const TextStyle(
                color: CustomColors.outline,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (entry.state == HttpLogState.error ||
        entry.state == HttpLogState.timeout) {
      if (entry.responseBody == null && entry.errorMessage != null) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection('Error', [
                _buildCodeBlock(entry.errorMessage!, isError: true),
              ]),
              if (entry.duration != null) ...[
                const SizedBox(height: 16),
                _buildSection('Duration', [
                  _buildDetailRow('Time elapsed', entry.durationText),
                ]),
              ],
              SizedBox(height: mediaQuery.padding.bottom + 16),
            ],
          ),
        );
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.statusCode != null) ...[
            _buildSection('Status', [
              _buildDetailRow(
                'Code',
                '${entry.statusCode} (${entry.statusCategory})',
              ),
              if (entry.duration != null)
                _buildDetailRow('Duration', entry.durationText),
              if (entry.responseSize != null)
                _buildDetailRow('Size', entry.responseSizeText),
            ]),
            const SizedBox(height: 16),
          ],
          if (entry.responseHeaders != null &&
              entry.responseHeaders!.isNotEmpty) ...[
            _buildSection('Headers', [
              _buildCodeBlock(
                const JsonEncoder.withIndent('  ')
                    .convert(entry.responseHeaders),
              ),
            ]),
            const SizedBox(height: 16),
          ],
          if (entry.responseBody != null)
            _buildSection(
              'Body${entry.responseSize != null ? ' (${entry.responseSizeText})' : ''}',
              [
                _buildCodeBlock(
                  entry.prettyResponseBody ?? entry.responseBody!,
                ),
              ],
            ),
          if (entry.responseBody == null && entry.errorMessage == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No response body',
                  style: TextStyle(color: CustomColors.outline),
                ),
              ),
            ),
          SizedBox(height: mediaQuery.padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CustomColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: CustomColors.outline),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: CustomColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeBlock(String code, {bool isError = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError
            ? CustomColors.error.withAlpha(20)
            : CustomColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: isError
            ? Border.all(color: CustomColors.error.withAlpha(50))
            : null,
      ),
      child: SelectableText(
        code,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          color: isError ? CustomColors.error : CustomColors.onSurface,
        ),
      ),
    );
  }
}

class _MessageLogDetailsSheet extends StatelessWidget {
  const _MessageLogDetailsSheet({required this.entry});
  final MessageLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.85),
      decoration: const BoxDecoration(
        color: CustomColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CustomColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: entry.level.color.withAlpha(40),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    entry.level.label,
                    style: TextStyle(
                      color: entry.level.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, color: CustomColors.onSurface),
                  tooltip: 'Copy to clipboard',
                  onPressed: () => copyToClipboard(context, log: entry),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: CustomColors.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: CustomColors.divider),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('General', [
                    _buildDetailRow('ID', entry.id),
                    _buildDetailRow('Level', entry.level.label),
                    _buildDetailRow(
                      'Timestamp',
                      entry.timestamp.toIso8601String(),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('Message', [
                    _buildCodeBlock(entry.message),
                  ]),
                  if (entry.url != null) ...[
                    const SizedBox(height: 16),
                    _buildSection('URL', [
                      _buildCodeBlock(entry.url!),
                    ]),
                  ],
                  SizedBox(height: mediaQuery.padding.bottom + 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CustomColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: CustomColors.outline),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: CustomColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeBlock(String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CustomColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        code,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          color: CustomColors.onSurface,
        ),
      ),
    );
  }
}

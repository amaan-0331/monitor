import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:monitor/src/models/api_log_entry.dart';
import 'package:monitor/src/ui/theme.dart';
import 'package:monitor/src/utils/funtions.dart';

void showLogDetails(BuildContext context, {required ApiLogEntry log}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _LogDetailsSheet(log: log),
  );
}

class _LogDetailsSheet extends StatelessWidget {
  const _LogDetailsSheet({required this.log});

  final ApiLogEntry log;

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
                const Text(
                  'Log Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: CustomColors.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, color: CustomColors.onSurface),
                  tooltip: 'Copy to clipboard',
                  onPressed: () => copyToClipboard(context, log: log),
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
                    _buildDetailRow('ID', log.id),
                    _buildDetailRow('Type', log.type.label),
                    _buildDetailRow(
                      'Timestamp',
                      log.timestamp.toIso8601String(),
                    ),
                    if (log.method != null)
                      _buildDetailRow('Method', log.method!),
                    if (log.statusCode != null)
                      _buildDetailRow(
                        'Status',
                        '${log.statusCode} (${log.statusCategory})',
                      ),
                    if (log.duration != null)
                      _buildDetailRow('Duration', log.durationText),
                    if (log.size != null) _buildDetailRow('Size', log.sizeText),
                  ]),

                  if (log.url != null) ...[
                    const SizedBox(height: 16),
                    _buildSection('URL', [_buildCodeBlock(log.url!)]),
                  ],

                  if (log.message != null) ...[
                    const SizedBox(height: 16),
                    _buildSection('Message', [_buildCodeBlock(log.message!)]),
                  ],

                  if (log.requestHeaders != null &&
                      log.requestHeaders!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSection('Request Headers', [
                      _buildCodeBlock(
                        const JsonEncoder.withIndent(
                          '  ',
                        ).convert(log.requestHeaders),
                      ),
                    ]),
                  ],

                  if (log.requestBody != null) ...[
                    const SizedBox(height: 16),
                    _buildSection('Request Body', [
                      _buildCodeBlock(
                        log.prettyRequestBody ?? log.requestBody!,
                      ),
                    ]),
                  ],

                  if (log.responseBody != null) ...[
                    const SizedBox(height: 16),
                    _buildSection('Response Body', [
                      _buildCodeBlock(
                        log.prettyResponseBody ?? log.responseBody!,
                      ),
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

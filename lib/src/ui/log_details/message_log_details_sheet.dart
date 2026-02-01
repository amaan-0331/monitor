import 'package:flutter/material.dart';
import 'package:monitor/src/models/api_log_entry.dart';
import 'package:monitor/src/ui/log_details/widgets/shared_widgets.dart';
import 'package:monitor/src/ui/theme.dart';
import 'package:monitor/src/utils/functions.dart';

class MessageLogDetailsSheet extends StatelessWidget {
  const MessageLogDetailsSheet({required this.entry, super.key});
  final MessageLogEntry entry;

  static const _titleStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: CustomColors.onSurfaceVariant,
    letterSpacing: 0.5,
  );
  static const _labelStyle = TextStyle(
    fontSize: 11,
    color: CustomColors.outline,
    fontWeight: FontWeight.w500,
  );
  static const _valueStyle = TextStyle(
    fontSize: 13,
    fontFamily: 'monospace',
    color: CustomColors.onSurface,
    fontWeight: FontWeight.w500,
  );
  static const _codeStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 11,
    height: 1.5,
    color: CustomColors.onSurface,
  );

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final levelColor = entry.level.color;

    return Container(
      constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.85),
      decoration: const BoxDecoration(
        color: CustomColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HandleBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: levelColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entry.level.label,
                    style: TextStyle(
                      color: levelColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
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
          ),
          const Divider(height: 1, color: CustomColors.divider),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoGrid([
                    ('Level', entry.level.label),
                    ('Time', entry.timestamp.toIso8601String()),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection('Message', entry.message),
                  if (entry.url != null) ...[
                    const SizedBox(height: 16),
                    _buildSection('URL', entry.url!),
                  ],
                  SizedBox(height: bottomPadding + 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(List<(String, String)> items) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: items.map((item) {
        return SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.$1, style: _labelStyle),
              const SizedBox(height: 2),
              Text(item.$2, style: _valueStyle),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _titleStyle),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: CustomColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(6),
          ),
          child: SelectableText(content, style: _codeStyle),
        ),
      ],
    );
  }
}

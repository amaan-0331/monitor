import 'package:flutter/material.dart';
import 'package:monitor/src/ui/theme.dart';

class HandleBar extends StatelessWidget {
  const HandleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: CustomColors.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class Section extends StatelessWidget {
  const Section({required this.title, required this.child, super.key});
  final String title;
  final Widget child;

  static const _titleStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: CustomColors.onSurfaceVariant,
    letterSpacing: 0.5,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _titleStyle),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class InfoGrid extends StatelessWidget {
  const InfoGrid({required this.items, super.key});
  final List<(String, String)> items;

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

  @override
  Widget build(BuildContext context) {
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
}

class CodeBlock extends StatelessWidget {
  const CodeBlock({required this.code, super.key, this.isError = false});
  final String code;
  final bool isError;

  static const Color _errorBackgroundColor = CustomColors.error;
  static const Color _surfaceColor = CustomColors.surfaceContainerHigh;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError
            ? _errorBackgroundColor.withValues(alpha: 0.08)
            : _surfaceColor,
        borderRadius: BorderRadius.circular(6),
        border: isError
            ? Border.all(
                color: _errorBackgroundColor.withValues(alpha: 0.2),
              )
            : null,
      ),
      child: SelectableText(
        code,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          height: 1.5,
          color: isError ? CustomColors.error : CustomColors.onSurface,
        ),
      ),
    );
  }
}

class ModeChip extends StatelessWidget {
  const ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primaryColor = CustomColors.primary;
    const outlineColor = CustomColors.outline;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? primaryColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected
                ? primaryColor.withValues(alpha: 0.3)
                : outlineColor.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? primaryColor : CustomColors.onSurface,
          ),
        ),
      ),
    );
  }
}

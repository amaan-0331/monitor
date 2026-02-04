import 'package:flutter/material.dart';
import 'package:monitor/src/ui/theme.dart';

class EnumSetting<T> extends StatelessWidget {
  const EnumSetting({
    required this.title,
    required this.value,
    required this.values,
    required this.onChanged,
    required this.labelBuilder,
    super.key,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final T value;
  final List<T> values;
  final ValueChanged<T> onChanged;
  final String Function(T) labelBuilder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: CustomColors.onSurface,
                    fontSize: 16,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: CustomColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CustomColors.outlineVariant),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                dropdownColor: CustomColors.surfaceContainerHigh,
                style: const TextStyle(color: CustomColors.onSurface),
                icon: const Icon(Icons.arrow_drop_down, color: CustomColors.outline),
                onChanged: (newValue) {
                  if (newValue != null) {
                    onChanged(newValue);
                  }
                },
                items: values.map((item) {
                  return DropdownMenuItem<T>(
                    value: item,
                    child: Text(labelBuilder(item)),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:monitor/src/ui/theme.dart';

class BoolSetting extends StatelessWidget {
  const BoolSetting({
    required this.title,
    required this.value,
    required this.onChanged,
    super.key,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(color: CustomColors.onSurface),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(color: CustomColors.onSurfaceVariant),
            )
          : null,
      value: value,
      onChanged: onChanged,
      // ignore: deprecated_member_use
      activeColor: CustomColors.primary,
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return CustomColors.primary.withAlpha(100);
        }
        return CustomColors.surfaceContainerHigh;
      }),
      contentPadding: EdgeInsets.zero,
    );
  }
}

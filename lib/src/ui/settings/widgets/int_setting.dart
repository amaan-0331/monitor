import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:monitor/src/ui/theme.dart';

class IntSetting extends StatefulWidget {
  const IntSetting({
    required this.title,
    required this.value,
    required this.onChanged,
    super.key,
    this.subtitle,
    this.canBeNull = false,
    this.suffix = '',
  });

  final String title;
  final String? subtitle;
  final int? value;
  final ValueChanged<int?> onChanged;
  final bool canBeNull;
  final String suffix;

  @override
  State<IntSetting> createState() => _IntSettingState();
}

class _IntSettingState extends State<IntSetting> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(IntSetting oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      final text = widget.value?.toString() ?? '';
      if (_controller.text != text) {
        _controller.text = text;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    if (value.isEmpty) {
      if (widget.canBeNull) {
        widget.onChanged(null);
      } else {
        // If cannot be null, don't update or set to 0?
        // Let's set to 0 as fallback or keep old value?
        // Better to treat empty as invalid or 0.
        // For maxLogs, 0 is valid.
        // But for user experience, maybe just don't trigger callback if invalid?
        // Let's assume 0.
        // Or wait for valid input.
      }
      return;
    }

    final intVal = int.tryParse(value);
    if (intVal != null) {
      widget.onChanged(intVal);
    }
  }

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
                  widget.title,
                  style: const TextStyle(
                    color: CustomColors.onSurface,
                    fontSize: 16,
                  ),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle!,
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
          SizedBox(
            width: 100,
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: CustomColors.onSurface),
              decoration: InputDecoration(
                isDense: true,
                hintText: widget.canBeNull ? 'Unlimited' : null,
                hintStyle: const TextStyle(color: CustomColors.outline),
                suffixText: widget.suffix,
                suffixStyle: const TextStyle(color: CustomColors.outline),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: CustomColors.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: CustomColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onChanged: _handleChanged,
            ),
          ),
        ],
      ),
    );
  }
}

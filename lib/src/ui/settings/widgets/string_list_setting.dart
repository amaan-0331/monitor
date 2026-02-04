import 'package:flutter/material.dart';
import 'package:monitor/src/ui/theme.dart';

class StringListSetting extends StatefulWidget {
  const StringListSetting({
    required this.title,
    required this.value,
    required this.onChanged,
    super.key,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<String> value;
  final ValueChanged<List<String>> onChanged;

  @override
  State<StringListSetting> createState() => _StringListSettingState();
}

class _StringListSettingState extends State<StringListSetting> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !widget.value.contains(text)) {
      widget.onChanged([...widget.value, text]);
      _controller.clear();
    }
  }

  void _remove(String item) {
    final newList = List.of(widget.value)..remove(item);
    widget.onChanged(newList);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
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
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: CustomColors.onSurface),
                decoration: InputDecoration(
                  hintText: 'Add new key...',
                  hintStyle: const TextStyle(color: CustomColors.outline),
                  isDense: true,
                  filled: true,
                  fillColor: CustomColors.surfaceContainerHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _add,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: CustomColors.primary,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.value.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.value.map((item) {
              return Chip(
                label: Text(item),
                labelStyle: const TextStyle(fontSize: 12),
                backgroundColor: CustomColors.surfaceContainerHigh,
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _remove(item),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: CustomColors.outlineVariant),
                ),
              );
            }).toList(),
          )
        else
          const Text(
            'No keys configured',
            style: TextStyle(
              color: CustomColors.outline,
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

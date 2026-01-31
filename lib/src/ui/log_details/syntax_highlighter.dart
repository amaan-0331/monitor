import 'package:flutter/material.dart';
import 'package:monitor/src/ui/theme.dart';

class SyntaxHighlighter {
  static const Color keyColor = Color(0xFF9CDCFE);
  static const Color stringColor = Color(0xFFCE9178);
  static const Color numberColor = Color(0xFFB5CEA8);
  static const Color booleanColor = Color(0xFF569CD6);
  static const Color nullColor = Color(0xFF569CD6);
  static const Color defaultColor = CustomColors.onSurface;

  static const _openBrace = TextSpan(text: '{\n');
  static const _closeBrace = TextSpan(text: '}');
  static const _openBracket = TextSpan(text: '[\n');
  static const _closeBracket = TextSpan(text: ']');
  static const _colonSpace = TextSpan(text: ': ');
  static const _comma = TextSpan(text: ',');
  static const _newline = TextSpan(text: '\n');
  static const _nullSpan = TextSpan(
    text: 'null',
    style: TextStyle(color: nullColor),
  );

  static TextSpan buildTree(dynamic json, [int indent = 0]) {
    final spacing = '  ' * indent;
    final nextSpacing = '  ' * (indent + 1);

    if (json is Map) {
      if (json.isEmpty) return _closeBrace;

      final children = <TextSpan>[];
      children.add(_openBrace);

      final entries = json.entries.toList();
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        children.add(TextSpan(text: nextSpacing));
        children.add(
          TextSpan(
            text: '"${entry.key}"',
            style: const TextStyle(color: keyColor),
          ),
        );
        children.add(_colonSpace);
        children.add(buildTree(entry.value, indent + 1));
        if (i < entries.length - 1) children.add(_comma);
        children.add(_newline);
      }
      children.add(TextSpan(text: '$spacing}'));

      return TextSpan(children: children);
    } else if (json is List) {
      if (json.isEmpty) return _closeBracket;

      final children = <TextSpan>[];
      children.add(_openBracket);

      for (int i = 0; i < json.length; i++) {
        children.add(TextSpan(text: nextSpacing));
        children.add(buildTree(json[i], indent + 1));
        if (i < json.length - 1) children.add(_comma);
        children.add(_newline);
      }
      children.add(TextSpan(text: '$spacing]'));

      return TextSpan(children: children);
    } else if (json is String) {
      return TextSpan(
        text: '"$json"',
        style: const TextStyle(color: stringColor),
      );
    } else if (json is num) {
      return TextSpan(
        text: json.toString(),
        style: const TextStyle(color: numberColor),
      );
    } else if (json is bool) {
      return TextSpan(
        text: json.toString(),
        style: const TextStyle(color: booleanColor),
      );
    } else if (json == null) {
      return _nullSpan;
    } else {
      return TextSpan(
        text: json.toString(),
        style: const TextStyle(color: defaultColor),
      );
    }
  }
}

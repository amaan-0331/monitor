import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:monitor/src/models/api_log_entry.dart';
import 'package:monitor/src/ui/log_details/syntax_highlighter.dart';
import 'package:monitor/src/ui/log_details/widgets/shared_widgets.dart';
import 'package:monitor/src/ui/log_details/widgets/state_widgets.dart';
import 'package:monitor/src/ui/theme.dart';

// Configuration constants
// Set to true to enable text wrapping in JSON view
const bool _kEnableJsonWrapping = false;
// Set to true to enable text wrapping in raw view
const bool _kEnableRawWrapping = true;
// Set to true to enable text wrapping in HTML view
const bool _kEnableHtmlWrapping = false;

enum PreviewMode { json, raw, html }

class ResponsePreview extends StatefulWidget {
  const ResponsePreview({super.key, required this.entry});
  final HttpLogEntry entry;

  @override
  State<ResponsePreview> createState() => _ResponsePreviewState();
}

class _ResponsePreviewState extends State<ResponsePreview> {
  PreviewMode _mode = PreviewMode.json;
  String? _formattedJson;
  String? _jsonError;
  late final String _raw;
  late final bool _isHtml;

  static const _monospaceStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 11,
    height: 1.5,
  );

  @override
  void initState() {
    super.initState();
    _raw = widget.entry.responseBody ?? '';
    _isHtml = _detectHtml(_raw);
    _prepareJson();
  }

  bool _detectHtml(String content) {
    if (content.isEmpty) return false;

    final trimmed = content.trim();

    // Check for common HTML patterns
    if (trimmed.startsWith('<!DOCTYPE html') ||
        trimmed.startsWith('<!doctype html') ||
        trimmed.startsWith('<html')) {
      return true;
    }

    // Check for common HTML tags
    final htmlTagPattern = RegExp(
      r'<(html|head|body|div|span|p|a|table|form|input|button|h[1-6]|ul|ol|li)[>\s]',
      caseSensitive: false,
    );

    return htmlTagPattern.hasMatch(
      trimmed.substring(0, trimmed.length > 500 ? 500 : trimmed.length),
    );
  }

  void _prepareJson() {
    final body = widget.entry.responseBody;
    if (body == null || body.isEmpty) return;

    Future(() {
      try {
        final decoded = json.decode(body);
        const encoder = JsonEncoder.withIndent('  ');
        return (encoder.convert(decoded), null);
      } on FormatException catch (e) {
        return (null, e.message);
      } catch (e) {
        return (null, e.toString());
      }
    }).then((result) {
      if (!mounted) return;
      setState(() {
        _formattedJson = result.$1;
        _jsonError = result.$2;
      });
    });
  }

  void _setMode(PreviewMode mode) {
    if (_mode != mode) setState(() => _mode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          children: [
            ModeChip(
              label: 'Raw',
              selected: _mode == PreviewMode.raw,
              onTap: () => _setMode(PreviewMode.raw),
            ),
            ModeChip(
              label: 'JSON',
              selected: _mode == PreviewMode.json,
              onTap: () => _setMode(PreviewMode.json),
            ),
            if (_isHtml)
              ModeChip(
                label: 'HTML',
                selected: _mode == PreviewMode.html,
                onTap: () => _setMode(PreviewMode.html),
              ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: switch (_mode) {
            PreviewMode.json => _buildJsonView(),
            PreviewMode.raw => _buildRawView(),
            PreviewMode.html => _buildHtmlView(),
          },
        ),
      ],
    );
  }

  Widget _buildJsonView() {
    if (_formattedJson == null && _jsonError == null) {
      return const LoadingBlock(message: 'Formatting JSON…');
    }
    if (_jsonError != null) {
      return ErrorBlock(message: 'Invalid JSON: $_jsonError');
    }

    final content = SelectableText.rich(
      SyntaxHighlighter.buildTree(json.decode(_raw)),
      style: _monospaceStyle,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: CustomColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
      ),
      child: _kEnableJsonWrapping
          ? content
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: content,
            ),
    );
  }

  Widget _buildRawView() {
    final content = SelectableText(
      _raw,
      style: _monospaceStyle.copyWith(color: CustomColors.onSurface),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: CustomColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
      ),
      child: _kEnableRawWrapping
          ? content
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: content,
            ),
    );
  }

  Widget _buildHtmlView() {
    final content = SelectableText(
      _raw,
      style: _monospaceStyle.copyWith(color: CustomColors.onSurface),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: CustomColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
      ),
      child: _kEnableHtmlWrapping
          ? content
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: content,
            ),
    );
  }
}

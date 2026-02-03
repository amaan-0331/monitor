import 'dart:convert' show latin1, utf8;
import 'dart:typed_data';

import 'package:monitor/src/models/multipart_info.dart';

/// Utility class to parse multipart/form-data requests
class MultipartParser {
  MultipartParser._();

  /// Check if the content type indicates a multipart request
  static bool isMultipart(Map<String, String>? headers) {
    if (headers == null) return false;
    final contentType = _getContentType(headers);
    return contentType?.toLowerCase().contains('multipart/form-data') ?? false;
  }

  /// Extract boundary from Content-Type header
  /// Returns null if not found
  static String? extractBoundary(Map<String, String>? headers) {
    if (headers == null) return null;
    final contentType = _getContentType(headers);
    if (contentType == null) return null;

    // Parse: multipart/form-data; boundary=----WebKitFormBoundary...
    final boundaryMatch = RegExp(
      r'boundary=([^\s;]+)',
      caseSensitive: false,
    ).firstMatch(contentType);
    if (boundaryMatch == null) return null;

    var boundary = boundaryMatch.group(1)!;
    // Remove quotes if present
    if (boundary.startsWith('"') && boundary.endsWith('"')) {
      boundary = boundary.substring(1, boundary.length - 1);
    }
    return boundary;
  }

  /// Parse a multipart body and extract part information
  /// Returns null if parsing fails or not a multipart request
  static MultipartInfo? parse({
    required Map<String, String>? headers,
    String? body,
    List<int>? bodyRawBytes,
  }) {
    if (!isMultipart(headers)) return null;

    final boundary = extractBoundary(headers);
    if (boundary == null) return null;

    if (bodyRawBytes != null) {
      final Uint8List bytes;
      if (bodyRawBytes is Uint8List) {
        bytes = bodyRawBytes;
      } else {
        bytes = Uint8List.fromList(bodyRawBytes);
      }
      return _parseBytes(bytes: bytes, boundary: boundary);
    }

    if (body == null) return null;
    return _parseString(body: body, boundary: boundary);
  }

  static MultipartInfo? _parseString({
    required String body,
    required String boundary,
  }) {
    final parts = <MultipartPartInfo>[];

    final boundaryDelimiter = '--$boundary';
    var index = body.indexOf(boundaryDelimiter);
    if (index == -1) return null;

    while (index != -1) {
      final start = index + boundaryDelimiter.length;
      final next = body.indexOf(boundaryDelimiter, start);
      if (next == -1) break;

      final segment = body.substring(start, next);
      final trimmed = segment.trim();
      if (trimmed.isNotEmpty && trimmed != '--') {
        final partInfo = _parsePartSegment(segment);
        if (partInfo != null) {
          parts.add(partInfo);
        }
      }

      index = next;
    }

    if (parts.isEmpty) return null;

    return MultipartInfo(parts: parts, boundary: boundary);
  }

  static MultipartInfo? _parseBytes({
    required Uint8List bytes,
    required String boundary,
  }) {
    final parts = <MultipartPartInfo>[];
    final boundaryDelimiter = Uint8List.fromList(utf8.encode('--$boundary'));
    final headerSeparator = Uint8List.fromList([13, 10, 13, 10]);
    final headerSeparatorAlt = Uint8List.fromList([10, 10]);

    var index = _indexOfBytes(bytes, boundaryDelimiter, 0, bytes.length);
    if (index == -1) return null;

    while (index != -1) {
      var segmentStart = index + boundaryDelimiter.length;
      final next = _indexOfBytes(
        bytes,
        boundaryDelimiter,
        segmentStart,
        bytes.length,
      );
      if (next == -1) break;

      if (segmentStart + 1 < next &&
          bytes[segmentStart] == 13 &&
          bytes[segmentStart + 1] == 10) {
        segmentStart += 2;
      } else if (segmentStart < next && bytes[segmentStart] == 10) {
        segmentStart += 1;
      }

      if (segmentStart < next) {
        var headerEndIndex = _indexOfBytes(
          bytes,
          headerSeparator,
          segmentStart,
          next,
        );
        var separatorLength = 4;
        if (headerEndIndex == -1) {
          headerEndIndex = _indexOfBytes(
            bytes,
            headerSeparatorAlt,
            segmentStart,
            next,
          );
          separatorLength = 2;
        }

        if (headerEndIndex != -1) {
          final partInfo = _parsePartBytes(
            bytes: bytes,
            headerStart: segmentStart,
            headerEnd: headerEndIndex,
            contentStart: headerEndIndex + separatorLength,
            contentEnd: next,
          );
          if (partInfo != null) {
            parts.add(partInfo);
          }
        }
      }

      index = next;
    }

    if (parts.isEmpty) return null;

    return MultipartInfo(parts: parts, boundary: boundary);
  }

  static MultipartPartInfo? _parsePartBytes({
    required Uint8List bytes,
    required int headerStart,
    required int headerEnd,
    required int contentStart,
    required int contentEnd,
  }) {
    final headerSection = latin1.decode(bytes.sublist(headerStart, headerEnd));

    final dispositionMatch = RegExp(
      r'Content-Disposition:\s*form-data;\s*name="([^"]*)"',
      caseSensitive: false,
    ).firstMatch(headerSection);

    if (dispositionMatch == null) return null;

    final name = dispositionMatch.group(1)!;
    final filenameMatch = RegExp(
      'filename="([^"]*)"',
      caseSensitive: false,
    ).firstMatch(headerSection);
    final filename = filenameMatch?.group(1);

    final contentTypeMatch = RegExp(
      r'Content-Type:\s*([^\r\n]+)',
      caseSensitive: false,
    ).firstMatch(headerSection);
    final contentType = contentTypeMatch?.group(1)?.trim();

    var adjustedEnd = contentEnd;
    if (adjustedEnd - 2 >= contentStart &&
        bytes[adjustedEnd - 2] == 13 &&
        bytes[adjustedEnd - 1] == 10) {
      adjustedEnd -= 2;
    } else if (adjustedEnd - 1 >= contentStart &&
        bytes[adjustedEnd - 1] == 10) {
      adjustedEnd -= 1;
    }

    if (adjustedEnd < contentStart) {
      adjustedEnd = contentStart;
    }

    final size = adjustedEnd - contentStart;
    final isFile = filename != null;

    return MultipartPartInfo(
      name: name,
      filename: filename,
      contentType: contentType,
      size: size,
      isFile: isFile,
    );
  }

  static int _indexOfBytes(
    Uint8List data,
    Uint8List pattern,
    int start,
    int end,
  ) {
    if (pattern.isEmpty || start >= end) return -1;
    final lastStart = end - pattern.length;
    for (var i = start; i <= lastStart; i++) {
      var matched = true;
      for (var j = 0; j < pattern.length; j++) {
        if (data[i + j] != pattern[j]) {
          matched = false;
          break;
        }
      }
      if (matched) return i;
    }
    return -1;
  }

  /// Parse a single part segment to extract metadata
  static MultipartPartInfo? _parsePartSegment(String segment) {
    // Parts have the format:
    // \r\n
    // Content-Disposition: form-data; name="field"; filename="file.txt"
    // Content-Type: text/plain
    // \r\n
    // <content>
    // \r\n

    // Find the header/body separator (double newline)
    final headerEndIndex = segment.indexOf('\r\n\r\n');
    if (headerEndIndex == -1) {
      // Try with just \n\n
      final altIndex = segment.indexOf('\n\n');
      if (altIndex == -1) return null;
      return _parseWithSeparator(segment, altIndex, '\n\n');
    }
    return _parseWithSeparator(segment, headerEndIndex, '\r\n\r\n');
  }

  static MultipartPartInfo? _parseWithSeparator(
    String segment,
    int headerEndIndex,
    String separator,
  ) {
    final headerSection = segment.substring(0, headerEndIndex);
    final contentSection = segment.substring(headerEndIndex + separator.length);

    // Parse Content-Disposition
    final dispositionMatch = RegExp(
      r'Content-Disposition:\s*form-data;\s*name="([^"]*)"',
      caseSensitive: false,
    ).firstMatch(headerSection);

    if (dispositionMatch == null) return null;

    final name = dispositionMatch.group(1)!;

    // Check for filename
    final filenameMatch = RegExp(
      'filename="([^"]*)"',
      caseSensitive: false,
    ).firstMatch(headerSection);
    final filename = filenameMatch?.group(1);

    // Parse Content-Type
    final contentTypeMatch = RegExp(
      r'Content-Type:\s*([^\r\n]+)',
      caseSensitive: false,
    ).firstMatch(headerSection);
    final contentType = contentTypeMatch?.group(1)?.trim();

    // Calculate content size
    // Remove trailing boundary markers and whitespace
    var content = contentSection;
    if (content.endsWith('\r\n')) {
      content = content.substring(0, content.length - 2);
    } else if (content.endsWith('\n')) {
      content = content.substring(0, content.length - 1);
    }

    final size = utf8.encode(content).length;
    final isFile = filename != null;

    return MultipartPartInfo(
      name: name,
      filename: filename,
      contentType: contentType,
      size: size,
      isFile: isFile,
    );
  }

  /// Get Content-Type header value (case-insensitive lookup)
  static String? _getContentType(Map<String, String> headers) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'content-type') {
        return entry.value;
      }
    }
    return null;
  }
}

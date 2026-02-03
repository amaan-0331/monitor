import 'package:flutter/foundation.dart';

/// Information about a single part in a multipart request
@immutable
class MultipartPartInfo {
  const MultipartPartInfo({
    required this.name,
    required this.size,
    required this.isFile,
    this.filename,
    this.contentType,
  });

  /// Field name from Content-Disposition
  final String name;

  /// File name if this is a file upload (null for text fields)
  final String? filename;

  /// MIME type from Content-Type header
  final String? contentType;

  /// Size of this part's content in bytes
  final int size;

  /// Whether this is a file upload or a regular form field
  final bool isFile;

  /// Human-readable size string
  String get sizeText {
    const kb = 1024;
    if (size < kb) return '${size}B';
    final kbSize = size / kb;
    if (kbSize < kb) return '${kbSize.toStringAsFixed(1)}KB';
    final mbSize = kbSize / kb;
    return '${mbSize.toStringAsFixed(2)}MB';
  }

  /// Display string for console/UI
  /// Examples:
  /// - "avatar (file: avatar.png, image/png, 150KB)"
  /// - "name (field: 24B)"
  String get displayText {
    if (isFile) {
      final type = contentType ?? 'unknown';
      final file = filename ?? 'unnamed';
      return '$name (file: $file, $type, $sizeText)';
    }
    return '$name (field: $sizeText)';
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'filename': filename,
      'contentType': contentType,
      'size': size,
      'isFile': isFile,
    };
  }
}

/// Aggregated information about a multipart/form-data request
@immutable
class MultipartInfo {
  MultipartInfo({
    required this.parts,
    required this.boundary,
  }) : fileCount = _countFiles(parts),
       fieldCount = _countFields(parts),
       totalSize = _sumSize(parts);

  /// All parts in this multipart request
  final List<MultipartPartInfo> parts;

  /// The boundary string used to separate parts
  final String boundary;

  /// Number of file parts
  final int fileCount;

  /// Number of text field parts
  final int fieldCount;

  /// Total size of all parts
  final int totalSize;

  /// Human-readable total size
  String get totalSizeText {
    const kb = 1024;
    if (totalSize < kb) return '${totalSize}B';
    final kbSize = totalSize / kb;
    if (kbSize < kb) return '${kbSize.toStringAsFixed(1)}KB';
    final mbSize = kbSize / kb;
    return '${mbSize.toStringAsFixed(2)}MB';
  }

  /// Summary string for quick display
  /// Example: "2 files, 3 fields (1.2MB total)"
  String get summary {
    final parts = <String>[];
    if (fileCount > 0) {
      parts.add('$fileCount ${fileCount == 1 ? 'file' : 'files'}');
    }
    if (fieldCount > 0) {
      parts.add('$fieldCount ${fieldCount == 1 ? 'field' : 'fields'}');
    }
    if (parts.isEmpty) return 'Empty multipart';
    return '${parts.join(', ')} ($totalSizeText total)';
  }

  /// Placeholder body text to replace binary content
  String get placeholderBody => '[Multipart: $summary]';

  Map<String, dynamic> toJson() {
    return {
      'boundary': boundary,
      'fileCount': fileCount,
      'fieldCount': fieldCount,
      'totalSize': totalSize,
      'parts': parts.map((p) => p.toJson()).toList(),
    };
  }

  static int _countFiles(List<MultipartPartInfo> parts) {
    var count = 0;
    for (final part in parts) {
      if (part.isFile) count++;
    }
    return count;
  }

  static int _countFields(List<MultipartPartInfo> parts) {
    var count = 0;
    for (final part in parts) {
      if (!part.isFile) count++;
    }
    return count;
  }

  static int _sumSize(List<MultipartPartInfo> parts) {
    var sum = 0;
    for (final part in parts) {
      sum += part.size;
    }
    return sum;
  }
}

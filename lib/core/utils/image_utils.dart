import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Utility functions for image processing
class ImageUtils {
  ImageUtils._();

  /// Convert a File to a base64 data URI
  /// Returns format: `data:image/jpeg;base64,{base64_encoded_data}`
  static String fileToBase64DataUri(File file) {
    final bytes = file.readAsBytesSync();
    final base64String = base64Encode(bytes);
    final mimeType = _getMimeType(file.path);
    return 'data:$mimeType;base64,$base64String';
  }

  /// Convert an XFile to a base64 data URI
  static Future<String> xFileToBase64DataUri(XFile xFile) async {
    final bytes = await xFile.readAsBytes();
    final base64String = base64Encode(bytes);
    final mimeType = _getMimeType(xFile.path);
    return 'data:$mimeType;base64,$base64String';
  }

  /// Convert bytes to a base64 data URI
  static String bytesToBase64DataUri(Uint8List bytes, String filename) {
    final base64String = base64Encode(bytes);
    final mimeType = _getMimeType(filename);
    return 'data:$mimeType;base64,$base64String';
  }

  /// Convert multiple XFiles to base64 data URIs
  static Future<List<String>> xFilesToBase64DataUris(List<XFile> files) async {
    return Future.wait(files.map((f) => xFileToBase64DataUri(f)));
  }

  /// Estimate the byte size of a base64 data URI (data:image/...;base64,XXX).
  /// Each 4 base64 chars decode to 3 bytes.
  static int estimateBytesFromDataUri(String dataUri) {
    final commaIdx = dataUri.indexOf(',');
    final body = commaIdx >= 0 ? dataUri.substring(commaIdx + 1) : dataUri;
    return (body.length * 3) ~/ 4;
  }

  /// Estimate total payload bytes for a list of data URIs.
  static int estimateTotalBytes(Iterable<String> dataUris) {
    return dataUris.fold<int>(
      0,
      (sum, uri) => sum + estimateBytesFromDataUri(uri),
    );
  }

  /// Caddy enforces a 10 MB hard cap on POST bodies at the edge
  /// (per api.md §1). Leave ~512 KB headroom for JSON envelope.
  static const int maxAnalysisPayloadBytes = (10 * 1024 * 1024) - 512 * 1024;

  /// Get MIME type from file path extension
  static String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      'bmp' => 'image/bmp',
      _ => 'image/jpeg',
    };
  }

  /// Get file extension from MIME type
  static String getExtensionFromMimeType(String mimeType) {
    return switch (mimeType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      'image/gif' => 'gif',
      'image/heic' => 'heic',
      'image/heif' => 'heif',
      'image/bmp' => 'bmp',
      _ => 'jpg',
    };
  }

  /// Estimate the base64 size of an image (before encoding)
  /// Base64 encoding increases size by ~33%
  static int estimateBase64Size(int originalBytes) {
    return ((originalBytes * 4) / 3).ceil();
  }
}

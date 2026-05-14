import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // Make sure this Cloudinary preset is unsigned and active.
  // Use your Cloudinary environment values here.
  static const String cloudName = 'dzkubbzpk';
  static const String uploadPreset = 'unimacate_upload';

  static Future<String?> uploadImageFromPath(String path) {
    return _uploadFromPath(
      path: path,
      resourceType: 'auto',
      mediaLabel: 'image',
      timeout: const Duration(minutes: 2),
      timeoutMessage: 'Upload timeout - Check internet connection',
    );
  }

  static Future<String?> uploadImageBytes({
    required List<int> bytes,
    required String filename,
  }) {
    return _uploadFromBytes(
      bytes: bytes,
      filename: filename,
      resourceType: 'auto',
      mediaLabel: 'image',
      timeout: const Duration(minutes: 2),
      timeoutMessage: 'Upload timeout - Check internet connection',
    );
  }

  static Future<String?> uploadVideoFromPath(String path) {
    return _uploadFromPath(
      path: path,
      resourceType: 'auto',
      mediaLabel: 'video',
      timeout: const Duration(minutes: 5),
      timeoutMessage: 'Upload timeout - Video is too large or internet is slow',
    );
  }

  static Future<String?> uploadVideoBytes({
    required List<int> bytes,
    required String filename,
  }) {
    return _uploadFromBytes(
      bytes: bytes,
      filename: filename,
      resourceType: 'auto',
      mediaLabel: 'video',
      timeout: const Duration(minutes: 5),
      timeoutMessage: 'Upload timeout - Video is too large or internet is slow',
    );
  }

  static Future<String?> _uploadFromPath({
    required String path,
    required String resourceType,
    required String mediaLabel,
    required Duration timeout,
    required String timeoutMessage,
  }) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload',
      );
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', path));

      debugPrint(
        'Uploading $mediaLabel... CloudName: $cloudName, Preset: $uploadPreset',
      );

      return _sendRequest(
        request: request,
        mediaLabel: mediaLabel,
        timeout: timeout,
        timeoutMessage: timeoutMessage,
      );
    } catch (e, stackTrace) {
      debugPrint('Cloudinary $mediaLabel upload error: $e');
      debugPrint(stackTrace.toString());
      return null;
    }
  }

  static Future<String?> _uploadFromBytes({
    required List<int> bytes,
    required String filename,
    required String resourceType,
    required String mediaLabel,
    required Duration timeout,
    required String timeoutMessage,
  }) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload',
      );
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );

      debugPrint(
        'Uploading $mediaLabel bytes... CloudName: $cloudName, Preset: $uploadPreset',
      );

      return _sendRequest(
        request: request,
        mediaLabel: mediaLabel,
        timeout: timeout,
        timeoutMessage: timeoutMessage,
      );
    } catch (e, stackTrace) {
      debugPrint('Cloudinary $mediaLabel upload error: $e');
      debugPrint(stackTrace.toString());
      return null;
    }
  }

  static Future<String?> _sendRequest({
    required http.MultipartRequest request,
    required String mediaLabel,
    required Duration timeout,
    required String timeoutMessage,
  }) async {
    try {
      final response = await request.send().timeout(
        timeout,
        onTimeout: () {
          throw Exception(timeoutMessage);
        },
      );
      final responseBody = await response.stream.bytesToString();

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: $responseBody');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = json.decode(responseBody);
        return responseData['secure_url'] as String?;
      }

      debugPrint(
        'Cloudinary $mediaLabel upload failed: ${response.statusCode}',
      );
      return null;
    } catch (e, stackTrace) {
      debugPrint('Cloudinary $mediaLabel upload error: $e');
      debugPrint(stackTrace.toString());
      return null;
    }
  }
}

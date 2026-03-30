import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class CloudflareImageUploadResult {
  CloudflareImageUploadResult({required this.id, required this.url});

  final String id;
  final String url;
}

class CloudflareImageService {
  CloudflareImageService._();

  static const String _defaultCloudName = 'dtcywgw6q';
  static const String _defaultUploadPreset = 'BTL-NHOM2-PTUDCCTBDD';
  static const String _defaultFolder = 'BTL';

  static const String _cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: _defaultCloudName,
  );
  static const String _uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: _defaultUploadPreset,
  );
  static const String _folder = String.fromEnvironment(
    'CLOUDINARY_FOLDER',
    defaultValue: _defaultFolder,
  );

  static bool get isConfigured =>
      _cloudName.trim().isNotEmpty && _uploadPreset.trim().isNotEmpty;

  static Future<CloudflareImageUploadResult> uploadNoteImage({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    if (!isConfigured) {
      throw Exception(
        'Thiếu cấu hình Cloudinary (cloud name hoặc upload preset). '
        'Hãy đảm bảo các biến môi trường đã được thiết lập đúng.',
      );
    }

    final Uri uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final http.MultipartRequest request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = _folder
      ..fields['public_id'] =
          'note_${DateTime.now().millisecondsSinceEpoch}_${fileName.replaceAll(' ', '_')}'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: _parseMediaType(mimeType),
        ),
      );

    final http.StreamedResponse streamedResponse = await request.send().timeout(
      const Duration(seconds: 15),
    );
    final http.Response response = await http.Response.fromStream(
      streamedResponse,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Upload thất bại (${response.statusCode}): ${response.body}',
      );
    }

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;

    final String? id = body['public_id']?.toString();
    final String? url = body['secure_url']?.toString();

    if (id == null || id.isEmpty || url == null || url.isEmpty) {
      throw Exception('Không thể lấy URL ảnh từ Cloudinary. Vui lòng thử lại.');
    }

    return CloudflareImageUploadResult(id: id, url: url);
  }

  static MediaType _parseMediaType(String mimeType) {
    final List<String> split = mimeType.split('/');
    if (split.length != 2) {
      return MediaType('image', 'jpeg');
    }
    return MediaType(split[0], split[1]);
  }

  static Future<void> deleteNoteImage(String imageId) async {
    // Cloudinary delete requires signed API calls from a secure backend.
    // Keep this as no-op on client to avoid exposing API secret.
    if (imageId.trim().isEmpty) {
      return;
    }
  }
}

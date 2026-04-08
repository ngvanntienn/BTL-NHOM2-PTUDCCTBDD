import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../cloudflare_image_service.dart';

class ImageUploadService {
  ImageUploadService({FirebaseStorage? storage, FirebaseAuth? auth})
    : _storage = storage ?? FirebaseStorage.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  Future<String> uploadFoodImage(XFile file) async {
    final Uint8List bytes = await file.readAsBytes();

    if (CloudflareImageService.isConfigured) {
      try {
        final CloudflareImageUploadResult result =
            await CloudflareImageService.uploadFoodImage(
              bytes: bytes,
              fileName: file.name,
              mimeType: file.mimeType ?? 'image/jpeg',
            ).timeout(const Duration(seconds: 20));
        return result.url;
      } catch (_) {
        // Fallback to Firebase Storage when Cloudinary is unavailable.
      }
    }

    final String userId = _auth.currentUser?.uid ?? 'anonymous';
    final String extension = _extractExtension(file.name);
    final String path =
        'food_images/$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';

    final Reference ref = _storage.ref().child(path);
    await ref.putData(
      bytes,
      SettableMetadata(contentType: file.mimeType ?? 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  String _extractExtension(String fileName) {
    final int idx = fileName.lastIndexOf('.');
    if (idx < 0 || idx == fileName.length - 1) {
      return 'jpg';
    }
    return fileName.substring(idx + 1).toLowerCase();
  }
}

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class ImageService {
  static final _picker = ImagePicker();
  static const _uuid = Uuid();

  static Future<String?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (image == null) return null;
      return await _saveImageLocally(image);
    } catch (e) {
      return null;
    }
  }

  static Future<String?> pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (image == null) return null;
      return await _saveImageLocally(image);
    } catch (e) {
      return null;
    }
  }

  static Future<String> _saveImageLocally(XFile image) async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/note_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    final ext = path.extension(image.path).toLowerCase();
    final filename = '${_uuid.v4()}$ext';
    final savedFile = await File(image.path).copy('${imagesDir.path}/$filename');
    return savedFile.path;
  }

  static Future<void> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  static Future<bool> imageExists(String imagePath) async {
    return File(imagePath).exists();
  }
}

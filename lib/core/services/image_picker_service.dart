import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality:
            70, // Compresses to optimize Firestore storage / network bandwidth
      );
      return file?.path;
    } catch (_) {
      return null;
    }
  }

  Future<String?> pickImageFromCamera() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      return file?.path;
    } catch (_) {
      return null;
    }
  }
}

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class Camera {
  final picker = ImagePicker();

  Future<String> extractTextFromImage(XFile? pickedImage) async {
    try {
      final inputImage = InputImage.fromFilePath(pickedImage!.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognizedText = await textRecognizer.processImage(inputImage);
      print("Extracted text: ${recognizedText.text}");

      if (recognizedText.text.isEmpty) {
        return 'error';
      }

      return recognizedText.text;
    } catch (e) {
      print(e);
      return "error";
    }
  }

  Future<String?> saveInDirectory(File? pickedFile) async {

    final directory = Platform.isAndroid ?  await getExternalStorageDirectory() : await getApplicationDocumentsDirectory();

    // Create the subdirectory 'images'
    final imagesDir = Directory(p.join(directory!.path, 'images'));

    // Ensure it exists
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
      print("Created image folder");
    }

    final fileName = p.basename(pickedFile!.path);
    final savedImage = await File(pickedFile.path).copy('${directory.path}/images/$fileName');

    return savedImage.path;
  }
}

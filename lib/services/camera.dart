
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class Camera {

  Future<String> extractTextFromImage(XFile? pickedImage) async {

    try {
      final inputImage = InputImage.fromFilePath(pickedImage!.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognizedText = await textRecognizer.processImage(inputImage);
      print("Extracted text: ${recognizedText.text}");

      return recognizedText.text;

    } catch(e) {
      print(e);
      return "error";
    }

  }

}
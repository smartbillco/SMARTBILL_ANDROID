import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CufeService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<String?> processImage(InputImage inputImage) async {
    final recognizedText = await _textRecognizer.processImage(inputImage);

    // 1. Intentar extraerlo primero de la estructura cruda (mejor para saltos de línea)
    final cufe = extractCufe(recognizedText);

    if (cufe != null) {
      print("🎯 CUFE ENCONTRADO: $cufe");
    }

    return cufe;
  }

  String? extractCufe(RecognizedText recognizedText) {
    // 1. Recolectamos TODAS las líneas de todos los bloques en una sola lista
    List<String> allLines = [];
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        allLines.add(line.text.toLowerCase());
      }
    }

    // 2. Unimos todo en una "super cadena" eliminando espacios
    // Esto ignora si ML Kit cree que una parte del CUFE está en el bloque A
    // y la otra en el bloque B.
    String longChain = allLines.join('');

    // 3. Limpieza Quirúrgica
    // Primero quitamos palabras que NO son hex pero que el OCR confunde o pega
    String cleaned = longChain
        .replaceAll('cufe', '')
        .replaceAll('cufé', '')
        .replaceAll('codigo', '')
        .replaceAll('código', '')
        .replaceAll(
            RegExp(r'[:.\-\s]'), ''); // Elimina puntos, guiones y espacios

    // 4. Normalización Hexadecimal
    // Corregimos errores de lectura típicos (Letras que parecen números)
    cleaned = cleaned
        .replaceAll('g', '9')
        .replaceAll('s', '5')
        .replaceAll('z', '2')
        .replaceAll('o', '0')
        .replaceAll('l', '1')
        .replaceAll('i', '1');

    // 5. Filtro final: Solo dejamos caracteres hexadecimales
    cleaned = cleaned.replaceAll(RegExp(r'[^a-f0-9]'), '');

    print("Super Cadena Detectada (${cleaned.length} caracteres):");
    print(cleaned);

    // 6. Búsqueda de la secuencia ganadora
    // Buscamos primero 96 (estándar actual) y si no, 64.
    final match96 = RegExp(r'[a-f0-9]{96}').firstMatch(cleaned);
    if (match96 != null) return match96.group(0);

    final match64 = RegExp(r'[a-f0-9]{64}').firstMatch(cleaned);
    if (match64 != null) return match64.group(0);

    return null;
  }

  void dispose() {
    _textRecognizer.close();
  }


}

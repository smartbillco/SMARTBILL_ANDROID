import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:smartbill/models/dian_pdf.dart';
import 'package:smartbill/models/dian_receipts.dart';

class DianReceiptService {
  String url = 'http://147.93.184.41:8088/api/pos/dian/document';

  Future<Receipt> getReceiptByCufe(String cufe) async {
    final response = await http.get(Uri.parse('$url/$cufe'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      final List documentos = json['data']['documentos'];
      if (documentos.isEmpty) throw Exception("No document found");
      return Receipt.fromJson(documentos.first);
    } else {
      throw Exception("Error: ${response.statusCode}");
    }
  }

  Future<DianPdf> getPdfDian(String cufe) async {
    String downloadUrl =
        'http://147.93.184.41:9095/api/dian/consultar-selenium-pdf';

    final response = await http.post(
      Uri.parse(downloadUrl), 
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Cache-Control': 'no-cache', 
      },
      body: jsonEncode({
        'cufe': cufe,
        'request_id': DateTime.now().millisecondsSinceEpoch.toString(), // Forzar proceso nuevo
      })
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return DianPdf.fromJson(data);
    } else {
      throw Exception("Error downloading PDF: ${response.statusCode}");
    }
  }

  // UPDATED: Now requires the CUFE to ensure a unique, identifiable filename
  Future<File?> base64ToPdfAndSave(String base64Pdf, String cufe) async {
    try {
      final baseDir = Platform.isAndroid
          ? await getExternalStorageDirectory()
          : await getApplicationDocumentsDirectory();

      final folder = Directory("${baseDir!.path}/invoices");
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      // 1. Limpieza del Base64
      String cleanBase64 =
          base64Pdf.trim().replaceAll('\n', '').replaceAll('\r', '');
      Uint8List bytes = base64Decode(cleanBase64);

      // 2. Nombre ÚNICO: Usamos CUFE + Timestamp para que NUNCA se solapen
      // Incluso si el servidor falla, el archivo físico será nuevo.
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = "invoice_${cufe.substring(0, 8)}_$timestamp.pdf";

      final file = File("${folder.path}/$fileName");

      // 3. ESCRITURA FÍSICA REAL
      // flush: true asegura que el archivo se escriba en el disco antes de seguir
      await file.writeAsBytes(bytes, flush: true);

      print("✅ Archivo físico creado: ${file.path}");
      return file;
    } catch (e) {
      print("❌ Error al guardar: $e");
      return null;
    }
  }
}

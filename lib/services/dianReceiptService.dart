import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:smartbill/models/dian_pdf.dart';
import 'package:smartbill/models/dian_receipts.dart';


class DianReceiptService {

  String url = 'http://147.93.184.41:8088/api/dian/document';

  Future<Receipt> getReceiptByCufe(String cufe) async {
    
    final receiptUrl = '$url/$cufe';

    print("Url servicio: $receiptUrl");

    final response = await http.get(Uri.parse(receiptUrl));

    print("Documento 1: ${response.body}");

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);

      final List documentos = json['data']['documentos'];

      if (documentos.isEmpty) {
        throw Exception("No document found");
      }
      print("Documento: ${documentos.first}");

      return Receipt.fromJson(documentos.first);
    } else {
      throw Exception("Error: ${response.statusCode}");
    }
  }


  //Get the PDF in base 64
  Future<DianPdf> getPdfDian(String cufe) async {
    String downloadUrl = 'http://147.93.184.41:9095/api/dian/consultar-selenium-pdf';

    final response = await http.post(
      Uri.parse(downloadUrl), 
      headers: {'Content-Type': 'application/json; charset=UTF-8',},
      body: jsonEncode({
        'cufe': cufe
        })
    );

    if(response.statusCode == 200) {

      final Map<String, dynamic> data = jsonDecode(response.body);
      final DianPdf pdf = DianPdf.fromJson(data);

      return pdf;

    } else {
      throw Exception("No se pudo descargar el PDF.");
    }

  }

  //Convert base 64 to pdf file and save.
  Future<File?> base64ToPdfAndSave(String base64Pdf) async {

    try {

      final baseDir = Platform.isAndroid
          ? await getExternalStorageDirectory()
          : await getApplicationDocumentsDirectory();

      final folder = Directory("${baseDir!.path}/invoices");
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      Uint8List bytes = base64Decode(base64Pdf);

      final fileName = "invoice_${DateTime.now().millisecondsSinceEpoch}.pdf";
    
      final file = File("${folder.path}/$fileName");

      await file.writeAsBytes(bytes);

      print("✅ PDF guardado en: ${file.path}");

      return file;

    } catch (e) {
      throw Exception("Error al guardar PDF: $e");
    }
  }



}
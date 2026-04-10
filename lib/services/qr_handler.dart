import 'package:flutter/services.dart';
import 'package:read_pdf_text/read_pdf_text.dart';
import 'package:smartbill/services/db.dart';

class QRBillHandler {

  DatabaseConnection _databaseConnection = DatabaseConnection();

  Map<String, String> parseQrColombia(String qr) {

  Map<String, String> data = {};

  try {
    print("QR RAW: $qr");

    // 🔹 1. Separar por ;
    List<String> parts = qr.split(';');

    for (var part in parts) {

      part = part.trim();
      if (part.isEmpty) continue;

      // 🔹 2. Detectar si usa = o :
      List<String> keyValue;

      if (part.contains('=')) {
        keyValue = part.split('=');
      } else if (part.contains(':')) {
        keyValue = part.split(':');
      } else {
        continue;
      }

      if (keyValue.length < 2) continue;

      String key = keyValue[0].trim().toLowerCase();
      String value = keyValue.sublist(1).join('=').trim(); 
      // 👆 importante: por si el valor tiene '=' (como URLs)

      data[key] = value;
    }

    print("PARSED DATA: $data");

    // 🔹 3. Mapear a tus keys
    return {
      'bill_number': data['numfac'] ?? "Vacio",
      'date': data['fecfac'] ?? "Vacio",
      'time': data['horfac'] ?? "Vacio",
      'nit': data['nitfac'] ?? "Vacio",
      'customer_id': data['docadq'] ?? "Vacio",
      'amount_before_iva': data['valfac'] ?? "0",
      'iva': data['valiva'] ?? "0",
      'other_tax': data['valotroim'] ?? "0",
      'total_amount': data['valtotalfac'] ?? "0",
      'cufe': data['cufe'] ?? "Vacio",
      'dian_link': data['qrcode'] ?? "Vacio",
    };

  } catch (e) {

    print("ERROR: $e");

    // 🔥 CONTINGENCIA SOLO CUFE
    RegExp cufeRegex = RegExp(r'\b([a-fA-F0-9]{32,})\b');
    final match = cufeRegex.firstMatch(qr);

    return {
      'bill_number': "Vacio",
      'date': "Vacio",
      'time': "Vacio",
      'nit': "Vacio",
      'customer_id': "Vacio",
      'amount_before_iva': "0",
      'iva': "0",
      'other_tax': "0",
      'total_amount': "0",
      'cufe': match != null ? match.group(1)! : "No encontrado",
      'dian_link': "Vacio",
    };
  }
}

  //Read QR bill from Peru
  Map<String, dynamic> parseQrPeru(String qrResult) {

    try {
      List qrList = qrResult.split('|');
      List keys = ['ruc_company', 'receipt_id', 'code_start', 'code_end', 'igv', 'amount', 'date', 'percentage', 'ruc_customer', 'summery'];

      Map<String, dynamic> qrPdf = {};

      for (var i = 0; i < keys.length; i++) {
         if (i >= qrList.length || qrList[i].trim().isEmpty) {
            qrPdf[keys[i]] = "Empty";
          } else {
            qrPdf[keys[i]] = qrList[i];
          }
        
      }

      print(qrPdf);

      return qrPdf;
    } catch(e) {
      Map<String, dynamic> error = {
        'error': e
      };
      return error;
    }
    
  }


  //Parse info into pdf
  Map <String, dynamic> parsePdf(dynamic id, dynamic companyId, String text) {
    final Map<String, dynamic> newPdf = {
        '_id': id,
        'id_bill': '',
        'customer': 'PDF',
        'company': '',
        'company_id': companyId,
        'price': '0',
        'cufe': '',
        'city': '',
        'date': '',
        'time': '',
        'currency': 'PDF',
    };

    return newPdf;

  }

  Future getPdfs() async {
    final db = await _databaseConnection.db;
    var pdfFiles = await db.query('pdf_files');
    return pdfFiles;
  }


  Future<String> getPDFtext(String path) async {
    String text = "";
    try {
      text = await ReadPdfText.getPDFtext(path);
      insertPdf(text);
    } on PlatformException {
      print('Failed to get PDF text.');
    }
    return text;
  }


  Future insertPdf(String pdf) async {
    final db = await _databaseConnection.db;
    var result = await db.insert('pdf_files', {'pdf_text':pdf});
    return result;
  }

  Future<void> deletePdf(int id) async {
    try {
      final db = await _databaseConnection.db;
      await db.delete('pdf_files', where: '_id = ?', whereArgs: [id]);
      print("deleted");
    } catch (e){
      print("Could not delete: $e");
    }
    
  }

}
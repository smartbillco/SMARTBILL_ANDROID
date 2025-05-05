import 'package:flutter/services.dart';
import 'package:read_pdf_text/read_pdf_text.dart';
import 'package:smartbill/services/db.dart';

class PdfHandler {

  //Read new Colombian QR code
  dynamic parseQrColombia(String qrResult) {

    bool isColonAfterNumFac(String input) {
      RegExp regex = RegExp(r'NumFac\s*([=:])');
      final match = regex.firstMatch(input);
      if (match != null) {
        return match.group(1) == ':'; // true if ':', false if '='
      }
      return false; // or throw an error if NumFac not found
    }

    try {
      
      if(isColonAfterNumFac(qrResult)) {
        print("QR: $qrResult");
        List lines = qrResult.contains('\n') ? qrResult.split('\n') : qrResult.split(' ');
        print("lines: $lines");
        List qrList = lines.map((item) => item.split(':').last).toList();
        print("QR list: $qrList");
        List keys = ['bill_number', 'date', 'time', 'nit', 'customer_id', 'amount_before_iva', 'iva', 'other_tax', 'total_amount', 'cufe', 'dian_link'];

        Map<String, dynamic> qrPdf = {};

        for(var i = 0; i < 11; i++){
          if(i >= qrList.length || qrList[i].trim().isEmpty) {
            qrPdf[keys[i]] = "Vacio2";
          } else {
            qrPdf[keys[i]] = qrList[i];
          }
        }

        print("Printing QR pdf $qrPdf");

        return qrPdf;

      } else {
        List lines = qrResult.contains('\n') ? qrResult.split('\n') : qrResult.split(' ');
        List qrList = lines.map((item) => item.split('=')[1].split(' ')[0]).toList();
        List keys = ['bill_number', 'date', 'time', 'nit', 'customer_id', 'amount_before_iva', 'iva', 'other_tax', 'total_amount', 'cufe', 'dian_link'];

        Map<String, dynamic> qrPdf = {};

        for(var i = 0; i < 11; i++){
          if(i >= qrList.length || qrList[i].trim().isEmpty) {
            qrPdf[keys[i]] = "Vacio3";
          } else {
            qrPdf[keys[i]] = qrList[i];
          }
        }

        print("Printing QR pdf right $qrPdf");

        return qrPdf;

      }

    } catch(e) {
      Map<String, dynamic> error = {
        'error': e
      };
      return error;
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
    DatabaseConnection databaseConnection = DatabaseConnection();
    var db = await databaseConnection.openDb();
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


  //Extract information from PDF
  Map<String, dynamic> extractInfoFromPdf(String pdf, int idItem) {

    final RegExp nameRegex = RegExp(r'\b([A-ZÁÉÍÓÚÑ][a-záéíóúñ]+)\s+([A-ZÁÉÍÓÚÑ][a-záéíóúñ]+)\b');
    final RegExp companyRegex = RegExp(r'\b(NIT|NIF)\s*([\w\d.-]+)', caseSensitive: false);
    final RegExp idRegex = RegExp(r'\b\d{10}\b'); // Matches exactly 10-digit numbers
    final RegExp dateRegex = RegExp(r'\b\d{1,2}[/.-]\d{1,2}[/.-]\d{2,4}\b'); // Matches various date formats
    final RegExp priceRegex = RegExp(r'(?:valor bruto|valor|total pagado|total|pagado|\$)\s*([\d.,]+)', caseSensitive: false);
    Iterable<Match> matches = priceRegex.allMatches(pdf);
    String? fixedCurrency;

    if (matches.isNotEmpty) {
      final String lastGroup = matches.first.group(1) ?? ''; // Ensure null safety
      fixedCurrency = lastGroup.replaceAll(',', '');
    } else {
      fixedCurrency = '0';
    }
    

    // Extract matches
    final String? name = nameRegex.firstMatch(pdf)?.group(0);
    final String company = companyRegex.firstMatch(pdf)?.group(0).toString() ?? 'Nit:' ;
    final String? id = idRegex.firstMatch(pdf)?.group(0);
    final String? date = dateRegex.firstMatch(pdf)?.group(0);
    final String? total = fixedCurrency;

    Map<String, dynamic> extractedPdf = {
      'is_pdf': true,
      '_id': idItem,
      'customer': name,
      'customer_id': id,
      'company': 'Empresa',
      'company_id': company,
      'date': date,
      'price': total,
      'currency': 'PDF',
      'time': '0:00',
      'cufe': 'No encontrado',
      'city': 'N/A'
    };

    print("Extracted: $name, $company, $id, $date, $total");

    return extractedPdf;

  }

  Future insertPdf(String pdf) async {
    DatabaseConnection databaseConnection = DatabaseConnection();
    var db = await databaseConnection.openDb();
    var result = await db.insert('pdf_files', {'pdf_text':pdf});
    return result;
  }

  Future<void> deletePdf(int id) async {
    try {
      DatabaseConnection databaseConnection = DatabaseConnection();
      var db = await databaseConnection.openDb(); 
      await db.delete('pdf_files', where: '_id = ?', whereArgs: [id]);
      print("deleted");
    } catch (e){
      print("Could not delete: $e");
    }
    
  }


  Map<String, dynamic> parseDIANpdf(String billNumber, String company, String? date, String? total) {
    Map<String, dynamic> dianPdf = {
      'bill_number': billNumber,
      'company': company,
      'date': date,
      'total': total
    };

    return dianPdf;

  }


}
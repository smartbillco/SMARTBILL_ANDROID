import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smartbill/models/pdf.dart';
import 'package:smartbill/services/db.dart'; 

class PdfService {

  Future<dynamic> extractTextfromPdf(File pdf) async {
    final uri = Uri.parse('http://213.199.60.150:8086/ocr/extract-details/pdf');

    var request = http.MultipartRequest('POST', uri);

    // Add pdf to request
    request.files.add(
      await http.MultipartFile.fromPath(
        'file', // Field name on the server
        pdf.path,
        filename: basename(pdf.path),
        contentType: MediaType('application', 'pdf'),
      ),
    );

    // Optional: Add headers or other fields
    request.headers.addAll({
      'Content-Type': 'multipart/form-data',
    });

    // Send the request
    var response = await request.send();

    // Handle response
    if (response.statusCode == 200) {
      String responseString = await response.stream.bytesToString();
      Map<String, dynamic> pdfText = jsonDecode(responseString);
      print(pdfText['data']);
      return pdfText['data'];
      
    } else {
      print('Upload failed with status: ${response.statusCode}');
    }

  }

  double parseDouble(String number) {
    // Remove all spaces
  number = number.replaceAll(' ', '');

  // If there are both '.' and ',' in the string
  if (number.contains('.') && number.contains(',')) {
    // Assume the last separator is the decimal separator
    int lastDot = number.lastIndexOf('.');
    int lastComma = number.lastIndexOf(',');

    if (lastDot > lastComma) {
      // Dot is decimal separator
      number = number.replaceAll(',', '');
    } else {
      // Comma is decimal separator
      number = number.replaceAll('.', '');
      number = number.replaceAll(',', '.');
    }
  } else if (number.contains(',')) {
    // Assume comma is the decimal separator if it's used only once
    int commaCount = '.'.allMatches(number).length;
    if (commaCount == 1) {
      number = number.replaceAll(',', '.');
    } else {
      // Otherwise, assume it's a thousands separator
      number = number.replaceAll(',', '');
    }
  } else if (number.contains('.')) {
    // Handle possible thousands separators
    List<String> parts = number.split('.');
    if (parts.length > 2) {
      // More than one dot → assume dots are thousands separators
      number = number.replaceAll('.', '');
    }
  }

  return double.parse(number);
  }

  Future<String> saveExtractedText(File pdfFile) async {
    Map<String, dynamic> pdfData = await extractTextfromPdf(pdfFile);

    double amount = parseDouble(pdfData['TOTAL']);

    print("Double: $amount");

    final Pdf pdf = Pdf(cufe: pdfData['CUFE'], nit: pdfData['NIT'], date: pdfData['FECHA'], totalAmount: amount);

    int result = await pdf.insertToDatabase();

    print("El registro número $result, se creó");

    return pdf.cufe;

    
  }

  Future<dynamic> fetchAllPdfs() async {
    DatabaseConnection databaseConnection = DatabaseConnection();
    var db = await databaseConnection.openDb();
    var result = await db.query('pdfs');
    return result;
  }


  Future<void> deletePdf(int id, String cufe) async {
    final dir = Platform.isAndroid ?  await getExternalStorageDirectory() : await getApplicationDocumentsDirectory(); 
    final filePath = "${dir!.path}/pdfs/$cufe";

    try {
      //Delete pdf from local storage
      final file = File(filePath);

      if(await file.exists()) {
        await file.delete();
        print('🗑️ Deleted: $cufe');
      } else {
        print('❌ File not found: $cufe');
      }

      //Dekete from database
      DatabaseConnection databaseConnection = DatabaseConnection();
      var db = await databaseConnection.openDb(); 
      await db.delete('pdfs', where: '_id = ?', whereArgs: [id]);
      print("deleted");
    } catch (e){
      print("❌ Could not delete: $e");
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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartbill/services/db.dart';

class OcrReceiptsService {
  final DatabaseConnection databaseConnection = DatabaseConnection();
  final String id = FirebaseAuth.instance.currentUser!.uid;

  Future<List<Map<String, dynamic>>> fetchOcrReceipts() async {
    var db = await databaseConnection.openDb();
    List<Map<String, dynamic>> ocrList = [];

    try {
      List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT _id, date, company, nit, user_document, amount FROM ocr_receipts WHERE userId = ?',
        [id],
      );
      for(var receipt in result) {
        ocrList.add(parseOcrReceipt(receipt));
      }
      print("Lista: $ocrList");
      return ocrList;

    } catch(e) {
      print("Error fetching ocrs: $e");
      return [{"error": "$e"}];
    }

  }

  Map<String, dynamic> parseOcrReceipt(dynamic ocrReceipt) {
    Map<String, dynamic> newOcr = {
        '_id': ocrReceipt['_id'],
        'id_bill': '0000',
        'customer': 'Consumidor final',
        'customer_id': ocrReceipt['user_document'],
        'company': ocrReceipt['company'],
        'company_id': ocrReceipt['nit'],
        'price': ocrReceipt['amount'].toString(),
        'cufe': 'No disponible',
        'date': ocrReceipt['date'],
        'currency': 'OCR'
      };

    return newOcr;
  }

  Future<void> deleteOcrReceipt(int id) async {
    var db = await databaseConnection.openDb();
    
    await db.delete('ocr_receipts', where: '_id = ?', whereArgs: [id]);
    print("Delete receipt");
  }

  Future<String> fetchImage(int id) async {
    final db = await DatabaseConnection().openDb();
    final result = await db.rawQuery(
      'SELECT image FROM ocr_receipts WHERE _id = ?',
      [id],
    );
    return result.first['image'] as String; 
    }

}
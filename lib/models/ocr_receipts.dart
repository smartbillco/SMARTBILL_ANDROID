import 'package:smartbill/services/db.dart';
import 'package:sqflite/sqflite.dart';

class OcrReceipts {
  final String userId;
  final String image;
  final String extractedText;
  final String date;
  final String company;
  final String nit;
  final String userDocument;
  final double amount;

  OcrReceipts({required this.userId, required this.image, required this.extractedText, required this.date, required this.company, required this.nit, required this.userDocument, required this.amount});

  Map<String, dynamic> converTransactionToMap() {
    return {
      'userId': userId,
      'image': image,
      'extracted_text': extractedText,
      'date': date,
      'company': company,
      'nit': nit,
      'user_document': userDocument,
      'amount': amount
    };
  }

  Future<String> saveOcrReceipt() async {
    try {
      final Database db = await DatabaseConnection().db;
      int id = await db.insert('ocr_receipts', converTransactionToMap(), conflictAlgorithm: ConflictAlgorithm.replace); 
      return id.toString();
    } catch(e) {
      return "Hubo un error: $e";

    }

  }

}
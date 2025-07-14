import 'package:smartbill/services/db.dart';

class ColombianBill {
  final DatabaseConnection _databaseConnection = DatabaseConnection();

  Future<dynamic> saveColombianBill(Map<String, Object?> colombianBill) async {
    var db = await _databaseConnection.db;

    try {
      await db.insert('colombian_bill', colombianBill);
      return "success";
    } catch(e) {
      print(e);
      return "error";
    }
  }

  Future getColombianBills() async {
    try {
      final db = await _databaseConnection.db;
      var result = await db.query('colombian_bill');
      return result;
    } catch(e) {
      print('Error: $e');
    }
  }

  Map parseColombianBills(Map bill) {

    try {
        Map billMap = {
          '_id': bill['_id'],
          'id_bill': bill['bill_number'],
          'customer': bill['customer_id'],
          'customer_id': bill['customer_id'],
          'company': bill['nit'],
          'company_id': bill['nit'],
          'price': bill['total_amount'],
          'cufe': bill['cufe'],
          'iva': bill['iva'],
          'date': bill['date'],
          'time': bill['time'],
          'currency': 'COP',
          'type': 'bill_co'
        };

      return billMap;

    } catch(e) {
      Map error = {
        'error': e
      };
      print("Error: $e");
      return error;
    }
    
  }

  Future<void> deleteBill(int id) async {
    DatabaseConnection databaseConnection = DatabaseConnection();
    var db = await databaseConnection.openDb();
    
    await db.delete('colombian_bill', where: '_id = ?', whereArgs: [id]);
    print("Delete bills");
  }

}
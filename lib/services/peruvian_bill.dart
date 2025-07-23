import 'package:smartbill/services/db.dart';

class PeruvianBill {

  final DatabaseConnection _databaseConnection = DatabaseConnection();

  Future<void> savePeruvianBill(Map<String, Object?> peruvianBill) async {
    var db = await _databaseConnection.db;

    try {
      var result = await db.insert('peruvian_bill', peruvianBill);
      print("Saved bill: $result");
    } catch(e) {
      print("Error: $e");
    }
  }

  Future getPeruvianBills() async {

    try {
      DatabaseConnection databaseConnection = DatabaseConnection();
      var db = await databaseConnection.openDb();
      var result = await db.query('peruvian_bill');
      return result;

    } catch(e) {
      print('Error: $e');
    }
  }

  Map parsePeruvianBills(Map bill) {

    try {
        Map billMap = {
          '_id': bill['_id'],
          'id_bill': bill['receipt_id'],
          'customer': bill['ruc_customer'],
          'customer_id': bill['ruc_customer'],
          'company': bill['percentage'],
          'company_id': bill['ruc_company'],
          'price': bill['amount'],
          'cufe': "${bill['code_start']} - ${bill['code_end']}",
          'igv': bill['igv'],
          'date': bill['date'],
          'time': '00:00',
          'currency': 'PEN',
          'type': 'bill_pen'
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
    
    await db.delete('peruvian_bill', where: '_id = ?', whereArgs: [id]);
    print("Delete bills");
  }

}
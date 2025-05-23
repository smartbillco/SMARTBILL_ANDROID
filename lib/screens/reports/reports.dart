import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartbill/screens/reports/reportBalance/report_balance_graph.dart';
import 'package:smartbill/screens/reports/reportCards/report_card.dart';
import 'package:smartbill/screens/reports/reportExpenses/report_expense_graph.dart';
import 'package:smartbill/screens/reports/reportTotal/report_total_cards.dart';
import 'package:smartbill/services/colombian_bill.dart';
import 'package:smartbill/services/db.dart';
import 'package:smartbill/services/peruvian_bill.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}


class _ReportsScreenState extends State<ReportsScreen> {
  DatabaseConnection databaseConnection = DatabaseConnection();
  
  ColombianBill colombianBill = ColombianBill();
  PeruvianBill peruvianBill = PeruvianBill();
  User? user = FirebaseAuth.instance.currentUser!;
  
  String balance = '';




  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getBalance();
  }

  Future<void> getBalance() async {
    var db = await databaseConnection.openDb();
    double totalSum = 0;
    double totalSubs = 0;

    var result = await db.query('transactions', where: 'userId = ?', whereArgs: [user!.uid], orderBy: 'date DESC');

    for(var transaction in result) {
      String transactionAmount = transaction['amount'].toString().replaceAll(',', '');
      if(transaction['type'] == 'income') {
        totalSum += double.parse(transactionAmount);
      } else if (transaction['type'] == 'expense') {
        totalSubs += double.parse(transactionAmount);
      }
      
    }

    String formattedNumber = NumberFormat("#,##0.00").format(totalSum - totalSubs);
    setState(() {
      balance = formattedNumber;
    });
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(65),
        child: AppBar(
          titleSpacing: 30,
          title: const Text("Reportes", style: TextStyle(color: Colors.white)),
          backgroundColor: const Color.fromARGB(255, 29, 29, 29),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
          ),
        ),
      ),
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 14),
          child: Column(
            spacing: 4,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumen de actividad',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              ReportCard(),
              SizedBox(height: 12),
              Text('Balance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 20),
              BalanceGraph(),
              Text('Gastos por categoria', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ExpensePieChart()
        
            ],
          ),
        ),
      ),
    );
  }
}



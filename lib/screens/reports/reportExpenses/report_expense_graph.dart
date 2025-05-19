import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartbill/services/db.dart';

class ExpensePieChart extends StatefulWidget {
  const ExpensePieChart({super.key});

  @override
  State<ExpensePieChart> createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends State<ExpensePieChart> {
  DatabaseConnection databaseConnection = DatabaseConnection();
  User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;
  List<Map<String, dynamic>> summary = [];
  final categoryColors = {
      'Alimentación': Colors.blue,
      'Transporte': Colors.orange,
      'Arriendo': Colors.yellowAccent,
      'Servicios': Colors.cyan,
      'Salidas': Colors.redAccent,
      'Salud': Colors.green,
      'Otro': Colors.deepOrangeAccent
    };

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {

    setState(() {
      _isLoading = true;
    });

    List<Map<String, dynamic>> summaryList = [];
    var db = await databaseConnection.openDb();
    var transactions = await db.query('transactions', where: 'userId = ? AND type = ?', whereArgs: [user!.uid, 'expense']);


    for (var tx in transactions) {
      final category = tx['category'];
      final amount = tx['amount'];

      // Try to find existing category in the summary
      final existing = summaryList.firstWhere(
        (item) => item['category'] == category,
        orElse: () => {},
      );

      if (existing.isNotEmpty) {
        // If found, update the amount
        existing['amount'] += amount;
      } else {
        // If not found, add a new entry
        summaryList.add({'category': category, 'amount': amount});
      }
    }

    setState(() {
      summary = summaryList;
      _isLoading: false;
    });

  }


  @override
  Widget build(BuildContext context) {

    return summary.isEmpty
    ? Center(child: const Text("Todavia no hay gastos en tu gestión de balance"))
    : Row(
      children: [
        SizedBox(
          height: 230,
          width: 230,
          child: PieChart(
            PieChartData(
              sections: buildSections(summary),
              sectionsSpace: 0,
              centerSpaceRadius: 0,
              pieTouchData: PieTouchData(enabled: false), // no interaction needed
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: summary.map((data) {
            final category = data['category'] as String;
            final amount = data['amount'] as double;
            final color = categoryColors[category] ?? Colors.grey;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: buildLegendItem(category, amount, color),
            );
          }).toList(),
        ),
      ],
    );
  }
}

List<PieChartSectionData> buildSections(List<Map<String, dynamic>> summary) {

  final categoryColors = {
    'Alimentación': Colors.blue,
    'Transporte': Colors.orange,
    'Arriendo': Colors.yellowAccent,
    'Servicios': Colors.cyan,
    'Salidas': Colors.redAccent,
    'Salud': Colors.green,
    'Otro': Colors.deepOrangeAccent
  };


  return summary.map((data) {
    final category = data['category'] as String;
    final value = data['amount'] as double;
    final color = categoryColors[category] ?? Colors.grey;

    return PieChartSectionData(
      value: value,
      title: category, // Hide title on chart itself
      color: color,
      radius: 100
    );
  }).toList();
}

Widget buildLegendItem(String category, double amount, Color color) {
  String formattedAmount = NumberFormat("#,##0.00").format(amount);
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        Text(formattedAmount, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
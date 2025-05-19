import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:smartbill/services/db.dart';

class BalanceGraph extends StatefulWidget {
  const BalanceGraph({super.key});

  @override
  State<BalanceGraph> createState() => _BalanceGraphState();
}

class _BalanceGraphState extends State<BalanceGraph> {
  DatabaseConnection databaseConnection = DatabaseConnection();
  User? user = FirebaseAuth.instance.currentUser;
  final currencyFormatter = NumberFormat.simpleCurrency(decimalDigits: 0);
  late double income = 0;
  late double expenses = 0;


  Future<void> getTotalIncome() async {
    var db = await databaseConnection.openDb();
    double totalSum = 0;

    var result = await db.query('transactions', where: 'userId = ? AND type = ?', whereArgs: [user!.uid, 'income']);

    print(result);

    for(var item in result) {
      totalSum += item['amount'];
    }

    setState(() {
      income = totalSum;
    });

  }

  Future<void> getTotalExpense() async {
    var db = await databaseConnection.openDb();
    double totalSub = 0;

    var result = await db.query('transactions', where: 'userId = ? AND type = ?', whereArgs: [user!.uid, 'expense']);

    for(var item in result) {
      totalSub += item['amount'];
    }

    setState(() {
      expenses = totalSub;
    });

  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getTotalIncome();
    getTotalExpense();
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: AspectRatio(
        aspectRatio: 1.7,
        child: BarChart(
          BarChartData(
            barGroups: [
              BarChartGroupData(
                x: 0,
                barRods: [
                  BarChartRodData(
                    toY: expenses,
                    color: Colors.redAccent,
                    width: 35,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
              BarChartGroupData(
                x: 1,
                barRods: [
                  BarChartRodData(
                    toY: income,
                    color: Colors.green,
                    width: 35,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ],
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    switch (value.toInt()) {
                      case 0:
                        return const Text('Gastos');
                      case 1:
                        return const Text('Ingresos');
                      default:
                        return const Text('');
                    }
                  },
                ),
              ),
      
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false)
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            alignment: BarChartAlignment.spaceAround,
            maxY: income,
             barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label = group.x == 0 ? 'Gastos' : 'Ingreso';
                final value = currencyFormatter.format(rod.toY);
                return BarTooltipItem(
                  '$label\n$value',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ), // Add headroom
          ),
        ),
        )
      ),
    );
  }
}
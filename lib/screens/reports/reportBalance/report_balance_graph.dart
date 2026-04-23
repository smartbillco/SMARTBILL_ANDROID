import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartbill/services/db.dart';

class BalanceGraph extends StatefulWidget {
  const BalanceGraph({super.key});

  @override
  State<BalanceGraph> createState() => _BalanceGraphState();
}

class _BalanceGraphState extends State<BalanceGraph> {
  DatabaseConnection databaseConnection = DatabaseConnection();
  User? user = FirebaseAuth.instance.currentUser;
  
  double ingresos = 0;
  double gastos = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBalanceData();
  }

  Future<void> fetchBalanceData() async {
    try {
      var db = await databaseConnection.openDb();
      double totalIncome = 0;
      double totalExpense = 0;

      // Consultamos las transacciones del usuario
      var result = await db.query(
        'transactions', 
        where: 'userId = ?', 
        whereArgs: [user!.uid]
      );

      for (var transaction in result) {
        // Limpiamos el formato por si vienen con comas de miles
        String amountStr = transaction['amount'].toString().replaceAll(',', '');
        double amount = double.tryParse(amountStr) ?? 0;

        if (transaction['type'] == 'income') {
          totalIncome += amount;
        } else if (transaction['type'] == 'expense') {
          totalExpense += amount;
        }
      }

      setState(() {
        ingresos = totalIncome;
        gastos = totalExpense;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error cargando datos de gráfica: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    // Lógica de escalas
    double maxVal = ingresos > gastos ? ingresos : gastos;
    // Si ambos son 0, ponemos un techo por defecto para que no explote
    double topLimit = maxVal == 0 ? 1000 : maxVal * 1.2;

    return AspectRatio(
      aspectRatio: 1.7,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: topLimit,
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: topLimit / 5,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.1),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 0:
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: const Text('Gastos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      );
                    case 1:
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: const Text('Ingresos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      );
                    default:
                      return const SizedBox();
                  }
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                interval: topLimit / 5,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const Text('0', style: TextStyle(fontSize: 10));
                  
                  String text;
                  if (value.abs() >= 1000000) {
                    text = '${(value / 1000000).toStringAsFixed(1)}M';
                  } else if (value.abs() >= 1000) {
                    text = '${(value / 1000).toStringAsFixed(0)}k';
                  } else {
                    text = value.toInt().toString();
                  }

                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Text(
                      text,
                      style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            // Columna de Gastos
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: gastos,
                  color: Colors.redAccent,
                  width: 22,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
            // Columna de Ingresos
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: ingresos,
                  color: Colors.green,
                  width: 22,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
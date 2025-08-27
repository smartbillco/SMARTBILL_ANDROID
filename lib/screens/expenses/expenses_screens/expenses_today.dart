import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartbill/screens/expenses/add_expenses_widgets/add_expense_form.dart';
import 'package:smartbill/screens/expenses/add_income_widgets/add_income_form.dart';
import 'package:smartbill/screens/expenses/balance_container.dart';
import 'package:smartbill/screens/expenses/divider.dart';
import 'package:smartbill/services/db.dart';

class ExpensesToday extends StatefulWidget {
  const ExpensesToday({super.key});

  @override
  State<ExpensesToday> createState() => _ExpensesTodayState();
}

class _ExpensesTodayState extends State<ExpensesToday> {
  DatabaseConnection databaseConnection = DatabaseConnection();
  User? user = FirebaseAuth.instance.currentUser;
  double total = 0;
  List transactions = [];

  void _redirectToAddIncomeForm() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AddIncomeForm()));  
  }

  void _redirectToAddExpensesForm() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AddExpensesForm()));  
  }

  @override
  void initState() {
    super.initState();
    getAllTransactions();
  }

  Future<void> getAllTransactions() async {
    var db = await databaseConnection.openDb();
    double totalSum = 0;
    double totalSubs = 0;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    var result = await db.query(
      'transactions',
      where: 'userId = ? AND date >= ? AND date < ?',
      whereArgs: [
        user!.uid,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
      orderBy: 'date DESC',
    );

    for (var transaction in result) {
      String transactionAmount = transaction['amount'].toString().replaceAll(',', '');
      if (transaction['type'] == 'income') {
        totalSum += double.parse(transactionAmount);
      } else if (transaction['type'] == 'expense') {
        totalSubs += double.parse(transactionAmount);
      }
    }

    setState(() {
      transactions = result;
      total = totalSum - totalSubs;
    });
  }
  
  //Delete transaction
  Future<void> deleteRegister(int id) async {
    var db = await databaseConnection.openDb();
    await db.delete(
      'transactions', // table name
      where: '_id = ?',
      whereArgs: [id],
    );
  }


  //Show delete dialog
  void _showDeleteDialog(BuildContext context, int id, VoidCallback onDeleted) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar transacción'),
        content: const Text('Está seguro de que desea eliminar esta transacción?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close dialog
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await deleteRegister(id);
              Navigator.pop(context); // Close dialog
              onDeleted(); // Optional callback to refresh list
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            BalanceContainer(balance: NumberFormat("#,##0.00").format(total).toString()),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.green)),
                  onPressed: _redirectToAddIncomeForm,
                  label: const Text('Ingreso', style: TextStyle(color: Colors.white),),
                  icon: const Icon(Icons.add_rounded, color: Colors.white)
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.redAccent)),
                  onPressed: _redirectToAddExpensesForm,
                  label: const Text('Gastos', style: TextStyle(color: Colors.white)),
                  icon: const Icon(Icons.remove, color: Colors.white)
                ),
              ]
            ),
            const SizedBox(height: 20),
            const TimeDivider(title: 'Hoy'),
            const SizedBox(height: 20),
            transactions.isEmpty
            ? const Text("Todavía no tiene transacciones hoy", style: TextStyle(color: Colors.black54, fontSize: 18),)
            : Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder:(context, index) {
                  return Card(
                    elevation: 4,
                    child: ListTile(
                      onLongPress: () {
                        _showDeleteDialog(context, transactions[index]['_id'], () {
                        // You could refresh state here using setState in a StatefulWidget
                        getAllTransactions();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Eliminado: ${transactions[index]['description']}')));
                        });
                      },
                      leading: const Icon(Icons.attach_money, color: Colors.green, size:25),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      title: Text(transactions[index]['description'].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(transactions[index]['category'], style: const TextStyle(fontSize: 14)),
                          Text(DateFormat('dd/MM/yyyy').format(DateTime.parse(transactions[index]['date'])), style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                      trailing: Text(NumberFormat("#,##0.00").format(transactions[index]['amount']), style: 
                      transactions[index]['type'] == 'income' 
                      ? const TextStyle(fontSize: 15, color: Colors.green, fontWeight: FontWeight.bold)
                      : const TextStyle(fontSize: 15, color: Colors.red, fontWeight: FontWeight.bold)
                      )
                    ),
                  );
                },
              ),
            ),
          ],
        )
    );
  }
}
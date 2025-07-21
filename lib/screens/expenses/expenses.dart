import 'package:flutter/material.dart';
import 'package:smartbill/screens/expenses/expenses_screens/expenses_all.dart';
import 'package:smartbill/screens/expenses/expenses_screens/expenses_today.dart';
import 'package:smartbill/screens/expenses/expenses_screens/expenses_week.dart';
import 'package:smartbill/screens/expenses/voice_recorder/voice_recorder.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});
  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  int _currentIndex = 0;
  List<Widget> _bottomItemsList = [
    ExpensesToday(),
    ExpensesWeek(),
    ExpensesAll(),
  ];

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agregar ingreso"),
      ),
      body: _bottomItemsList[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Hoy'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_view_week),
            label: '7 dias'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month ),
            label: 'Todos'
          )
        ]
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const VoiceRecorderScreen()));
        },
        child: const Icon(Icons.mic),
      ),
    );
  }
}
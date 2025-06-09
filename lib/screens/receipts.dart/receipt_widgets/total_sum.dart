import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TotalSumWidget extends StatefulWidget {
  final double totalColombia;
  final double totalPeru;
  final double totalPanama;

  const TotalSumWidget({super.key, required this.totalColombia, required this.totalPeru, required this.totalPanama});

  @override
  State<TotalSumWidget> createState() => _TotalSumWidgetState();
}

class _TotalSumWidgetState extends State<TotalSumWidget> {
  String? indicator = FirebaseAuth.instance.currentUser!.phoneNumber!.substring(0, 3);


  @override
  Widget build(BuildContext context) {
    return Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
              height: 110,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: const LinearGradient(colors: [Color.fromARGB(255, 68, 95, 109), Colors.black87])
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Tu total hasta hoy", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w200)),
                  const SizedBox(height: 8),
                  
                  indicator == '+57'
                  ? _buildConditionalText(widget.totalColombia)
                  : indicator == '+51'
                  ? _buildConditionalText(widget.totalPeru)
                  : _buildConditionalText(widget.totalPanama)
                    
                ],
                )
              );
  }
}

Widget _buildConditionalText(double text) {
  final currencyFormatter = NumberFormat('#,##0.00', 'en_US');
  
  return Text(currencyFormatter.format(text), style: const TextStyle(color: Colors.white,fontSize: 34, fontWeight: FontWeight.w600),);
   // or return Container() to show nothing
}
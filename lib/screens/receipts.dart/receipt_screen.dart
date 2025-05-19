import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartbill/screens/PDFList/pdf_list.dart';
import 'package:smartbill/screens/receipts.dart/my_receipts.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  bool isColombian = false;
  String? phoneNumber = FirebaseAuth.instance.currentUser!.phoneNumber;

  final List<Widget> pages = [
    const MyReceiptsPage(),
    const PDFListScreen()
  ];


  void switchPage(int index) {
    setState(() => _currentPage = index);
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void checkIfUserIsFromColombia() {
    setState(() {
      isColombian = phoneNumber!.startsWith('+57');
    });
  }


  @override
  void initState() {
    super.initState();
    checkIfUserIsFromColombia();
    _pageController = PageController(initialPage: _currentPage);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis recibos"),
      ),
      body: isColombian
      ? Column(
        children: [
          // Row with buttons
          Row(
            spacing: 10,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.receipt_long, size: 27, color: Colors.blueGrey),
                onPressed: () => switchPage(0),
                label: const Text("Mis facturas", style: TextStyle(fontSize: 16)),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf, size: 27, color: Colors.redAccent,),
                onPressed: () => switchPage(1),
                label: const Text("Facturas DIAN", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),

          // PageView gets full height below the buttons
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: pages,
            ),
          ),
        ],
      )
      : const MyReceiptsPage()
    );
  }
}


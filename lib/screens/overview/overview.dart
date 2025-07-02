import 'package:flutter/material.dart';
import 'package:smartbill/screens/dashboard/dashboard.dart';
import 'package:smartbill/screens/reports/reports.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  void changePage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    setState(() {
      _currentPage = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(); 
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _pageController.dispose();
    super.dispose();
    
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const DashboardScreen(),
        const ReportsScreen()
      ],
    );
  }
}
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
  List<Widget> pages = [
    const DashboardScreen(),
    const ReportsScreen()
  ];
  int _currentPage = 0;

  void changePage(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        changePage(index);
      },
      children: pages,
    );
  }
}
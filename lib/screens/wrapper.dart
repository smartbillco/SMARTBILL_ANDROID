import 'package:flutter/material.dart';
import 'package:smartbill/screens/home/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartbill/screens/overview/overview.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {

  User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {

    return user != null ? const OverviewScreen() : const HomeScreen();
    
  }
}
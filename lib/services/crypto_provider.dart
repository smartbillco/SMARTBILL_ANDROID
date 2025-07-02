
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CryptoProvider with ChangeNotifier {

  List<dynamic> _cryptoData = [];
  List<dynamic> get cryptoData => _cryptoData;
  bool _isLoading = true;
  bool get isLoading => _isLoading;


  Future<void> fetchCryptoData() async {
    try {
      final response = await http.get(Uri.parse('https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=10&page=1&sparkline=false'));

      if(response.statusCode == 200) {
        _cryptoData = jsonDecode(response.body);
      } else {
        print("Fetch wasn't succesfull");
      }
    } catch(e) {
      print("Error getting crypto $e");
    }
    _isLoading = false;
    notifyListeners();

  }

}
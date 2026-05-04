import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartbill/services/db.dart';
import '../../models/cryptos.dart';

class CryptoProvider extends ChangeNotifier {
  List<Crypto> _cryptos = [];
  Set<String> _favoriteIds = {};
  bool _isLoading = false;
  
  List<Crypto> get cryptos => _cryptos;
  Set<String> get favoriteIds => _favoriteIds;
  bool get isLoading => _isLoading;

  final DatabaseConnection _dbConnection = DatabaseConnection();

  // Load everything once
  Future<void> initializeData() async {
    _isLoading = true;
    notifyListeners();

    await fetchCryptos();
    await fetchAllFavorites();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchCryptos() async {
    try {
      final url = Uri.parse(
          'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=10&page=1&sparkline=false');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _cryptos = data.map((json) => Crypto.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching cryptos: $e");
    }
  }

  Future<void> fetchAllFavorites() async {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    try {
      final db = await _dbConnection.db;
      final result = await db.query('favorites', where: 'userId = ?', whereArgs: [userId]);
      _favoriteIds = result.map((item) => item['cryptoId'].toString()).toSet();
    } catch (e) {
      debugPrint("Error fetching favorites: $e");
    }
  }

  Future<void> toggleFavorite(String cryptoId) async {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    final db = await _dbConnection.openDb();

    if (_favoriteIds.contains(cryptoId)) {
      _favoriteIds.remove(cryptoId);
      await db.delete('favorites', where: 'cryptoId = ? AND userId = ?', whereArgs: [cryptoId, userId]);
    } else {
      _favoriteIds.add(cryptoId);
      await db.insert('favorites', {'userId': userId, 'cryptoId': cryptoId});
    }
    notifyListeners();
  }
}
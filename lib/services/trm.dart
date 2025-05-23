import 'dart:convert';

import 'package:http/http.dart' as http;


class Trm {

  String uri;

  Trm(this.uri);

  Future<Map<String, dynamic>> getExchangeCurrency() async {
    final url = Uri.parse(uri);

    try {
      final response = await http.get(url);

      if(response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return jsonDecode("There was an error");
      }

    } catch(e) {
      return jsonDecode("There was an error: $e");
    }
  }
}
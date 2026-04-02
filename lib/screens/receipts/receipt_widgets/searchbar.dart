import 'package:flutter/material.dart';

class SearchbarWidget extends StatefulWidget {
  const SearchbarWidget({super.key});

  @override
  State<SearchbarWidget> createState() => _SearchbarWidgetState();
}

class _SearchbarWidgetState extends State<SearchbarWidget> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width - 30,
      child: TextField(
        decoration: InputDecoration(
          suffixIcon: const Icon(Icons.search),
          contentPadding: const EdgeInsets.only(left: 20),
          border: OutlineInputBorder(
            borderSide: const BorderSide(width: 5),
            borderRadius: BorderRadius.circular(30),
            gapPadding: 5.0
          ),
          label: const Text("Buscar...")
        ),
      ));
  }
}
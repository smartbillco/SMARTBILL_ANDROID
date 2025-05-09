import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartbill/models/ocr_receipts.dart';
import 'package:smartbill/screens/receipts.dart/receipt_screen.dart';

class DisplayImageScreen extends StatefulWidget {
  final File? image;
  final String? recognizedText;

  const DisplayImageScreen({super.key, required this.image, required this.recognizedText});

  @override
  State<DisplayImageScreen> createState() => _DisplayImageScreenState();
}


class _DisplayImageScreenState extends State<DisplayImageScreen> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  List<String> ocrLines = [];
  String nit = '';
  String date = '';
  String customer = '';
  String company = '';
  double total = 0;
  bool _isLoading = false;

  @override
  void initState() {
  
    super.initState();
    _extractData();
  }

  String normalizeMoney(String raw) {
    String cleaned = raw.replaceAll(RegExp(r'\s+'), '');

    // If it has both . and , we determine the decimal separator
    if (cleaned.contains('.') && cleaned.contains(',')) {
      if (cleaned.lastIndexOf('.') > cleaned.lastIndexOf(',')) {
        // Likely US style: 1,000.50
        cleaned = cleaned.replaceAll(',', '');
      } else {
        // Likely EU style: 1.000,50
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      }
    } else if (cleaned.contains(',')) {
      // If only ',' is present, assume it’s decimal if it ends with ,xx
      if (RegExp(r',\d{2}$').hasMatch(cleaned)) {
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // Just thousands separator
        cleaned = cleaned.replaceAll(',', '');
      }
    } else {
      // Only dots
      if (RegExp(r'\.\d{2}$').hasMatch(cleaned)) {
        // Decimal
        cleaned = cleaned.replaceAll(',', '');
      } else {
        // Thousand separator
        cleaned = cleaned.replaceAll('.', '');
      }
    }

    return cleaned;
  }


  void _extractData() {
    List<String> extractedLines = widget.recognizedText!.split('\n');

    RegExp dateRegex = RegExp(r'\b(\d{2}[/-]\d{2}[/-]\d{2,4}|\d{4}[/-]\d{2}[/-]\d{2})\b');
    RegExp nitRegex = RegExp(r'NIT[:\s.\-]*?([\d.]+-\d+|\d+)', caseSensitive: false);
    RegExp ccRegex = RegExp(r'C\.?C\.?[:\s.\-]*?(\d[\d.]*)', caseSensitive: false);
    //In case nit is not explicit
    RegExp unlabeledNitRegex = RegExp(r'\b\d{9}(-\d)?\b');
    RegExp moneyRegex = RegExp(r'^\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?$');

    List<String> dates = [];
    List<String> nitValues = [];
    List<String> ccValues = [];
    List<double> moneyValues = [];
    String companyName = '';

    for (var item in extractedLines) {

      // Check for dates
      for (final match in dateRegex.allMatches(item)) {
        dates.add(match.group(0)!);
      }

      // Extract NIT
      final nitMatch = nitRegex.firstMatch(item);
      if (nitMatch != null) {
        String rawNit = nitMatch.group(1)!;
        String cleanedNit = rawNit.replaceAll('.', '');
        nitValues.add(cleanedNit);
      }

      // Extract unlabeled NITs (if not already captured)
      final unlabeledMatches = unlabeledNitRegex.allMatches(item);
      for (final match in unlabeledMatches) {
        String candidate = match.group(0)!;
        if (!nitValues.contains(candidate)) {
          nitValues.add(candidate);
        }
      }

      // Extract CC
      final ccMatch = ccRegex.firstMatch(item);
      if (ccMatch != null) {
        String rawCc = ccMatch.group(1)!;
        String cleanedCc = rawCc.replaceAll('.', '');
        ccValues.add(cleanedCc);
      }


      // Check for money values
      for (final match in moneyRegex.allMatches(item)) {
        String matchText = match.group(0)!;
        String normalized = normalizeMoney(matchText);
        double? value = double.tryParse(normalized);

        if (value != null && value < 10000000) {
          moneyValues.add(value);
        }
      }
    }

    //Pick first line as company name
    if(extractedLines[0] != '') {
      companyName = extractedLines[0];
    } else {
      companyName = extractedLines[1];
    }
    

    double totalAmount = moneyValues.isNotEmpty ? moneyValues.reduce((a, b) => a > b ? a : b) : 0;

    print('Dates: $dates');
    print('NIT Value: $nitValues');
    print('CC Value: $ccValues');
    print('Amount: $totalAmount');
    print("Company name: $companyName");

    if(dates.isEmpty || nitValues.isEmpty) {
      print("Faltante");
      setState(() {
        ocrLines = ["Parece que la información no se pudo extraer bien. Intenta con una foto foto de mejor resolución."];

      });
    } else {
        setState(() {
        date = dates.isEmpty ? 'No encontrado' : dates.last;
        nit = nitValues.first;
        customer = ccValues.isEmpty ? '22222222222' : ccValues.first;
        total = totalAmount;
        company = companyName;
        ocrLines = extractedLines;
        
      });

    }
    
  }

  Future<void> _saveNewOcrReceipt() async {

    setState(() {
      _isLoading = true;
    });

    final Uint8List convertedImage = await widget.image!.readAsBytes();
    print(convertedImage);
    final OcrReceipts ocrReceipts = OcrReceipts(userId: userId, image: convertedImage, extractedText: widget.recognizedText!, date: date, company: company, nit: nit, userDocument: customer, amount: total);
   
    try {
      String result = await ocrReceipts.saveOcrReceipt();
      if(result.startsWith("Hubo un error")) {
        print(result);
      } else {
        print("Success! $result");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Factura descargada")));
        Future.delayed(Duration(seconds: 3), () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ReceiptScreen())));
        
      }
      
    } catch(e) {
      print("Error saving ocr: $e");
    }finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Imagen"),
      ),
      body: _isLoading
      ? const CircularProgressIndicator()
      : SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: ocrLines.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              TextButton(onPressed: _saveNewOcrReceipt,
                style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.green)),
                child: const Text("Guardar factura", style: TextStyle(color: Colors.white),),
                ),
              const SizedBox(height: 20),
              widget.image != null ? Image.file(widget.image!, width: 320,) : const Center(child: Text("La imagen no se pudo cargar")),
              const SizedBox(height: 20),
              for (var line in ocrLines) Text(line),
            ],
        ),
      ),
    );
  }
}
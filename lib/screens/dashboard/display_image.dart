import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
  TextEditingController _textController = TextEditingController();
  

  List<String> ocrLines = [];
  String nit = '';
  String date = '';
  String customer = '';
  String company = '';
  double total = 0;
  bool isTotalCorrect = true;

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

   WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        List<String> extractedLines = widget.recognizedText!.split('\n');

        RegExp dateRegex = RegExp(r'\b(\d{2}[/-]\d{2}[/-]\d{2,4}|\d{4}[/-]\d{2}[/-]\d{2})\b');
        RegExp nitRegex = RegExp(r'NIT[:\s.\-]*?([\d.]+-\d+|\d+)', caseSensitive: false);
        RegExp ccRegex = RegExp(r'C\.?C\.?[:\s.\-]*?(\d[\d.]*)', caseSensitive: false);
        RegExp unlabeledNitRegex = RegExp(r'\b\d{9}(-\d)?\b');
        RegExp moneyRegex = RegExp(r'\b\d{1,3}(?:[\s.,]\s?\d{3})+(?:[\s.,]\s?\d{2})?\b(?!\s*-\d)');

        List<String> dates = [];
        List<String> nitValues = [];
        List<String> ccValues = [];
        List<double> moneyValues = [];
        String companyName = '';

        for (var item in extractedLines) {
          for (final match in dateRegex.allMatches(item)) {
            dates.add(match.group(0)!);
          }

          if (item.toLowerCase().startsWith('nit')) {
            nitValues.add(item.substring(4).trim());
          }

          final nitMatch = nitRegex.firstMatch(item);
          if (nitMatch != null) {
            String rawNit = nitMatch.group(1)!;
            String cleanedNit = rawNit.replaceAll('.', '');
            nitValues.add(cleanedNit);
          }

          final unlabeledMatches = unlabeledNitRegex.allMatches(item);
          for (final match in unlabeledMatches) {
            String candidate = match.group(0)!;
            if (!nitValues.contains(candidate)) {
              nitValues.add(candidate);
            }
          }

          final ccMatch = ccRegex.firstMatch(item);
          if (ccMatch != null) {
            String rawCc = ccMatch.group(1)!;
            String cleanedCc = rawCc.replaceAll('.', '');
            ccValues.add(cleanedCc);
          }

          for (final match in moneyRegex.allMatches(item)) {
            String matchText = match.group(0)!;
            String normalized = normalizeMoney(matchText);
            double? value = double.tryParse(normalized);

            if (value != null && value < 800000) {
              moneyValues.add(value);
            }
          }
        }

        if (extractedLines[0] != '') {
          companyName = extractedLines[0];
        } else {
          companyName = extractedLines[1];
        }

        double totalAmount = moneyValues.isNotEmpty
            ? moneyValues.reduce((a, b) => a > b ? a : b)
            : 0;

        setState(() {
          date = dates.isEmpty ? 'No encontrado' : dates.last;
          nit = nitValues.firstOrNull ?? '';
          customer = ccValues.isEmpty ? '22222222222' : ccValues.first;
          total = totalAmount;
          company = companyName;
  

          if (nit.isEmpty || nit.length < 8 || total < 1000) {
            // Safe to show UI feedback now
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Parece que el contenido está incompleto o no es una factura válida.')),
              );
              Navigator.pop(context);
            }
             
          } else {
            ocrLines = extractedLines;
          }
        });

      } catch (e) {
        // Safe to show UI feedback now
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Parece que el contenido está incompleto o no es una factura válida.')),
          );
          Navigator.pop(context);
        }
      }
    });
  }

  Future<void> _saveNewOcrReceipt() async {

    final Uint8List convertedImage = await widget.image!.readAsBytes();
    print(convertedImage);
   
    try {
      final OcrReceipts ocrReceipts = OcrReceipts(userId: userId, image: convertedImage, extractedText: widget.recognizedText!, date: date, company: company, nit: nit, userDocument: customer, amount: total);
      String result = await ocrReceipts.saveOcrReceipt();
      if(result.startsWith("Hubo un error")) {
        print(result);
      } else {
        print("Success! $result");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Factura descargada")));
        Future.delayed(const Duration(seconds: 3), () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ReceiptScreen())));
        
      }
      
    } catch(e) {
      print("Error saving ocr: $e");

    } 
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Imagen"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          spacing: 8,
            children: [
              const SizedBox(height: 10),
              widget.image != null ? Image.file(widget.image!, width: 320,) : const Center(child: Text("La imagen no se pudo cargar")),
              const SizedBox(height: 10),
              receiptRow("Empresa", company),
              receiptRow("Id de Empresa", nit),
              receiptRow("Fecha", date),

              //Change total if incorrect
              isTotalCorrect
              ? receiptRow("Total", total)
              : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total: "),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _textController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          total = double.parse(value);
                        });
                      },
                    ),
                  )
                ],
              ),

              //If extraction was not success
              ocrLines.isEmpty
              ? const Text("El texto no pudo ser extraido")
              : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 12,
                children: [
                  TextButton(onPressed: _saveNewOcrReceipt,
                    style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.green)),
                    child: const Text("Guardar factura", style: TextStyle(color: Colors.white),),
                  ),
                  TextButton(onPressed: () {
                    setState(() {
                      isTotalCorrect = !isTotalCorrect;
                    });
                  }, child: isTotalCorrect ? Text("Cambiar Total") : Text("Establecer") )
                ],
              )
            ],
        ),
      ),
    );
  }
}

Row receiptRow(String type, dynamic value) {

  final currencyFormatter = NumberFormat('#,##0.00', 'en_US');

  if(value is double) {
    value = currencyFormatter.format(value);
  }

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text("$type: ", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      Text(value.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400))
    ],
  );
}
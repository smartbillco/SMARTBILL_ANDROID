import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:read_pdf_text/read_pdf_text.dart';
import 'package:smartbill/screens/PDFList/filter/filter.dart';
import 'package:smartbill/services/pdf_reader.dart';

class PDFListScreen extends StatefulWidget {
  const PDFListScreen({super.key});

  @override
  State<PDFListScreen> createState() => _PDFListScreenState();
}

class _PDFListScreenState extends State<PDFListScreen> {
  final PdfService pdfService = PdfService();

  final currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');
  List<File> pdfFiles = [];
  Map<String, ImageProvider> pdfThumbnails = {};
  List<Map<String, dynamic>> extractedText = [];
  num totalBills = 0;
  num totalAmount = 0;
  num total = 0;


  @override
  void initState() {
    super.initState();
    loadPdfs();
    
  }

  //Extract values from pdfText
  dynamic extractValuesFromPdf(String value, List<String>pdfLines) {

    for (String text in pdfLines) {    
      if(text.toLowerCase().contains(value.toLowerCase())) {
        return text;
      }
    }
    return "NIT de la empresa";
  }

  //Extract values from pdfText
  dynamic extractBillNumber(List<String>pdfLines) {

    String value = "Número de Factura";
    for (String text in pdfLines) { 
      if(text.toLowerCase().contains(value.toLowerCase())) {
        String substring = text.substring(21,32);
        return substring;
      } else if(text.toLowerCase().contains('NIT'.toLowerCase())) {
        String substring = text;
        return substring;
      }
    }

  }

  //Extract values from pdfText
  dynamic extractCompany(List<String>pdfLines) {
    String value = "Razón Social";
    for (String text in pdfLines) {
      if(text.toLowerCase().contains(value.toLowerCase())) {
        if(text.length > 40) {
          String subtring = text.substring(16, 40) + '...';
          return subtring;
        }
          String subtring = text.substring(14,);
          return subtring;
      }
      
    }
  }

  String? extractDate(List<String> textList) {
  // Regex pattern for various date formats
  RegExp datePattern = RegExp(
      r'\b(?:\d{4}[-./]\d{2}[-./]\d{2}|\d{2}/\d{2}/\d{4}|\d{2}-\d{2}-\d{4})\b');

  for (String text in textList) {
    RegExpMatch? match = datePattern.firstMatch(text);
    if (match != null) {
      return match.group(0); // Return the first found date
    }
  }
  
  return null; // Return null if no date is found
}

String? extractTotalPrice(List<String> textList) {
  // Regex pattern to find "COP $" followed by any text
  RegExp pattern = RegExp(r'(?<=COP \$)\s*\S+');
  final regex = RegExp(r'TOTAL A PAGAR\s*\$?\s*([\d.,]+)', caseSensitive: false);
  

  for (String text in textList) {
    RegExpMatch? match = pattern.firstMatch(text);
    final matchTotal = regex.firstMatch(text);

    if (match != null) {
      return match.group(0); // Return the first matched text
    } else if (matchTotal != null) {
    
      String value = matchTotal.group(1) ?? "";

      return value;
    }
      
    
  }
  
  return "0"; // Return null if no match is found
}



 Future<void> loadPdfs() async {
    Directory? appDir = Platform.isAndroid ?  await getExternalStorageDirectory() : await getApplicationDocumentsDirectory();

    if (appDir == null) {
      print("Error: External storage directory is null.");
      return;
    }

    Directory invoicesDir = Directory("${appDir.path}/invoices");

    if (await invoicesDir.exists()) {
      List<FileSystemEntity> files = invoicesDir.listSync();
      List<File> pdfs = files
          .where((file) => file.path.endsWith('.pdf'))
          .map((e) => File(e.path))
          .toList();

      setState(() {
        pdfFiles = pdfs;
        totalBills = pdfs.length;
        extractedText = List.generate(pdfs.length, (index) => {}); // Initialize list to avoid null issues
      });

      for (int i = 0; i < pdfFiles.length; i++) {
        var pdf = pdfFiles[i];
        if (await pdf.exists()) {
          try {
            await generateThumbnail(pdf);

            Map<String, dynamic> resultPdf = await extractTextFromPdf(pdf);

            setState(() {
              extractedText[i] = resultPdf; // Update each extracted text entry safely
            });

          } catch (e) {
            print("Error processing PDF ${pdf.path}: $e");
          }
        } else {
          print("Error: PDF file does not exist: ${pdf.path}");
        }
      }

    } else {
      print("Error: Invoices directory does not exist: ${invoicesDir.path}");
    }
  }

  void redirectFilter() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const FilterScreen()));
  }

  /// Generate PDF thumbnail (first page)
  Future<void> generateThumbnail(File pdf) async {
    final document = await PdfDocument.openFile(pdf.path);
    final page = await document.getPage(1);
    final image = await page.render(
      width: 100, // Adjust width as needed
      height: 150, // Adjust height as needed
      format: PdfPageImageFormat.png,
    );
    await page.close();

    if (image != null) {
      setState(() {
        pdfThumbnails[pdf.path] = MemoryImage(image.bytes);
      });
    }
  }

  /// Extract text using read_pdf_text package
  Future<dynamic> extractTextFromPdf(File pdf) async {
    String? pdfContent = await ReadPdfText.getPDFtext(pdf.path);
    List<String> lines = pdfContent.split('\n');
    Map<String, dynamic> parsedPdf = {};
    String? total = extractTotalPrice(lines);
  
    String billNumber = extractBillNumber(lines);
    String company = extractCompany(lines);
    String? date = extractDate(lines);
    String? formatTotal = total!.replaceAll('.', '').replaceAll(',', '.');

    parsedPdf = pdfService.parseDIANpdf(billNumber, company, date!, formatTotal);

    setState(() {
      totalAmount += double.parse(formatTotal);
    });

    return parsedPdf;
  }

  void openPdf(String path) async {
    await OpenFilex.open(path);
  }
  
  

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [const Icon(Icons.attach_money, color: Colors.green, size: 30), Text("Total: ${NumberFormat('#,##0', 'en_US').format(totalAmount)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600))]),
                  Row(children: [const Icon(Icons.receipt, color: Colors.green, size: 30), Text("Facturas: $totalBills", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600))])
                ]
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 130,
                child: ElevatedButton(
                  style: const ButtonStyle(
                    side: WidgetStatePropertyAll(BorderSide(color: Colors.grey))
                  ),
                  onPressed: redirectFilter,
                  child: const Text("Filtrar")
                ),
              ),
            ),
            const SizedBox(height: 15),
            pdfFiles.isEmpty
          ? const Center(child: Text("Todavía no tienes PDFs."))
          : Expanded(
            child: ListView.builder(
              itemCount: pdfFiles.length,
              itemBuilder: (context, index) {
                final file = pdfFiles[index];

                // Ensure extractedText[index] exists before accessing keys
                final data = (index < extractedText.length) ? extractedText[index] : {};

                double totalAmount = double.tryParse(data['total']?.toString() ?? '0') ?? 0;

                total = totalAmount;

                return Card(
                  child: ListTile(
                    onLongPress: () async {
                      final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Eliminar PDF?'),
                        content: const Text('Está seguro que quiere eliminar el archivo?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.red))),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.green))),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      final filePath = pdfFiles[index].path;
                      final fileToDelete = File(filePath);

                      if (await fileToDelete.exists()) {
                        await fileToDelete.delete();
                      }

                      setState(() {
                        pdfFiles.removeAt(index);
                        if (index < extractedText.length) {
                          extractedText.removeAt(index);
                        }
                      });
                    }
                      
                    },
                    leading: pdfThumbnails[file.path] != null
                        ? Image(image: pdfThumbnails[file.path]!)
                        : const CircularProgressIndicator(),
                    title: Text(data['bill_number'] ?? "Extracting text..."),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['company'] ?? ''),
                        Text(data['date'] ?? ''),
                        Text(currencyFormatter.format(total), style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    onTap: () => openPdf(file.path),
                  ),
                );
              },
            )
          ),
          ]
        ),
      );

  }
  
}
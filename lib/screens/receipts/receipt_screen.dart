import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:read_pdf_text/read_pdf_text.dart';
import 'package:smartbill/screens/PDFList/pdf_list.dart';
import 'package:smartbill/screens/receipts/my_receipts.dart';
import 'package:smartbill/services/pdf_reader.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  bool isColombian = false;
  String? phoneNumber = FirebaseAuth.instance.currentUser?.phoneNumber;
  final PdfService pdfService = PdfService();

  // PDF logic State
  List<File> pdfFiles = [];
  Map<String, ImageProvider> pdfThumbnails = {};
  List<Map<String, dynamic>> extractedText = [];
  num totalAmount = 0;
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
    checkIfUserIsFromColombia();
    loadPdfs();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ------- PDF Processing Logic --------- //

  String? extractTotalPrice(List<String> textList) {
    RegExp pattern = RegExp(r'(?<=COP \$)\s*\S+');
    final regex =
        RegExp(r'TOTAL A PAGAR\s*\$?\s*([\d.,]+)', caseSensitive: false);

    for (String text in textList) {
      RegExpMatch? match = pattern.firstMatch(text);
      final matchTotal = regex.firstMatch(text);

      if (match != null) return match.group(0);
      if (matchTotal != null) return matchTotal.group(1) ?? "0";
    }
    return "0";
  }

  String? extractDate(List<String> textList) {
    RegExp datePattern = RegExp(
        r'\b(?:\d{4}[-./]\d{2}[-./]\d{2}|\d{2}/\d{2}/\d{4}|\d{2}-\d{2}-\d{4})\b');
    for (String text in textList) {
      RegExpMatch? match = datePattern.firstMatch(text);
      if (match != null) return match.group(0);
    }
    return null;
  }

  dynamic extractBillNumber(List<String> pdfLines) {
    for (String text in pdfLines) {
      if (text.toLowerCase().contains("número de factura")) {
        return text.length > 32 ? text.substring(21, 32) : text;
      } else if (text.toLowerCase().contains('nit')) {
        return text;
      }
    }
    return "No encontrado";
  }

  dynamic extractCompany(List<String> pdfLines) {
    for (String text in pdfLines) {
      if (text.toLowerCase().contains("razón social")) {
        return text.length > 40
            ? "${text.substring(14, 40)}..."
            : text.substring(14);
      }
    }
    return "Empresa desconocida";
  }

  Future<void> generateThumbnail(File pdf) async {
    try {
      final document = await PdfDocument.openFile(pdf.path);
      final page = await document.getPage(1);
      final image = await page.render(width: 100, height: 150);
      await page.close();
      await document.close();

      if (image != null) {
        setState(() {
          pdfThumbnails[pdf.path] = MemoryImage(image.bytes);
        });
      }
    } catch (e) {
      debugPrint("Error thumbnail: $e");
    }
  }

  Future<Map<String, dynamic>> extractTextFromPdf(File pdf) async {
    String? pdfContent = await ReadPdfText.getPDFtext(pdf.path);
    List<String> lines = pdfContent.split('\n');

    String? total = extractTotalPrice(lines);
    String billNumber = extractBillNumber(lines);
    String company = extractCompany(lines);
    String? date = extractDate(lines) ?? "S/F";

    String formatTotal = total!.replaceAll('.', '').replaceAll(',', '.');

    setState(() {
      totalAmount += double.tryParse(formatTotal) ?? 0;
    });

    return pdfService.parseDIANpdf(billNumber, company, date, formatTotal);
  }

  Future<void> loadPdfs() async {
    if (isLoaded) return;

    Directory? appDir = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();

    if (appDir == null) return;
    Directory invoicesDir = Directory("${appDir.path}/invoices");

    if (await invoicesDir.exists()) {
      List<FileSystemEntity> files = invoicesDir.listSync();
      List<File> pdfs = files
          .where((file) => file.path.endsWith('.pdf'))
          .map((e) => File(e.path))
          .toList();

      Map<String, ImageProvider> tempThumbnails = {};
      List<Map<String, dynamic>> tempExtractedText = [];
      num tempTotalAmount = 0;

      for (var pdf in pdfs) {
        try {
          // Miniatura
          final document = await PdfDocument.openFile(pdf.path);
          final page = await document.getPage(1);
          final image = await page.render(width: 100, height: 150);
          if (image != null) {
            tempThumbnails[pdf.path] = MemoryImage(image.bytes);
          }
          await page.close();
          await document.close();

          // Texto y Datos
          String? pdfContent = await ReadPdfText.getPDFtext(pdf.path);
          List<String> lines = pdfContent.split('\n');

          String? total = extractTotalPrice(lines);
          String billNumber = extractBillNumber(lines);
          String company = extractCompany(lines);
          String date = extractDate(lines) ?? "S/F";

          String formatTotal = total!.replaceAll('.', '').replaceAll(',', '.');
          tempTotalAmount += double.tryParse(formatTotal) ?? 0;

          tempExtractedText.add(
              pdfService.parseDIANpdf(billNumber, company, date, formatTotal));
        } catch (e) {
          debugPrint("Error procesando individual: $e");
        }
      }

      setState(() {
        pdfFiles = pdfs;
        pdfThumbnails = tempThumbnails;
        extractedText = tempExtractedText;
        totalAmount = tempTotalAmount;
        isLoaded = true;
      });
    }
  }

  Future<void> refreshPdfs() async {
    // 1. IMPORTANTE: Cambiamos isLoaded a false para permitir la recarga
    setState(() {
      isLoaded = false; 
    });

    // 2. Llamamos a la lógica de carga (ahora sí pasará el check inicial)
    await loadPdfs();
  }

  // ------- UI Logic --------- //

  void switchPage(int index) {
    setState(() => _currentPage = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void checkIfUserIsFromColombia() {
    setState(() {
      isColombian = phoneNumber?.startsWith('+57') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // IMPORTANTE: Definimos las páginas aquí para pasarle el estado actual
    final List<Widget> pages = [
      const MyReceiptsPage(),
      PDFListScreen(
        onRefresh: () async {
          await refreshPdfs();
        },
        pdfFiles: pdfFiles,
        pdfThumbnails: pdfThumbnails,
        extractedText: extractedText,
        totalAmount: totalAmount,
        onDelete: (index) {
          setState(() {
            // Lógica para restar del totalAmount antes de eliminar
            String val = extractedText[index]['total']?.toString() ?? "0";
            totalAmount -= double.tryParse(val) ?? 0;

            pdfFiles.removeAt(index);
            extractedText.removeAt(index);
          });
        },
      )
    ];

    return Scaffold(
        appBar: AppBar(
          title: const Text("MIS RECIBOS",
              style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: isColombian
            ? Column(
                children: [
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTabButton("Mis Facturas", Icons.receipt_long, 0),
                      const SizedBox(width: 10),
                      _buildTabButton("Facturas PDF", Icons.picture_as_pdf, 1),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) =>
                          setState(() => _currentPage = index),
                      children: pages,
                    ),
                  ),
                ],
              )
            : const MyReceiptsPage());
  }

  Widget _buildTabButton(String label, IconData icon, int index) {
    bool isSelected = _currentPage == index;
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.black : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black,
        elevation: 0,
        side: const BorderSide(color: Colors.black, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      icon: Icon(icon, size: 18),
      onPressed: () => switchPage(index),
      label: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
    );
  }
}

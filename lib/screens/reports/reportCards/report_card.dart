import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:read_pdf_text/read_pdf_text.dart';
import 'package:smartbill/services/ocr_receipts.dart';
import 'package:smartbill/services/pdf_reader.dart';
import 'package:smartbill/services/xml/xml.dart';
import 'package:smartbill/services/xml/xml_colombia.dart';
import 'package:smartbill/services/xml/xml_panama.dart';
import 'package:smartbill/services/xml/xml_peru.dart';
import 'package:xml/xml.dart';

class ReportCard extends StatefulWidget {
  const ReportCard({super.key});

  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
  final currencyFormatter = NumberFormat('#,##0.00', 'en_US');
  OcrReceiptsService ocrService = OcrReceiptsService();
  Xmlhandler xmlhandler = Xmlhandler();
  final XmlColombia xmlColombia = XmlColombia();
  final XmlPeru xmlPeru = XmlPeru();
  final XmlPanama xmlPanama = XmlPanama();
  PdfService pdfService = PdfService();
  String indicator = FirebaseAuth.instance.currentUser!.phoneNumber!.substring(0,3);

  int xml = 0;
  int pdf = 0;
  int ocr = 0;
  int dian = 0;
  int billAmount = 0;

  double totalDian = 0;
  double totalImages = 0;
  double totalPdf = 0;
  double totalXml = 0;
  

  Future<void> getAllBillAmounts() async {
    int xmlAmount = await getNumberOfBills(xmlhandler.getXmls);
    int pdfAmount = await getNumberOfBills(pdfService.fetchAllPdfs);
    int ocrAmount = await getNumberOfBills(ocrService.fetchOcrReceipts);
    int dianAmount = await getDIANPdfNumber();
    double totalDianAmount = await extractTotalDIAN();
    double totalImagesAmount = await extractTotalImages();
    double totalPdfAmount = await extractTotalPdf();
    double totalXmlAmount = await extractTotalXml();

    setState(() {
      xml = xmlAmount;
      pdf = pdfAmount;
      ocr = ocrAmount;
      dian = dianAmount;
      totalDian = totalDianAmount;
      totalImages = totalImagesAmount;
      totalPdf = totalPdfAmount;
      totalXml = totalXmlAmount;
    });
  }


  //check if it's colombia
  bool isColombia() {
    return indicator == '+57';
  }


  //Get bills amount
  Future<int> getNumberOfBills(Function bringBill) async {
    var bills = await bringBill();
    return bills.length;
  
  }

  //Number of DIAN pdfs
  Future<int> getDIANPdfNumber() async {
    Directory? appDir = Platform.isAndroid ?  await getExternalStorageDirectory() : await getApplicationDocumentsDirectory();

    if(appDir == null) {
      return 0;
    }

    Directory invoicesDir = Directory("${appDir.path}/invoices");

     if (await invoicesDir.exists()) {
      List<FileSystemEntity> files = invoicesDir.listSync();
      return files.length;
     } else {
      return 0;
     }

  }

  //Get total from dian pdfs
  Future<double> extractTotalDIAN() async {

    Directory? appDir = Platform.isAndroid ?  await getExternalStorageDirectory() : await getApplicationDocumentsDirectory();
    RegExp pattern = RegExp(r'(?<=COP \$)\s*\S+');
    double totalSum = 0;


    if(appDir == null) {
      return 0;
    }

    Directory invoicesDir = Directory("${appDir.path}/invoices");

     if (await invoicesDir.exists()) {
      List<FileSystemEntity> files = invoicesDir.listSync();
      List<File> pdfs = files
          .where((file) => file.path.endsWith('.pdf'))
          .map((e) => File(e.path))
          .toList();

      

      for(var file in pdfs) {
        String? pdfContent = await ReadPdfText.getPDFtext(file.path);
        List textList = pdfContent.split('\n');
        for (String text in textList) {
          String formatted = text.replaceAll('.', '').replaceAll(',', '.');
          RegExpMatch? match = pattern.firstMatch(formatted);
          if (match != null) {
            double num = double.parse(match.group(0)!);
            totalSum += num;// Return the first matched text
          } 
        }

      }
      return totalSum;
      
     } else {
      return 0;
     }
  }

  //Get total from images
  Future<double> extractTotalImages() async {
    var ocrReceipts = await ocrService.fetchOcrReceipts();
    double totalSum = 0;
    for(var item in ocrReceipts) {
      totalSum += double.parse(item['price']);
      
    }
    print(totalSum);
    return totalSum;

  }


  //Total price PDFs
  Future<double> extractTotalPdf() async {
    var pdfFiles = await pdfService.fetchAllPdfs();
    double totalSum = 0;

    for(var pdf in pdfFiles) {
      totalSum += pdf['total_amount'];
    }

    return totalSum;
  }


  // Get total from xml
  Future<double> extractTotalXml() async {
    var xmlFiles = await xmlhandler.getXmls();
    
    double totalSum = 0;

    if(indicator == '+57') {

      for(var file in xmlFiles) {
        XmlDocument xmlDocument = XmlDocument.parse(file['xml_text']);

        Map parsedDoc = xmlhandler.xmlToMap(xmlDocument.rootElement);

        //Colombian logic
        final String cDataContent = xmlColombia.extractCData(xmlDocument);

        final XmlDocument xmlCData = xmlColombia.parseCDataToXml(cDataContent);

        final Map newColombianXml = xmlColombia.parseColombianXml(file['_id'], parsedDoc, xmlCData);

        totalSum += double.parse(newColombianXml['price']);

      }

      return totalSum;

    } else if(indicator == '+51') {
      for(var file in xmlFiles) {
        XmlDocument xmlDocument = XmlDocument.parse(file['xml_text']);

        Map parsedDoc = xmlhandler.xmlToMap(xmlDocument.rootElement);
        //Peru logic
        final Map newPeruvianXml = xmlPeru.parsePeruvianXml(file['_id'], parsedDoc, xmlDocument);

        totalSum += double.parse(newPeruvianXml['price']);

      } 

      return totalSum;
        
    } else {
      for(var file in xmlFiles) {
        XmlDocument xmlDocument = XmlDocument.parse(file['xml_text']);

        final Map newPanamanianXml = xmlPanama.parsedPanamaXml(file['_id'], xmlDocument);

        totalSum += double.parse(newPanamanianXml['price']);
      }
      return totalSum;

    }

  }

  @override
  void initState() {  
    super.initState();
    getAllBillAmounts();
    extractTotalImages();
    extractTotalXml();
    
  }


  @override
  Widget build(BuildContext context) {
    return isColombia()
    ?
    Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _StatCard(label: 'XML', total: totalXml, value: xml.toString()),
            _StatCard(label: 'PDF', total: totalPdf, value: pdf.toString()),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _StatCard(label: 'Imagen', total: totalImages, value: ocr.toString()),
            _StatCard(label: 'DIAN', total: totalDian, value: dian.toString()),
          ],
        ),
      ],
    )
    : Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _StatCard(label: 'XML', total: totalXml, value: xml.toString()),
            _StatCard(label: 'PDF', total: totalPdf, value: pdf.toString()),
            
          ],
        ),
        Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Text(ocr.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(currencyFormatter.format(totalImages), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    Text('Imagenes', style: const TextStyle(fontSize: 14, color: Colors.black38)),
                  ],
                ),
              ),
            )
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double total;
  final String value;

  const _StatCard({
    required this.label,
    required this.total,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {

    final currencyFormatter = NumberFormat('#,##0.00', 'en_US');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.41,
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(currencyFormatter.format(total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text(label, style: const TextStyle(fontSize: 14, color: Colors.black38)),
          ],
        ),
      ),
    );
  }
}
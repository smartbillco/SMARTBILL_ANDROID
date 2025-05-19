import 'package:flutter/material.dart';
import 'package:smartbill/services/ocr_receipts.dart';
import 'package:smartbill/services/pdf_reader.dart';
import 'package:smartbill/services/xml/xml.dart';

class ReportCard extends StatefulWidget {
  const ReportCard({super.key});

  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
  OcrReceiptsService ocrService = OcrReceiptsService();
  Xmlhandler xmlhandler = Xmlhandler();
  PdfService pdfService = PdfService();

  int xml = 0;
  int pdf = 0;
  int ocr = 0;
  int billAmount = 0;

  Future<void> getAllBillAmounts() async {
    int xmlAmount = await getNumberOfBills(xmlhandler.getXmls, 'xml');
    int pdfAmount = await getNumberOfBills(pdfService.fetchAllPdfs, 'pdf');
    int ocrAmount = await getNumberOfBills(ocrService.fetchOcrReceipts, 'ocr');

    setState(() {
      xml = xmlAmount;
      pdf = pdfAmount;
      ocr = ocrAmount;
    });
  }

  //Get bills amount
  Future<int> getNumberOfBills(Function bringBill, String type) async {
    var bills = await bringBill();
    return bills.length;
  
  }

  @override
  void initState() {  
    super.initState();
    getAllBillAmounts();
    
  }



  @override
  Widget build(BuildContext context) {
    return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatCard(label: 'XML', value: xml.toString()),
                _StatCard(label: 'PDF', value: pdf.toString()),
                _StatCard(label: 'Imagen', value: ocr.toString()),
              ],
            );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.26,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 14, color: Colors.black38)),
          ],
        ),
      ),
    );
  }
}
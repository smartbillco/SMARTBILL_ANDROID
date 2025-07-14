import 'package:flutter/material.dart';
import 'package:smartbill/services/colombian_bill.dart';
import 'package:smartbill/services/ocr_receipts.dart';
import 'package:smartbill/services/pdf.dart';
import 'package:smartbill/services/pdf_reader.dart';
import 'package:smartbill/services/peruvian_bill.dart';
import 'package:smartbill/services/xml/xml.dart';


//Creating the delete confirm dialog
class DeleteDialogWidget extends StatefulWidget {
  final dynamic item;
  final Function func;
  const DeleteDialogWidget({super.key, required this.item, required this.func});

  @override
  State<DeleteDialogWidget> createState() => _DeleteDialogWidgetState();
}

class _DeleteDialogWidgetState extends State<DeleteDialogWidget> {
  final OcrReceiptsService ocrService = OcrReceiptsService();
  Xmlhandler xmlhandler = Xmlhandler();
  PdfHandler pdfHandler = PdfHandler();
  PdfService pdfService = PdfService();
  ColombianBill colombiaBill = ColombianBill();
  PeruvianBill peruvianBill = PeruvianBill();

  Future deleteFile(item) async {
    try {
      if(item['currency'] == 'PDF') {
        print("Deleted");
        await pdfService.deletePdf(item['_id'], item['cufe']);

      } else if (item['type'] == 'bill_co') {
        await colombiaBill.deleteBill(item['_id']);

      } else if (item['type'] == 'bill_pen') {
        await peruvianBill.deleteBill(item['_id']);

      } else if(item['currency'] == 'OCR') {
        await ocrService.deleteOcrReceipt(item['_id']);
      }
      else {
        await xmlhandler.deleteXml(item['_id']);

      }

    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Eliminar factura"),
      content: const Text("¿Está seguro que desea eliminar la factura?"),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              "No",
              style: TextStyle(color: Colors.redAccent, fontSize: 17),
            )),
        TextButton(
            onPressed: () async {
              await deleteFile(widget.item);
              Navigator.pop(context);
              widget.func();
              
            },
            child: const Text("Si",
                style: TextStyle(color: Colors.green, fontSize: 17)))
      ],
    );
  }
}
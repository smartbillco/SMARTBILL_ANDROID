import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartbill/screens/receipts.dart/receipt_screen.dart';
import 'package:smartbill/screens/receipts.dart/receipt_widgets/delete_dialog.dart';
import 'package:smartbill/services/ocr_receipts.dart';

class BillDetailScreen extends StatefulWidget {
  final Map receipt;
  const BillDetailScreen({super.key, required this.receipt});

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  OcrReceiptsService ocrService = OcrReceiptsService();
  List textPdf = [];
  Uint8List? imageRendered;

  @override
  void initState() {
    super.initState();
    if(widget.receipt['currency'] == 'OCR') getImageForReceipt();
    
  }

  void returnToReceipts() {
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ReceiptScreen()),
    );
  }

  Future<void> getImageForReceipt() async {

    Uint8List image = await ocrService.fetchImage(widget.receipt['_id']);
    print(image);
    setState(() {
      imageRendered = image;
    });

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalles de la factura"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: widget.receipt.containsKey('text') ?
        Container(
          child: Column(
            children: [
              const SizedBox(height:30),
              const Icon(Icons.check, size: 60, color: Colors.green,),
              const SizedBox(height:50),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: textPdf.map((item) {
                  List<String> parts = item.split(':'); // Split key and value
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space left & right
                    children: [
                      SizedBox(width: MediaQuery.of(context).size.width * 0.35,
                      child: parts[0].length > 15 ? Text(parts[0].substring(0,15)) : Text(parts[0],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), 
                      const SizedBox(height: 30),// Key (Left)
                      SizedBox(width: MediaQuery.of(context).size.width * 0.5, child: Text(parts[1], style: const TextStyle(fontSize: 14))), // Value (Right)
                ],
                            );
                          }).toList(),
                ),
              ),
              Center(
                    child: ElevatedButton(
                      style: const ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(Colors.redAccent)
                      ),
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (_) => DeleteDialogWidget(
                              item: widget.receipt,
                              func: returnToReceipts));
                      },
                      child: const Text("Eliminar", style: TextStyle(color: Colors.white),)),
                  )
            ]
             
          ),
        ) :
        Container(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:BorderRadius.all(Radius.circular(15))
          ),
          child: Column(
            children: [
              imageRendered != null
              ? Image.memory(imageRendered!, width: 200,)
              : SizedBox.shrink(),
              const Icon(Icons.check, size: 60, color: Colors.green,),
              const SizedBox(height: 20,),
              Text("Factura: ${widget.receipt['id_bill']}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
              Text("ID Empresa: ${widget.receipt['company_id']}", style: const TextStyle(fontSize: 17)),
              const SizedBox(height: 20,),
              const Divider(
                  color: Colors.grey, // Line color
                  thickness: 1, // Line thickness
                  indent: 20, // Left padding
                  endIndent: 20, // Right padding
                ),
              const SizedBox(height: 20,),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReceiptRows(type: "Cliente", value: widget.receipt['customer'].toUpperCase()),
                  ReceiptRows(type: "Identificación", value: widget.receipt['customer_id'].toUpperCase()),
                  ReceiptRows(type: "Compañia", value: widget.receipt['company_id']),
                  ReceiptRows(type: "Fecha", value: widget.receipt['date']),
                  widget.receipt['iva'] != null
                  ? ReceiptRows(type: "IVA", value:  NumberFormat('#,##0', 'en_US').format(double.parse(widget.receipt['iva'])).toString())
                  : SizedBox.shrink(),
                  ReceiptRows(type: "Precio", value: NumberFormat('#,##0', 'en_US').format(double.parse(widget.receipt['price'])).toString()),
                  ReceiptRows(type: "Código", value: widget.receipt['cufe']),
                  const SizedBox(height: 15,),
                  Center(
                    child: ElevatedButton(
                      style: const ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(Colors.redAccent)
                      ),
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (_) => DeleteDialogWidget(
                              item: widget.receipt,
                              func: returnToReceipts));
                      },
                      child: const Text("Eliminar", style: TextStyle(color: Colors.white),)),
                  )
                ],
              )
            ],
          ),
        ),
      )
    );
  }
}


class ReceiptRows extends StatelessWidget {
  final String type;
  final dynamic value;
  const ReceiptRows({super.key, required this.type, required this.value});

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(width: 5),
            Flexible(child: Text(value ?? "No encontrado", softWrap: true, )),
          ],
        ),
        const SizedBox(height: 7)
      ]
       
    );
  }
}
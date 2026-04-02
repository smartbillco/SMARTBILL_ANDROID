import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:smartbill/models/dian_receipts.dart';
import 'package:smartbill/screens/receipts/receipt_screen.dart';
import 'package:smartbill/services/dianReceiptService.dart';


class ReceiptDisplayScreen extends StatefulWidget {
  final String? uri; 
  const ReceiptDisplayScreen({super.key, required this.uri});

  @override
  State<ReceiptDisplayScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptDisplayScreen> {
  late String? cufe;
  final DianReceiptService dianReceiptService = DianReceiptService();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    cufe = extractCufe(widget.uri!);
    print("Cufe: $cufe");
  }

  bool _isValidCufe(String cufe) {
    return RegExp(r'^[a-fA-F0-9]{64,}$').hasMatch(cufe);
  }

  String? extractCufe(String input) {
    // 1. Try URL parsing first (fast & reliable)
    try {
      final uri = Uri.parse(input);
      final cufeFromUrl = uri.queryParameters['documentkey'];
      if (cufeFromUrl != null && _isValidCufe(cufeFromUrl)) {
        print("Cufe: $cufeFromUrl");
        return cufeFromUrl;
      }
    } catch (_) {
      // Not a URL → continue
    }

    // 2. Normalize text (remove spaces, line breaks, etc.)
    String cleaned = input
        .replaceAll(RegExp(r'\s+'), '')
        .toLowerCase();

    // 3. Fix common OCR mistakes (optional but VERY useful)
    cleaned = cleaned
        .replaceAll('o', '0')
        .replaceAll('l', '1')
        .replaceAll('i', '1');

    // 4. Extract any 64-length hex string
    final regex = RegExp(r'[a-f0-9]{64},');
    final match = regex.firstMatch(cleaned);
    print("Cufe: ${match?.group(0)}");
    return match?.group(0);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Factura"),
      ),
      body: FutureBuilder(
        future: dianReceiptService.getReceiptByCufe(cufe!),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if(snapshot.connectionState == ConnectionState.waiting) {

            return const Center(child: CircularProgressIndicator());

          } else if(snapshot.hasError) {

            print(snapshot.error);
            return const Center(child: Text("Hubo un error cargando la factura"));

          } else if(snapshot.hasData) {

            Receipt data = snapshot.data;
            return SingleReceipt(cufe: data.uuid, companyName: data.emisor.nombre, nit: data.emisor.numeroDoc, buyer: data.receptor.nombre, buyerId: data.receptor.numeroDoc, eventos: data.eventos, date: data.fechaEmision, total: data.totales);

          } else {
            return const Text("No data found");
          }
        }
      )
    );
  }
}




//Receipt container

class SingleReceipt extends StatefulWidget {
  final String companyName;
  final String nit;
  final String buyer;
  final String buyerId;
  final List<dynamic> eventos;
  final String date;
  final String cufe;
  final Totales total;

  const SingleReceipt({
    super.key,
    required this.companyName,
    required this.nit,
    required this.buyer,
    required this.buyerId,
    required this.eventos,
    required this.date,
    required this.cufe,
    required this.total,
  });

  @override
  State<SingleReceipt> createState() => _SingleReceiptState();
}

class _SingleReceiptState extends State<SingleReceipt> {

  final DianReceiptService dianReceiptService = DianReceiptService();
  bool isLoading = false;


  Future<void> downloadPdfFile(String cufe) async {

    setState(() {
      isLoading = true;
    });

    try {

      final pdfData = await dianReceiptService.getPdfDian(cufe);

      await dianReceiptService.base64ToPdfAndSave(pdfData.pdf);

      print("Finished: ${pdfData.pdf}");

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ReceiptScreen()));

    } catch(e) {

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));

    } finally {

      setState(() {
        isLoading = false;
      });

    }

  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 35, 20, 0),
      child: isLoading
      ?  Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            Lottie.asset('assets/download icon.json', backgroundLoading: false,),
            const SizedBox(height: 40),
            const Text("Estamos descargando tu factura. Esto podría tardar un poco.", textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),)
          ]
        )
      : Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow:  [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 4), // X, Y
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          
              /// 🏪 HEADER
              Text(
                widget.companyName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
          
              Text(
                "NIT: ${widget.nit}",
                style: TextStyle(color: Colors.grey[900]),
              ),
          
              const SizedBox(height: 8),
          
              const Divider(height: 30),
          
              /// 📄 INFO
              sectionTitle("Información"),
              receiptRow("Comprador", widget.buyer),
              receiptRow("Documento", widget.buyerId),
              receiptRow("Fecha", widget.date),
              receiptRow("CUFE", widget.cufe),

              const SizedBox(height: 8),
          
              const Divider(height: 30),
          
              /// 💰 TOTALES
              sectionTitle("Totales"),
              receiptRow("Total", "\$${widget.total.total}"),
              receiptRow("IVA", widget.total.iva?.toString() ?? "N/A"),

              const SizedBox(height: 8),
          
              const SizedBox(height: 30),
          
              /// 🎯 ACTIONS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Cancelar"),
                  ),
                  ElevatedButton(
                    onPressed: () => downloadPdfFile(widget.cufe),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text("Descargar"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


Widget sectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}


Widget receiptRow(String title, String description) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            description,
            softWrap: true,
          ),
        ),
      ],
    ),
  );
}
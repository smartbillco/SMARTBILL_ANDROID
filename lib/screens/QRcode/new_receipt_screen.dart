import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:smartbill/models/dian_receipts.dart';
import 'package:smartbill/screens/receipts/receipt_screen.dart';
import 'package:smartbill/services/colombian_bill.dart';
import 'package:smartbill/services/dian_receipt_service.dart';

class ReceiptDisplayScreen extends StatefulWidget {
  final String cufe;
  const ReceiptDisplayScreen({super.key, required this.cufe});

  @override
  State<ReceiptDisplayScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptDisplayScreen> {
  final DianReceiptService dianReceiptService = DianReceiptService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Un gris muy claro para resaltar la tarjeta
      appBar: AppBar(
        title: const Text("Detalle de Factura"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder(
        future: dianReceiptService.getReceiptByCufe(widget.cufe),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text("Buscando en la DIAN...", style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
            
          } else if (snapshot.hasError) {
            return _buildErrorState();

          } else if (snapshot.hasData) {
            Receipt data = snapshot.data;
            return SingleReceipt(
              cufe: data.uuid,
              companyName: data.emisor.nombre,
              nit: data.emisor.numeroDoc,
              buyer: data.receptor.nombre,
              buyerId: data.receptor.numeroDoc,
              eventos: data.eventos,
              date: data.fechaEmision,
              total: data.totales,
            );
          } else {
            return const Center(child: Text("No se encontró información"));
          }
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
          const SizedBox(height: 20),
          const Text(
            "¡Ups! Algo salió mal",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "No pudimos cargar la factura. Verifica tu conexión o el CUFE e intenta de nuevo.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

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
  ColombianBill colombianBill = ColombianBill();
  bool isLoading = false;

  Future<void> downloadPdfFile(String cufe) async {

    setState(() => isLoading = true);

    try {
      final pdfData = await dianReceiptService.getPdfDian(cufe);
      await dianReceiptService.base64ToPdfAndSave(pdfData.pdf, cufe);

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ReceiptScreen()));

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));

    } finally {

      if (mounted) setState(() => isLoading = false);

    }
  }

  //Persist receipt data into database
  Future<void> saveReceiptToDatabase() async {

    setState(() => isLoading = true);

    final newReceipt = {
      'bill_number': widget.cufe,
      'company_name': widget.companyName,
      'date': widget.date,
      'nit': widget.nit,
      'customer_id': widget.buyerId,
      'iva': widget.total.iva,
      'total_amount': widget.total.total,
      'cufe': widget.cufe
    };

    try {

      await colombianBill.saveColombianBill(newReceipt);

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ReceiptScreen()));

    } catch(e) {

      print("Error: $e");

      if(mounted) {

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Parece que no se pudo guardar la factura")));
      
      }

    } finally {

      if (mounted) setState(() => isLoading = false);

    }

  }


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/download icon.json', width: 320),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "Descargando factura. Esto puede tardar unos segundos...",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
              ],
            ),
            child: Column(
              children: [
                // Parte superior (Emisor)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.03),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.storefront, color: Colors.deepPurple, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        widget.companyName.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1),
                      ),
                      const SizedBox(height: 4),
                      Text("NIT: ${widget.nit}", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(Icons.info_outline, "Información"),
                      _receiptRow("Comprador", widget.buyer),
                      _receiptRow("Documento", widget.buyerId),
                      _receiptRow("Fecha", widget.date),
                      const SizedBox(height: 10),
                      
                      const Text("CUFE:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                        child: Text(widget.cufe, style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                      ),

                      const Divider(height: 40, thickness: 1.2),

                      _sectionHeader(Icons.payments_outlined, "Totales"),
                      _receiptRow("Subtotal", "\$${widget.total.total}"), // Asumiendo que tienes subtotal, sino borrar
                      _receiptRow("IVA", "\$${widget.total.iva ?? "0"}"),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("TOTAL", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text(
                            "\$${widget.total.total}",
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Cancelar", style: TextStyle(color: Colors.black)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => saveReceiptToDatabase(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Guardar Factura", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.deepPurple),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
        ],
      ),
    );
  }

  Widget _receiptRow(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              description,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
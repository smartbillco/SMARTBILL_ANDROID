import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:smartbill/screens/receipts/receipt_screen.dart';
import 'package:smartbill/screens/receipts/receipt_widgets/delete_dialog.dart';
import 'package:smartbill/services/ocr_receipts.dart';
import 'package:smartbill/services/dianReceiptService.dart';

class BillDetailScreen extends StatefulWidget {
  final Map receipt;
  const BillDetailScreen({super.key, required this.receipt});

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  final OcrReceiptsService ocrService = OcrReceiptsService();
  final DianReceiptService dianReceiptService = DianReceiptService();
  
  File? imageRendered;
  bool isLoading = false;
  final currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    if (widget.receipt['currency'] == 'OCR' || widget.receipt.containsKey('image')) {
      getImageForReceipt();
    }
  }

  void returnToReceipts() {
    if (mounted) {
      Navigator.pop(context); 
      Navigator.pop(context); 
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ReceiptScreen()),
      );
    }
  }

  Future<void> getImageForReceipt() async {
    try {
      String? imagePath;
      if (widget.receipt.containsKey('_id')) {
        imagePath = await ocrService.fetchImage(widget.receipt['_id']);
      }
      if (imagePath != null && imagePath.isNotEmpty) {
        setState(() => imageRendered = File(imagePath!));
      }
    } catch (e) {
      debugPrint("Error imagen: $e");
    }
  }

  Future<void> downloadPdfFile(String? cufe) async {
    if (cufe == null || cufe.isEmpty || cufe == "No encontrado") {
      _showSnackBar("CUFE no válido para descarga.", Colors.black87);
      return;
    }

    setState(() => isLoading = true);
    try {
      final pdfData = await dianReceiptService.getPdfDian(cufe);
      await dianReceiptService.base64ToPdfAndSave(pdfData.pdf);
      if (!mounted) return;
      _showSnackBar("¡Factura guardada correctamente!", Colors.black);
    } catch (e) {
      if (mounted) {
        _showSnackBar("Error en la descarga: $e", Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOcr = widget.receipt.containsKey('text');
    
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2), // Gris muy claro de fondo
      appBar: AppBar(
        title: const Text("Detalle de Factura", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (widget.receipt['cufe'] != null && widget.receipt['cufe'] != "No encontrado")
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.black), // Cambiado a Negro
              onPressed: isLoading ? null : () => downloadPdfFile(widget.receipt['cufe']),
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 16),
                isOcr ? _buildOcrDataCard() : _buildStandardDataCard(),
                const SizedBox(height: 24),
                _buildDeleteButton(),
              ],
            ),
          ),

          if (isLoading)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.white.withOpacity(0.98), 
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset('assets/download icon.json', width: 300),
                  const SizedBox(height: 20),
                  const Text(
                    "Procesando PDF...",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.business_rounded, color: Colors.black, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.receipt['company']?.toString().toUpperCase() ?? 'EMPRESA',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                    Text("NIT: ${widget.receipt['company_id'] ?? 'S/N'}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, thickness: 0.5),
          ),
          Text(
            currencyFormat.format(double.tryParse(widget.receipt['price'].toString()) ?? 0),
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: -1),
          ),
          const SizedBox(height: 4),
          Text(
            "Emitida el: ${widget.receipt['date']?.toString() ?? 'S/F'}",
            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardDataCard() {
    return _buildInfoCard(
      icon: Icons.info_outline_rounded,
      title: "Información General",
      content: Column(
        children: [
          if (imageRendered != null) _buildImagePreview(),
          _buildDataRow(Icons.person_outline, "Cliente", widget.receipt['customer']),
          _buildDataRow(Icons.numbers_outlined, "Factura N°", widget.receipt['id_bill']),
          if (widget.receipt['iva'] != null && widget.receipt['iva'] != "0")
             _buildDataRow(Icons.account_balance_wallet_outlined, "Impuestos (IVA)", currencyFormat.format(double.tryParse(widget.receipt['iva'].toString()) ?? 0)),
          _buildCufeSection(),
        ],
      ),
    );
  }

  Widget _buildOcrDataCard() {
    List<dynamic> textLines = widget.receipt['text'] as List? ?? [];
    return _buildInfoCard(
      icon: Icons.document_scanner_outlined,
      title: "Datos Escaneados",
      content: Column(
        children: textLines.map((item) {
          List<String> parts = item.toString().split(':');
          return _buildDataRow(Icons.arrow_right, parts[0].trim(), parts.length > 1 ? parts[1].trim() : "");
        }).toList(),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: InteractiveViewer(child: Image.file(imageRendered!, fit: BoxFit.contain)),
      ),
    );
  }

  Widget _buildDataRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value ?? "---", 
              textAlign: TextAlign.end, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCufeSection() {
    if (widget.receipt['cufe'] == null || widget.receipt['cufe'] == "No encontrado") return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("CUFE / CÓDIGO SEGURO", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(widget.receipt['cufe'], style: const TextStyle(fontSize: 10, color: Colors.black54, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required Widget content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 18, color: Colors.black87), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))]),
          const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider(height: 1, thickness: 0.5)),
          content,
        ],
      ),
    );
  }

  Widget _buildDeleteButton() {
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: Colors.redAccent,
        backgroundColor: const Color(0xFFFFEBEE),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {
        showDialog(context: context, builder: (_) => DeleteDialogWidget(item: widget.receipt, func: returnToReceipts));
      },
      icon: const Icon(Icons.delete_outline_rounded, size: 20),
      label: const Text("ELIMINAR FACTURA", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2)),
    );
  }
}
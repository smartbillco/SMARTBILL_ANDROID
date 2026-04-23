import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:smartbill/screens/PDFList/filter/filter.dart';

class PDFListScreen extends StatelessWidget {
  // Parámetros requeridos pasados por el padre (ReceiptScreen)
  final List<File> pdfFiles;
  final Map<String, ImageProvider> pdfThumbnails;
  final List<Map<String, dynamic>> extractedText;
  final num totalAmount;
  final Function(int) onDelete;

  const PDFListScreen({
    super.key,
    required this.pdfFiles,
    required this.pdfThumbnails,
    required this.extractedText,
    required this.totalAmount,
    required this.onDelete,
  });

  void openPdf(String path) async {
    await OpenFilex.open(path);
  }

  void redirectFilter(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FilterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          // Resumen de Totales
          Container(
            margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  Icons.attach_money, 
                  "Total: ${NumberFormat('#,##0', 'en_US').format(totalAmount)}"
                ),
                _buildSummaryItem(
                  Icons.receipt_outlined, 
                  "Facturas: ${pdfFiles.length}"
                ),
              ],
            ),
          ),

          // Botón Filtrar
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 130,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  side: const BorderSide(color: Colors.black, width: 1.2),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                onPressed: () => redirectFilter(context),
                child: const Text("FILTRAR", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
              ),
            ),
          ),
          
          const SizedBox(height: 15),

          // Lista de PDFs
          Expanded(
            child: pdfFiles.isEmpty
                ? const Center(
                    child: Text("NO TIENES PDFS", 
                    style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey)))
                : ListView.builder(
                    itemCount: pdfFiles.length,
                    itemBuilder: (context, index) {
                      final file = pdfFiles[index];
                      final data = (index < extractedText.length) ? extractedText[index] : {};
                      
                      // Obtener el total individual para este item
                      double itemTotal = double.tryParse(data['total']?.toString() ?? '0') ?? 0;

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: const RoundedRectangleBorder(
                          side: BorderSide(color: Colors.black12, width: 1),
                        ),
                        child: ListTile(
                          onTap: () => openPdf(file.path),
                          onLongPress: () => _showDeleteDialog(context, index),
                          leading: Container(
                            width: 45,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: pdfThumbnails[file.path] != null
                                ? Image(image: pdfThumbnails[file.path]!, fit: BoxFit.cover)
                                : const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)),
                          ),
                          title: Text(
                            data['bill_number'] ?? "Procesando...",
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['company'] ?? '', style: const TextStyle(fontSize: 11)),
                              Text(data['date'] ?? '', style: const TextStyle(fontSize: 11)),
                              Text(
                                currencyFormatter.format(itemTotal),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 12),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.black, size: 24),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text("ELIMINAR ARCHIVO", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        content: const Text("¿Deseas eliminar este PDF de tu dispositivo?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () async {
              final fileToDelete = pdfFiles[index];
              if (await fileToDelete.exists()) {
                await fileToDelete.delete();
              }
              onDelete(index); // Llama al callback del padre
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("ELIMINAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';
import 'package:workmanager/workmanager.dart';

class CufesDetailScreen extends StatefulWidget {
  final File imageFile;

  const CufesDetailScreen({super.key, required this.imageFile});

  @override
  State<CufesDetailScreen> createState() => _CufesDetailScreenState();
}

class _CufesDetailScreenState extends State<CufesDetailScreen> {
  // Variables de estado
  String _extractedText = "Procesando texto...";
  String _fileDate = "";
  String? _detectedCufe;
  bool _isDownloading = false; // Control del letrero persistente

  // El motor de reconocimiento de texto de Google ML Kit
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  @override
  void initState() {
    super.initState();
    _loadFileData();
    _processImageWithOCR();
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  // Extraer metadata del archivo
  void _loadFileData() {
    try {
      final DateTime date = widget.imageFile.lastModifiedSync();
      setState(() {
        _fileDate = DateFormat('dd/MM/yyyy - hh:mm a').format(date);
      });
    } catch (e) {
      setState(() {
        _fileDate = "Fecha no disponible";
      });
    }
  }

  // Lógica de procesamiento de imagen
  Future<void> _processImageWithOCR() async {
    try {
      final inputImage = InputImage.fromFile(widget.imageFile);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      if (mounted) {
        final String? cufe = _findCufe(recognizedText.text);

        setState(() {
          _extractedText = recognizedText.text;
          _detectedCufe = cufe ??
              "No se encontró la etiqueta CUFE/CUDE o el código es ilegible.";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _extractedText = "Error al procesar el OCR: $e";
        });
      }
    }
  }

  // Encontrar y extraer el CUFE
  String? _findCufe(String text) {
    String searchTitle = text.toUpperCase();
    int index = searchTitle.indexOf("CUFE");
    if (index == -1) index = searchTitle.indexOf("CUDE");

    if (index != -1) {
      String rawPart = text.substring(index + 4);
      String cleanStart = rawPart.replaceFirst(RegExp(r'^[\s\:\-]+'), '');
      String solidBlock = cleanStart.replaceAll(RegExp(r'\s+'), '');

      if (solidBlock.length >= 96) {
        return solidBlock.substring(0, 96);
      }
      return solidBlock.isNotEmpty ? solidBlock : null;
    }
    return null;
  }

  // Intentar descargar en background
  void _startBackgroundDownload() {
    if (_detectedCufe == null || _detectedCufe!.contains("No se encontró")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay un CUFE válido para procesar")),
      );
      return;
    }

    setState(() {
      _isDownloading = true; // Mostramos el letrero azul
    });

    Workmanager().registerOneOffTask(
      "downloadPdfTask_${DateTime.now().millisecondsSinceEpoch}",
      "downloadPdfTask",
      inputData: {
        'cufe': _detectedCufe,
      },
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  // Eliminar foto del CUFE
  Future<void> _deletePhoto() async {
    try {
      bool confirm = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("¿Eliminar factura?"),
              content: const Text("Esta acción borrará la foto de forma permanente."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("CANCELAR"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("ELIMINAR", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ) ??
          false;

      if (confirm) {
        if (await widget.imageFile.exists()) {
          await widget.imageFile.delete();
        }
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      debugPrint("Error al eliminar: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final double halfScreenHeight = MediaQuery.of(context).size.height / 2;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Detalle de Factura", style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _isDownloading ? null : _deletePhoto,
            tooltip: "Eliminar factura",
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Contenedor de la Imagen
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    height: halfScreenHeight,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Image.file(
                          widget.imageFile,
                          width: double.infinity,
                          height: halfScreenHeight,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 10),
                
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _isDownloading ? null : _startBackgroundDownload,
                    icon: const Icon(Icons.cloud_download),
                    label: const Text("Descargar PDF"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "CUFE / CUDE Detectado",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        _detectedCufe ?? "No detectado",
                        style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "Fecha de Captura",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                      Text(_fileDate, style: const TextStyle(fontSize: 15, color: Colors.black87)),
                      
                      const SizedBox(height: 24),
                      const Text(
                        "Texto Extraído (OCR)",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                      const Divider(height: 20),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: SelectableText(
                          _extractedText,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 100), // Espacio para que el letrero no tape el contenido final
                    ],
                  ),
                ),
              ],
            ),
          ),

          // LETRERO PERSISTENTE (Estilo Bill Details)
          if (_isDownloading)
            Positioned(
              bottom: 20,
              left: 15,
              right: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5), // Azul intenso
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Descarga iniciada. Te notificaremos cuando el PDF esté listo.",
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () => setState(() => _isDownloading = false),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
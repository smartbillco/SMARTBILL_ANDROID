import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'package:smartbill/screens/QRcode/new_receipt_screen.dart';
import 'package:smartbill/screens/QRcode/qrcode_screen.dart';
import 'package:smartbill/screens/QRcode/scanner/take_photo.dart';
import 'package:smartbill/services/cufe.dart';
import 'scanner_overlay.dart';

class QRScanner extends StatefulWidget {
  const QRScanner({super.key});

  @override
  State<QRScanner> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> {
  final MobileScannerController scannerController = MobileScannerController();
  final CufeService _cufeService = CufeService();

  Timer? _timeoutTimer;
  bool _scanning = true;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 7), () async {
      if (!_scanning) return;

      await scannerController.stop();
      if (!mounted) return;

      final shouldScan = await _showCufeDialog();

      if (shouldScan == true) {
        await _scanCufeFromPhoto();
      } else {
        _resetScanner();
      }
    });
  }

  void _resetScanner() {
    if (!mounted) return;
    setState(() => _scanning = true);
    scannerController.start();
    _startTimer();
  }

  Future<bool?> _showCufeDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("No se detectó QR"),
        content: const Text("¿Deseas intentar extraer el CUFE tomando una foto manual de la factura?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            }, 
            child: const Text("Cancelar", style: TextStyle(color: Colors.red))
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Reintentar QR"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Tomar Foto"),
          ),
        ],
      ),
    );
  }

  Future<String?> cropImage(String path) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Encuadra el CUFE',
          toolbarColor: Colors.deepPurple,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Encuadra el CUFE',
          aspectRatioLockEnabled: false,
        ),
      ],
    );
    return croppedFile?.path;
  }

  Future<void> _scanCufeFromPhoto() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TakePhotoScreen()),
      );

      if (result == null || result is! String) {
        _resetScanner();
        return;
      }

      final String? croppedPath = await cropImage(result);
      if (croppedPath == null) {
        _resetScanner();
        return;
      }

      final inputImage = InputImage.fromFilePath(croppedPath);
      final cufe = await _cufeService.processImage(inputImage);

      // El RegExp aquí valida si el CUFE tiene 64 o 96 caracteres hex
      if (cufe != null && RegExp(r'^[a-fA-F0-9]{64}$|^[a-fA-F0-9]{96}$').hasMatch(cufe)) {
        await _navigate(ReceiptDisplayScreen(cufe: cufe));
      } else {
        _showError("No se pudo leer un CUFE válido. Intenta de nuevo.");
      }
    } catch (e) {
      _showError("Error al procesar la imagen");
    }
  }

  Future<void> _navigate(Widget screen) async {
    _scanning = false;
    _timeoutTimer?.cancel();
    await scannerController.stop();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
    _resetScanner();
  }

  String? extractCufe(String input) {
    // Intento 1: Buscar en parámetros de URL
    try {
      final uri = Uri.parse(input);
      final cufe = uri.queryParameters['documentkey'] ?? uri.queryParameters['DocKey'];
      if (cufe != null) return cufe;
    } catch (_) {}

    // Intento 2: Buscar cadena de 64 o 96 caracteres hexadecimales
    final match = RegExp(r'[a-fA-F0-9]{96}|[a-fA-F0-9]{64}').firstMatch(input);
    return match?.group(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Escanear Factura"), 
        backgroundColor: Colors.transparent, 
        elevation: 0
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            controller: scannerController,
            onDetect: (capture) async {
              if (!_scanning) return;

              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;

              final raw = barcodes.first.rawValue;
              if (raw == null || raw.isEmpty) return;

              final cufe = extractCufe(raw);

              if (cufe != null) {
                await _navigate(ReceiptDisplayScreen(cufe: cufe));
              } else {
                // Si no es un CUFE pero el QR tiene datos, enviamos a pantalla de soporte
                await _navigate(QrcodeScreen(qrResult: raw));
              }
            },
          ),
          const ScannerOverlay(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _cufeService.dispose();
    scannerController.dispose();
    super.dispose();
  }
}
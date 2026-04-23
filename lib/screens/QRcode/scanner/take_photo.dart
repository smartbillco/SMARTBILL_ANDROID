import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:smartbill/screens/wrapper.dart';

class TakePhotoScreen extends StatefulWidget {
  const TakePhotoScreen({super.key});

  @override
  State<TakePhotoScreen> createState() => _TakePhotoScreenState();
}

class _TakePhotoScreenState extends State<TakePhotoScreen> {
  CameraController? _controller;
  bool _isReady = false;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();
    if (!mounted) return;

    setState(() => _isReady = true);
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isTakingPicture) return;

    setState(() => _isTakingPicture = true);

    try {
      // 1. Capturar la imagen
      final XFile picture = await _controller!.takePicture();

      // 2. Guardar permanentemente
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String savePath = path.join(appDir.path, 'fotos_facturas');
      await Directory(savePath).create(recursive: true);

      final String fileName = 'Factura_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String finalPath = path.join(savePath, fileName);

      await File(picture.path).copy(finalPath);

      // 3. Notificar al cliente y redirigir
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("¡Foto guardada con éxito!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // 4. Redirigir al Wrapper limpiando el stack de navegación
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Wrapper()),
        (route) => false,
      );

    } catch (e) {
      debugPrint("Error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.previewSize!.height,
                height: _controller!.value.previewSize!.width,
                child: CameraPreview(_controller!),
              ),
            ),
          ),
          // Indicador de guardado
          if (_isTakingPicture)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 15),
                    Text("Guardando factura...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _takePicture,
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, size: 35),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
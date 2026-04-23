import 'package:flutter/material.dart';
import 'qr_scanner_overlay_shape.dart';

class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: ShapeDecoration(
          shape: QrScannerOverlayShape(
            borderColor: Colors.blue,
            borderRadius: 10,
            borderLength: 25,
            borderWidth: 6,
            cutOutSize: 280,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt,
                  size: 90, color: Color.fromARGB(120, 255, 255, 255)),
              SizedBox(height: 40),
              Text(
                "Escanea tu factura",
                style: TextStyle(
                  color: Color.fromARGB(180, 255, 255, 255),
                  fontSize: 18,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
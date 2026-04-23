import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smartbill/screens/QRcode/new_receipt_screen.dart';
import 'package:smartbill/screens/QRcode/qrcode_screen.dart';

class QRScanner extends StatefulWidget {
  const QRScanner({super.key});

  @override
  State<QRScanner> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> {
  final MobileScannerController scannerController = MobileScannerController();
  Timer? _timeoutTimer;
  bool _scanning = true;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _showSnackbarError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Ocurrió un error: $error"),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSnackbarTimeout() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Su factura no pudo ser leída. Intenta con otra."),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _startTimer() {
    _timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (_scanning) {
        scannerController.stop();
        _scanning = false;
        _showSnackbarTimeout();
        Navigator.of(context).pop();
      }
    });
  }

  bool _isValidCufeFlexible(String cufe) {
    return RegExp(r'^[a-fA-F0-9]{64,}$').hasMatch(cufe);
  }

  String? extractCufe(String input) {
    // 1. Intentar desde URL
    try {
      final uri = Uri.parse(input);
      final cufeFromUrl = uri.queryParameters['documentkey'];
      if (cufeFromUrl != null && _isValidCufeFlexible(cufeFromUrl)) {
        return cufeFromUrl;
      }
    } catch (_) {}

    // 2. Buscar CUFE completo después de "CUFE:"
    final regexLabel = RegExp(r'CUFE:\s*([a-fA-F0-9]+)');
    final matchLabel = regexLabel.firstMatch(input);
    if (matchLabel != null) {
      return matchLabel.group(1);
    }

    // 3. Fallback: buscar bloque largo (mínimo 64)
    final regexGeneric = RegExp(r'[a-fA-F0-9]{64,}');
    final matchGeneric = regexGeneric.firstMatch(input);

    return matchGeneric?.group(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: scannerController,
            onDetect: (BarcodeCapture capture) async {
              final barcodes = capture.barcodes;

              if (barcodes.isEmpty) return;

              try {
                final barcode = barcodes.first;

                if (barcode.format != BarcodeFormat.qrCode) {
                  _showSnackbarError("El código no es un QR válido.");
                  Navigator.pop(context);
                  return;
                }

                final raw = barcode.rawValue;

                if (raw == null || raw.isEmpty) {
                  _showSnackbarError("No se pudo leer el QR.");
                  return;
                }

                _timeoutTimer?.cancel();
                _scanning = false;

                await scannerController.stop();
                await scannerController.dispose();

                // 🔥 EXTRAER CUFE
                final cufe = extractCufe(raw);

                if (cufe != null && _isValidCufeFlexible(cufe)) {
                  print("✅ CUFE detectado: $cufe");

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReceiptDisplayScreen(cufe: cufe),
                    ),
                  );
                } else {
                  // 🔁 FALLBACK
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QrcodeScreen(qrResult: raw),
                    ),
                  );
                }
              } catch (e) {
                print("Error: $e");
                _showSnackbarError("QR inválido o no compatible.");
              }
            },
            onDetectError: (error, stackTrace) {
              _showSnackbarError(error.toString());
            },
          ),

          /// Overlay UI
          Positioned.fill(
            child: Container(
              decoration: ShapeDecoration(
                shape: QrScannerOverlayShape(
                  borderColor: Colors.blue,
                  borderRadius: 10,
                  borderLength: 20,
                  borderWidth: 6,
                  cutOutSize: 280,
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
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
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    scannerController.dispose();
    super.dispose();
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromARGB(131, 0, 0, 0),
    this.borderRadius = 0,
    this.borderLength = 40,
    double? cutOutSize,
    double? cutOutWidth,
    double? cutOutHeight,
    this.cutOutBottomOffset = 0,
  })  : cutOutWidth = cutOutWidth ?? cutOutSize ?? 250,
        cutOutHeight = cutOutHeight ?? cutOutSize ?? 250 {
    assert(
      borderLength <=
          min(this.cutOutWidth, this.cutOutHeight) / 2 + borderWidth * 2,
      "Border can't be larger than ${min(this.cutOutWidth, this.cutOutHeight) / 2 + borderWidth * 2}",
    );
    assert(
        (cutOutWidth == null && cutOutHeight == null) ||
            (cutOutSize == null && cutOutWidth != null && cutOutHeight != null),
        'Use only cutOutWidth and cutOutHeight or only cutOutSize');
  }

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutWidth;
  final double cutOutHeight;
  final double cutOutBottomOffset;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(
        rect.right,
        rect.bottom,
      )
      ..lineTo(
        rect.left,
        rect.bottom,
      )
      ..lineTo(
        rect.left,
        rect.top,
      );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final mBorderLength =
        borderLength > min(cutOutHeight, cutOutHeight) / 2 + borderWidth * 2
            ? borderWidthSize / 2
            : borderLength;
    final mCutOutWidth =
        cutOutWidth < width ? cutOutWidth : width - borderOffset;
    final mCutOutHeight =
        cutOutHeight < height ? cutOutHeight : height - borderOffset;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - mCutOutWidth / 2 + borderOffset,
      -cutOutBottomOffset +
          rect.top +
          height / 2 -
          mCutOutHeight / 2 +
          borderOffset,
      mCutOutWidth - borderOffset * 2,
      mCutOutHeight - borderOffset * 2,
    );

    canvas
      ..saveLayer(
        rect,
        backgroundPaint,
      )
      ..drawRect(
        rect,
        backgroundPaint,
      )
      // Draw top right corner
      ..drawRRect(
        RRect.fromLTRBAndCorners(
          cutOutRect.right - mBorderLength,
          cutOutRect.top,
          cutOutRect.right,
          cutOutRect.top + mBorderLength,
          topRight: Radius.circular(borderRadius),
        ),
        borderPaint,
      )
      // Draw top left corner
      ..drawRRect(
        RRect.fromLTRBAndCorners(
          cutOutRect.left,
          cutOutRect.top,
          cutOutRect.left + mBorderLength,
          cutOutRect.top + mBorderLength,
          topLeft: Radius.circular(borderRadius),
        ),
        borderPaint,
      )
      // Draw bottom right corner
      ..drawRRect(
        RRect.fromLTRBAndCorners(
          cutOutRect.right - mBorderLength,
          cutOutRect.bottom - mBorderLength,
          cutOutRect.right,
          cutOutRect.bottom,
          bottomRight: Radius.circular(borderRadius),
        ),
        borderPaint,
      )
      // Draw bottom left corner
      ..drawRRect(
        RRect.fromLTRBAndCorners(
          cutOutRect.left,
          cutOutRect.bottom - mBorderLength,
          cutOutRect.left + mBorderLength,
          cutOutRect.bottom,
          bottomLeft: Radius.circular(borderRadius),
        ),
        borderPaint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          cutOutRect,
          Radius.circular(borderRadius),
        ),
        boxPaint,
      )
      ..restore();
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}

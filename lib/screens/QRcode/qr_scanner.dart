import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smartbill/screens/QRcode/qrcode_link_screen.dart';
import 'package:smartbill/screens/QRcode/qrcode_screen.dart';

class QRScanner extends StatefulWidget {
  const QRScanner({super.key});

  @override
  State<QRScanner> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> {
  MobileScannerController scannerController = MobileScannerController();
  Timer? _timeoutTimer;
  bool _scanning = true;
  bool isUri = true;



  void _showSnackbarError(String error) {
    var snackbar = SnackBar(content: Text("Ocurrió un error: $error"), duration: Duration(seconds: 6),);
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }

  void _showSnackbarTimeout() {
    var snackbar = const SnackBar(content: Text("Su factura no pudo ser leida. Intenta con otra factura."), duration: Duration(seconds: 3),);
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }


  void _startTimer() {
    
    _timeoutTimer = Timer(const Duration(seconds: 15), () async {
      if(_scanning) {
        scannerController.stop();
        _scanning = false;
        _showSnackbarTimeout();
        Navigator.of(context).pop();
      }
    });
  }

  bool checkIfIsUri(String? result) {
    Uri? uri = Uri.tryParse(result!);
    return uri != null && uri.hasScheme && uri.hasAuthority  && result.startsWith("https://catalogo-vpfe.dian.gov.co");
  }

  bool checkIfQRContainsValidInfo(String? result) {
    return result!.length > 20;

  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _startTimer();
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
        MobileScanner(
          controller: scannerController,
          onDetect: (BarcodeCapture capture) async {
            final List<Barcode> barcodes = capture.barcodes;

            if(barcodes.first.format != BarcodeFormat.qrCode) {
              _showSnackbarError("El código detectado no es QR. Verifique que el código es válido o no hay un código de barras en la factura.");
              Navigator.pop(context);
              scannerController.dispose();
              
            } else {
              final qrResult = barcodes.first;
      
              if (qrResult.rawValue != null) {

                _timeoutTimer?.cancel(); // Stop timeout if QR is scanned
                _scanning = false;
                //To do with code
                await scannerController
                  .stop()
                  .then((value) => scannerController.dispose())
                  .then((value) {
                    var isUri = checkIfIsUri(qrResult.rawValue);
                    //Check if qr content is valid information
                    if(qrResult.rawValue!.length > 20) {
                      //Check if is url or data
                      if(isUri) {
                        if(checkIfQRContainsValidInfo(qrResult.rawValue))  {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => QrcodeLinkScreen(uri: qrResult.rawValue)));
                        } else {
                          _showSnackbarError("El codigo QR no contiene informacion valida");
                        }
                        
                      } else {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => QrcodeScreen(qrResult: qrResult.rawValue!)));
                      }
                      //If information is not valid show snackbar
                    } else {
                      _showSnackbarError("Parece que el código QR no contiene información relevante.");
                      Navigator.pop(context);
                    }
                      
                  });
                              
              } else {
                    _showSnackbarError("ERROR al leer QR");    
              }
              
            }
  
          },
          onDetectError:(error, stackTrace) {
            _showSnackbarError(error.toString());
          },
        ),
        Positioned.fill(
              child: Container(
                decoration: ShapeDecoration(
                  shape: QrScannerOverlayShape(
                    borderColor: Colors.blue,
                    borderRadius: 10,
                    borderLength: 20,
                    borderWidth: 7,
                    cutOutSize: 280,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt, size: 100, color: Color.fromARGB(122, 255, 255, 255),),
                      Transform.translate(
                        offset: const Offset(0, 60),
                        child: const Text("Escanea tu factura", style: TextStyle(color: Color.fromARGB(150, 255, 255, 255), fontSize: 18))
                      )
                    ])
                ),
              ),
            ),
            
      ]),
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
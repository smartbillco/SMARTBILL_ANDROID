import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:smartbill/screens/PDFList/pdf_list.dart';
import 'package:smartbill/screens/QRcode/confirmDownload/confirm_download.dart';
import 'package:smartbill/screens/dashboard/dashboard.dart';
import 'package:smartbill/screens/receipts.dart/receipt_screen.dart';

class QrcodeLinkScreen extends StatefulWidget {
  final String? uri; 
  const QrcodeLinkScreen({super.key, required this.uri});

  @override
  State<QrcodeLinkScreen> createState() => _QrcodeLinkScreenState();
}

class _QrcodeLinkScreenState extends State<QrcodeLinkScreen> {
  InAppWebViewController? webViewController;
  bool isLoading = false;
  bool cloudflarePassed = false;
  bool hasCheckedUrl = false;

  //DIAN receipt variables
  String? originalUrl;
  bool hasNavigated = false;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();

  }

  void showSnackbar(String content) {
    final snackbar = SnackBar(content: Text(content));

    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }

   bool checkIfUrlIsDian(String url) {
    return url.startsWith("https://catalogo-vpfe.dian.gov.co");
  }

  dynamic validateIfQRContainsCufe(Uri url) {
    if(checkIfUrlIsDian(url.toString())) {
      print("Starts with");
      if(url.queryParameters.containsKey('DocumentKey')) {
        print("Contains");
      } else {
        if(mounted) {
          showSnackbar("Parece que tu QR no contiene CUFE. Intenta con otro código");
        }
        
        Navigator.pop(context);
      }
      
    } 
  } 


  Future<bool> isDownloadLink(String url) async {
    try {
      final response = await http.head(Uri.parse(url));

      if (response.statusCode == 200) {
          // Check Content-Disposition header
          final contentDisposition = response.headers['content-disposition'];
          if (contentDisposition != null && contentDisposition.contains('attachment')) {
            return true; // Server explicitly suggests download
          }

          // Check Content-Type header for common download file types
          final contentType = response.headers['content-type'];
          if (contentType != null) {
            // Example: check for common binary types or archives
            if (contentType.contains('application/octet-stream') ||
                contentType.contains('application/zip') ||
                contentType.contains('application/pdf') ||
                contentType.contains('image/') // Consider images as downloadable if desired
                // Add more content types as needed
            ) {
              return true;
            }
          }
        }
        return false; 

    } catch(e) {
      print('Error checking URL: $e');
      return false;

    }

  }

  Future<void> downloadPdfDian(String downloadUrl) async {
    setState(() {
      isLoading = true;
    });
    
    final dir = Platform.isAndroid ?  await getExternalStorageDirectory() : await getApplicationDocumentsDirectory(); // Returns app's external storage
    final path = "${dir!.path}/invoices";
    final dirPath = Directory(path);
    
    if(!await dirPath.exists()) {
      await Directory(path).create(recursive: true);
    }
    
    String fileName = "invoice_${DateTime.now().millisecondsSinceEpoch}.pdf";

    try {
      await FlutterDownloader.enqueue(
        url: downloadUrl,
        savedDir: path,
        fileName: fileName,
        showNotification: true,
        openFileFromNotification: true,
      );

      await Future.delayed(const Duration(seconds: 6), () {
        setState(() {
          isLoading = false;
        });

        showSnackbar("Se ha descargado la factura");
        Navigator.pop(context);
        
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ReceiptScreen()));
      });

    } catch (e) {

      showSnackbar("Ha ocurrido un problema con el PDF");
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Descargar factura"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 35),
        child: isLoading
        ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 10,), Text("Descargando archivo...")]))
        : InAppWebView(
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            useOnDownloadStart: true,
            allowFileAccess: true,
            allowContentAccess: true,
            useHybridComposition: true,
          ),
          initialUrlRequest: URLRequest(url: WebUri(widget.uri!)),
          onWebViewCreated: (controller) {
            webViewController = controller;
            originalUrl = widget.uri;
          },
          shouldInterceptRequest: (controller, request) async {
            final url = request.url.toString();
            if(url.contains('Document/DownloadPDF')) {
              await downloadPdfDian(url);

            } else {
              print("Not detected yet");
            }
            return Future.value(null);
          },
          onDownloadStartRequest: (controller, request) {
            final String url = request.url.toString();

            if(widget.uri == url) {
              downloadPdfDian(url);
            } else {
              print("Url: $url");
            }
          },
        ),
      ),
    );
  }
}
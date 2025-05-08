import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smartbill/screens/PDFList/pdf_list.dart';
import 'package:smartbill/screens/QRcode/confirmDownload/confirm_download.dart';

class QrcodeLinkScreen extends StatefulWidget {
  final String? uri; 
  const QrcodeLinkScreen({super.key, required this.uri});

  @override
  State<QrcodeLinkScreen> createState() => _QrcodeLinkScreenState();
}

class _QrcodeLinkScreenState extends State<QrcodeLinkScreen> {
  late InAppWebViewController webViewController;
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

  void showSnackbar(String content) {
    final snackbar = SnackBar(content: Text(content));

    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }

  Future<void> downloadElectronicBill(String downloadUrl) async {
    setState(() {
      isLoading = true;
    });
                
    final dir = await getExternalStorageDirectory(); // Returns app's external storage
    final path = "${dir!.path}/invoices";
    await Directory(path).create(recursive: true);

    String fileName = "invoice_${DateTime.now().millisecondsSinceEpoch}.pdf";

    try {
      await FlutterDownloader.enqueue(
        url: downloadUrl,
        savedDir: path,
        fileName: fileName,
        showNotification: true,
        openFileFromNotification: true,
       );

      showSnackbar("Se esta descargando la factura");

      await Future.delayed(const Duration(seconds: 6), () {
        setState(() {
          isLoading = false;
        });

        showSnackbar("Se ha descargado la factura");
        Navigator.pop(context);
            
        });

      } catch (e) {

      showSnackbar("Ha ocurrido un problema con el PDF");
    } finally {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const PDFListScreen()));
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
          },
          onLoadStart: (controller, url) {
            if(!hasCheckedUrl && url != null) {
              hasCheckedUrl = true;
              validateIfQRContainsCufe(Uri.parse(url.toString()));
            }
            if(url.toString().contains('ShowDocument')) {
              cloudflarePassed = true;
              print("URL: ${url.toString()}");
            } else {
              cloudflarePassed = false;
            }
            originalUrl ??= url.toString();
            
          },
          onUpdateVisitedHistory: (controller, url, isReload) {
            if(originalUrl != null && originalUrl != url.toString() && !hasNavigated && cloudflarePassed) {
              hasNavigated = true;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ConfirmDownloadScreen(url: url.toString())));
            }
          },
          onDownloadStartRequest: (controller, request) {
            print("Download: ${request.url.toString()}");
            
          },
        ),
      ),
    );
  }
}
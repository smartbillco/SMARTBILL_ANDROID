import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smartbill/screens/dashboard/dashboard.dart';

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

  void showSnackbar(String content) {
    final snackbar = SnackBar(content: Text(content));

    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }

  Future<void> _startDownload(String url) async {

    final dir = Platform.isAndroid ?  await getExternalStorageDirectory() : await getApplicationDocumentsDirectory();

    final pathDir = Directory("${dir!.path}/invoices");

    if(!await pathDir.exists()) {
      await Directory("${dir.path}/invoices").create(recursive: true);
    }

    try {
        await FlutterDownloader.enqueue(
          url: url,
          savedDir: pathDir.path,
          fileName: 'Invoice_${DateTime.now().millisecondsSinceEpoch}.pdf',
          showNotification: true,
          openFileFromNotification: true,
        );

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Descargando factura...")));

        await Future.delayed(Duration(seconds: 5), () async {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Factura descargada en PDFs DIAN")));
          Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
        });

    } catch(e) {

      print("Error: $e");

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hubo un problema con la descarga: $e")));

    }

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



  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Descargar factura"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 35),
        child: InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri(widget.uri!),
            ),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              useOnDownloadStart: true,
              allowFileAccess: true,
              allowContentAccess: true,
              useHybridComposition: true,
            ),
            onWebViewCreated: (controller) {
              webViewController = controller;
              print("WebView Created");
            },
            onLoadStop: (controller, url) async {
              if(!hasCheckedUrl && url != null) {
                hasCheckedUrl = true;
                validateIfQRContainsCufe(Uri.parse(url.toString()));
              }
              print("Loaded: $url");
            },
            onUpdateVisitedHistory: (controller, url, androidIsReload) async {
              final link = url.toString();
              print("Link message: $url");
              if (Platform.isIOS && link.contains("https://catalogo-vpfe.dian.gov.co/Document/DownloadPDF?trackId")) {
                await _startDownload(link);
              }
            },
            onReceivedHttpError: (controller, request, errorResponse) {
              
            },
          ),
      ),
    );
  }
}
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
      Navigator.push(context, MaterialPageRoute(builder: (context) => const ReceiptScreen()));
    }
  }

  Future<void> _downloadPdf(String url) async {
    // Get cookies from current WebView session
    final cookies = await CookieManager().getCookies(url: WebUri(url));
    final cookieHeader = cookies.map((c) => "${c.name}=${c.value}").join("; ");

    setState(() {
      isLoading = true;
    });
    
    
    String fileName = "invoice_${DateTime.now().millisecondsSinceEpoch}.pdf";

    // Make HTTP request with cookies
    final response = await http.get(
      Uri.parse(url),
      headers: {"Cookie": cookieHeader},
    );

    if (response.statusCode == 200) {
      final dir = Platform.isAndroid ?  await getExternalStorageDirectory() : await getApplicationDocumentsDirectory();
      final path = "${dir!.path}/invoices/$fileName";
      final file = File(path);
      await file.writeAsBytes(response.bodyBytes);
      print("PDF saved at $path");
    } else {
      print("Download failed: ${response.statusCode}");
    }

     setState(() {
      isLoading = true;
    });

    showSnackbar("Se ha descargado la factura");
    Navigator.pop(context);
        
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ReceiptScreen()));


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
          },
          onDownloadStartRequest: (controller, request) async {
            final String url = request.url.toString();
            print("Download: $url");
            await _downloadPdf(url);
            
          },
        ),
      ),
    );
  }
}
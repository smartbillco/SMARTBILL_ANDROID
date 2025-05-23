import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:provider/provider.dart';
import 'package:smartbill/screens/dashboard/dashboard.dart';
import 'package:smartbill/screens/receipts.dart/receipt_screen.dart';
import 'package:smartbill/services/settings.dart';

class ConfirmDownloadScreen extends StatefulWidget {
  final String url;
  const ConfirmDownloadScreen({super.key, required this.url});

  @override
  State<ConfirmDownloadScreen> createState() => _ConfirmDownloadScreenState();
}

class _ConfirmDownloadScreenState extends State<ConfirmDownloadScreen> {
  String downloadUrl = "";
  bool isLoading = false;
  bool isDian = false;
  bool isPanama =  false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    formDownloadUrl();
    checkUrlAndExecute(widget.url);
  }

  String getTrackId() {
    Uri uri = Uri.parse(widget.url);
    List<String> segments = uri.pathSegments;

    if (segments.isNotEmpty) {
      String extractedId = segments.last;
      return extractedId;
    }
    return "no id found";
  }

  String getTokenFromUrl() {
    Uri uri = Uri.parse(widget.url);

    // Extracting the 'Token' query parameter
    String? token = uri.queryParameters['Token'];

    if (token != null) {
      return token;
    } else {
      return "no token found";
    }
  }

  void showSnackbar(String content) {
    final snackbar = SnackBar(content: Text(content));

    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
    }
  }

  void formDownloadUrl() {
    String id = getTrackId();
    String token = getTokenFromUrl();

    setState(() {
      downloadUrl = "https://catalogo-vpfe.dian.gov.co/Document/DownloadPDF?trackId=${id}&token=${token}";
    });

    print("This is the download url: $downloadUrl");
  }

  void checkUrlAndExecute(String url) {
  final regex1 = RegExp(r'^https:\/\/catalogo-vpfe\.dian\.gov\.co\/User\/SearchDocument');
  final regex2 = RegExp(r'^https:\/\/dgi-fep\.mef\.gob\.pa\/Consultas\/Facturas');
  
  if (regex1.hasMatch(url)) {
    print("Ejecutando acción para el primer enlace");
    // Coloca aquí la línea de código para el primer enlace
  } else if (regex2.hasMatch(url)) {
    print("Ejecutando acción para el segundo enlace");
    // Coloca aquí la línea de código para el segundo enlace
  } else {
    print("URL no coincide con los patrones definidos");
  }
} 

  Future<void> downloadPdfDian() async {
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

    final autoDownloadOn = context.watch<SettingsProvider>().autoDownloadOn;

    if(autoDownloadOn) {
      downloadPdfDian();
    }

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: isLoading
        ? CircularProgressIndicator()
        : AlertDialog(
          shadowColor: Colors.grey,
          title: const Text("Desea descargar el archivo?"),
          actions: [
            TextButton(
              onPressed: downloadPdfDian,
              child: const Text("Sí", style: TextStyle(color: Colors.green))
            ),
            TextButton(
              onPressed: () {
                showSnackbar("No se descargo el archivo");
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const DashboardScreen()), (r) => false);
              },
              child: const Text("No", style: TextStyle(color: Colors.redAccent))
            ),
            
          ],
        ),
      ),
    );
  }
}

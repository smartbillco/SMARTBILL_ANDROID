import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smartbill/screens/receipts/receipt_screen.dart';

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

  void showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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



  //Comienzo de descarga, verificar si clouflare autentico
  Future<bool> _isCloudflareVerifying() async {
    try {
      final controller = webViewController;
      if (controller == null) return false;
      // Get visible text of the page
      final result = await controller.evaluateJavascript(source: r"""
        (function(){
          try {
            return (document.body && document.body.innerText) ? document.body.innerText : "";
          } catch(e) { return ""; }
        })();
      """);
      if (result == null) return false;
      final bodyText = result.toString().toLowerCase();

      // Common Cloudflare phrases / paths
      if (bodyText.contains('checking your browser') ||
          bodyText.contains('just a moment') ||
          bodyText.contains('attention required') ||
          bodyText.contains('cf-chl-') ||
          bodyText.contains('cdn-cgi')) {
        return true;
      }

      return false;
    } catch (e) {
      // If anything goes wrong, assume not verifying (so we don't block)
      return false;
    }
  } 

  //Descargar pdf dian con cookies
  Future<void> downloadPdfDian(Uri downloadUrl) async {
    if (!mounted) return;
    setState(() => isLoading = true);

    final uri = downloadUrl;
    final webUri = WebUri(uri.toString());

    try {
      // 1) If Cloudflare is still verifying, notify and wait until verified (poll)
      bool verifying = await _isCloudflareVerifying();
      if (verifying) {
        showSnackbar("Espera: verificando seguridad (Cloudflare)...");
        // Poll until verification completes or timeout (e.g., 15s)
        const int maxRetries = 15;
        int tries = 0;
        while (tries < maxRetries && mounted) {
          await Future.delayed(const Duration(seconds: 1));
          if (!mounted) break;
          verifying = await _isCloudflareVerifying();
          if (!verifying) break;
          tries++;
        }
        if (verifying) {
          // still verifying after retries
          showSnackbar("Aún en verificación. Intenta nuevamente en unos segundos.");
          if (mounted) setState(() => isLoading = false);
          return;
        }
      }

      // 2) Build cookie header from WebView session cookies (WebUri)
      final cookies = await CookieManager.instance().getCookies(url: webUri);
      final cookieHeader = cookies.map((c) => "${c.name}=${c.value}").join('; ');

      // 3) Prepare folders and file paths
      final baseDir = Platform.isAndroid
          ? await getExternalStorageDirectory()
          : await getApplicationDocumentsDirectory();
      final folder = Directory("${baseDir!.path}/invoices");
      if (!await folder.exists()) await folder.create(recursive: true);

      final fileName = "invoice_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final filePath = "${folder.path}/$fileName";
      final debugHtmlPath = "${folder.path}/debug_${DateTime.now().millisecondsSinceEpoch}.html";

      // 4) HttpClient with manual redirect handling (preserve cookies)
      final httpClient = HttpClient();
      httpClient.autoUncompress = true;

      Uri current = uri;
      HttpClientResponse? response;
      int redirectCount = 0;
      while (redirectCount < 6) {
        final req = await httpClient.getUrl(current);
        if (cookieHeader.isNotEmpty) req.headers.set(HttpHeaders.cookieHeader, cookieHeader);
        req.headers.set(HttpHeaders.userAgentHeader, "Mozilla/5.0 (Android)");
        req.headers.set(HttpHeaders.acceptHeader, "application/pdf, */*; q=0.8");
        req.headers.set(HttpHeaders.refererHeader, uri.origin);

        final res = await req.close();

        // 3xx -> follow Location manually
        if (res.statusCode >= 300 && res.statusCode < 400) {
          final location = res.headers.value(HttpHeaders.locationHeader);
          if (location == null) {
            response = res;
            break;
          }
          current = current.resolve(location);
          redirectCount++;
          await res.drain();
          continue;
        } else {
          response = res;
          break;
        }
      }

      if (response == null) throw Exception("No response from server");

      // 5) Inspect status and content-type
      final status = response.statusCode;
      final contentType = response.headers.contentType?.mimeType ?? response.headers.value("content-type") ?? "";

      if (status != 200) {
        // Save debug HTML to inspect
        final body = await response.transform(utf8.decoder).join();
        await File(debugHtmlPath).writeAsString(body);
        showSnackbar("Error HTTP $status. Se guardó debug HTML.");
        if (mounted) setState(() => isLoading = false);
        return;
      }

      // If the response isn't a PDF, save debug html and prompt user to complete verification
      final lowerCt = contentType.toLowerCase();
      if (!(lowerCt.contains("pdf") || lowerCt.contains("octet-stream"))) {
        final body = await response.transform(utf8.decoder).join();
        await File(debugHtmlPath).writeAsString(body);
        // If Cloudflare still shows up in returned HTML, instruct user
        if (body.toLowerCase().contains("checking your browser") ||
            body.toLowerCase().contains("attention required") ||
            body.toLowerCase().contains("cdn-cgi")) {
          showSnackbar("Debes completar la verificación de seguridad en la página antes de descargar.");
        } else {
          showSnackbar("Respuesta no es PDF. Debug guardado.");
        }
        if (mounted) setState(() => isLoading = false);
        return;
      }

      // 6) Stream response to file (efficient)
      final file = File(filePath);
      final sink = file.openWrite();
      await response.pipe(sink);
      await sink.close();

      if (!mounted) return;
      setState(() => isLoading = false);

      showSnackbar("Se ha descargado la factura");
      // Option A: only download (we do not open the file)
      print("PDF guardado en: $filePath");
    } catch (e, st) {
      print("Error en descarga segura: $e\n$st");
      if (mounted) setState(() => isLoading = false);
      showSnackbar("Ha ocurrido un problema al descargar el PDF. Revisa los logs.");
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
          onLoadStop: (controller, url) async {
            // Optional: we keep controller updated (used by _isCloudflareVerifying)
            webViewController = controller;
          },
          onDownloadStartRequest: (controller, request) async {
            print("Url: ${request.url}");
            // request.url is the resource the webview wants to download
            if (request.url != null) {
              // attempt secure download with cloudflare handling
              await downloadPdfDian(request.url);
            } else {
              showSnackbar("URL de descarga inválida");
            }
          },
        ),
      ),
    );
  }
}
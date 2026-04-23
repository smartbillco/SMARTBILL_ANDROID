import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smartbill/screens/splash/splash.dart';
import 'package:smartbill/services/auth.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:smartbill/services/crypto_provider.dart';
import 'package:smartbill/services/db.dart';
import 'package:smartbill/services/settings.dart';
import 'package:smartbill/services/dianReceiptService.dart'; // Tu servicio
import './route_observer.dart';

// Instancia global de notificaciones
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// Workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == "downloadPdfTask") {
      final String? cufe = inputData?['cufe'];
      
      debugPrint("--- [WORKMANAGER] Iniciando tarea para CUFE: $cufe ---");

      if (cufe == null) {
        debugPrint("--- [WORKMANAGER] ERROR: CUFE es nulo ---");
        return Future.value(false);
      }

      // Instanciamos tu servicio
      final dianService = DianReceiptService();

      try {
        
        debugPrint("--- [WORKMANAGER] Paso 1: Llamando a getPdfDian... ---");
        final dianPdfResponse = await dianService.getPdfDian(cufe);

        if (dianPdfResponse.pdf.isNotEmpty) {
          
          
          debugPrint("--- [WORKMANAGER] Paso 2: Convirtiendo Base64 a archivo... ---");
          final File? savedFile = await dianService.base64ToPdfAndSave(dianPdfResponse.pdf);

          if (savedFile != null && await savedFile.exists()) {
            debugPrint("--- [WORKMANAGER] ÉXITO: PDF guardado en ${savedFile.path} ---");

            await _showNotification(
              "Factura Descargada", 
              "El PDF oficial ha sido guardado exitosamente.",
              isError: false
            );
            return Future.value(true);
          } else {
            throw Exception("El archivo no se pudo crear correctamente.");
          }
        } else {
          throw Exception("La API no devolvió contenido en base64.");
        }
      } catch (e) {
        debugPrint("--- [WORKMANAGER] EXCEPCIÓN: $e ---");
        
        await _showNotification(
          "Error de Descarga", 
          "No pudimos procesar tu factura. Intenta de nuevo más tarde.",
          isError: true
        );
        return Future.value(false);
      }
    }
    return Future.value(true);
  });
}

// Notificar al cliente
Future<void> _showNotification(String title, String body, {required bool isError}) async {
  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    isError ? 'error_channel' : 'downloads_channel',
    isError ? 'Errores Smartbill' : 'Descargas Smartbill',
    channelDescription: 'Estado de las descargas de facturas',
    importance: Importance.max,
    priority: Priority.high,
    color: isError ? Colors.red : Colors.blue,
  );

  final NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    id: isError ? 1 : 0, 
    title: title, 
    body: body, 
    notificationDetails: platformDetails,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Notificaciones
  const AndroidInitializationSettings initializationSettingsAndroid = 
      AndroidInitializationSettings('@mipmap/launcher_icon');
  const InitializationSettings initializationSettings = 
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);

  // Inicializar Workmanager
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  // Otros servicios
  await DatabaseConnection().db;
  await FlutterDownloader.initialize(debug: false, ignoreSsl: true);
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        StreamProvider.value(
          value: AuthService().user, 
          initialData: null,
          catchError: (_, __) => null,
        ),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => CryptoProvider()..fetchCryptoData()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: <NavigatorObserver>[routeObserver],
      debugShowCheckedModeBanner: false,
      title: 'Smartbill',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartbill/providers/crypto_provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smartbill/screens/splash/splash.dart';
import 'package:smartbill/services/auth.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:smartbill/services/db.dart';
import 'package:smartbill/services/settings.dart';
import 'package:smartbill/services/dianReceiptService.dart'; // Tu servicio
import './route_observer.dart';

// Instancia global de notificaciones
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications({
  bool requestPermission = false,
}) async {

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );

  // ONLY request permission from main UI isolate
  if (requestPermission) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }
}

// Workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {

  Workmanager().executeTask((task, inputData) async {

    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp();

    // IMPORTANT:
    // Initialize notifications WITHOUT requesting permission
    await initializeNotifications();

    if (task == "downloadPdfTask") {

      final String? cufe = inputData?['cufe'];

      debugPrint("--- [WORKMANAGER] Iniciando tarea para CUFE: $cufe ---");

      if (cufe == null) {
        debugPrint("--- [WORKMANAGER] ERROR: CUFE es nulo ---");
        return Future.value(false);
      }

      final dianService = DianReceiptService();

      try {

        debugPrint("--- PASO A ---");

        final dianPdfResponse =
            await dianService.getPdfDian(cufe);

        debugPrint("--- PASO B ---");

        if (dianPdfResponse.pdf.isEmpty) {
          throw Exception("La API no devolvió contenido base64.");
        }

        debugPrint("--- PASO C ---");

        final File? savedFile =
            await dianService.base64ToPdfAndSave(
              dianPdfResponse.pdf,
            );

        debugPrint("--- PASO D ---");

        if (savedFile != null && await savedFile.exists()) {

          debugPrint(
              "--- PDF guardado en ${savedFile.path} ---");

          await _showNotification(
            "Factura Descargada",
            "El PDF oficial ha sido guardado exitosamente.",
            isError: false,
          );

          return Future.value(true);

        } else {
          throw Exception(
              "El archivo no se pudo crear correctamente.");
        }

      } catch (e, stack) {

        debugPrint("--- ERROR WORKMANAGER ---");
        debugPrint(e.toString());
        debugPrint(stack.toString());

        await _showNotification(
          "Error de Descarga",
          "No pudimos procesar tu factura.",
          isError: true,
        );

        return Future.value(false);
      }
    }

    return Future.value(true);
  });
}

// Notificar al cliente
Future<void> _showNotification(
  String title,
  String body, {
  required bool isError,
}) async {

  const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
    'downloads_channel',
    'Descargas Smartbill',
    channelDescription:
        'Estado de las descargas de facturas',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails platformDetails =
      NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    id: isError ? 1 : 0,
    title: title,
    body: body,
    notificationDetails: platformDetails,
  );
}


// -------- Main------------ //
Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await initializeNotifications(
    requestPermission: true,
  );

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  await DatabaseConnection().db;
  await FlutterDownloader.initialize(
    debug: false,
    ignoreSsl: true,
  );

  runApp(
    MultiProvider(
      providers: [
        StreamProvider.value(
          value: AuthService().user,
          initialData: null,
          catchError: (_, __) => null,
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              CryptoProvider()..initializeData(),
        ),

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
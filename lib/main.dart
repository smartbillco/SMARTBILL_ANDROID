import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:smartbill/services/db.dart';
import 'package:smartbill/services/dian_receipt_service.dart';
import 'package:smartbill/app.dart'; 

// Global notification instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications({
  bool requestPermission =
      false, // Keep the parameter for compatibility, but don't use it
}) async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    requestAlertPermission: false, // Ensure these are false
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);

  // Remove the "if (requestPermission)" block entirely
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    await initializeNotifications();

    if (task == "downloadPdfTask") {
      final String? cufe = inputData?['cufe'];
      if (cufe == null) return Future.value(false);

      final dianService = DianReceiptService();
      try {
        final dianPdfResponse = await dianService.getPdfDian(cufe);
        final File? savedFile = await dianService.base64ToPdfAndSave(
          dianPdfResponse.pdf, 
          cufe
        );
        return Future.value(savedFile != null);
      } catch (e) {
        return Future.value(false);
      }
    }
    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Parallelizing initializations where possible
  await Firebase.initializeApp();
  await initializeNotifications(requestPermission: false);

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  await DatabaseConnection().db;

  await FlutterDownloader.initialize(debug: false, ignoreSsl: true);

  runApp(const MyApp());
}

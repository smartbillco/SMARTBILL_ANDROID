import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartbill/screens/settings/settings_widgets/backup_widget.dart';
import 'package:smartbill/screens/settings/settings_widgets/restore_widget.dart';
import 'package:smartbill/screens/settings/settings_widgets/settings_widgets.dart';
import 'package:smartbill/services/custom_user.dart';
import 'package:smartbill/services/settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  dynamic myUser = [];
  CustomUser customUser = CustomUser();


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    startCustomUser();
  }

  Future<void> startCustomUser() async {

    try {
      var userInfo = await customUser.getUser();
      setState(() {
        myUser = userInfo;
      });
    } catch (e) {
      print("ER: $e");
    }
    
  }


  @override
  Widget build(BuildContext context) {

    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Configuración")
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsRow(settingsValue: settings.autoDownloadOn, title: "Descargas", subtitle: "Descargar facturas de links automáticamente"),
            const SizedBox(height: 18),
            const SizedBox(height: 18),
            SettingsRow(settingsValue: settings.notificationsOn, title: "Notificaciones", subtitle: "Activar notificaciones"),
            const SizedBox(height: 18),
            const BackupWidget(),
            const SizedBox(height: 18),
            const RestoreWidget(),
            const SizedBox(height: 40),
            myUser.isEmpty
            ? const Column(children: [Text("Cargando información del usuario..."), SizedBox(height:10), CircularProgressIndicator()] )
            : Expanded(
                child: ListViewUserFields(email: myUser!['email'], name: myUser!['displayName'], userId: myUser!['documentId'], address: myUser['address'],)
            ),
          ],
        )
      ),
    );
  }
}
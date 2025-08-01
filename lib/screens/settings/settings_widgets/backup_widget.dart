import 'package:flutter/material.dart';
import 'package:smartbill/services/backup.dart';

class BackupWidget extends StatefulWidget {
  const BackupWidget({super.key});

  @override
  State<BackupWidget> createState() => _BackupWidgetState();
}

class _BackupWidgetState extends State<BackupWidget> {
  BackupService backupService = BackupService();
  bool _isDownloading = false;
  double _progress = 0;
  String? date;


  Future<void> _createBackUp() async {

      try {
        await backupService.initBackupDir();
        final backupResposne = await backupService.backupFilesFolder();
        await backupService.backupDatabase();

        if(backupResposne == 'success') {
            for(var i = 0; i <= 4; i++) {
              await Future.delayed(Duration(seconds: 1), () {
                setState(() {
                  _progress += 0.25;
                });
              });
            }

            DateTime now = DateTime.now();

            setState(() {
              _isDownloading = false;
              _progress = 0;
              date = "${now.year}-${now.month}-${now.day}. ${now.hour}:${now.minute}h";
            });

            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Se guardo la copia de seguridad")));

        } else if (backupResposne == 'no files') {
          
          setState(() {
            _isDownloading = false;
            _progress = 0;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No tienes facturas para guardar")));

        } else {
          setState(() {
            _isDownloading = false;
            _progress = 0;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hay un error exportando los datos.")));
        } 


      } catch(e) {
        print("Hubo un error: $e");
      }

  }


  void _showBackupConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar respaldo'),
          content: const Text('¿Quieres exportar sus archivos a una carpeta?'),
          actions: [
            TextButton(
              child: const Text('Cancelar', style: TextStyle(color: Colors.pinkAccent),),
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
              },
            ),
            ElevatedButton(
              child: const Text('Confirmar', style: TextStyle(color: Colors.green),),
              onPressed: () async {
                setState(() {
                  _isDownloading = true; 
                });
                Navigator.of(context).pop(); // close dialog

                await _createBackUp();
// your backup function
              },
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return _isDownloading
     ? SizedBox(
        width: MediaQuery.of(context).size.width - 20,
        height: 10,
        child: LinearProgressIndicator(
          value: _progress
        ),
      )
    : Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Exportar", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Container(width: 200, child: Text("Exportar mis facturas a una carpeta como copia de seguridad", style: const TextStyle(color: Colors.black54))),
              date == null
              ? SizedBox.shrink()
              : Text("Copia de seguridad: $date", style: TextStyle(color: Colors.grey),)
            ],
          ),
          IconButton(onPressed: () {
            _showBackupConfirmationDialog(context);
            },
          icon: Icon(Icons.download), color: Colors.blueGrey,)
        ],
    );
     
  }
}
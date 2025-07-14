import 'package:flutter/material.dart';
import 'package:smartbill/services/restore.dart';

class RestoreWidget extends StatefulWidget {
  const RestoreWidget({super.key});

  @override
  State<RestoreWidget> createState() => _RestoreWidgetState();
}

class _RestoreWidgetState extends State<RestoreWidget> {
  RestoreService restoreService = RestoreService();

  Future<void> restore() async {
    if(restoreService.checkIfBackupExists() == false) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No hay archivo por restaurar")));

    } else {
      final restoreState = await restoreService.restoreBackup();
      if(restoreState == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Se reestablecieron las facturas")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ocurrio un error")));
      }
    }

  }


  void _showRestoreConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Restaurar copia de seguridad'),
          content: const Text('¿Esta seguro que quiere reestablecer la ultima copia de seguridad?'),
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

                Navigator.of(context).pop(); // close dialog

                //Restore method
                restore();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Restaurar", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Container(width: 200, child: Text("Restablecer facturas desde copia de seguridad", style: const TextStyle(color: Colors.black54))),
        
            ],
          ),
          IconButton(onPressed: () {
            _showRestoreConfirmationDialog(context);
          },
          icon: Icon(Icons.upload), color: Colors.blueGrey,)
        ],
    );
  }
}
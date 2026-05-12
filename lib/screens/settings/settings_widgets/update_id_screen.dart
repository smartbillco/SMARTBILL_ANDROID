import 'package:flutter/material.dart';
import 'package:smartbill/screens/settings/settings.dart';
import 'package:smartbill/services/custom_user.dart';

class UpdateIdScreen extends StatefulWidget {
  const UpdateIdScreen({super.key});

  @override
  State<UpdateIdScreen> createState() => _UpdateIdScreenState();
  
}

class _UpdateIdScreenState extends State<UpdateIdScreen> {
  final TextEditingController _idController = TextEditingController();
  final CustomUser customUser = CustomUser();
  bool isLoading = false;



  Future<void> _changeDocumentId() async {

    setState(() {
      isLoading = true;
    });

    try {
      print(_idController.text);
      await customUser.updateDocumentId(_idController.text.trim());
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Documento de identidad actualizado")));
      }
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SettingsScreen())); 

    } catch(e) {
      print("Error updating id: $e");
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error actualizando")));
      }
      
    } finally {
      setState(() {
        isLoading = false;
      });
    }
    
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Actualizar ID"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(35),
        child: Column(
          children: [
            const Text("Actualiza tu nombre", style: TextStyle(fontSize: 22)),
            const SizedBox(height: 40),
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                label: Text('No de Identificación')
              ),
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: MediaQuery.of(context).size.width - 20,
              child: ElevatedButton(
                style: const ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.black54)
                ),
                onPressed: _changeDocumentId,
                child: isLoading
                ? CircularProgressIndicator()
                : const Text("Enviar", style: TextStyle(color: Colors.white, fontSize: 16),)
              ),
            )
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartbill/screens/wrapper.dart';
import 'package:smartbill/services/custom_user.dart';

class UpdateNameScreen extends StatefulWidget {
  const UpdateNameScreen({super.key});

  @override
  State<UpdateNameScreen> createState() => _UpdateNameScreenState();
}

class _UpdateNameScreenState extends State<UpdateNameScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  User? user = FirebaseAuth.instance.currentUser;
  final CustomUser customUser = CustomUser();
  bool isLoading = false;


  void _updateName() async {

    setState(() {
      isLoading = true;
    });

    try {
  
      String fullName = "${_nameController.text.trim()} ${_lastNameController.text.trim()}";
      await customUser.updateDisplayName(fullName);

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nombre actualizado")));
      }
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Wrapper())); 

    } catch(e) {
      print("Error updating name: $e");
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error actualizando.")));
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
        title: Text("Actualizar nombre"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(35),
        child: Column(
          children: [
            const Text("Actualiza tu nombre", style: TextStyle(fontSize: 22)),
            const SizedBox(height: 40),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                label: Text('Nombre')
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                label: Text('Apellido')
              ),
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: MediaQuery.of(context).size.width - 20,
              child: ElevatedButton(
                style: const ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.black54)
                ),
                onPressed: _updateName,
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
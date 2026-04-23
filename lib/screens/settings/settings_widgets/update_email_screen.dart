import 'package:flutter/material.dart';
import 'package:smartbill/screens/wrapper.dart';
import 'package:smartbill/services/custom_user.dart';


class UpdateEmailScreen extends StatefulWidget {
  const UpdateEmailScreen({super.key});

  @override
  State<UpdateEmailScreen> createState() => _UpdateEmailScreenState();
}

class _UpdateEmailScreenState extends State<UpdateEmailScreen> {
  final TextEditingController _emailController = TextEditingController();
  CustomUser customUser = CustomUser();
  bool isLoading = false;

  void _updateCurrentEmail() async {

    setState(() {
      isLoading =  true;
    });

    try {
      await customUser.updateEmail(_emailController.text);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Se ha cambiado el correo electronica")));
      }
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Wrapper())); 

    } catch(e) {
      print("ERROR trying to update: $e");
    } finally{
      setState(() {
        isLoading = false;
      });
    }

    
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Actualizar email"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(35),
        child: Column(
          children: [
            const Text("Actualiza tu cuenta de correo electrónico", style: TextStyle(fontSize: 22)),
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                label: Text('Email')
              ),
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: MediaQuery.of(context).size.width - 20,
              child: ElevatedButton(
                style: const ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.black54)
                ),
                onPressed: _updateCurrentEmail,
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
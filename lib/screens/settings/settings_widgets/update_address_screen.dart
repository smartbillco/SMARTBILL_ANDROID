import 'package:flutter/material.dart';
import 'package:smartbill/screens/dashboard/dashboard.dart';
import 'package:smartbill/services/custom_user.dart';

class UpdateAddressScreen extends StatefulWidget {
  const UpdateAddressScreen({super.key});

  @override
  State<UpdateAddressScreen> createState() => _UpdateAddressScreenState();
}

class _UpdateAddressScreenState extends State<UpdateAddressScreen> {
  final TextEditingController _addressController = TextEditingController();
  final CustomUser customUser = CustomUser();
  bool isLoading = false;



  Future<void> _changeAddress() async {

    setState(() {
      isLoading = true;
    });

    try {
      print(_addressController.text);
      await customUser.updateAddress(_addressController.text.trim());
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dirreción ha sido actualizada actualizado")));
      }
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen())); 

    } catch(e) {

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
        title: Text("Actualizar Dirección"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(35),
        child: Column(
          children: [
            const Text("Actualiza tu nombre", style: TextStyle(fontSize: 22)),
            const SizedBox(height: 40),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                label: Text('Dirección')
              ),
            ),
            const SizedBox(height: 50),
            isLoading 
            ? const CircularProgressIndicator()
            : SizedBox(
              width: MediaQuery.of(context).size.width - 20,
              child: ElevatedButton(
                style: const ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.black54)
                ),
                onPressed: _changeAddress,
                child: const Text("Enviar", style: TextStyle(color: Colors.white, fontSize: 16),)
              ),
            )
          ],
        ),
      ),
    );
  }
}
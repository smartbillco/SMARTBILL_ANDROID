import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:smartbill/screens/wrapper.dart';
import 'package:smartbill/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OtpScreen extends StatefulWidget {
  final String? code;

  const OtpScreen({super.key, required this.code});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _codeText = TextEditingController();
  final AuthService _auth = AuthService();
  //Simulating http request with loading time
  bool isLoading = false;

  //Fuction for simulating http request with Future.delay

  Future<void> simHttpRequest() async {
    setState(() {
      isLoading = true;
    });

    User? user = await _auth.signInWithCode(
        widget.code.toString(), _codeText.text.trim());

    if (user != null) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Wrapper()), (r) => false);
    }

    if (user == null) {
      _showSnackbar();
    }

    setState(() {
      isLoading = false;
    });
  }

  void _showSnackbar() {
    const snackBar = SnackBar(
      content: Text("El codigo no es valido"),
      duration: Duration(seconds: 3),
    );

    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Verifica tu numero"),
      ),
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 90),
        //Begin layout
        child: Column(
          children: [
            //Image of receiving text
            const Image(image: AssetImage('assets/images/notificacion_texto.png'), width: 100, height: 120, ),
            const SizedBox(
              height: 30,
            ),
            //Enter OTP
            const Text(
              "Ingresa tu código: ",
              style: TextStyle(fontSize: 22),
            ),
            const SizedBox(
              height: 30,
            ),
            Pinput(
              crossAxisAlignment: CrossAxisAlignment.center,
              length: 6,
              controller: _codeText,
              onCompleted: (pin) => print(pin),
              defaultPinTheme: PinTheme(
                width: 50,
                height: 50,
                textStyle: const TextStyle(
                    fontSize: 24,
                    color: Color.fromRGBO(30, 60, 87, 1),
                    fontWeight: FontWeight.w600),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color.fromARGB(255, 75, 78, 80)),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(
              height: 45,
            ),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: simHttpRequest,
                    style: const ButtonStyle(
                        backgroundColor:
                            WidgetStatePropertyAll(Color.fromARGB(255, 75, 78, 80))),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 7),
                      child: Text("Verificar",
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),

            //Form for four digits
          ],
        ),
      ),
    );
  }
}

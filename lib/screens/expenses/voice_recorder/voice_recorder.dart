import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartbill/models/transaction.dart';
import 'package:smartbill/screens/expenses/expenses.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:lottie/lottie.dart';

class VoiceRecorderScreen extends StatefulWidget {
  const VoiceRecorderScreen({super.key});

  @override
  State<VoiceRecorderScreen> createState() => _VoiceRecorderScreenState();
}

class _VoiceRecorderScreenState extends State<VoiceRecorderScreen> {
  String userId = FirebaseAuth.instance.currentUser!.uid;
  SpeechToText stt = SpeechToText();
  bool _isSpeechEnable = false;
  String _lastWords = '';
  String? _type;
  double _amount = 0;
  String _category = 'Otro';

  bool _isListening = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
      bool available = await stt.initialize(
      onStatus: (status) {
        print('Speech status: $status');
        if (status == 'listening') {
          setState(() => _isListening = true);
        } else if (status == 'notListening' || status == 'done') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) => print('Speech error: $error'),
    );

    if (!available) {
      setState(() => _isListening = false);
    }
  }

  void _startRecording() async {
    await stt.listen(onResult: _processSpeech, localeId: 'es-CO');
    setState(() {
      
    });
  }

  void _stopRecording() async {
    await stt.stop();
    setState(() {
     
    });
  }

  

  String _getType(String text) {
    List expense = ["gasté", "compré", "invertí", "regalé", "pagué"];

    bool isExpense = expense.any((word) => text.contains(word));

    print("Type: $isExpense");

    return isExpense ? "expense" : "income";
  }

  double parsearMillones(String text) {
    final Map<String, int> contentWords = {
      '1 millón': 1,
      "un millón": 1,
      'dos': 2,
      'tres': 3,
      'cuatro': 4,
      'cinco': 5,
      'seis': 6,
      'siete': 7,
      'ocho': 8,
      'nueve': 9,
    };

    int millones = 1; // Default to 1 millón if no word is found

    contentWords.forEach((key, value) {
      if (text.contains(key)) {
        millones = value;
      }
    });

    print("Mill9ones: $millones");

    return millones * 1000000.0;
  }

  String obtenerCategorias(String text, String type) {
    final Map<String, List> catExpense = {
      'Mercado': ['mercado', 'supermercado', 'compras de comida'],
      'Alimentación': ['almuerzo', 'cena', 'desayuno', 'comida', 'restaurante', 'cafetería', 'alimentación'],
      'Arriendo': ['arriendo', 'alquiler', 'apartamento', 'local'],
      'Servicios': ['agua', 'luz', 'gas', 'internet', 'teléfono', 'telefono'],
      'Transporte': ['bus', 'taxi', 'uber', 'didi', 'metro', 'gasolina', 'peaje', 'carro', 'auto'],
      'Salidas': ['cine', 'bar', 'fiesta', 'discoteca', 'evento'],
      'Salud': ['medicinas', 'doctor', 'hospital', 'clinica', 'cita médica'],
      'Deuda': ['pago de deuda', 'crédito', 'credito', 'prestamo', 'préstamo', 'hipoteca'],
      'Otro': []
      };

    final Map<String, List> catIncome = {
      'Independiente': ['freelance', 'trabajo independiente', 'proyecto', 'freelancer'],
      'Arriendos': ['arriendo', 'alquilere', 'renta', 'arriendos', 'alquileres', 'rentas', 'apartamento', 'local'],
      'Inversiones': ['intereses', 'dividendos', 'ganancias', 'acciones'],
      'Itro': []
    };


    // Dividimos en palabras
    final words = text.split(RegExp(r'\s+'));

    if (type == "expense") {
      for (var entry in catExpense.entries) {
        if (words.any((word) => entry.value.contains(word))) {
          return entry.key;
        }
      }
    } else {
      for (var entry in catIncome.entries) {
        if (words.any((word) => entry.value.contains(word))) {
          return entry.key;
        }
      }
    }

    return "Otro";
    
  }

  Future<void> _createNewTransaction(double amount, String description, String category, String type) async {
    
    // Usamos la fecha seleccionada pero con hora incluida
      final now = DateTime.now();
      String date = now.toIso8601String(); 

      Transaction income = Transaction(
        userId: userId,
        amount: amount,
        date: date, 
        description: description,
        category: category,
        type: type,
      );

      await income.saveNewTransaction();

      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ExpensesScreen()),
      );

  }



  //Procesar y guardar la transaccion de voz
  Future<void> _processSpeech(SpeechRecognitionResult result) async {
    String text = result.recognizedWords.toLowerCase();
    final type = _getType(text);
    double? parsedNumber;

    print("Texto: $text");

    text = text.replaceAll(RegExp(r'1\s*mill[oó]n'), 'un millón');

    print("Replaced text: $text");

    //Extract money amount from recording
    final amountRegex = RegExp(r'\d+(?:[\s.,]\d{3})*');
    final matches = amountRegex.allMatches(text);

    if(matches.isNotEmpty) {

      final match = double.tryParse(matches.last.group(0)?.replaceAll(',', '').replaceAll('.', '') ?? '');

      if (text.contains('millón') || text.contains('millones')) {
        print("Amouht: $match");
        parsedNumber = parsearMillones(text) + match!;
      } else {
        parsedNumber = match;
      }
      
    } else {
      if (text.contains('millón') || text.contains('millones')) {
        parsedNumber = parsearMillones(text);
      } 

    }


    final newCategory = obtenerCategorias(text, type);

    setState(() {
      _lastWords = result.recognizedWords;
      _type = type;
      _amount = parsedNumber!;
      _category = newCategory;
    });
    
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Grabar transacción"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isListening ? Lottie.asset('assets/sound_waves.json', width: 250) : const SizedBox.shrink(),
              const Text("Grabar una nueva transacción"),
              const SizedBox(height: 30),
              TextButton.icon(
                label: _isListening ? const Text("Dejar de grabar", style: TextStyle(color: Colors.white),) : const Text("Comenzar a grabar", style: TextStyle(color: Colors.white)),
                onPressed: _isListening ? _stopRecording : _startRecording,
                icon: Icon(_isListening ? Icons.mic_off : Icons.mic, size: 30, color: Colors.white,),
                style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll( _isListening ? Colors.red : Colors.green)),),
              _lastWords.isEmpty
                  ? const SizedBox.shrink()
                  : Card(
                      margin: const EdgeInsets.all(20),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Contenido: $_lastWords"),
                            Text( "Descripcion: ${_type == 'expense' ? 'Gasto' : 'Ingreso'}"),
                            Text("Categoria: $_category"),
                            Text("Cantidad: ${NumberFormat("#,##0.00").format(_amount).toString()}"),
                          ],
                        ),
                      ),
                    ),
                    _lastWords.isEmpty
                    ? const SizedBox.shrink()
                    : ElevatedButton(
                      onPressed: () { _createNewTransaction(_amount, _lastWords, _category, _type!);},
                      style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.black45)),
                      child: const Text("Guardar transaccion", style: TextStyle(color: Colors.white)),)
            ],
          ),
        ));
  }
}

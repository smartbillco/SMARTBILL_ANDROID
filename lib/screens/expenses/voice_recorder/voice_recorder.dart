import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartbill/models/transaction.dart';
import 'package:smartbill/screens/expenses/expenses.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _isSpeechEnable = await stt.initialize();
    setState(() {});
  }

  void _startRecording() async {
    await stt.listen(onResult: _processSpeech, localeId: 'es-CO');
    setState(() {});
  }

  void _stopRecording() async {
    await stt.stop();
    setState(() {});
  }

  

  String _getType(String text) {
    List expense = ["gasté", "compré", "invertí", "regalé", "pagué"];

    bool isExpense = expense.any((word) => text.contains(word));

    return isExpense ? "expense" : "income";
  }

  double parsearMillones(String text) {
    final Map<String, int> contentWords = {
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

    return millones * 1000000.0;
  }

  String obtenerCategorias(String text, String type) {
    final Map<String, List> catExpense = {
      'Mercado': ['mercado', 'supermercado', 'compras de comida'],
      'Alimentacion': ['almuerzo', 'cena', 'desayuno', 'comida', 'restaurante', 'cafetería', 'alimentación'],
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

    final categories = type == 'expense' ? catExpense : catIncome;

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
    
    String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
   
    Transaction income = Transaction(userId: userId, amount: amount, date: date, description: description, category: category, type: 'income');

    await income.saveNewTransaction();

    Navigator.pop(context);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ExpensesScreen()));

  }



  //Procesar y guardar la transaccion de voz
  Future<void> _processSpeech(SpeechRecognitionResult result) async {
    final text = result.recognizedWords.toLowerCase();
    final type = _getType(text);
    double? parsedNumber;

    //Extract money amount from recording
    final amountRegex = RegExp(r'\d+(?:[\s.,]\d{3})*');
    double? amount = double.tryParse(
        amountRegex.firstMatch(text)?.group(0)?.replaceAll(',', '') ?? '');

    final rawMatch = amountRegex.firstMatch(text)?.group(0);
    if (rawMatch != null) {
      parsedNumber = double.tryParse(rawMatch.replaceAll(RegExp(r'[^\d]'), ''));
    }

    // 2️⃣ Si no detectó bien o hay "millón/millones", procesar especial
    if (text.contains('millón') || text.contains('millones')) {
      parsedNumber = parsearMillones(text) + amount!;
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
          title: Text("Grabar transacción"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Grabar una nueva transacción"),
              const SizedBox(height: 30),
              IconButton(
                padding: EdgeInsets.all(16),
                onPressed: stt.isListening ? _stopRecording : _startRecording,
                icon: Icon(stt.isListening ? Icons.mic_off : Icons.mic),
                style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(
                        stt.isListening ? Colors.red : Colors.green)),
                iconSize: 30,
              ),
              _lastWords.isEmpty
                  ? SizedBox.shrink()
                  : Card(
                      margin: EdgeInsets.all(20),
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
                      child: Text("Guardar transaccion", style: TextStyle(color: Colors.white),),
                      style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.black45)),)
            ],
          ),
        ));
  }
}

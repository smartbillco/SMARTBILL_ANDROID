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

  String _lastWords = '';
  String? _type;
  double _amount = 0;
  String _category = 'Otro';

  bool _isListening = false;
  int _animationKey = 0;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    await stt.initialize(
      onStatus: (status) {
        print('Speech status: $status');

        if (status == 'done' || status == 'notListening') {
          _forceStopListening();
        }
      },
      onError: (error) => print('Speech error: $error'),
    );
  }

  void _startRecording() async {
    await stt.listen(
      onResult: _processSpeech,
      localeId: 'es-CO',
    );

    setState(() {
      _isListening = true;
      _lastWords = '';
      _animationKey++; // 🔥 force Lottie restart
    });
  }

  void _stopRecording() async {
    await stt.stop();

    setState(() {
      _isListening = false;
    });
  }

  void _forceStopListening() async {
    await stt.stop();

    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }
  }

  String _getType(String text) {
    List expense = [
      "gasté",
      "compré",
      "invertí",
      "regalé",
      "pagué",
      "compro",
      "usé",
      "consumí",
      "derroché",
      "gasto",
      "pago",
      "inversión",
      "perdí"
    ];

    bool isExpense = expense.any((word) => text.contains(word));
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

    int millones = 1;

    contentWords.forEach((key, value) {
      if (text.contains(key)) {
        millones = value;
      }
    });

    return millones * 1000000.0;
  }

  String obtenerCategorias(String text, String type) {
    final Map<String, List> catExpense = {
      'Mercado': ['mercado', 'supermercado', 'compras'],
      'Alimentación': ['almuerzo', 'cena', 'desayuno', 'restaurante'],
      'Arriendo': ['arriendo', 'alquiler'],
      'Servicios': ['agua', 'luz', 'gas', 'internet'],
      'Transporte': ['bus', 'taxi', 'uber', 'metro', 'gasolina'],
      'Salidas': ['cine', 'bar', 'fiesta'],
      'Salud': ['medicinas', 'doctor', 'hospital'],
      'Deuda': ['crédito', 'prestamo'],
      'Otro': []
    };

    final Map<String, List> catIncome = {
      'Independiente': ['freelance', 'proyecto'],
      'Arriendos': ['arriendo', 'renta'],
      'Inversiones': ['intereses', 'dividendos'],
      'Otro': []
    };

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

  Future<void> _createNewTransaction(
      double amount, String description, String category, String type) async {
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

  Future<void> _processSpeech(SpeechRecognitionResult result) async {
    String text = result.recognizedWords.toLowerCase();
    final type = _getType(text);
    double? parsedNumber;

    text = text.replaceAll(RegExp(r'1\s*mill[oó]n'), 'un millón');

    final amountRegex = RegExp(r'\d+(?:[\s.,]\d{3})*');
    final matches = amountRegex.allMatches(text);

    if (matches.isNotEmpty) {
      final match = double.tryParse(
          matches.last.group(0)?.replaceAll(',', '').replaceAll('.', '') ?? '');

      if (text.contains('millón') || text.contains('millones')) {
        parsedNumber = parsearMillones(text) + (match ?? 0);
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
      _amount = parsedNumber ?? 0;
      _category = newCategory;
    });

    // 🔥 KEY FIX: stop when final result arrives
    if (result.finalResult) {
      _forceStopListening();
    }
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
            _isListening
                ? Lottie.asset(
                    'assets/sound_waves.json',
                    width: 250,
                    key: ValueKey(_animationKey),
                  )
                : const SizedBox.shrink(),
            const Text(
              "Grabar una nueva transacción",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),
            TextButton.icon(
              label: Text(
                _isListening ? "Dejar de grabar" : "Comenzar a grabar",
                style: const TextStyle(color: Colors.white),
              ),
              onPressed: _isListening ? _stopRecording : _startRecording,
              icon: Icon(
                _isListening ? Icons.mic_off : Icons.mic,
                size: 30,
                color: Colors.white,
              ),
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(
                    _isListening ? Colors.red : Colors.green),
              ),
            ),
            _lastWords.isEmpty
                ? const SizedBox.shrink()
                : Card(
                    margin: const EdgeInsets.all(20),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Contenido: $_lastWords"),
                          Text("Tipo: ${_type == 'expense' ? 'Gasto' : 'Ingreso'}"),
                          Text("Categoria: $_category"),
                          Text(
                              "Cantidad: ${NumberFormat("#,##0.00").format(_amount)}"),
                        ],
                      ),
                    ),
                  ),
            _lastWords.isEmpty
                ? const SizedBox.shrink()
                : ElevatedButton(
                    onPressed: () {
                      _createNewTransaction(
                          _amount, _lastWords, _category, _type!);
                    },
                    child: const Text("Guardar transaccion"),
                  )
          ],
        ),
      ),
    );
  }
}
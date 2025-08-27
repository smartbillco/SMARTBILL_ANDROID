import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartbill/screens/expenses/expenses.dart';
import 'package:smartbill/screens/expenses/number_formatter.dart';
import 'package:smartbill/models/transaction.dart';

class AddIncomeForm extends StatefulWidget {
  const AddIncomeForm({super.key});

  @override
  State<AddIncomeForm> createState() => _AddIncomeFormState();
}

class _AddIncomeFormState extends State<AddIncomeForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _incomeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  String userId = FirebaseAuth.instance.currentUser!.uid;
  String? _selectedCategory;
  DateTime? _selectedDate;



  void _pickDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }


    Future<void> _createNewTransaction() async {
    // Usamos la fecha seleccionada pero con hora incluida
    final now = _selectedDate ?? DateTime.now();
    String date = now.toIso8601String(); 

    String formattedAmount = _incomeController.text.replaceAll(',', '');
    double amount = double.parse(formattedAmount);

    Transaction income = Transaction(
      userId: userId,
      amount: amount,
      date: date, // <-- ISO8601 con hora
      description: _descriptionController.text,
      category: _selectedCategory!,
      type: 'income',
    );

    await income.saveNewTransaction();

    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ExpensesScreen()),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(),
      body: Padding(
        padding: EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: 
          [
            const Text("Agregar ingreso", style: TextStyle(fontWeight: FontWeight.w300, fontSize: 30),),
            const SizedBox(height: 40),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 230,
                    child: TextFormField(
                      inputFormatters: [
                        ThousandsSeparatorInputFormatter()
                      ],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                      controller: _incomeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Cantidad",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Por favor ingresa un valor";
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 45),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: "Categoría",
                    ),
                    items: ["Salario", "Independiente", "Arriendos", "Inversiones", "Otro"].map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                    validator: (value) => value == null ? "Por favor seleccione una categoria" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Selecciona fecha',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () => _pickDate(context),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _descriptionController, // Allows multiple lines
                    decoration: const InputDecoration(
                      labelText: "Descripcion",
                      hintText: "Descripción de tu ingreso...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height:30),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _createNewTransaction();
                          // Process the form submission
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Ingreso agregado!")),
                          );
                        }
                      },
                      style: const ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(Colors.green)
                      ),
                      child: const Text("Agregar", style: TextStyle(color: Colors.white, fontSize: 17),),
                    ),
                  ),
                ],
              ),
            ),
          ]
        ),
      ),
    );
  }
}
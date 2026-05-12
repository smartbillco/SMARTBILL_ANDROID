import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:smartbill/drawer/drawer.dart';
import 'package:smartbill/models/country.dart';
import 'package:smartbill/screens/dashboard/dashboard_widgets/dashboard_container.dart';
import 'package:smartbill/screens/deleteAccount/delete_account.dart';
import 'package:smartbill/screens/home/flag_icon.dart';
import 'package:smartbill/screens/settings/settings.dart';
import 'package:smartbill/services/auth.dart';
import 'package:smartbill/services/colombian_bill.dart';
import 'package:smartbill/services/db.dart';
import 'package:smartbill/services/ocr_receipts.dart';
import 'package:smartbill/services/pdf_reader.dart';
import 'package:smartbill/services/peruvian_bill.dart';
import 'package:smartbill/services/trm.dart';
import 'package:smartbill/services/xml/xml.dart';
import 'package:smartbill/route_observer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with RouteAware {
  DatabaseConnection databaseConnection = DatabaseConnection();
  User? user = FirebaseAuth.instance.currentUser;
  String uri =
      "https://v6.exchangerate-api.com/v6/b68f1074f3d7d6240f3db214/latest/USD";
  String data = "0";
  Country _currentCountry = Country(
      id: 1,
      flag: "assets/images/colombian_flag.png",
      name: "Colombia",
      currency: "COP");

  final OcrReceiptsService ocrService = OcrReceiptsService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Xmlhandler xmlhandler = Xmlhandler();
  final ColombianBill colombianBill = ColombianBill();
  final PeruvianBill peruvianBill = PeruvianBill();
  final PdfService pdfService = PdfService();
  final AuthService _auth = AuthService();

  int billsAmount = 0;
  double balance = 0;

  @override
  void initState() {
    super.initState();
    getNumberOfBills();
    getData();
    getAllTransactions();
  }

  Future<void> onCountryChange(Country newCountry) async {
    setState(() {
      _currentCountry = newCountry;
    });
    await getData();
  }

  Future<void> getAllTransactions() async {
    var db = await databaseConnection.openDb();
    double totalSum = 0;
    double totalSubs = 0;

    var result = await db.query('transactions',
        where: 'userId = ?', whereArgs: [user!.uid], orderBy: 'date DESC');

    for (var transaction in result) {
      String transactionAmount =
          transaction['amount'].toString().replaceAll(',', '');
      if (transaction['type'] == 'income') {
        totalSum += double.parse(transactionAmount);
      } else if (transaction['type'] == 'expense') {
        totalSubs += double.parse(transactionAmount);
      }
    }
    setState(() {
      balance = totalSum - totalSubs;
    });
  }

  //Get echange currency
  Future<dynamic> getData() async {
    Trm trm = Trm(uri);
    dynamic response = await trm.getExchangeCurrency();

    if (mounted) {
      setState(() {
        data = response['conversion_rates'][_currentCountry.currency]
            .toStringAsFixed(2);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // your refresh logic
    getNumberOfBills();
    getAllTransactions();
  }

  //Get bills amount
  Future<void> getNumberOfBills() async {
    if (!mounted) return; // Validación inicial

    try {
      // Lanzamos las peticiones
      final ocrReceipts = await ocrService.fetchOcrReceipts();
      final resultXmls = await xmlhandler.getXmls();

      // Esta es la llamada que suele disparar el plugin conflictivo
      final resultPdfs = await pdfService.fetchAllPdfs();

      final allColombianBills = await colombianBill.getColombianBills();
      final allPeruvianBills = await peruvianBill.getPeruvianBills();

      // Verificamos de nuevo antes de actualizar el estado
      if (mounted) {
        setState(() {
          billsAmount = resultXmls.length +
              resultPdfs.length +
              allColombianBills.length +
              allPeruvianBills.length +
              ocrReceipts.length;
        });
      }
    } catch (e) {
      debugPrint("Error cargando facturas: $e");
      // Si hay un error de "Reply already submitted", aquí se captura y no rompe la app
    }
  }


  //Logout
  void logginOut() {
    _auth.logout(context);
  }

  //Logout
  void redirectDeleteAccount() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const DeleteAccountScreen()));
  }

  void redirectSettings() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }

  //Validate user information before showing QR
  Future<Map<String, String>?> getValidatedUserData() async {
    if (user == null) return null;

    try {
      // Consultamos Firestore usando el UID del Auth para encontrar su perfil
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        // Extraemos los 4 valores específicos que mencionaste
        String? name = data['displayName'] ?? user?.displayName;
        String? personalId =
            data['documentId']?.toString(); // El ID personal/cédula
        String? email = data['email'] ?? user?.email;
        String? address = data['address'];

        // Validamos que ninguno sea nulo ni esté vacío
        if (_isValid(name) &&
            _isValid(personalId) &&
            _isValid(email) &&
            _isValid(address)) {
          return {
            'displayName': name!,
            'documentId': personalId!,
            'email': email!,
            'address': address!,
          };
        }
      }
    } catch (e) {
      debugPrint("Error en validación: $e");
    }
    return null;
  }

// Función auxiliar para limpiar el código de validación
  bool _isValid(String? value) => value != null && value.trim().isNotEmpty;

  //Show user info through QR
  void _showQRCodeModal(BuildContext context, String qrData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // <--- Esto permite que el modal suba más
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          // Ajusta este valor para controlar qué tan alto llega el modal
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle visual para que el usuario sepa que puede deslizar hacia abajo
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Text(
                'Tu Código QR',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 220.0, // Aumenté un poco el tamaño
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 20),
              // Un poco de espacio extra abajo para que no choque con el borde de la pantalla
              Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 40),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 29, 29, 29),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const DrawerMenu(),
      // Cambiamos a un diseño de AppBar más limpio
      appBar: AppBar(
        elevation: 0, // Quitamos elevación para un look moderno
        backgroundColor: const Color.fromARGB(255, 29, 29, 29),
        toolbarHeight: 70, // Altura estándar controlada
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        leading: IconButton(
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          icon: const Icon(Icons.more_vert),
          color: Colors.white,
        ),
        actions: [
          FlagIcon(changeFlag: onCountryChange),
        ],
        // El bottom es lo que suele causar el estiramiento si el contenido es mucho
        bottom: PreferredSize(
          preferredSize:
              const Size.fromHeight(130), // Reducido un poco para balancear
          child: Padding(
            padding: const EdgeInsets.fromLTRB(25, 0, 25, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Evita que crezca de más
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHeaderStat("Mis facturas", billsAmount.toString()),
                    _buildHeaderStat("Cotización dolar",
                        "${_currentCountry.currency} ${NumberFormat("#,##0.00").format(double.parse(data))}"),
                  ],
                ),
                const SizedBox(height: 15),
                const Text("Balance Total",
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text(
                  "\$${NumberFormat("#,##0.00").format(balance)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: getNumberOfBills,
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child:
              DashboardContainer(), // Asegúrate que este container no tenga alturas fijas (double.infinity)
        ),
      ),
      // Usamos el widget correcto para botones flotantes con texto
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color.fromARGB(255, 29, 29, 29),
        onPressed: () async {
          final validatedData = await getValidatedUserData();

          if (validatedData != null) {
            // El contenido del QR con los 4 campos validados
            String qrContent = "Nombre: ${validatedData['displayName']}\n"
                "Documento: ${validatedData['documentId']}\n"
                "Email: ${validatedData['email']}\n"
                "Direccion: ${validatedData['address']}";

            _showQRCodeModal(context, qrContent);
          } else {
            // Recordatorio si falta información
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    "Completa tu Nombre, Documento, Email y Dirección en ajustes para compartir."),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: "COMPLETAR",
                  textColor: Colors.white,
                  onPressed: redirectSettings,
                ),
              ),
            );
          }
        },
        icon: const Icon(Icons.qr_code, color: Colors.white),
        label: const Text("Compartir datos",
            style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

Widget _buildHeaderStat(String title, String value) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  String uri = "https://v6.exchangerate-api.com/v6/b68f1074f3d7d6240f3db214/latest/USD";
  String data = "0";
  Country _currentCountry = Country(id: 1, flag: "assets/images/colombian_flag.png", name: "Colombia", currency: "COP");

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

    var result = await db.query('transactions', where: 'userId = ?', whereArgs: [user!.uid], orderBy: 'date DESC');

    for(var transaction in result) {
      String transactionAmount = transaction['amount'].toString().replaceAll(',', '');
      if(transaction['type'] == 'income') {
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

    if(mounted) {
      setState(() {
        data = response['conversion_rates'][_currentCountry.currency].toStringAsFixed(2);
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

    if(mounted) {
      var ocrReceipts = await ocrService.fetchOcrReceipts();
      var resultXmls = await xmlhandler.getXmls();
      var resultPdfs = await pdfService.fetchAllPdfs();
      var allColombianBills = await colombianBill.getColombianBills();
      var allPeruvianBills = await peruvianBill.getPeruvianBills();
      var total = await resultXmls.length + resultPdfs.length + allColombianBills.length + allPeruvianBills.length + ocrReceipts.length;

      if(mounted) {
        setState(() {
          billsAmount = total;
        });
      }
      
    }
  
  }


  //Logout
  void logginOut() {
    _auth.logout(context);
  }

  //Logout
  void redirectDeleteAccount() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const DeleteAccountScreen()));
  }

  void redirectSettings() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      key: _scaffoldKey,
      drawer: const DrawerMenu(),
      appBar: AppBar(
          elevation: 2,
          backgroundColor: const Color.fromARGB(255, 29, 29, 29),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
          ),
          leading: IconButton(onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          }, icon: Icon(Icons.more_vert), color: Colors.white,),
          actions: [
            FlagIcon(changeFlag: onCountryChange),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(150),
            child: Container(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          const Text("Mis facturas", style: TextStyle(color: Colors.white)),
                          Text(billsAmount.toString(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Column(
                        children: [
                          const Text("Cotización dolar", style: TextStyle(color: Colors.white)),
                          Text("${_currentCountry.currency} ${NumberFormat("#,##0.00").format(double.parse(data))}", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10,),
                  const Text("Balance", style: TextStyle(color: Colors.white)),
                  Text("\$${NumberFormat("#,##0.00").format(balance)}", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w600)),
                ],
              ),
            )
          ),
        ),
        body: RefreshIndicator(
          onRefresh: getNumberOfBills,
          child: const SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: DashboardContainer()
          )
        )
      );
  }
}
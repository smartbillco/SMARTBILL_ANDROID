import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smartbill/screens/cryptocurrencies/crypto_currency.dart';
import 'package:smartbill/services/crypto_provider.dart';
import 'package:smartbill/services/db.dart';
import 'package:smartbill/route_observer.dart';


class DashboardCarrousel extends StatefulWidget {
  const DashboardCarrousel({super.key});

  @override
  State<DashboardCarrousel> createState() => _DashboardCarrouselState();
}

class _DashboardCarrouselState extends State<DashboardCarrousel> with RouteAware {
  final DatabaseConnection databaseConnection = DatabaseConnection();
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  String id = FirebaseAuth.instance.currentUser!.uid;
  bool _isLoading = false;
  bool _done = false;
  List favorites = [];


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchFavorites();

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
    fetchFavorites();
  }


  Future<void> fetchFavorites() async {
    final db = await databaseConnection.openDb();
    final response = await db.query('favorites', where: 'userId = ?', whereArgs: [userId]);

    print("Favoritos: $response");

    setState(() {
      favorites = response;
    });

  }

  @override
  Widget build(BuildContext context) {

    final cryptoProvider = Provider.of<CryptoProvider>(context);

    List items = [];

    if (cryptoProvider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    for(var crypto in cryptoProvider.cryptoData) {
      for(var favorite in favorites) {
        if(crypto['id'] == favorite['cryptoId']) {
          items.add(crypto);
        }
      }
    }

    setState(() {
      _done = true;
    });
    

    return _isLoading 
    ? Center(child: CircularProgressIndicator())
    : _done && items.isEmpty
    ? Text("Todavía no tienes criptomonedas favoritas...")
    : Column(
      spacing: 4,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Tus criptomonedas", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        SizedBox(
          height: 90,
          child: PageView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              return Card(
                elevation: 6,
                child: ListTile(
                    leading: Image.network(items[index]['image'], width: 40, height: 40),
                    title: Text('${items[index]['name']} (${items[index]['symbol']})', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),),
                    subtitle: Text(NumberFormat("#,##0.00").format(items[index]['current_price']), style: TextStyle(fontSize: 16)),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => CryptoListScreen()));
                    },
                  
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
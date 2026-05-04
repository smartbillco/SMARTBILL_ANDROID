import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smartbill/screens/cryptocurrencies/crypto_currency.dart';
import 'package:smartbill/providers/crypto_provider.dart'; // Asegúrate que la ruta sea correcta

class DashboardCarrousel extends StatelessWidget {
  const DashboardCarrousel({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos los cambios del provider
    final cryptoProvider = context.watch<CryptoProvider>();

    if (cryptoProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filtramos las criptos que están marcadas como favoritas en el provider
    final favoriteItems = cryptoProvider.cryptos
        .where((crypto) => cryptoProvider.favoriteIds.contains(crypto.id))
        .toList();

    if (favoriteItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text("Todavía no tienes criptomonedas favoritas...", 
          style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Tus criptomonedas", 
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: PageView.builder(
            itemCount: favoriteItems.length,
            itemBuilder: (context, index) {
              final crypto = favoriteItems[index];
              
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: ListTile(
                    leading: Image.network(crypto.image, width: 40, height: 40),
                    title: Text(
                      '${crypto.name} (${crypto.symbol.toUpperCase()})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      NumberFormat("#,##0.00").format(crypto.price),
                      style: const TextStyle(fontSize: 14),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CryptoListScreen()),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
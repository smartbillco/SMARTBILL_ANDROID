import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/crypto_provider.dart'; // Import your provider

class CryptoListScreen extends StatelessWidget {
  const CryptoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch the provider for changes
    final cryptoProvider = context.watch<CryptoProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Criptomonedas')),
      body: cryptoProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 20),
                const Text("Top 10 de Criptomonedas", 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
                const SizedBox(height: 50),
                Expanded(
                  child: ListView.builder(
                    itemCount: cryptoProvider.cryptos.length,
                    itemBuilder: (context, index) {
                      final crypto = cryptoProvider.cryptos[index];
                      final isFavorite = cryptoProvider.favoriteIds.contains(crypto.id);

                      return ListTile(
                        leading: Image.network(crypto.image, width: 32, height: 32),
                        title: Text('${crypto.name} (${crypto.symbol.toUpperCase()})'),
                        subtitle: Text(NumberFormat("#,##0.00").format(crypto.price)),
                        trailing: Icon(
                          isFavorite ? Icons.star : Icons.star_border,
                          color: isFavorite ? Colors.amber : null,
                        ),
                        onTap: () => cryptoProvider.toggleFavorite(crypto.id),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
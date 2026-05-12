import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartbill/providers/crypto_provider.dart';
import 'package:smartbill/providers/download_provider.dart';
import 'package:smartbill/services/auth.dart';
import 'package:smartbill/services/settings.dart';
import 'package:smartbill/screens/splash/splash.dart';
import './route_observer.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider.value(
          value: AuthService().user,
          initialData: null,
          catchError: (_, __) => null,
        ),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(
            create: (_) => CryptoProvider()..initializeData()),
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
      ],
      child: MaterialApp(
        navigatorObservers: <NavigatorObserver>[routeObserver],
        debugShowCheckedModeBanner: false,
        title: 'Smartbill',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
          useMaterial3: true,
        ),
        builder: (context, child) {
          return Stack(
            children: [
              child!,
              const GlobalDownloadOverlay(),
            ],
          );
        },
        home: const SplashScreen(),
      ),
    );
  }
}

class GlobalDownloadOverlay extends StatelessWidget {

  const GlobalDownloadOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadProvider>(
      builder: (context, provider, _) {
        if (!provider.isDownloading) return const SizedBox.shrink();

        bool isResult = provider.message.contains("¡") ||
            provider.message.contains("No") ||
            provider.message.contains("Error");

        double bottomGap = MediaQuery.of(context).padding.bottom + 80;

        return Positioned(
          bottom: bottomGap,
          left: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isResult
                    ? (provider.isSuccess ? Colors.green[800] : Colors.red[900])
                    : Colors.black.withOpacity(0.9),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Row(
                children: [
                  if (!isResult)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    Icon(
                      provider.isSuccess ? Icons.check_circle : Icons.error,
                      color: Colors.white,
                      size: 20,
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      provider.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

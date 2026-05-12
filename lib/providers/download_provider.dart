import 'package:flutter/material.dart';

class DownloadProvider extends ChangeNotifier {
  bool _isDownloading = false;
  String _message = "";
  bool _isSuccess = true;

  bool get isDownloading => _isDownloading;
  String get message => _message;
  bool get isSuccess => _isSuccess;

  void startDownload(String name) {
    _isDownloading = true;
    _isSuccess = true; // Reset state
    _message = "Descargando $name...";
    notifyListeners();
  }

  void showResult(String msg, bool success) {
    _message = msg;
    _isSuccess = success;
    _isDownloading = true; // Keep visible to show the message
    notifyListeners();

    // Auto-hide after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _isDownloading = false;
      notifyListeners();
    });
  }

  void stopDownload() {
    _isDownloading = false;
    notifyListeners();
  }
}
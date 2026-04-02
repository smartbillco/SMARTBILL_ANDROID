import 'package:flutter/material.dart';
import 'package:smartbill/models/dian_receipts.dart';
import 'package:smartbill/services/dianReceiptService.dart';

class ReceiptsProvider extends ChangeNotifier{

  bool _isLoading = false;
  Receipt? _receipt;
  DianReceiptService receiptService = DianReceiptService();

  Receipt? get receipt => _receipt;
  bool get isLoading => _isLoading;

}
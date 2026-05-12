import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartbill/screens/receipts/bill_detail_screen.dart';
import 'package:smartbill/screens/receipts/cufe_detail_screen.dart';
import 'package:smartbill/screens/receipts/receipt_widgets/delete_dialog.dart';
import 'package:smartbill/screens/receipts/receipt_widgets/total_sum.dart';
import 'package:smartbill/services/colombian_bill.dart';
import 'package:smartbill/services/ocr_receipts.dart';
import 'package:smartbill/services/pdf_reader.dart';
import 'package:smartbill/services/peruvian_bill.dart';
import 'package:smartbill/services/xml/xml.dart';
import 'package:smartbill/services/xml/xml_colombia.dart';
import 'package:smartbill/services/xml/xml_panama.dart';
import 'package:smartbill/services/xml/xml_peru.dart';
import 'package:xml/xml.dart';

class MyReceiptsPage extends StatefulWidget {
  const MyReceiptsPage({super.key});

  @override
  State<MyReceiptsPage> createState() => _MyReceiptsPageState();
}

class _MyReceiptsPageState extends State<MyReceiptsPage> {
  List<File> _cufesImages = [];

  final ColombianBill colombianBill = ColombianBill();
  final PeruvianBill peruvianBill = PeruvianBill();
  final OcrReceiptsService ocrService = OcrReceiptsService();
  final XmlColombia xmlColombia = XmlColombia();
  final XmlPeru xmlPeru = XmlPeru();
  final XmlPanama xmlPanama = XmlPanama();
  final Xmlhandler xmlhandler = Xmlhandler();
  final PdfService pdfService = PdfService();

  double totalColombia = 0;
  double totalPeru = 0;
  double totalPanama = 0;
  List<dynamic> _fileContent = [];
  List<String> companies = ['Todas las empresas'];
  String? selectedValue;
  List<dynamic> filteredReceipts = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // Sequence initialization to prevent race conditions
  Future<void> _loadAllData() async {
    await getReceipts();
    await fetchAllCompanies();
    await loadCufesImages();
  }

  Future<void> loadCufesImages() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String folderPath = path.join(appDir.path, 'cufes');
      final Directory cufesDir = Directory(folderPath);

      if (await cufesDir.exists()) {
        final List<FileSystemEntity> entities = cufesDir.listSync();
        if (mounted) {
          setState(() {
            _cufesImages = entities.whereType<File>().toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error cargando imágenes: $e");
    }
  }

  Future<void> getReceipts() async {
    var ocrReceipts = await ocrService.fetchOcrReceipts();
    var xmlFiles = await xmlhandler.getXmls();
    var pdfFiles = await pdfService.fetchAllPdfs();
    List myFiles = [];
    double totalPaidColombia = 0;
    double totalPaidPeru = 0;
    double totalPaidPanama = 0;

    for (var item in ocrReceipts) {
      totalPaidColombia += double.parse(item['price']);
      myFiles.add(item);
    }

    for (var item in xmlFiles) {
      XmlDocument xmlDocument = XmlDocument.parse(item['xml_text']);
      Map parsedDoc = xmlhandler.xmlToMap(xmlDocument.rootElement);

      if (xmlDocument.findAllElements('cac:Signature').isNotEmpty) {
        final Map newPeruvianXml = xmlPeru.parsePeruvianXml(item['_id'], parsedDoc, xmlDocument);
        totalPaidPeru += double.parse(newPeruvianXml['price']);
        myFiles.add(newPeruvianXml);
      } else if (xmlDocument.findAllElements('rFE').isNotEmpty) {
        final Map newPanamanianXml = xmlPanama.parsedPanamaXml(item['_id'], xmlDocument);
        totalPaidPanama += double.parse(newPanamanianXml['price']);
        myFiles.add(newPanamanianXml);
      } else {
        final String cDataContent = xmlColombia.extractCData(xmlDocument);
        final XmlDocument xmlCData = xmlColombia.parseCDataToXml(cDataContent);
        final Map newColombianXml = xmlColombia.parseColombianXml(item['_id'], parsedDoc, xmlCData);
        totalPaidColombia += double.parse(newColombianXml['price']);
        myFiles.add(newColombianXml);
      }
    }

    for (var item in pdfFiles) {
      Map<String, dynamic> newPdf = {
        '_id': item['_id'],
        'id_bill': item['cufe'],
        'customer': item['customer_id'] ?? 'Consumidor final',
        'customer_id': 'Factura PDF',
        'company': item['company_name'],
        'company_id': item['nit'],
        'price': item['total_amount'].toString(),
        'cufe': item['cufe'],
        'date': item['date'],
        'currency': 'PDF'
      };
      totalPaidColombia += item['total_amount'];
      myFiles.add(newPdf);
    }

    var bills = await colombianBill.getColombianBills();
    for (var bill in bills) {
      Map newMap = colombianBill.parseColombianBills(bill);
      totalPaidColombia += double.parse(newMap['price']);
      myFiles.add(newMap);
    }

    var peruBills = await peruvianBill.getPeruvianBills();
    for (var bill in peruBills) {
      Map newMap = peruvianBill.parsePeruvianBills(bill);
      totalPaidPeru += double.parse(newMap['price']);
      myFiles.add(newMap);
    }

    if (mounted) {
      setState(() {
        _fileContent = myFiles;
        filteredReceipts = myFiles;
        totalColombia = totalPaidColombia;
        totalPeru = totalPaidPeru;
        totalPanama = totalPaidPanama;
      });
    }
  }

  Future<void> fetchAllCompanies() async {
    // Artificial delay for UI smoothness
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    List<String> myCompanies = _fileContent
        .map((bill) => bill['company']?.toString().trim() ?? '')
        .where((company) => company.isNotEmpty)
        .map((company) => company.toUpperCase())
        .toSet()
        .toList();

    if (mounted) {
      setState(() {
        companies = ['Todas las empresas', ...myCompanies];
      });
    }
  }

  void filterReceipts(String value) {
    List<dynamic> results = [];
    if (value == 'Todas las empresas') {
      results = _fileContent;
    } else {
      results = _fileContent
          .where((bill) => bill['company']?.toString().toUpperCase() == value)
          .toList();
    }

    double totalPrice = results.fold(0.0, (sum, bill) {
      return sum + (double.tryParse(bill['price']?.toString() ?? '0') ?? 0.0);
    });

    setState(() {
      filteredReceipts = results;
      totalColombia = totalPrice;
      totalPanama = totalPrice;
      totalPeru = totalPrice;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TotalSumWidget(
              totalColombia: totalColombia,
              totalPeru: totalPeru,
              totalPanama: totalPanama,
            ),
            const SizedBox(height: 20),
            companies.length <= 1
                ? const Text(
                    "No hay compañias todavia...",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                  )
                : DropdownButton<String>(
                    value: selectedValue,
                    hint: const Text('Buscar por compañia'),
                    isExpanded: true,
                    items: companies.map((value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        filterReceipts(value);
                        setState(() {
                          selectedValue = value;
                        });
                      }
                    },
                  ),
            const SizedBox(height: 14),
            filteredReceipts.isNotEmpty
                ? ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(7),
                    itemCount: filteredReceipts.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
                        child: Material(
                          borderRadius: const BorderRadius.all(Radius.circular(10)),
                          elevation: 12,
                          shadowColor: const Color.fromARGB(255, 185, 185, 185),
                          child: ListReceipts(
                            fileContent: filteredReceipts,
                            index: index,
                            getReceipts: getReceipts,
                          ),
                        ),
                      );
                    },
                  )
                : const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text("No hay archivos todavia...", style: TextStyle(fontSize: 18))),
                  ),
            const SizedBox(height: 20),
            const Text(
              "Tus CUFE: ",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            _cufesImages.isEmpty
                ? const Text("No hay imagenes de CUFE guardadas.", style: TextStyle(color: Colors.grey))
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _cufesImages.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () async {
                          final bool? wasDeleted = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CufesDetailScreen(imageFile: _cufesImages[index]),
                            ),
                          );

                          if (wasDeleted == true) {
                            await loadCufesImages();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Imagen eliminada")),
                              );
                            }
                          }
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Hero(
                            tag: _cufesImages[index].path,
                            child: Image.file(
                              _cufesImages[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

class ListReceipts extends StatelessWidget {
  final List<dynamic> fileContent;
  final int index;
  final Function getReceipts;

  const ListReceipts({
    super.key,
    required this.fileContent,
    required this.index,
    required this.getReceipts,
  });

  void redirectToBillDetail(BuildContext context, Map receipt) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => BillDetailScreen(receipt: receipt)));
  }

  @override
  Widget build(BuildContext context) {
    final receipt = fileContent[index];
    final String company = receipt['company'] ?? "Razon social";

    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      onTap: () => redirectToBillDetail(context, receipt),
      contentPadding: const EdgeInsets.fromLTRB(10, 5, 5, 3),
      tileColor: const Color.fromARGB(244, 238, 238, 238),
      title: Text(receipt['customer'] ?? 'Consumidor', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            company.length > 40 ? "${company.substring(0, 40)}..." : company,
            style: const TextStyle(fontSize: 15),
          ),
          Text(receipt['company_id'] ?? '', style: const TextStyle(fontSize: 15)),
          Text(
            "Valor: ${NumberFormat('#,##0.00', 'en_US').format(double.parse(receipt['price'] ?? '0'))}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      trailing: IconButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => DeleteDialogWidget(
              item: receipt,
              func: getReceipts,
            ),
          );
        },
        icon: const Icon(Icons.delete, size: 25, color: Colors.redAccent),
      ),
    );
  }
}
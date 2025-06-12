import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartbill/screens/receipts.dart/receipt_modal.dart';
import 'package:smartbill/screens/receipts.dart/receipt_widgets/delete_dialog.dart';
import 'package:smartbill/screens/receipts.dart/receipt_widgets/searchbar.dart';
import 'package:smartbill/screens/receipts.dart/receipt_widgets/total_sum.dart';
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
  //Colombian and peruvian bills stored in database
  final ColombianBill colombianBill = ColombianBill();
  final PeruvianBill peruvianBill = PeruvianBill();

  //Handle of XML stored
  final OcrReceiptsService ocrService = OcrReceiptsService();
  final XmlColombia xmlColombia = XmlColombia();
  final XmlPeru xmlPeru = XmlPeru();
  final XmlPanama xmlPanama = XmlPanama();
  final Xmlhandler xmlhandler = Xmlhandler();
  final PdfService pdfService = PdfService();

  //Handling sums
  double totalColombia = 0;
  double totalPeru = 0;
  double totalPanama = 0;
  List<dynamic> _fileContent = [];
  List<String> companies = ['Todas las empresas'];
  String? selectedValue;
  List<dynamic> filteredReceipts = [];


  //Initstate
  @override
  void initState() {
    super.initState();
    getReceipts();
    fetchAllCompanies();
  }



  //Get all XML files from sqlite
  void getReceipts() async {
    var ocrReceipts = await ocrService.fetchOcrReceipts();
    var xmlFiles = await xmlhandler.getXmls();
    var pdfFiles = await pdfService.fetchAllPdfs();
    List myFiles = [];
    double totalPaidColombia = 0;
    double totalPaidPeru = 0;
    double totalPaidPanama = 0;

    for(var item in ocrReceipts) {
      totalPaidColombia += double.parse(item['price']);
      myFiles.add(item);
    }


    for (var item in xmlFiles) {

      XmlDocument xmlDocument = XmlDocument.parse(item['xml_text']);

      Map parsedDoc = xmlhandler.xmlToMap(xmlDocument.rootElement);

      if(xmlDocument.findAllElements('cac:Signature').isNotEmpty) {
        //Peru logic
        final Map newPeruvianXml = xmlPeru.parsePeruvianXml(item['_id'], parsedDoc, xmlDocument);

        totalPaidPeru += double.parse(newPeruvianXml['price']);

        myFiles.add(newPeruvianXml);

      } else if(xmlDocument.findAllElements('rFE').isNotEmpty) {

        final Map newPanamanianXml = xmlPanama.parsedPanamaXml(item['_id'], xmlDocument);


        totalPaidPanama += double.parse(newPanamanianXml['price']);

        myFiles.add(newPanamanianXml);

      } else {

        //Colombian logic
        final String cDataContent = xmlColombia.extractCData(xmlDocument);

        final XmlDocument xmlCData = xmlColombia.parseCDataToXml(cDataContent);

        final Map newColombianXml = xmlColombia.parseColombianXml(item['_id'], parsedDoc, xmlCData);

        totalPaidColombia += double.parse(newColombianXml['price']);

        myFiles.add(newColombianXml);

        
      }
      
    }

    for(var item in pdfFiles) {

      Map<String, dynamic> newPdf = {
        '_id': item['_id'],
        'id_bill': item['cufe'],
        'customer': 'Consumidor final',
        'customer_id': 'Factura PDF',
        'company': item['nit'],
        'company_id': item['nit'],
        'price': item['total_amount'].toString(),
        'cufe': item['cufe'],
        'date': item['date'],
        'currency': 'PDF'
      };

      totalPaidColombia += item['total_amount'];

      myFiles.add(newPdf);

    }

    //Get colombian bills saved in database
    var bills = await colombianBill.getColombianBills();
    for(var bill in bills) {
      Map newMap = colombianBill.parseColombianBills(bill);
      totalPaidColombia += double.parse(newMap['price']);
      myFiles.add(newMap);
      
    }

    var peruBills = await peruvianBill.getPeruvianBills();
    for(var bill in peruBills) {
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


  //Get all the companies
  Future<void> fetchAllCompanies() async {

    Future.delayed(Duration(milliseconds: 1000), () {
      List<String> myCompanies = [];
      _fileContent.forEach((bill) {
        myCompanies.add(bill['company']);
      });

      setState(() {
        companies.addAll(myCompanies);
      });

      print("Companies: $companies");
    });

  }

  void filterReceipts(String value) {
    
      if(value == 'Todas las empresas') {
        filteredReceipts = _fileContent;
      } else {
        filteredReceipts = _fileContent
        .where((bill) => bill['company'].contains(value))
        .toList();
      }

      double totalPrice = filteredReceipts.fold(0.0, (sum, bill) {
        return sum + double.tryParse(bill['price'] ?? '0')!;
      });

      setState(() {
        totalColombia = totalPrice;
        totalPanama = totalPrice;
        totalPeru = totalPrice;
      });

      
    }
      

  //Receipts screens
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 42),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TotalSumWidget(totalColombia: totalColombia, totalPeru: totalPeru, totalPanama: totalPanama),
            const SizedBox(height: 18),
            
            companies.isEmpty
            ? Text("No hay compañias todavia...", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),)
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
                filterReceipts(value!);
                setState(() {
                  selectedValue = value;
                });
              },
            ),

            const SizedBox(height: 14),
            Expanded(
              child: _fileContent.isNotEmpty
                  ? ListView.builder(
                    padding: const EdgeInsets.all(7),
                      itemCount: filteredReceipts.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 0),
                          child: Material(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(10)),
                            elevation: 12,
                            shadowColor: const Color.fromARGB(255, 185, 185, 185),
                            child: ListReceipts(fileContent: filteredReceipts, index: index, getReceipts: getReceipts,)
                          ),
                        );
                      },
                    )
                  : const Text("No hay archivos todavia...", style:TextStyle(fontSize: 18, fontWeight: FontWeight.w400)),
            ),
        ]),
      );
  }
}



//Tiles for the receipts
class ListReceipts extends StatefulWidget {
  final dynamic fileContent;
  final int index;
  final Function getReceipts;
  const ListReceipts({super.key, required this.fileContent, required this.index, required this.getReceipts});

  @override
  State<ListReceipts> createState() => _ListReceiptsState();
}

class _ListReceiptsState extends State<ListReceipts> {

  void redirectToBillDetail(Map receipt) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => BillDetailScreen(receipt: receipt)));
  }


  @override
  void initState() {
    super.initState();
  } 

  @override
  Widget build(BuildContext context) {

    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), // Rounded corners
      ),
      onTap: () => redirectToBillDetail(widget.fileContent[widget.index]),
      contentPadding: const EdgeInsets.fromLTRB(10, 5, 5, 3),
      tileColor: const Color.fromARGB(244, 238, 238, 238),
      title: Text(widget.fileContent[widget.index]['customer'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.fileContent[widget.index]['company'].length > 25 ? widget.fileContent[widget.index]['company'].substring(0,25) : widget.fileContent[widget.index]['company'], style: const TextStyle(fontSize: 15)),
          Text(widget.fileContent[widget.index]['company_id'], style: const TextStyle(fontSize: 15)),
          Text("Valor: ${NumberFormat('#,##0.00', 'en_US').format(double.parse(widget.fileContent[widget.index]['price']))}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]
      ),
      trailing:  IconButton(
         onPressed: () {
           showDialog(
             context: context,
             builder: (_) => DeleteDialogWidget(
              item: widget.fileContent[widget.index],
              func: widget.getReceipts)); 
          },
          icon: const Icon(Icons.delete, size: 25, color: Colors.redAccent)),

    );
  }
}
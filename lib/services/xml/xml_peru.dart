import 'package:smartbill/services/xml/xml.dart';
import 'package:xml/xml.dart';


class XmlPeru extends Xmlhandler {

  String parseCData(XmlDocument xmlDocument, String search) {
    final cDataContent = xmlDocument.findAllElements(search)
      .toList()
      .last
      .innerText;

    print(cDataContent);

    return cDataContent;

  }


  Map <String, dynamic> parsePeruvianXml(dynamic id, Map parsedDoc, XmlDocument xmlDocument) {
    final customer = parseCData(xmlDocument, 'cbc:RegistrationName');
    final company = parseCData(xmlDocument, 'cbc:Name');

    Map <String, dynamic> newXml = {
        '_id': id,
        'id_bill': parsedDoc['cbc:ID']['text'],
        'customer': customer,
        'customer_id': parsedDoc['cac:AccountingSupplierParty']['cac:Party']['cac:PartyIdentification']['cbc:ID']['text'],
        'company': company,
        'company_id': parsedDoc['cac:AccountingSupplierParty']['cac:Party']['cac:PartyIdentification']['cbc:ID']['text'],
        'price': parsedDoc['cac:LegalMonetaryTotal']['cbc:PayableAmount']['text'],
        'cufe': parsedDoc['cac:Signature']['cbc:ID']['text'],
        'date': parsedDoc['cbc:IssueDate']['text'],
        'currency': 'PEN'
    };

    return newXml;

  }

}
import 'dart:io';
import 'package:xml/xml.dart';
import '../db.dart';

class Xmlhandler {
  Map<String, dynamic> xmlToMap(XmlElement element) {
    final Map<String, dynamic> map = {};

    // If the element has attributes, add them to the map
    for (var attribute in element.attributes) {
      map[attribute.name.toString()] = attribute.value;
    }

    // Add children or text content
    for (final node in element.children) {
      if (node is XmlElement) {
        // Recursive call for nested elements
        map[node.name.toString()] = xmlToMap(node);
      } else if (node is XmlText && node.value.trim().isNotEmpty) {
        map['text'] = node.value.trim();
      }
    }

    return map;
  }

  Future<Map<String, dynamic>> getXml(String pathFile) async {
    try {
      File file = File(pathFile);
      String fileData = await file.readAsString();
      final xmlDocument = XmlDocument.parse(fileData);

      // 1. Detectar el nodo raíz (manejando AttachedDocument de la DIAN)
      XmlElement rootElement = xmlDocument.rootElement;
      String rootName = rootElement.name.local;

      if (rootName == 'AttachedDocument') {
        try {
          final attachment =
              xmlDocument.findAllElements('cbc:Description').first.innerText;
          if (attachment.contains('<Invoice')) {
            rootElement = XmlDocument.parse(attachment).rootElement;
            rootName = rootElement.name.local;
          }
        } catch (e) {
          return {
            "success": false,
            "error": "El contenedor no incluye una factura válida."
          };
        }
      }

      // 2. Validación estricta de tipos UBL 2.1 (Colombia, Perú, Panamá)
      List<String> validTypes = ['Invoice', 'CreditNote', 'DebitNote'];
      if (!validTypes.contains(rootName)) {
        return {
          "success": false,
          "error": "El archivo no es una Factura Electrónica reconocida."
        };
      }

      // 3. SI ES VÁLIDO: Guardar en la base de datos
      await insertXml(xmlDocument.toString());

      // 4. Mapear y retornar éxito
      Map<String, dynamic> parsedMap = xmlToMap(rootElement);
      parsedMap["success"] = true;
      return parsedMap;
    } catch (e) {
      return {"success": false, "error": "No se pudo leer el archivo XML."};
    }
  }

  Future insertXml(String xml) async {
    DatabaseConnection databaseConnection = DatabaseConnection();
    var db = await databaseConnection.openDb();
    var result = await db.insert('xml_files', {'xml_text': xml});
    return result;
  }

  Future getXmls() async {
    DatabaseConnection databaseConnection = DatabaseConnection();
    var db = await databaseConnection.openDb();
    var xmlFiles = await db.query('xml_files');
    return xmlFiles;
  }

  Future<void> deleteXml(int id) async {
    DatabaseConnection databaseConnection = DatabaseConnection();
    var db = await databaseConnection.openDb();

    await db.delete('xml_files', where: '_id = ?', whereArgs: [id]);
  }
}

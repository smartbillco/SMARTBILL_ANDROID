import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smartbill/screens/dashboard/display_image.dart';
import 'package:smartbill/services/camera.dart';
import 'package:smartbill/services/crop_image.dart';
import 'package:smartbill/services/pdf_reader.dart';
import 'package:smartbill/screens/receipts.dart/receipt_screen.dart';
import 'package:smartbill/services/xml/xml.dart';

class AddBillChoice extends StatefulWidget {
  const AddBillChoice({super.key});

  @override
  State<AddBillChoice> createState() => _AddBillChoiceState();
}

class _AddBillChoiceState extends State<AddBillChoice> {
  final CropImageService cropImageService = CropImageService();
  final Xmlhandler xmlhandler = Xmlhandler();
  final PdfService pdfService = PdfService();
  final Camera cameraService = Camera();


  //Snackbar for receipt cancel
  //Cancelled picking a xml file
  void _showSnackbarCancelXml() {
    var snackbar = const SnackBar(
      content: Text("No elegiste una factura"),
      duration: Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }



  //Open files and save and display a new XML
  Future<void> _pickAndDisplayXMLFile() async {
    FilePickerResult? fileResult = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xml']);

    if (fileResult != null) {

      String filePath = fileResult.files.single.path!;
      String fileName = fileResult.files.single.name.toLowerCase();

       if (fileName.endsWith('.xml')) {
        await xmlhandler.getXml(filePath);

        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const ReceiptScreen()));
      }
    } else {
      print("Se canceló");
      _showSnackbarCancelXml();
    }
  }

  //Open files and save and display a new XML
  Future<void> _pickAndDisplayPDFFile() async {
    FilePickerResult? fileResult = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);

    //Send pdf to backend
    if (fileResult != null) {
       String filePath = fileResult.files.single.path!;

      try {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Subiendo PDF..."), duration: Duration(seconds: 3),));

        //Save whole PDF locally
        final dir = Platform.isAndroid ?  await getExternalStorageDirectory() : await getApplicationDocumentsDirectory(); 
        final savePath = "${dir!.path}/pdfs";
        final dirPath = Directory(savePath);

        if(!await dirPath.exists()) {
          await Directory(savePath).create(recursive: true);
        }
        File pdfFile = File(filePath);

        //Send PDF to backend
        final cufe = await pdfService.saveExtractedText(pdfFile);

        File savedFile = File("${dirPath.path}/$cufe");
        await pdfFile.copy(savedFile.path);
        print("✅ PDF saved at: ${savedFile.path}");

        Future.delayed(const Duration(seconds: 4), () {
          if(mounted) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const ReceiptScreen()));
          }
        });

      } catch(e) {

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("La factura ya existe, o hubo un error cargandola. Intente con otra factura.")));

        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const ReceiptScreen()));
      }
      
      
    } else {
      print("Se cancelo");
      _showSnackbarCancelXml();
    }
  }


  //Pick and crop from gallery
  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);

    if(pickedImage != null) {
      final image = File(pickedImage.path);

      final String recognizedText = await cameraService.extractTextFromImage(pickedImage as XFile?);

      final File croppedImage = await cropImageService.cropImage(image);

      print(croppedImage.path);


      if(recognizedText == 'error') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Parece que la imagen no contiene información completa o no es una factura")));
        Navigator.pop(context);
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DisplayImageScreen(image: croppedImage, recognizedText: recognizedText)));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DisplayImageScreen(image: croppedImage, recognizedText: recognizedText)));

      }

      
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se selecciono imagen")));
    }

  }


  //Take and crop picture
  void _takePicture() async {

    final ImagePicker picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.camera);
    
    final String recognizedText = await cameraService.extractTextFromImage(pickedImage);
    
    File image = File(pickedImage!.path);

    final croppedImage = await cropImageService.cropImage(image);

    if(recognizedText == 'error') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Parece que la imagen no contiene información completa o no es una factura")));
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DisplayImageScreen(image: croppedImage, recognizedText: recognizedText)));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DisplayImageScreen(image: croppedImage, recognizedText: recognizedText)));

    }
    
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agregar factura"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                onTap: _pickAndDisplayXMLFile,
                contentPadding: const EdgeInsets.all(10),
                leading: const Icon(Icons.code, color: Colors.orange, size: 28),
                title: const Text("Subir archivo XML"),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              ),
            ),
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                onTap: _pickAndDisplayPDFFile,
                contentPadding: const EdgeInsets.all(10),
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 28),
                title: const Text("Subir archivo PDF"),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              ),
            ),

            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                onTap: _pickImage,
                contentPadding: const EdgeInsets.all(10),
                leading: const Icon(Icons.image, color: Colors.green, size: 28),
                title: const Text("Subir imagen de factura"),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              ),
            ),

            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                onTap: _takePicture,
                contentPadding: const EdgeInsets.all(10),
                leading: const Icon(Icons.camera_alt, color: Colors.teal, size: 28),
                title: const Text("Tomar foto  de factura"),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              ),
            )
          ],
        ) 
      ),
    );
  }
}
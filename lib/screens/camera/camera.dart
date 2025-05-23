import 'package:flutter/material.dart';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartbill/screens/dashboard/display_image.dart';
import 'package:smartbill/services/camera.dart';

class CameraShotScreen extends StatefulWidget {
  const CameraShotScreen({super.key});

  @override
  State<CameraShotScreen> createState() => _CameraShotScreenState();
}

class _CameraShotScreenState extends State<CameraShotScreen> {
  late List<CameraDescription> _cameras;
  Camera cameraService = Camera();
  CameraController? _controller;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(_cameras[0], ResolutionPreset.high);
    await _controller!.initialize();
    setState(() {});
  }

  Future<void> _takePicture() async {

    final ImagePicker picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.camera);
    
    final String recognizedText = await cameraService.extractTextFromImage(pickedImage);
    
    File image = File(pickedImage!.path);

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DisplayImageScreen(image: image, recognizedText: recognizedText)));
    
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Stack(
        children: [
          // This makes sure the preview stretches to the full screen
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.previewSize!.height,
                height: _controller!.value.previewSize!.width,
                child: CameraPreview(_controller!),
              ),
            ),
          ), 
          if (_imageFile != null)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.file(
                  File(_imageFile!.path),
                  width: 100,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 45),
              child: FloatingActionButton(
                onPressed: _takePicture,
                backgroundColor: Colors.white,
                child: const Icon(Icons.camera, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
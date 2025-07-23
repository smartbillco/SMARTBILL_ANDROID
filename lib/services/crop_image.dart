
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

class CropImageService {


  Future<File?> cropImage(File image) async {

    try {

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recortar imagen',
            toolbarColor: Colors.black,              // dark background
            toolbarWidgetColor: Colors.white,        // white icons and text
            backgroundColor: Colors.black,           // crop background
            statusBarColor: Colors.black,            // dark status bar
            activeControlsWidgetColor: Colors.teal,  // highlight color
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Recortar imagen',
            aspectRatioLockEnabled: false,         // ✅ allows freeform crop
            rotateButtonsHidden: false,            
            rotateClockwiseButtonHidden: false,    
            resetButtonHidden: false,              
            aspectRatioPickerButtonHidden: false,
          )
        ],
      );

      return File(croppedFile!.path);

    } catch(e) {
      return null;
    }

    

  }

}
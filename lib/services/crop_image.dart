
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

class CropImageService {


  Future<File> cropImage(File image) async {

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      compressQuality: 85,
      aspectRatio: const CropAspectRatio(ratioX: 0.2, ratioY: 0.2),
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
          aspectRatioLockEnabled: false,
          rotateButtonsHidden: false,
          resetButtonHidden: false,
          // iOS respects system dark mode; no color customization needed
        )
      ],
    );

    return File(croppedFile!.path);

  }

}
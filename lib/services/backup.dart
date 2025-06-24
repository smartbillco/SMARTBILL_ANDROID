import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:smartbill/services/db.dart';

class BackupService {

  late Directory backupDir;
  DatabaseConnection databaseConnection =  DatabaseConnection();


  Future<String> saveDianPdfs(BuildContext context) async {
    final dPath = Platform.isAndroid ?  await getExternalStorageDirectory() : await getApplicationDocumentsDirectory();
    final dirPath = "${dPath!.path}/invoices";
    final dir = Directory(dirPath);

    try {

        //Fetch download or documents folder for smartbill
        if (Platform.isAndroid) {
          backupDir = Directory("/storage/emulated/0/Download/smartbill");
        } else if (Platform.isIOS) {
          final docsDir = await getApplicationDocumentsDirectory();
          backupDir = Directory("${docsDir.path}/smartbill");
        }

        //If the smartbill folder doesn't exist, creates it
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
          print("Created backup folder at ${backupDir.path}");
        } 

        if(!await dir.exists()) {
          return "empty folder";
        }

        final List<FileSystemEntity> dianFiles = dir.listSync();
        for (var file in dianFiles) {
          if (file is File && file.path.toLowerCase().endsWith('.pdf')) {
            final fileName = p.basename(file.path);
            final newPath = p.join(backupDir.path, fileName);
            await file.copy(newPath);
            print("Copied $fileName to backup folder.");
          }
        }

      return "success";

    } catch(e) {
      return "Error: $e";
    }

  }

  Future<String> saveXmlBackup() async {

    try {
      final db = await databaseConnection.openDb();
      final xmlFiles = await db.query('xml_files');

      //Fetch download or documents folder for smartbill
      if (Platform.isAndroid) {
        backupDir = Directory("/storage/emulated/0/Download/smartbill");
      } else if (Platform.isIOS) {
        final docsDir = await getApplicationDocumentsDirectory();
        backupDir = Directory("${docsDir.path}/smartbill");
      }

        //If the smartbill folder doesn't exist, creates it
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
        print("Created backup folder at ${backupDir.path}");
      } 

      if(xmlFiles.length > 0 ) {
        for(int i = 1; i <= xmlFiles.length; i++) {
          final String fileName = "backup_$i";
          File file = File('${backupDir.path}/$fileName.xml');
          await file.writeAsString(xmlFiles[i]['xml_text']);
          print("Done!");

        }

        return "success";
      }

      return "no data";

      

    } catch (e) {
      print("Error: $e");
      return "Error: $e";
    }
    
  }

}
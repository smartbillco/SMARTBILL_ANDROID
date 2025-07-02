import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smartbill/services/db.dart';
import 'package:sqflite/sqflite.dart';

class BackupService {
  late Directory backupDir;
  DatabaseConnection databaseConnection = DatabaseConnection();

  Future<void> initBackupDir() async {

    //If the smartbill folder doesn't exist, creates it
    if (Platform.isAndroid) {
      backupDir = Directory("/storage/emulated/0/Download/smartbill");
    } else if (Platform.isIOS) {
      final docsDir = await getApplicationDocumentsDirectory();
      backupDir = Directory("${docsDir.path}/smartbill");
    }

    //check if backup folder exists
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
      print("Created backup folder at ${backupDir.path}");
    } else {
      print("Backup dir already existed");
    }
    
  }


  Future<String> saveDianPdfsBackup() async {
    final dPath = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    final dirPath = "${dPath!.path}/invoices";
    final dir = Directory(dirPath);
    await initBackupDir();

    try {
      

      //Check if folder containing pdf exists if not create
      if (!await dir.exists()) {
        await dir.create(recursive: true);
        print("Created backup folder at ${dir.path}");
      }

      final contents = dir.listSync();

      if (!await dir.exists() || contents.isEmpty) {
        return "folder vacio";
      }

      final List<FileSystemEntity> dianFiles = dir.listSync();
      for (var file in dianFiles) {
        if (file is File && file.path.toLowerCase().endsWith('.pdf')) {
          final fileName = p.basename(file.path);
          final newPath = p.join(backupDir.path, fileName);
          await file.copy(newPath);
        }
      }

      print("Pdfs saved to download");

      return "success";
    } catch (e) {
      print("Error: $e");
      return "Error: $e";
    }
  }

  Future<String> saveXmlBackup() async {
    try {
      final db = await databaseConnection.openDb();
      final xmlFiles = await db.query('xml_files');

      if (xmlFiles.length > 0) {
        for (int i = 0; i < xmlFiles.length; i++) {
          final String fileName = "factura_xml_$i";
          File file = File('${backupDir.path}/$fileName.xml');
          await file.writeAsString(xmlFiles[i]['xml_text']);
          print("Done!");
        }

        return "success";
      } else {
        return "folder vacio";
      }
    } catch (e) {
      print("Error: $e");
      return "Error: $e";
    }
  }

  Future<String> savePdfBackup() async {
    final dPath = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    final dirPath = "${dPath!.path}/pdfs";
    final dir = Directory(dirPath);

    try {

      //Check if folder containing pdf exists if not create
      if (!await dir.exists()) {
        await dir.create(recursive: true);
        print("Created backup folder at ${dir.path}");
      }

      final contents = dir.listSync();

      if (!await dir.exists() || contents.isEmpty) {
        return "folder vacio";
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
    } catch (e) {
      print("Error: $e");
      return "Error: $e";
    }
  }


  Future<String> saveImageBackup() async {

    final directory = await getApplicationDocumentsDirectory();

    final imagesDir = Directory(p.join(directory.path, 'images'));

    try {

      // Ensure it exists
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final contents = imagesDir.listSync().whereType<File>();

      if (!await imagesDir.exists() || contents.isEmpty) {
        return "folder vacio";
      } 
      
      for (final file in contents) {
        final newPath = p.join(backupDir.path, p.basename(file.path));
        final dest = File(newPath);

        if (!await dest.exists()) {
          await file.copy(newPath);        // <-- works because `file` is a `File`
          print('Copied ${file.path}');
        } else {
          print('Skipped ${file.path} (already exists)');
        }
      }

    return "success";
    
    } catch(e) {
      print("Error: $e");
      return "Ha habido un error: $e";
    }

  }


  //Get database dir
  Future<String> getDatabasePath() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'smartbill.db'); // change to your actual db name
    return path;
  }

  Future<void> backupDatabase() async {
    try {
      final dbPath = await getDatabasePath();
      final dbFile = File(dbPath);
      final backupPath = join(backupDir.path, 'smartbill_backup.db');

      await dbFile.copy(backupPath);

      print('✅ Backup successful: ${backupDir.path}');
    } catch (e) {
      print('❌ Backup failed: $e');
    }
  }

}

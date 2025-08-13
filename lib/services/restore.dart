
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:smartbill/services/db.dart';
import 'package:sqflite/sqflite.dart';

class RestoreService {

  late Directory backupDir;

  Future<bool> checkIfBackupExists() async {

    //If the smartbill folder doesn't exist, creates it
    if (Platform.isAndroid) {
      backupDir = Directory("/storage/emulated/0/Download/smartbill_backup");
    } else if (Platform.isIOS) {
      final docsDir = await getApplicationDocumentsDirectory();
      backupDir = Directory(p.join(docsDir.path, 'smartbill_backup'));
    }

    if(await backupDir.exists()) {
      return true;
    } else {
      return false;
    }

  }

  Future<String> _restoreDatabaseBackup() async {

    try {
      File backupFile = File("${backupDir.path}/smartbill.db");

      if (!await backupFile.exists()) {
        return "Backup database vacio";
      }

      //Get old database
      final databasePath = await getDatabasesPath();
      final targetPath = p.join(databasePath, 'smartbill.db');

      print("Databases dir: $targetPath");

      final targetFile = File(targetPath);

      //Delete old database to make space for new one if it exists
      if (await targetFile.exists()) {
        await targetFile.delete();
      }

      await backupFile.copy(targetPath);

      print("Database restored successfully to $targetPath");

      return "success";


    } catch(e) {
      print("Hubo un error: e");
      return "Error: $e";
    }
    
  }

  Future<String> _restoreBackupFolder() async {
    final directory = Platform.isAndroid ? await getExternalStorageDirectory() : await getApplicationDocumentsDirectory();
    final Directory backupDirectory = Directory(backupDir.path);

    print("Restoring backup to ${directory!.path}");

    await _copyDirectory(backupDirectory, directory);
    print("Restore complete.");

    return "success";

  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    if (!destination.existsSync()) {
      await destination.create(recursive: true);
    }

    await for (FileSystemEntity entity in source.list(recursive: false)) {
      if (entity is Directory) {
        final newDirectory = Directory(p.join(destination.path, p.basename(entity.path)));
        await _copyDirectory(entity, newDirectory);
      } else if (entity is File) {
        final newFile = File(p.join(destination.path, p.basename(entity.path)));
        await newFile.writeAsBytes(await entity.readAsBytes());
      }
    }
  }


  //Calling restore functions
  Future<bool> restoreBackup() async {
    DatabaseConnection databaseConnection = DatabaseConnection();
    try {
      await databaseConnection.close();

      final responseFolder = await _restoreBackupFolder();
      final responseBackup = await _restoreDatabaseBackup();

      if(responseFolder == 'success' && responseBackup == 'success') {
        final db = await DatabaseConnection().db;
        db.isOpen ? print("Database connected") : print("Database not connected");
        print("Response: $responseFolder =+ $responseBackup");
        return true;
      }

      return false;

    } catch(e) {
      print("Hubo un error: $e");
      return false;
    }
    
  }

}
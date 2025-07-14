import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class BackupService {
  late Directory backupDir;
  final archive = Archive();

  Future<void> initBackupDir() async {

    //If the smartbill folder doesn't exist, creates it
    if (Platform.isAndroid) {
      backupDir = Directory("/storage/emulated/0/Download/smartbill_backup");
    } else if (Platform.isIOS) {
      final docsDir = await getApplicationDocumentsDirectory();
      backupDir = Directory(p.join(docsDir.path, 'smartbill_backup'));
    }

    //check if backup folder exists
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
      print("Created backup folder at ${backupDir.path}");
    } else {
      print("Backup dir already existed");
    }
    
  }

  Future<void> _copyRecursive(Directory from, Directory to) async {
    await for (var entity in from.list(recursive: true)) {
      if (entity is File) {
        final relative = p.relative(entity.path, from: from.path);
        final newPath = p.join(to.path, relative);
        final newFile = File(newPath);

        await newFile.parent.create(recursive: true);
        await entity.copy(newPath);
      }
    }
  }


  Future<String> backupFilesFolder() async {

    try {
      final directory = Platform.isAndroid ? await getExternalStorageDirectory() : await getApplicationDocumentsDirectory();

      if(!await directory!.exists() || await directory.list().isEmpty) {
        return "no files";
      }

      final entities = directory.listSync(recursive: false);

      for (var entity in entities) {
        if (entity is Directory) {
          final folderName = p.basename(entity.path);
          final destinationFolder = Directory(p.join(backupDir.path, folderName));

          if (!await destinationFolder.exists()) {
            await destinationFolder.create(recursive: true);
          }

          print("created ${entity.path}");
          await _copyRecursive(entity, destinationFolder);

        }
      }

      print("All folders and their contents copied.");

      return "success";

    } catch(e) {
      print("Error: $e");
      return "Hubo un error: $e";
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
      final backupPath = join(backupDir.path, 'smartbill.db');

      await dbFile.copy(backupPath);

      print('✅ Backup successful: ${backupDir.path}');
    } catch (e) {
      print('❌ Backup failed: $e');
    }
  }

}

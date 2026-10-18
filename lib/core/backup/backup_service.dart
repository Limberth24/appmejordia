import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';

class BackupResult {
  final String tempPath;
  final String? publicPath;
  BackupResult({required this.tempPath, this.publicPath});
}

class BackupService {
  static const _dbName = 'mejordia.db';

  static Future<String> getDbPath() async {
    final dbDir = await getDatabasesPath();
    return p.join(dbDir, _dbName);
  }

  static String backupFileName() {
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return 'mejordia_backup_$stamp.db';
  }
  static Future<File> createTempBackup() async {
    final dbPath = await getDbPath();
    final dbFile = File(dbPath);
    if (!await dbFile.exists()) {
      throw StateError('Aún no hay datos para respaldar.');
    }

    await AppDatabase.close();

    try {
      final tmpDir = await getTemporaryDirectory();
      final dest = File(p.join(tmpDir.path, backupFileName()));
      await dbFile.copy(dest.path);
      return dest;
    } finally {
      await AppDatabase.instance;
    }
  }

  static Future<String?> copyToPublicDownloads(File backupFile) async {
    try {
      if (Platform.isAndroid) {
        await _requestLegacyStorageIfNeeded();

        final candidates = <Directory>[
          Directory('/storage/emulated/0/Download'),
          Directory('/storage/emulated/0/Descargas'),
        ];
        try {
          final ext = await getExternalStorageDirectory();
          if (ext != null) candidates.add(Directory(p.join(ext.path, 'Backups')));
        } catch (_) {}

        for (final dir in candidates) {
          try {
            if (!await dir.exists()) {
              if (dir.path.endsWith('Backups')) {
                await dir.create(recursive: true);
              } else {
                continue;
              }
            }
            final dest = File(p.join(dir.path, p.basename(backupFile.path)));
            await backupFile.copy(dest.path);
            return dest.path;
          } catch (_) {
            continue;
          }
        }
        return null;
      } else {
        final docs = await getApplicationDocumentsDirectory();
        final dir = Directory(p.join(docs.path, 'MejorDia', 'Backups'));
        await dir.create(recursive: true);
        final dest = File(p.join(dir.path, p.basename(backupFile.path)));
        await backupFile.copy(dest.path);
        return dest.path;
      }
    } catch (_) {
      return null;
    }
  }

  static Future<void> _requestLegacyStorageIfNeeded() async {
    try {
      final status = await Permission.storage.status;
      if (status.isDenied || status.isRestricted) {
        await Permission.storage.request();
      }
    } catch (_) {
    }
  }

  static Future<BackupResult> exportBackup() async {
    final tmp = await createTempBackup();
    final publicPath = await copyToPublicDownloads(tmp);
    return BackupResult(tempPath: tmp.path, publicPath: publicPath);
  }

  static Future<void> shareBackupFile(String filePath) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath)],
        text: 'Respaldo MejorDía (${p.basename(filePath)})',
        subject: 'Respaldo MejorDía',
      ),
    );
  }

  static Future<File?> pickBackupFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db', 'sqlite', 'bak'],
    );
    if (files.isEmpty) return null;
    final path = files.single.path;
    if (path == null) return null;
    return File(path);
  }

  static Future<bool> isValidBackup(File file) async {
    Database? tmpDb;
    try {
      if (!await file.exists()) return false;
      tmpDb = await openDatabase(file.path, readOnly: true);
      final tables = await tmpDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('config','registros')",
      );
      return tables.length == 2;
    } catch (_) {
      return false;
    } finally {
      await tmpDb?.close();
    }
  }

  static Future<void> restoreBackup(File backupFile) async {
    if (!await isValidBackup(backupFile)) {
      throw StateError('El archivo elegido no es un respaldo válido.');
    }

    final dbPath = await getDbPath();

    await AppDatabase.close();

    try {
      final dest = File(dbPath);
      await dest.parent.create(recursive: true);
      await backupFile.copy(dest.path);

      for (final suffix in ['-wal', '-shm', '-journal']) {
        try {
          final aux = File('$dbPath$suffix');
          if (await aux.exists()) await aux.delete();
        } catch (_) {}
      }

      final db = await AppDatabase.instance;
      await db.query('config', limit: 1);
    } catch (e) {
      try {
        await AppDatabase.instance;
      } catch (_) {}
      rethrow;
    }
  }
}

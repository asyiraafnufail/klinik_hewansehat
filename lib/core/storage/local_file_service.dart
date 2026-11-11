import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LocalFileService {
  static const String _folderName = 'klinik_hewansehat_docs';

  Future<Directory> _getDirectory() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory('${baseDir.path}/$_folderName');
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    return targetDir;
  }

  /// Simpan berkas teks lokal (misal: ringkasan rekam medis / bukti reservasi)
  Future<File> saveFile({required String filename, required String content}) async {
    final dir = await _getDirectory();
    final sanitized = filename.replaceAll(RegExp(r'[^a-zA-Z0-9_\-\.]'), '_');
    final file = File('${dir.path}/$sanitized');
    return await file.writeAsString(content);
  }

  /// Dapatkan daftar semua berkas yang tersimpan lokal
  Future<List<FileSystemEntity>> listSavedFiles() async {
    final dir = await _getDirectory();
    final entities = dir.listSync();
    entities.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return entities;
  }

  /// Baca isi berkas lokal
  Future<String> readFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Berkas tidak ditemukan');
    }
    return await file.readAsString();
  }

  /// Hapus berkas lokal
  Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/storage/local_file_service.dart';

class LocalFileViewModel extends ChangeNotifier {
  final LocalFileService _service;

  List<FileSystemEntity> _files = [];
  String? _openedContent;
  String? _openedFilename;
  bool _isLoading = false;
  String? _errorMessage;

  LocalFileViewModel({LocalFileService? service})
      : _service = service ?? LocalFileService();

  List<FileSystemEntity> get files => _files;
  String? get openedContent => _openedContent;
  String? get openedFilename => _openedFilename;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadFiles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _files = await _service.listSavedFiles();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> openFile(String path) async {
    try {
      final content = await _service.readFile(path);
      _openedContent = content;
      _openedFilename = path.split('/').last;
      notifyListeners();
      return content;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<void> deleteFile(String path) async {
    await _service.deleteFile(path);
    await loadFiles();
  }
}

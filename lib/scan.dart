import 'dart:io';

import 'package:edge_detection/edge_detection.dart';
import 'package:paperless_app/api.dart';
import 'package:path_provider/path_provider.dart';

class ScanHandler {
  Directory scansDir;
  List<Function(int scansAmount)> statusListeners = [];
  bool running = false;

  Future<void> _init() async {
    scansDir = new Directory((await getTemporaryDirectory()).path + "/scans");
    if (!await scansDir.exists()) {
      scansDir.create();
    }
  }

  void attachListener(Function(int scansAmount) listener) {
    statusListeners.add(listener);
  }

  Future<void> handleScans() async {
    if (running) return;
    await _init();
    running = true;
    while (true) {
      var scansAmount = await scansDir.list().length;
      print("Amount: $scansAmount");
      statusListeners.first(scansAmount);
      if (scansAmount == 0) break;   //rajat
      await handleScan(await scansDir.list().first);
    }

    running = false;
  }

  Future<void> handleScan(File scannedDocument) async {
    await API.instance.uploadFile(scannedDocument.path);
    await scannedDocument.delete();
  }

  Future<void> scanDocument() async {
    // EdgeDetection.useInternalStorage(true);
    String imagePath = await EdgeDetection.detectEdge;
    moveFile(File(imagePath),scansDir.path + "/" + imagePath.split("/").last);
    //File(imagePath).rename(scansDir.path + "/" + imagePath.split("/").last);
    handleScans();
  }
}

Future<File> moveFile(File sourceFile, String newPath) async {
  try {
    // prefer using rename as it is probably faster
    return await sourceFile.rename(newPath);
  } on FileSystemException catch (e) {
    // if rename fails, copy the source file and then delete it
    final newFile = await sourceFile.copy(newPath);
    await sourceFile.delete();
    return newFile;
  }
}

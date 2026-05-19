import 'package:flutter/material.dart';
import 'package:gpx/gpx.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

//poly line layer

class RouteView extends StatelessWidget {
  const RouteView({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        // Action to perform when pressed
        await importRoute();
      },
      child: const Text('Import Route'),
    );
  }
}

Future<void> importRoute() async {
  try {
    String fileContent = await importFile();
    var gpxData = GpxReader().fromString(fileContent);
    // Access waypoints (consider using a logger in production)
    print(gpxData.wpts);
  } catch (e) {
    throw Exception('Failed to import file: $e');
  }
}

Future<String> importFile() async {
  FilePickerResult? result = await FilePicker.pickFiles(withData: true);
  if (result == null) throw Exception('No file selected');
  PlatformFile file = result.files.single;
  final bytes = file.bytes;
  if (bytes == null) return '';
  String fileContent = utf8.decode(bytes);
  return fileContent;
}

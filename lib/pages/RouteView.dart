import 'package:flutter/material.dart';
import 'package:gpx/gpx.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'MapView.dart';

//poly line layer

class RouteView extends StatefulWidget {
  const RouteView({super.key});

  @override
  State<RouteView> createState() => _RouteViewState();
}

class _RouteViewState extends State<RouteView> {
  var importedGpxData;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (importedGpxData != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Imported Route'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                importedGpxData = null;
              });
            },
          ),
        ),
        body: MapView(gpxData: importedGpxData),
      );
    }

    return Center(
      child: ElevatedButton(
        onPressed: isLoading ? null : () => _handleImport(),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Import Route'),
      ),
    );
  }

  Future<void> _handleImport() async {
    setState(() {
      isLoading = true;
    });

    try {
      String fileContent = await importRoute();
      var gpxData = GpxReader().fromString(fileContent);
      setState(() {
        importedGpxData = gpxData;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}

Future<String> importRoute() async {
  try {
    String fileContent = await importFile();
    var gpxData = GpxReader().fromString(fileContent);
    // Access waypoints (consider using a logger in production)
    print(gpxData.wpts);
    return fileContent;
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

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class PdfPreviewScreen extends StatelessWidget {
  final File file;
  const PdfPreviewScreen({required this.file, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(file.path.split('/').last)),
      body: PdfView(
        controller: PdfController(
          document: PdfDocument.openFile(file.path),
        ),
      ),
    );
  }
}

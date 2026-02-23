import 'dart:io';
import 'package:flutter/material.dart';

class TextFilePreviewScreen extends StatelessWidget {
  final File file;
  const TextFilePreviewScreen({required this.file, Key? key}) : super(key: key);

  Future<String> _readFile() async {
    return await file.readAsString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(file.path.split('/').last)),
      body: FutureBuilder<String>(
        future: _readFile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) return Center(child: Text('Error reading file'));
            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Text(snapshot.data ?? ''),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

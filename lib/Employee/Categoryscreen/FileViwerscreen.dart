import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:photo_view/photo_view.dart';

class FileViewerScreen extends StatelessWidget {
  final String url;
  final String fileType;

  const FileViewerScreen({super.key, required this.url, required this.fileType,});

  @override
  Widget build(BuildContext context) {
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(fileType.toLowerCase());
    final isPdf = fileType.toLowerCase() == 'pdf';

    return Scaffold(
      appBar: AppBar(
        title: const
        Text("File Viewer",style: TextStyle(fontFamily: "Times New Roman",color: Colors.white),),
        backgroundColor: Colors.blue.shade900,
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Center(
        child: isImage
            ? PhotoView(
          imageProvider: NetworkImage(url),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
        )
            : isPdf
            ? PDFView(
          filePath: url,
          enableSwipe: true,
          swipeHorizontal: true,
          autoSpacing: true,
          pageFling: true,
        )
            : const Center(child: Text("Unsupported file type")),
      ),
    );
  }
}
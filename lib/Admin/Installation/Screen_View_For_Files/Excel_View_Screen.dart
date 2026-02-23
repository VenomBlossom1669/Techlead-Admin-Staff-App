import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';

class ExcelPreviewScreen extends StatefulWidget {
  final File file;
  const ExcelPreviewScreen({required this.file, Key? key}) : super(key: key);

  @override
  State<ExcelPreviewScreen> createState() => _ExcelPreviewScreenState();
}

class _ExcelPreviewScreenState extends State<ExcelPreviewScreen> {
  List<List<Data?>> rows = [];

  @override
  void initState() {
    super.initState();
    _loadExcel();
  }

  void _loadExcel() {
    final bytes = widget.file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);

    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet != null) {
      rows = sheet.rows;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.file.path.split('/').last)),
      body: rows.isEmpty
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: rows.first
              .map((cell) => DataColumn(label: Text(cell?.value.toString() ?? '')))
              .toList(),
          rows: rows.skip(1).map((row) {
            return DataRow(
              cells: row.map((cell) => DataCell(Text(cell?.value.toString() ?? ''))).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}

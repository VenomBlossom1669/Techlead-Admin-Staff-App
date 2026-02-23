import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Common_Code_For_All_Dep/Dep_All_Ui.dart';
import '../Editdailytaskreport.dart';

class Hrdailytaskreport extends StatefulWidget {
  const Hrdailytaskreport({super.key});

  @override
  State<Hrdailytaskreport> createState() =>
      _HrdailytaskreportState();
}

class _HrdailytaskreportState
    extends State<Hrdailytaskreport> {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  String searchQuery = '';
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Daily Task Report",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF000F89), // Royal Blue
                          Color(0xFF0F52BA), // Cobalt Blue (replacing Indigo)
                          Color(0xFF002147), // Light Sky Blue
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.trim().toLowerCase();
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search Task Title',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF000F89), // Royal Blue
                        Color(0xFF0F52BA), // Cobalt Blue (replacing Indigo)
                        Color(0xFF002147), // Light Sky Blue
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.date_range, color: Colors.white),
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2023),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("DailyTaskReport")
            .where("Service_department", isEqualTo: "Human Resource")
            .where("userId", isEqualTo: currentUserId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error fetching data."));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allReports = snapshot.data!.docs;
          final filteredReports = allReports.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = (data['taskTitle'] ?? '').toString().toLowerCase();

            final matchesSearch = title.contains(searchQuery);
            final matchesDate = selectedDate == null ||
                (data['date'] != null &&
                    DateFormat('yyyy-MM-dd')
                        .format((data['date'] as Timestamp).toDate()) ==
                        DateFormat('yyyy-MM-dd').format(selectedDate!));

            return matchesSearch && matchesDate;
          }).toList();

          if (filteredReports.isEmpty) {
            return const Center(
              child: Text(
                "No Data Found!",
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredReports.length,
            itemBuilder: (context, index) {
              final doc = filteredReports[index];
              final report = doc.data() as Map<String, dynamic>;
              final docId = doc.id;

              // Use the shared reusable widget:
              return ReportCardWidget.buildReportCard(context, report, docId);
            },
          );
        },
      ),
    );
  }
}

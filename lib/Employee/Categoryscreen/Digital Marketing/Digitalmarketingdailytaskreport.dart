import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Common_Code_For_All_Dep/Dep_All_Ui.dart';
import '../Editdailytaskreport.dart';

class Digitalmarketingdailytaskreport extends StatefulWidget {
  const Digitalmarketingdailytaskreport({super.key});

  @override
  State<Digitalmarketingdailytaskreport> createState() =>
      _DigitalmarketingdailytaskreportState();
}

class _DigitalmarketingdailytaskreportState extends State<Digitalmarketingdailytaskreport> {
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
                        hintStyle: TextStyle(color: Colors.white),
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
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.light().copyWith(
                              dialogBackgroundColor: Colors.white,
                              // Optional: Dialog box color
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF0F52BA),
                                // Header & selected date background
                                onPrimary: Colors.white,
                                // Text in selected date
                                surface: Color(0xFF000F89),
                                // Calendar background (solid only)
                                onSurface: Colors.white, // Calendar text
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  // <- White text for buttons
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold, // <- Bold text
                                  ),
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
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
            .where("Service_department", isEqualTo: "Digital Marketing")
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

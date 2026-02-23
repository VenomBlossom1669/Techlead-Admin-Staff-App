import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Guildlinesmodel.dart';

class UserViewGuideLines extends StatefulWidget {
  const UserViewGuideLines({super.key});

  @override
  State<UserViewGuideLines> createState() => _UserViewGuideLinesState();
}

class _UserViewGuideLinesState extends State<UserViewGuideLines> {
  TextEditingController _searchController = TextEditingController();
  bool _isAscending = true;
  List<GuidelinesModel> _allGuidelines = [];
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "View Guidelines",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 4,
        actions: [
          IconButton(
            tooltip: _isAscending ? 'Sort Descending' : 'Sort Ascending',
            icon: Icon(_isAscending ? Icons.arrow_downward : Icons.arrow_upward),
            onPressed: () {
              setState(() {
                _isAscending = !_isAscending;
              });
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF000F89),
                Color(0xFF0F52BA),
                Color(0xFF002147),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search by headlines...',
                      hintStyle: TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      filled: true,
                      fillColor: Colors.blue.shade700.withOpacity(0.6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.date_range, color: Colors.white),
                  onPressed: _pickDate,
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('Guidelines')
            .orderBy('reportedDateTime', descending: !_isAscending)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No Guidelines data available!'));
          }

          _allGuidelines = snapshot.data!.docs
              .map((doc) => GuidelinesModel.fromSnapshot(doc))
              .toList();

          String query = _searchController.text.toLowerCase();
          List<GuidelinesModel> filteredGuidelines = _allGuidelines.where((item) {
            bool matchesHeadline = item.headlines.toLowerCase().contains(query);
            bool matchesDate = _selectedDate == null
                ? true
                : DateFormat('yyyy-MM-dd')
                .format(item.reportedDateTime.toDate()) ==
                DateFormat('yyyy-MM-dd').format(_selectedDate!);
            return matchesHeadline && matchesDate;
          }).toList();

          if (filteredGuidelines.isEmpty) {
            return const Center(
              child: Text(
                'No data found as you searched!',
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredGuidelines.length,
            itemBuilder: (context, index) {
              var item = filteredGuidelines[index];
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Card(
                  margin: const EdgeInsets.all(11.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF000F89),
                          Color(0xFF0F52BA),
                          Color(0xFF002147),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRow(Icons.title, 'Headlines: ', item.headlines),
                        const SizedBox(height: 16),
                        _buildRow(Icons.rule, 'Guidelines: ', item.guidelines),
                        const SizedBox(height: 10),
                        _buildEmailRow(item.contactus),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                color: Colors.cyanAccent, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Reported Date & Time: ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.cyanAccent,
                                  fontSize: 11),
                            ),
                            Expanded(
                              child: Text(
                                item.reportedDateTime != null
                                    ? DateFormat('dd/MM/yyyy HH:mm:ss')
                                    .format(item.reportedDateTime.toDate())
                                    : 'N/A',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailRow(String email) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.email, color: Colors.cyanAccent, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: TextButton(
            onPressed: () => _launchEmail(email),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Align(
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Contact Us: ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.cyanAccent),
                    ),
                    TextSpan(
                      text: email,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _pickDate() async {
    DateTime now = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color(0xFF0F52BA),
            colorScheme: ColorScheme.light(
              primary: Color(0xFF0F52BA), // Header and selected date
              onPrimary: Colors.white, // Text color on selected date
              surface: Colors.white, // Calendar background
              onSurface: Colors.black87, // Regular text color
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  _launchEmail(String emailAddress) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
      queryParameters: {
        'subject': 'Your subject here',
        'body': 'Your message here',
      },
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      throw 'Could not launch $emailLaunchUri';
    }
  }
}

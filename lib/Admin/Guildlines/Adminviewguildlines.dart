import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Employee/Homescreen/Guildlinesmodel.dart';

class AdminGuideLines extends StatefulWidget {
  const AdminGuideLines({super.key});

  @override
  State<AdminGuideLines> createState() => _AdminGuideLinesState();
}

class _AdminGuideLinesState extends State<AdminGuideLines> {
  TextEditingController _searchController = TextEditingController();
  bool _isAscending = true;
  List<GuidelinesModel> _allGuidelines = [];
  Set<String> _selectedIds = {};
  bool _selectAll = false;
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
          if (_selectedIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
              tooltip: 'Delete Selected',
              onPressed: _deleteSelectedGuidelines,
            ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF000F89), Color(0xFF0F52BA), Color(0xFF002147)],
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
                    decoration: InputDecoration(
                      hintText: 'Search by headline...',
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      hintStyle: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  tooltip: 'Filter by Date',
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
            bool matchesHeadline =
            item.headlines.toLowerCase().contains(query);
            bool matchesDate = _selectedDate == null
                ? true
                : DateFormat('yyyy-MM-dd')
                .format(item.reportedDateTime.toDate()) ==
                DateFormat('yyyy-MM-dd').format(_selectedDate!);
            return matchesHeadline && matchesDate;
          }).toList();

          if (_selectAll && _selectedIds.length != filteredGuidelines.length) {
            _selectedIds.addAll(filteredGuidelines.map((g) => g.id));
          }

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

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF000F89), Color(0xFF0F52BA), Color(0xFF002147)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _selectAll,
                        onChanged: (value) {
                          setState(() {
                            _selectAll = value!;
                            _selectedIds.clear();
                            if (_selectAll) {
                              _selectedIds.addAll(filteredGuidelines.map((g) => g.id));
                            }
                          });
                        },
                        side: const BorderSide(color: Colors.cyanAccent, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        activeColor: Colors.cyanAccent,
                        checkColor: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.select_all, color: Colors.cyanAccent),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Select All Guidelines',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredGuidelines.length,
                  itemBuilder: (context, index) {
                    var guideline = filteredGuidelines[index];
                    bool isSelected = _selectedIds.contains(guideline.id);

                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Card(
                        margin: const EdgeInsets.all(11.0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF000F89), Color(0xFF0F52BA), Color(0xFF002147)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedIds.remove(guideline.id);
                                      _selectAll = false;
                                    } else {
                                      _selectedIds.add(guideline.id);
                                    }
                                  });
                                },
                                child: ListTile(
                                  leading: Checkbox(
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedIds.add(guideline.id);
                                        } else {
                                          _selectedIds.remove(guideline.id);
                                          _selectAll = false;
                                        }
                                      });
                                    },
                                    activeColor: Colors.cyanAccent,
                                    checkColor: Colors.blue[900],
                                    side: const BorderSide(
                                        color: Colors.cyanAccent, width: 2),
                                  ),
                                  title: Text(
                                    'Headlines: ${guideline.headlines}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.rule,
                                      color: Colors.cyanAccent, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Guidelines: ${guideline.guidelines}',
                                      style:
                                      const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                icon: const Icon(Icons.email,
                                    color: Colors.cyanAccent),
                                label: Text(
                                  guideline.contactus,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                onPressed: () {
                                  _launchEmail(guideline.contactus);
                                },
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.access_time,
                                      color: Colors.cyanAccent, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      guideline.reportedDateTime != null
                                          ? DateFormat('dd/MM/yyyy HH:mm:ss')
                                          .format(guideline.reportedDateTime
                                          .toDate())
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
                ),
              ),
            ],
          );
        },
      ),
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
            primaryColor: const Color(0xFF0F52BA),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F52BA),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
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

  Future<void> _deleteSelectedGuidelines() async {
    if (_selectedIds.isEmpty) {
      Fluttertoast.showToast(msg: 'No items selected');
      return;
    }

    // Show confirmation dialog
    bool confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF002147),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Confirm Deletion',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete the selected guidelines?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.cyanAccent),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Yes',
                style: TextStyle(color: Color(0xFF002147), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    ) ??
        false;

    if (!confirmed) return;

    // Proceed with deletion
    try {
      for (String id in _selectedIds) {
        await FirebaseFirestore.instance.collection('Guidelines').doc(id).delete();
      }

      Fluttertoast.showToast(
        msg: 'Selected guidelines deleted ✅',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: const Color(0xFF002147),
        textColor: Colors.cyanAccent,
        fontSize: 16.0,
      );

      setState(() {
        _selectedIds.clear();
        _selectAll = false;
      });
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error deleting guidelines ❌',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.redAccent.shade700,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  void _launchEmail(String emailAddress) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
      queryParameters: {
        'subject': 'Your subject here',
        'body': 'Your message here',
      },
    );
    if (await canLaunch(emailLaunchUri.toString())) {
      await launch(emailLaunchUri.toString());
    } else {
      throw 'Could not launch $emailLaunchUri';
    }
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Widgeets/custom_app_bar.dart';
import '../../core/app_bar_provider.dart';
class TeamMembersScreen extends ConsumerStatefulWidget {
  final List<String> userDepartments;

  const TeamMembersScreen({Key? key, required this.userDepartments}) : super(key: key);

  @override
  ConsumerState<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends ConsumerState<TeamMembersScreen> {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> allMembers = [];
  List<Map<String, dynamic>> filteredMembers = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _loadTeamMembers();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appBarTitleProvider.notifier).state = "Team Members";
      ref.read(appBarGradientColorsProvider.notifier).state = [
        const Color(0xFF2F68AA),
        const Color(0xFF025BB6),
      ];
      ref.read(customTitleWidgetProvider.notifier).state = null;
    });
  }

  @override
  void dispose() {
    Future.microtask(() {
      if (mounted) {
        resetAppBar(ref);
      }
    });
    super.dispose();
  }


  Future<void> _loadTeamMembers() async {
    final snapshot = await _firestore.collection('EmpProfile').get();
    final List<Map<String, dynamic>> matchedMembers = [];

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final empCategories = List<dynamic>.from(data['categories'] ?? []);

      final bool isSameDepartment = empCategories.any(
            (cat) => widget.userDepartments.contains(cat.toString()),
      );

      if (isSameDepartment) {
        matchedMembers.add({
          'fullName': data['fullName'] ?? 'Unknown',
          'address': data['address'] ?? 'N/A',
          'categories': empCategories.join(', '),
          'mobile': data['mobile'] ?? 'N/A',
          'email': data['email'] ?? 'N/A',
        });
      }
    }

    setState(() {
      allMembers = matchedMembers;
      _filterMembers('');
    });
  }

  void _filterMembers(String query) {
    final filtered = allMembers.where((member) {
      final name = member['fullName'].toString().toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    for (int i = 0; i < filtered.length; i++) {
      filtered[i]['index'] = i + 1;
    }

    setState(() {
      filteredMembers = filtered;
    });
  }

  Future<void> launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> launchEmail(BuildContext context, String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else if (Platform.isAndroid) {
      final Uri gmailUri = Uri.parse("https://mail.google.com/mail/?view=cm&fs=1&to=$email");
      if (await canLaunchUrl(gmailUri)) {
        await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
      } else {
        _showError(context);
      }
    } else {
      _showError(context);
    }
  }

  void _showError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No email app found or unable to launch.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.indigo[900],
                  child: Text(
                    '${member['index']}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    member['fullName'],
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Times New Roman',
                      fontSize: 16,
                      color: Colors.cyanAccent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Address: ',
                  style: TextStyle(
                    fontFamily: 'Times New Roman',
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                  ),
                ),
                Expanded(
                  child: Text(
                    member['address'],
                    softWrap: true,
                    style: const TextStyle(
                      fontFamily: 'Times New Roman',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Department: ',
                  style: TextStyle(
                    fontFamily: 'Times New Roman',
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                  ),
                ),
                Expanded(
                  child: Text(
                    member['categories'],
                    softWrap: true,
                    style: const TextStyle(
                      fontFamily: 'Times New Roman',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => launchPhone(member['mobile']),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Phone: ',
                          style: TextStyle(
                            fontFamily: 'Times New Roman',
                            fontWeight: FontWeight.bold,
                            color: Colors.cyanAccent,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            member['mobile'],
                            softWrap: true,
                            style: const TextStyle(
                              fontFamily: 'Times New Roman',
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => launchEmail(context, member['email']),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Email: ',
                          style: TextStyle(
                            fontFamily: 'Times New Roman',
                            fontWeight: FontWeight.bold,
                            color: Colors.cyanAccent,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            member['email'],
                            softWrap: true,
                            overflow: TextOverflow.visible,
                            style: const TextStyle(
                              fontFamily: 'Times New Roman',
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[350],

      appBar: CustomAppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: _filterMembers,
              decoration: InputDecoration(
                labelText: 'Search by name',
                labelStyle:  TextStyle(color: Colors.blue.shade900,fontWeight: FontWeight.bold),
                prefixIcon:  Icon(Icons.search, color: Colors.blue.shade900),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Expanded(
            child: filteredMembers.isEmpty
                ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'No data available for this department right now!',
                  style: TextStyle(
                    fontFamily: 'Times New Roman',
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
                : ListView.builder(
              itemCount: filteredMembers.length,
              itemBuilder: (context, index) {
                return _buildMemberCard(filteredMembers[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

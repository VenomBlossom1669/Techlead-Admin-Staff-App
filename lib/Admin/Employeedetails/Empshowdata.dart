import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:techlead/Widgeets/custom_app_bar.dart';
import '../../core/app_bar_provider.dart';
import 'Edit Profile/All_Emp_Edit_Profiles.dart';
import 'Employee_Profile_Image_View/image_view.dart';

class EmpShowData extends ConsumerStatefulWidget {
  const EmpShowData({super.key});

  @override
  ConsumerState<EmpShowData> createState() => _EmpShowDataState();
}

class _EmpShowDataState extends ConsumerState<EmpShowData> {
  List<Map<String, dynamic>> profileList = [];
  List<Map<String, dynamic>> filteredList = [];

  final TextEditingController searchController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _loadProfileData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customTitleWidgetProvider.notifier).state = Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.person_2_rounded, color: Colors.white),
          SizedBox(width: 8),
          Text(
            "Employee Profile Details",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: "Times New Roman",
              fontSize: 18,
            ),
          ),
        ],
      );
    });
  }

  void _filterProfiles(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      filteredList = profileList.where((profile) {
        final name = profile['fullName']?.toLowerCase() ?? '';
        final empId = profile['empId']?.toLowerCase() ?? '';
        final department = profile['categories']?.join(', ')?.toLowerCase() ?? '';
        final mobile = profile['mobile']?.toLowerCase() ?? '';
        return name.contains(lowerQuery) ||
            empId.contains(lowerQuery) ||
            department.contains(lowerQuery) ||
            mobile.contains(lowerQuery);
      }).toList();
    });
  }

  void _showEmployeeDetails(Map<String, dynamic> profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF0A2A5A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      if (profile['profileImage'] != null && profile['profileImage'].isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullImageView(imageUrl: profile['profileImage']),
                          ),
                        );
                      }
                    },
                    child: Hero(
                      tag: profile['profileImage'],
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: profile['profileImage'] != null &&
                            profile['profileImage'].isNotEmpty
                            ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: profile['profileImage'],
                            placeholder: (context, url) =>
                            const CircularProgressIndicator(strokeWidth: 2),
                            errorWidget: (context, url, error) =>
                            const Icon(Icons.person, color: Colors.grey),
                            fit: BoxFit.cover,
                            width: 100,
                            height: 100,
                          ),
                        )
                            : const Icon(Icons.person, size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AllEmpEditProfiles(
                            profileData: profile,
                            onUpdateSuccess: _loadProfileData,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow("Full Name", profile['fullName'] ?? ''),
                      _buildInfoRow("Employee ID", profile['empId'] ?? ''),
                      _buildInfoRow("DOB", profile['dob'] ?? ''),
                      _buildInfoRow("Qualification", profile['qualification'] ?? ''),
                      _buildInfoRow("Department",
                          (profile['categories'] as List<dynamic>?)?.join(', ') ?? 'N/A'),
                      _buildInfoRow("Address", profile['address'] ?? ''),
                      _buildInfoRow("Mobile", profile['mobile'] ?? ''),
                      _buildInfoRow("Email", profile['email'] ?? ''),
                      _buildInfoRow("Joining Date", profile['dateOfJoining'] ?? ''),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadProfileData() async {
    try {
      QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('EmpProfile').get();

      setState(() {
        profileList = snapshot.docs.map((doc) {
          return {
            ...?doc.data() as Map<String, dynamic>?,
            'docId': doc.id,
          };
        }).toList();

        filteredList = profileList;
      });
    } catch (e) {
      print('Error loading profiles: $e');
      setState(() {
        profileList = [];
        filteredList = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFCDD5F6),
      appBar: const CustomAppBar(fontSize: 10),
      body: profileList.isEmpty
          ? Center(
        child: Text(
          'No employee profiles found!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Times New Roman',
            color: Colors.black54,
          ),
        ),
      )
          : Column(
        children: [
          // 🔍 Search box
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: _filterProfiles,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name, ID, department, or mobile',
                hintStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Times New Roman',
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.blue.shade900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),


          if (filteredList.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No matching employee found!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Times New Roman',
                    color: Colors.black54,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final profile = filteredList[index];
                  if (profile.isEmpty) return const SizedBox(); // safeguard

                  final docId = profile['id']; // 🔑 Firestore document id હોવું જોઈએ

                  return Dismissible(
                    key: Key(docId ?? index.toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete_forever, color: Colors.white, size: 32),
                    ),
                    confirmDismiss: (direction) async {
                      // confirm dialog before deleting
                      return await showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          title: const Text("Confirm Delete"),
                          content: const Text(
                              "Are you sure you want to delete this employee profile?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(false),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent),
                              onPressed: () => Navigator.of(dialogContext).pop(true),
                              child: const Text("Delete"),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) async {
                      try {
                        final docId = profile['docId']; // સાચું firestore docId

                        await FirebaseFirestore.instance
                            .collection("EmpProfile") // ✅ સાચું collection name
                            .doc(docId)
                            .delete();

                        // ❌ filteredList.removeAt(index); REMOVE THIS

                        // ✅ ફક્ત reload call કરજો
                        await _loadProfileData();

                        // ✅ Lavish Snackbar
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: const [
                                Icon(Icons.delete_forever, color: Colors.white),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "Employee deleted successfully!",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.redAccent,
                            duration: const Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Failed to delete: $e"),
                            backgroundColor: Colors.black87,
                            duration: const Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        );
                      }
                    },

                    child: GestureDetector(
                      onTap: () => _showEmployeeDetails(profile),
                      child: Card(
                        elevation: 4,
                        shape:
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF0A2A5A),
                                Color(0xFF15489C),
                                Color(0xFF1E64D8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile['fullName'] ?? 'N/A',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontFamily: 'Times New Roman',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "ID: ${profile['empId'] ?? 'N/A'}",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Times New Roman',
                                      ),
                                    ),
                                    Text(
                                      "Department: ${(profile['categories'] as List<dynamic>?)?.join(', ') ?? 'N/A'}",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Times New Roman',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.white,
                                backgroundImage: (profile['profileImage'] != null &&
                                    profile['profileImage'].isNotEmpty)
                                    ? NetworkImage(profile['profileImage'])
                                    : null,
                                child: (profile['profileImage'] == null ||
                                    profile['profileImage'].isEmpty)
                                    ? const Icon(Icons.person, size: 30, color: Colors.grey)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            )

        ],
      ),
    );
  }


  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.cyanAccent,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0A2A5A),
                  Color(0xFF15489C),
                  Color(0xFF1E64D8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.white54,
                        highlightColor: Colors.white,
                        child: Container(
                          width: 150,
                          height: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Shimmer.fromColors(
                        baseColor: Colors.white54,
                        highlightColor: Colors.white,
                        child: Container(
                          width: 100,
                          height: 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Shimmer.fromColors(
                        baseColor: Colors.white54,
                        highlightColor: Colors.white,
                        child: Container(
                          width: 80,
                          height: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Shimmer.fromColors(
                  baseColor: Colors.white54,
                  highlightColor: Colors.white,
                  child: const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

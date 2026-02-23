import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Account/Accounthomescreen.dart';
import 'Account/Accountshowdata.dart';
import 'Digital Marketing/Digitalmarketinghomescreen.dart';
import 'Digital Marketing/Digitlmarketingshowdata.dart';
import 'Finance/Financeshomescreen.dart';
import 'Finance/Financeshowdata.dart';
import 'HR/Hrhomescreen.dart';
import 'HR/hrreceivedscreen.dart';
import 'Installation/Installtionemployeedata.dart';
import 'Installation/installationhome.dart';
import 'Management/Managementhomescreen.dart';
import 'Management/Managementshowdata.dart';
import 'Reception/Receptionhomescreen.dart';
import 'Reception/Receptionshowdata.dart';
import 'Sales/Receivesaleshdata.dart';
import 'Sales/Saleshomescreen.dart';
import 'Services/Servicepage.dart';
import 'Social Media/SmHomescreen.dart';
import 'Social Media/Socialmediamarketingshowdata.dart';

class Categoryscreen extends StatefulWidget {
  const Categoryscreen({super.key});

  @override
  State<Categoryscreen> createState() => _CategoryscreenState();
}

class _CategoryscreenState extends State<Categoryscreen> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  Map<String, int> _unreadCountPerDept = {};
  late List<Map<String, dynamic>> allCategories;
  bool _initialRedirectHandled = false;
  StreamSubscription? _profileSub;
  StreamSubscription? _taskSub;
  Timer? _debounceTimer;
  Map<String, int> _previousCounts = {};
  bool navigated = false;
  String? latestTaskId;

  @override
  void initState() {
    super.initState();
    _initCategories();
    _listenToUnreadNotifications();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNotificationRedirect();
    });
  }

  void _initCategories() {
    final catColors = [
      const Color(0xFF000F89),
      const Color(0xFF0F52BA),
      const Color(0xFF002147),
    ];

    allCategories = [
      {'label': 'Human Resource', 'icon': Icons.work, 'color': catColors[0]},
      {'label': 'Finance', 'icon': Icons.account_balance_wallet, 'color': catColors[1]},
      {'label': 'Management', 'icon': Icons.business, 'color': catColors[2]},
      {'label': 'Installation', 'icon': Icons.build, 'color': catColors[0]},
      {'label': 'Sales', 'icon': Icons.shopping_cart, 'color': catColors[1]},
      {'label': 'Reception', 'icon': Icons.phone_in_talk, 'color': catColors[2]},
      {'label': 'Account', 'icon': Icons.attach_money, 'color': catColors[0]},
      {'label': 'Services', 'icon': Icons.miscellaneous_services, 'color': catColors[1]},
      {'label': 'Social Media', 'icon': Icons.public, 'color': catColors[2]},
      {'label': 'Digital Marketing', 'icon': Icons.trending_up, 'color': catColors[0]},
    ];
  }

  void _listenToUnreadNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _profileSub = FirebaseFirestore.instance
        .collection('EmpProfile')
        .doc(user.uid)
        .snapshots()
        .listen((profileDoc) {
      final profile = profileDoc.data();
      if (profile == null) return;

      final empId = profile['empId']?.toString().trim() ?? '';
      final departments = List<String>.from(profile['categories'] ?? []);

      _taskSub?.cancel();
      _taskSub = FirebaseFirestore.instance
          .collection('TaskAssign')
          .snapshots()
          .listen((taskSnap) {
        final Map<String, int> deptCounts = {};

        for (var doc in taskSnap.docs) {
          final data = doc.data();
          final dept = data['department']?.toString().trim();
          final empIds = data['empIds']?.toString().split(',').map((e) => e.trim()).toList() ?? [];
          final isUnread = data['read'] == false;

          if (dept != null && departments.contains(dept) && empIds.contains(empId) && isUnread) {
            deptCounts[dept] = (deptCounts[dept] ?? 0) + 1;
          }
        }

        if (!_mapEquals(_previousCounts, deptCounts)) {
          _previousCounts = Map.from(deptCounts);
          _debounceTimer?.cancel();
          _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
            if (mounted && _initialRedirectHandled) {
              setState(() {
                _unreadCountPerDept = Map.from(deptCounts);
              });
            }
          });
        }
      });
    });
  }

  bool _mapEquals(Map a, Map b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  Future<void> _checkNotificationRedirect() async {
    final prefs = await SharedPreferences.getInstance();
    final targetDept = prefs.getString('targetDepartment');
    final projectTitle = prefs.getString('notificationTitle');

    if (targetDept != null && !navigated && mounted) {
      navigated = true;
      await prefs.remove('targetDepartment');
      await prefs.remove('notificationTitle');

      Fluttertoast.showToast(
        msg: "Redirected to $targetDept for: $projectTitle",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.blueAccent,
        textColor: Colors.white,
      );

      _navigateToDept(context: context, department: targetDept, projectName: projectTitle);
    }

    if (mounted) {
      setState(() {
        _initialRedirectHandled = true;
      });
    }
  }

  Future<void> _navigateToDept({
    required BuildContext context,
    required String department,
    String? projectName,
  }) async {
    if (department == 'Services') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ServicePageList()));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    int unreadCount = 0;

    if (user != null) {
      final profileDoc = await FirebaseFirestore.instance.collection('EmpProfile').doc(user.uid).get();
      final empId = profileDoc.data()?['empId']?.toString().trim();

      final tasksQuery = await FirebaseFirestore.instance
          .collection('TaskAssign')
          .where('department', isEqualTo: department)
          .where('read', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (var doc in tasksQuery.docs) {
        final empIds = doc['empIds']?.toString().split(',') ?? [];
        if (empIds.contains(empId)) {
          unreadCount++;
          batch.update(doc.reference, {'read': true});
          latestTaskId = doc['taskId'];
        }
      }

      if (unreadCount > 0) await batch.commit();
    }

    Widget destination;
    switch (department) {
      case 'Human Resource':
        destination = unreadCount > 0 ? Hrreceiveddata(projectName: projectName, unreadCount: unreadCount, highlightedTaskId: latestTaskId) : const Hrhomescreen();
        break;
      case 'Finance':
        destination = unreadCount > 0 ? Financeshowdata(projectName: projectName, unreadCount: unreadCount, highlightedTaskId: latestTaskId) : const Financeshomescreen();
        break;
      case 'Management':
        destination = unreadCount > 0 ? Managementshowdata(projectName: projectName, unreadCount: unreadCount, highlightedTaskId: latestTaskId) : const Managementhomescreen();
        break;
      case 'Installation':
        destination = unreadCount > 0 ? AssignedTaskForInstallation(projectName: projectName, unreadCount: unreadCount, highlightedTaskId: latestTaskId) : const Inhomescreen();
        break;
      case 'Sales':
        destination = unreadCount > 0 ? Receivesalesdata(projectName: projectName, unreadCount: unreadCount, highlightedTaskId: latestTaskId) : const Saleshomescreen();
        break;
      case 'Reception':
        destination = unreadCount > 0 ? Receptionshowdata(projectName: projectName, unreadCount: unreadCount, highlightedTaskId: latestTaskId) : const Receptionhomescreen();
        break;
      case 'Account':
        destination = unreadCount > 0 ? Accountshowdata(projectName: projectName, unreadCount: unreadCount, highlightedTaskId: latestTaskId) : const Accounthomescreen();
        break;
      case 'Social Media':
        destination = unreadCount > 0 ? Socialmediamarketingshowdata(projectName: projectName, unreadCount: unreadCount, highlightedTaskId: latestTaskId) : const Smhomescreen();
        break;
      case 'Digital Marketing':
        destination = unreadCount > 0 ? Digitlmarketingshowdata(projectName: projectName, unreadCount: unreadCount, highlightedTaskId: latestTaskId) : const Digitalmarketinghomescreen();
        break;
      default:
        Fluttertoast.showToast(
          msg: "Unknown department: $department",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
        );
        return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    _taskSub?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        title: const Text(
          "Category Screen",
          style: TextStyle(fontFamily: "Times New Roman", fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('EmpProfile').doc(userId).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(child: Text('Error loading profile'));
          }

          final data = snap.data?.data() as Map<String, dynamic>?;
          if (data == null) {
            return const Center(child: Text('Please fill out your profile first!', style: TextStyle(fontWeight: FontWeight.bold)));
          }

          final userDepts = List<String>.from(data['categories'] ?? []);

          return CategoryGrid(
            userDepartments: userDepts,
            allCategories: allCategories,
            unreadCountPerDept: _unreadCountPerDept,
            onTapDept: (deptLabel) => _navigateToDept(context: context, department: deptLabel),
          );
        },
      ),
    );
  }
}

class CategoryGrid extends StatelessWidget {
  final List<String> userDepartments;
  final List<Map<String, dynamic>> allCategories;
  final Map<String, int> unreadCountPerDept;
  final void Function(String deptLabel) onTapDept;

  const CategoryGrid({
    super.key,
    required this.userDepartments,
    required this.allCategories,
    required this.unreadCountPerDept,
    required this.onTapDept,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = allCategories.where((c) => userDepartments.contains(c['label'])).toList();

    if (!filtered.any((c) => c['label'] == 'Services')) {
      filtered.add(allCategories.firstWhere((c) => c['label'] == 'Services'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filtered.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (context, idx) {
        final cat = filtered[idx];
        final label = cat['label'] as String;
        final unread = unreadCountPerDept[label] ?? 0;
        final bgColor = unread > 0 ? Colors.red : cat['color'] as Color;

        return GestureDetector(
          onTap: () => onTapDept(label),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(cat['icon'] as IconData, size: 50, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                if (unread > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$unread',
                        style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
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

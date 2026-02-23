import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:techlead/Widgeets/custom_app_bar.dart';
import 'package:techlead/core/app_bar_provider.dart';

class Showemployees extends ConsumerStatefulWidget {
  const Showemployees({super.key});

  @override
  ConsumerState<Showemployees> createState() => _ShowemployeesState();
}

class _ShowemployeesState extends ConsumerState<Showemployees> {
  String _searchQuery = '';

  final CollectionReference usersRef =
  FirebaseFirestore.instance.collection('Empauth');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appBarTitleProvider.notifier).state =
      "Employee Authentication Details";
    });

    fixMissingUids();
  }


  Future<void> fixMissingUids() async {
    final users = await usersRef.get();
    for (final doc in users.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['uid'] == null || data['uid'].toString().isEmpty) {
        print("⚠️ Missing UID for doc: ${doc.id}, fixing...");
        await usersRef.doc(doc.id).set({'uid': doc.id}, SetOptions(merge: true));
      }
    }
    print("✅ All missing UIDs fixed!");
  }

  Future<void> deleteUserFromAuth(String uid) async {
    if (uid.isEmpty) {
      print("⚠️ UID missing, cannot delete user");
      return;
    }

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('deleteUserAuth');

      print("DEBUG: Sending UID to CF = ${uid.toString().trim()}");

      final result = await callable.call({'uid': uid});
      print("DEBUG: CF result = ${result.data}");

      if (result.data['success'] == true) {
        print("✅ User deleted from Firebase Auth successfully");
      } else {
        print("❌ Error deleting user from Auth: ${result.data['error']}");
      }
    } catch (e) {
      print("⚠️ Cloud Function call failed: $e");
    }
  }

  Future<void> teUser(String docId) async {
    Map<String, dynamic>? deletedData;

    try {
      // 🔹 Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(color: Colors.cyanAccent),
              ],
            ),
          ),
        ),
      );

      // 🔹 Fetch the user document
      final doc = await usersRef.doc(docId).get();
      if (!doc.exists) {
        Navigator.pop(context); // Close loading
        return;
      }
      deletedData = doc.data() as Map<String, dynamic>?;

      if (deletedData == null) {
        Navigator.pop(context);
        return;
      }

      final uid = deletedData['uid']?.toString();
      final email = deletedData['email'];
      final username = deletedData['username'];

      if (uid == null || uid.isEmpty) {
        Navigator.pop(context);
        Fluttertoast.showToast(
          msg: "UID missing! Cannot delete user.",
          backgroundColor: Colors.red,
        );
        return;
      }

      // 🔹 Delete related collections
      final futures = <Future>[];
      futures.add(FirebaseFirestore.instance
          .collection('Attendance')
          .where('userId', isEqualTo: uid)
          .get()
          .then((snap) => Future.wait(snap.docs.map((d) => d.reference.delete()))));

      futures.add(FirebaseFirestore.instance
          .collection('product_shortage_reports')
          .where('assigned_technician', isEqualTo: username)
          .get()
          .then((snap) => Future.wait(snap.docs.map((d) => d.reference.delete()))));

      futures.add(FirebaseFirestore.instance
          .collection('Installation')
          .where('technician_name', isEqualTo: username)
          .get()
          .then((snap) => Future.wait(snap.docs.map((d) => d.reference.delete()))));

      futures.add(FirebaseFirestore.instance
          .collection('DailyTaskReport')
          .where('userId', isEqualTo: uid)
          .get()
          .then((snap) => Future.wait(snap.docs.map((d) => d.reference.delete()))));

      futures.add(FirebaseFirestore.instance
          .collection('EmpProfile')
          .where('userId', isEqualTo: uid)
          .get()
          .then((snap) => Future.wait(snap.docs.map((d) => d.reference.delete()))));

      futures.add(FirebaseFirestore.instance
          .collection('Empleave')
          .where('emailid', isEqualTo: email)
          .get()
          .then((snap) => Future.wait(snap.docs.map((d) => d.reference.delete()))));

      futures.add(FirebaseFirestore.instance
          .collection('Notifications')
          .where('empIds', arrayContains: username)
          .get()
          .then((snap) => Future.wait(snap.docs.map((d) => d.reference.delete()))));

      futures.add(FirebaseFirestore.instance
          .collection('ReceptionPage')
          .where('userId', isEqualTo: uid)
          .get()
          .then((snap) => Future.wait(snap.docs.map((d) => d.reference.delete()))));

      futures.add(FirebaseFirestore.instance
          .collection('TaskAssign')
          .where('employeeNames', arrayContains: username)
          .get()
          .then((snap) => Future.wait(snap.docs.map((d) => d.reference.delete()))));

      await Future.wait(futures);

      await usersRef.doc(docId).delete();

      await deleteUserFromAuth(uid);

      if (!mounted) return; // ✅ prevent context usage after dispose
      Navigator.pop(context);

      if (!mounted) return; // ✅ check again before showing snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          duration: const Duration(seconds: 3),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF000F89), Color(0xFF0F52BA), Color(0xFF002147)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Employee & related data deleted successfully!',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          action: SnackBarAction(
            label: "UNDO",
            textColor: Colors.yellowAccent,
            onPressed: () async {
              if (deletedData != null) {
                await usersRef.doc(docId).set(deletedData);
                Fluttertoast.showToast(
                  msg: "Employee $username restored successfully!",
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                  gravity: ToastGravity.BOTTOM,
                );
              }
            },
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 3));
      Fluttertoast.showToast(
        msg: "Employee $username deleted successfully!",
        backgroundColor: Colors.green,
        textColor: Colors.white,
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_SHORT,
      );

    } catch (e) {
      Navigator.pop(context);
      print("Delete error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete employee'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }


  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F52BA), Color(0xFF1E64D8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 40),
              const SizedBox(height: 16),
              const Text("Confirm Delete",
                  style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text("Are you sure you want to delete this employee?",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      teUser(docId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text("Delete"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildHeaderRow() {
    return TableRow(
      decoration: const BoxDecoration(color: Colors.black87),
      children: [
        _tableCell("Username", isHeader: true),
        _tableCell("Email", isHeader: true),
        _tableCell("Password", isHeader: true),
        _tableCell("Delete", isHeader: true),
      ],
    );
  }

  TableRow _buildDataRow(String id, String username, String email, String password) {
    return TableRow(
      children: [
        _tableCell(username, alignRight: false),
        _tableCell(email, alignRight: false),
        _tableCell(password, alignRight: false),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDelete(id),
          ),
        ),
      ],
    );
  }

  static Widget _tableCell(String text, {bool isHeader = false, bool alignRight = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isHeader ? Colors.cyanAccent : Colors.white,
          fontSize: 14,
        ),
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A2A5A), Color(0xFF15489C), Color(0xFF1E64D8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by username...',
                  hintStyle: const TextStyle(color: Colors.white),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  filled: true,
                  fillColor: Colors.blue.shade800,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.cyanAccent, width: 2),
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: usersRef.orderBy('createdAt', descending: false).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Something went wrong',
                          style: TextStyle(color: Colors.white)),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.cyanAccent),
                    );
                  }

                  final users = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final username = (data['username'] ?? '').toString().toLowerCase();
                    return username.contains(_searchQuery);
                  }).toList();

                  if (users.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: Text(
                              _searchQuery.isEmpty
                                  ? 'No employees available.'
                                  : 'No employee found matching your search.',
                              style: const TextStyle(
                                fontFamily: 'Times New Roman',
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Table(
                          defaultColumnWidth: const IntrinsicColumnWidth(),
                          border: TableBorder.all(color: Colors.white),
                          children: [
                            _buildHeaderRow(),
                            ...users.map((user) {
                              final data = user.data() as Map<String, dynamic>;
                              final id = user.id;
                              final username = data['username'] ?? 'No Name';
                              final email = data['email'] ?? 'No Email';
                              final password = data['password'] ?? 'No Password';

                              return _buildDataRow(id, username, email, password);
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

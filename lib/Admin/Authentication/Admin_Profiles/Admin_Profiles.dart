import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminProfiles extends StatefulWidget {
  const AdminProfiles({super.key});

  @override
  State<AdminProfiles> createState() => _AdminProfilesState();
}

class _AdminProfilesState extends State<AdminProfiles> {
  final ImagePicker _picker = ImagePicker();

  // Store your fetched admins here
  Map<String, Map<String, dynamic>> admins = {};

  // Image notifiers for each admin
  final Map<String, ValueNotifier<ImageProvider>> _imageNotifiers = {};

  @override
  void initState() {
    super.initState();
    _fetchAdmins();
    _loadAdminData();
  }

  final TextEditingController _adminidcontroller = TextEditingController();

  Future<void> _fetchAdmins() async {
    final snapshot =
    await FirebaseFirestore.instance.collection('Admin_Profiles').get();

    final fetchedAdmins = <String, Map<String, dynamic>>{};
    for (var doc in snapshot.docs) {
      fetchedAdmins[doc.id] = doc.data();
    }

    setState(() {
      admins = fetchedAdmins;

      admins.forEach((email, admin) {
        _imageNotifiers[email] = ValueNotifier<ImageProvider>(
          (admin['image'] != null)
              ? (admin['image'] is String
              ? NetworkImage(admin['image'] as String)
              : FileImage(admin['image'] as File) as ImageProvider)
              : const AssetImage('assets/images/default_avatar.png'),
        );
      });
    });
  }

  Future<void> _loadAdminData() async {
    final prefs = await SharedPreferences.getInstance();

    final name = prefs.getString('name') ?? '';

    if (mounted) {
      setState(() {
        _adminidcontroller.text = name;
      });
    }
  }

  Future<String?> _uploadImageToStorage(String email, File imageFile) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('admin_images')
          .child('$email.jpg'); // use email as filename

      await ref.putFile(imageFile);

      return await ref.getDownloadURL();
    } catch (e) {
      print("❌ Error uploading image: $e");
      return null;
    }
  }


  void _confirmDeleteAdmin(BuildContext parentContext, String email) async {
    final prefs = await SharedPreferences.getInstance();
    final currentEmail = prefs.getString('email');

    if (!parentContext.mounted) return;

    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 15,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 60, color: Colors.yellowAccent),
                const SizedBox(height: 15),
                const Text(
                  "Confirm Admin Deletion",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Are you sure you want to delete this admin profile & related data?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blueAccent,
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text("Cancel",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        if (!parentContext.mounted) return;

                        try {
                          if (currentEmail != null && currentEmail == email) {
                            Navigator.of(dialogContext).pop();

                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              const SnackBar(
                                backgroundColor: Colors.redAccent,
                                content: Text(
                                  "You cannot delete your own account",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 3),
                              ),
                            );
                            return;
                          }

                          Navigator.of(dialogContext).pop();

                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            const SnackBar(
                              duration: Duration(seconds: 1),
                              backgroundColor: Colors.black87,
                              content: Row(
                                children: [
                                  CircularProgressIndicator(
                                      color: Colors.cyanAccent, strokeWidth: 2),
                                  SizedBox(width: 12),
                                  Text("Deleting admin...",
                                      style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                          );

                          // 🔥 Fetch admin data
                          final adminDoc = await FirebaseFirestore.instance
                              .collection("Admin_Profiles")
                              .doc(email)
                              .get();

                          if (!adminDoc.exists) {
                            Fluttertoast.showToast(msg: "Admin not found!");
                            return;
                          }

                          final data =
                              adminDoc.data() as Map<String, dynamic>? ?? {};
                          final adminId = data['id'];
                          final adminName = data['name'];
                          final adminEmailid = data['email'];

                          await FirebaseFirestore.instance
                              .collection("Admin_Profiles")
                              .doc(email)
                              .delete();

                          final futures = <Future>[];
                          futures.add(FirebaseFirestore.instance
                              .collection('TaskAssign')
                              .where('adminId', isEqualTo: adminId)
                              .get()
                              .then((snap) => Future.wait(
                              snap.docs.map((d) => d.reference.delete()))));

                          futures.add(FirebaseFirestore.instance
                              .collection('Installation')
                              .where('technician_name', isEqualTo: adminName)
                              .get()
                              .then((snap) => Future.wait(
                              snap.docs.map((d) => d.reference.delete()))));

                          futures.add(FirebaseFirestore.instance
                              .collection('meetings')
                              .where('adminId', isEqualTo: adminEmailid)
                              .get()
                              .then((snap) => Future.wait(
                              snap.docs.map((d) => d.reference.delete()))));

                          futures.add(FirebaseFirestore.instance
                              .collection('ReceptionPage')
                              .where('assigned_staff', isEqualTo: adminName)
                              .get()
                              .then((snap) => Future.wait(
                              snap.docs.map((d) => d.reference.delete()))));

                          await Future.wait(futures);

                          await Future.delayed(const Duration(seconds: 0));

                          if (!parentContext.mounted) return;

                          ScaffoldMessenger.of(parentContext)
                              .hideCurrentSnackBar();
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 5),
                              content: const Text(
                                "Admin & related data deleted successfully!",
                                style: TextStyle(color: Colors.white),
                              ),
                              action: SnackBarAction(
                                label: "UNDO",
                                textColor: Colors.yellowAccent,
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection("Admin_Profiles")
                                      .doc(email)
                                      .set(data);

                                  Fluttertoast.showToast(
                                    msg: "Admin restored!",
                                    backgroundColor: Colors.green,
                                    textColor: Colors.white,
                                  );
                                },
                              ),
                            ),
                          );

                          // ✅ Toast confirmation
                          Future.delayed(const Duration(seconds: 3), () {
                            Fluttertoast.showToast(
                              msg: "Admin '$adminName' deleted successfully!",
                              backgroundColor: Colors.green,
                              textColor: Colors.white,
                            );
                          });
                        } catch (e) {
                          if (parentContext.mounted) {
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.red,
                                content: Text(
                                  "Error deleting admin: $e",
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text("Delete",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  Future<void> _deleteAdminWithUndo(
      String email, Map<String, dynamic> adminData) async {
    final removedAdmin = admins[email];
    final removedImageNotifier = _imageNotifiers[email];

    setState(() {
      admins.remove(email);
      _imageNotifiers.remove(email);
    });

    await FirebaseFirestore.instance
        .collection('Admin_Profiles')
        .doc(email)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 5),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.delete_forever, color: Colors.white, size: 28),
              const SizedBox(width: 15),
              const Expanded(
                child: Text(
                  "Admin deleted",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.yellowAccent,
                ),
                onPressed: () async {
                  // Restore admin to Firestore
                  await FirebaseFirestore.instance
                      .collection('Admin_Profiles')
                      .doc(email)
                      .set(adminData);

                  // Restore local state
                  setState(() {
                    admins[email] = removedAdmin!;
                    _imageNotifiers[email] = removedImageNotifier!;
                  });
                },
                child: const Text(
                  "UNDO",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFancySnackBar(BuildContext context, String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00c6ff), Color(0xFF0072ff)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 🟢 Edit Admin Dialog
  void _editAdmin(String email, Map<String, dynamic> admin) {
    TextEditingController nameController =
        TextEditingController(text: admin['name']);
    TextEditingController idController =
        TextEditingController(text: admin['id']);
    TextEditingController phoneController =
        TextEditingController(text: admin['phone']);
    TextEditingController emailController = TextEditingController(text: email);
    TextEditingController passwordController =
        TextEditingController(text: admin['password']);

    bool _obscurePassword = true;
    final _formKey = GlobalKey<FormState>();
    File? selectedImageFile;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF141E30), Color(0xFF243B55)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final choice = await showDialog<String>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text("Select Image"),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, "camera"),
                                    child: const Text("Camera"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, "gallery"),
                                    child: const Text("Gallery"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, "cancel"),
                                    child: const Text("Cancel"),
                                  ),
                                ],
                              ),
                            );
                            if (choice != null && choice != "cancel") {
                              XFile? pickedFile;
                              if (choice == "camera") {
                                pickedFile = await picker.pickImage(
                                    source: ImageSource.camera);
                              } else if (choice == "gallery") {
                                pickedFile = await picker.pickImage(
                                    source: ImageSource.gallery);
                              }
                              if (pickedFile != null) {
                                selectedImageFile = File(pickedFile.path);
                                _imageNotifiers[email]?.value =
                                    FileImage(selectedImageFile!);

                                Fluttertoast.showToast(
                                  msg: "Image selected successfully",
                                  backgroundColor: Colors.green,
                                );

                                setState(() {});
                                setStateDialog(() {});
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00c6ff), Color(0xFF0072ff)],
                              ),
                            ),
                            child: ValueListenableBuilder<ImageProvider>(
                              valueListenable: _imageNotifiers.putIfAbsent(
                                email,
                                () {
                                  if (admin['image'] == null) {
                                    Fluttertoast.showToast(
                                      msg:
                                          "Please select an image before saving",
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.BOTTOM,
                                      backgroundColor: Colors.red,
                                      textColor: Colors.white,
                                      fontSize: 16.0,
                                    );
                                  }
                                  return ValueNotifier<ImageProvider>(
                                    (admin['image'] != null)
                                        ? (admin['image'] is String
                                            ? NetworkImage(
                                                admin['image'] as String)
                                            : FileImage(admin['image'] as File)
                                                as ImageProvider)
                                        : const AssetImage(
                                            'assets/images/default_avatar.png'),
                                  );
                                },
                              ),
                              builder: (context, imageProvider, _) {
                                return CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.white,
                                  backgroundImage: imageProvider,
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Name
                        TextFormField(
                          controller: nameController,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration("Name", Icons.person),
                          validator: (value) => value == null || value.isEmpty
                              ? "Enter name"
                              : null,
                        ),
                        const SizedBox(height: 15),

                        // ID
                        TextFormField(
                          controller: idController,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration("Admin ID", Icons.badge),
                          validator: (value) => value == null || value.isEmpty
                              ? "Enter ID"
                              : null,
                        ),
                        const SizedBox(height: 15),

                        // Email
                        TextFormField(
                          controller: emailController,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration("Email", Icons.email),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return "Enter email";
                            if (!RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$')
                                .hasMatch(value)) {
                              return "Enter valid Gmail address";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),

                        // Phone
                        TextFormField(
                          textInputAction: TextInputAction.next,
                          controller: phoneController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration:
                              _inputDecoration("Phone", Icons.phone).copyWith(
                            counterText: "",
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return "Enter phone number";
                            if (value.length != 10)
                              return "Phone must be exactly 10 digits";
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),

                        // Password
                        TextFormField(
                          textInputAction: TextInputAction.next,
                          controller: passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.white),
                          decoration:
                              _inputDecoration("Password", Icons.lock).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.cyanAccent,
                              ),
                              onPressed: () {
                                setStateDialog(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              Fluttertoast.showToast(
                                msg: "Enter password",
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor: Colors.redAccent,
                                textColor: Colors.white,
                                fontSize: 14,
                              );
                              return "";
                            }
                            String pattern =
                                r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$&*~%^()_+=\-{};:"<>,.?/]).{8,}$';
                            if (!RegExp(pattern).hasMatch(v)) {
                              Fluttertoast.showToast(
                                msg:
                                    "Password must be 8+ chars, with A-Z, a-z, 0-9 & special char",
                                toastLength: Toast.LENGTH_LONG,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor: Colors.redAccent,
                                textColor: Colors.white,
                                fontSize: 14,
                                webShowClose: true,
                              );
                              return "";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.cyanAccent,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () async {
                                if (!_formKey.currentState!.validate()) return;

                                final newName = nameController.text.trim();
                                final newId = idController.text.trim();
                                final newEmail = emailController.text.trim();
                                final newPhone = phoneController.text.trim();
                                final newPassword =
                                    passwordController.text.trim();

                                // 🔹 Step 1: Update local state immediately (fast UI update)
                                setState(() {
                                  admins.remove(email);
                                  admins[newEmail] = {
                                    'name': newName,
                                    'id': newId,
                                    'email': newEmail,
                                    'phone': newPhone,
                                    'password': newPassword,
                                    'image': (admin['image'] is String)
                                        ? admin['image']
                                        : '', // only string allowed // keep old until new uploaded
                                  };
                                });

                                Navigator.pop(context);
                                _showFancySnackBar(
                                    context,
                                    "Admin updated successfully",
                                    Icons.check_circle);

                                try {
                                  // 🔹 Step 2: Firestore quick update with placeholder
                                  await FirebaseFirestore.instance
                                      .collection('Admin_Profiles')
                                      .doc(newEmail)
                                      .set({
                                    'name': newName,
                                    'id': newId,
                                    'email': newEmail,
                                    'phone': newPhone,
                                    'password': newPassword,
                                    'image': admin['image'] ?? '',
                                  }, SetOptions(merge: true));

                                  // 🔹 Step 3: If image selected, upload in background
                                  if (selectedImageFile != null) {
                                    final fileName =
                                        "${DateTime.now().millisecondsSinceEpoch}.jpg";
                                    final ref = FirebaseStorage.instance
                                        .ref()
                                        .child("admin_images")
                                        .child(fileName);
                                    final uploadTask =
                                        ref.putFile(selectedImageFile!);
                                    final snapshot = await uploadTask;
                                    final imageUrl =
                                        await snapshot.ref.getDownloadURL();

                                    await FirebaseFirestore.instance
                                        .collection('Admin_Profiles')
                                        .doc(newEmail)
                                        .update({
                                      'image': imageUrl,
                                    });

                                    // Update local notifier to new image
                                    _imageNotifiers[newEmail]?.value =
                                        NetworkImage(imageUrl);
                                    admins[newEmail]!['image'] = imageUrl;
                                  }
                                } catch (e) {
                                  Fluttertoast.showToast(
                                      msg: "Error updating admin: $e",
                                      backgroundColor: Colors.red);
                                }
                              },
                              child: const Text("Save"),
                            ),
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel",
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextFormField(String label, TextEditingController controller,
      {required IconData icon,
      bool obscure = false,
      TextInputType inputType = TextInputType.text,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      textInputAction: TextInputAction.next,
      obscureText: obscure,
      keyboardType: inputType,
      validator: validator,
      inputFormatters: inputType == TextInputType.phone
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10)
            ]
          : null,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.cyanAccent),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        prefixIcon: Icon(icon, color: Colors.cyanAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.cyanAccent),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {required IconData icon,
      bool obscure = false,
      TextInputType inputType = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: inputType,
      inputFormatters: inputType == TextInputType.phone
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10)
            ]
          : null,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.cyanAccent),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        prefixIcon: Icon(icon, color: Colors.cyanAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.cyanAccent),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return TextField(
      enabled: false,
      controller: TextEditingController(text: value),
      style: const TextStyle(color: Colors.white70, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        prefixIcon: Icon(icon, color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildAdminCard(String email, Map<String, dynamic> admin) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1e293b), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Profile Image
          GestureDetector(
            onTap: () => _viewFullImage(email, admin),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00c6ff), Color(0xFF0072ff)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ValueListenableBuilder<ImageProvider<Object>>(
                valueListenable: _imageNotifiers.putIfAbsent(
                  email,
                  () => ValueNotifier<ImageProvider<Object>>(
                    (admin['image'] != null && admin['image'] != '')
                        ? NetworkImage(admin['image']) as ImageProvider<Object>
                        : const AssetImage('assets/images/default_avatar.png'),
                  ),
                ),
                builder: (context, imageProvider, _) {
                  return CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    backgroundImage: imageProvider,
                  );
                },
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        admin['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.cyanAccent,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.edit, color: Colors.cyanAccent),
                          onPressed: () => _editAdmin(email, admin),
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _confirmDeleteAdmin(context, email),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.badge, color: Colors.deepOrange, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        admin['id'] ?? '',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                /// Phone
                Row(
                  children: [
                    const Icon(Icons.phone, color: Colors.deepOrange, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final Uri telUri =
                              Uri(scheme: 'tel', path: admin['phone']);
                          if (await canLaunchUrl(telUri))
                            await launchUrl(telUri);
                        },
                        child: Text(
                          admin['phone'] ?? '',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                /// Email
                Row(
                  children: [
                    const Icon(Icons.email, color: Colors.deepOrange, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final Uri emailUri =
                              Uri(scheme: 'mailto', path: email);
                          if (await canLaunchUrl(emailUri))
                            await launchUrl(emailUri);
                        },
                        child: Text(
                          email,
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                /// Password
                Row(
                  children: [
                    const Icon(Icons.password,
                        color: Colors.deepOrange, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        admin['password'] ?? '',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _viewFullImage(String email, Map<String, dynamic> admin) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: admin['image'] != null
                    ? admin['image'] is File
                        ? Image.file(admin['image'], fit: BoxFit.contain)
                        : Image.network(admin['image'], fit: BoxFit.contain)
                    : Image.asset('assets/images/default_avatar.png',
                        fit: BoxFit.contain),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateAdminDialog() {
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final idController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();

    File? selectedImageFile;
    bool isPasswordVisible = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            elevation: 20,
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0F2027),
                    Color(0xFF203A43),
                    Color(0xFF2C5364)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Create New Admin",
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 20),

                      // Avatar selection
                      GestureDetector(
                        onTap: () async {
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20)),
                            ),
                            builder: (context) {
                              return Wrap(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.camera_alt,
                                        color: Colors.blue),
                                    title: const Text("Take a photo"),
                                    onTap: () async {
                                      final pickedFile =
                                          await _picker.pickImage(
                                              source: ImageSource.camera);
                                      if (pickedFile != null) {
                                        setStateDialog(() => selectedImageFile =
                                            File(pickedFile.path));
                                      }
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.photo,
                                        color: Colors.green),
                                    title: const Text("Choose from gallery"),
                                    onTap: () async {
                                      final pickedFile =
                                          await _picker.pickImage(
                                              source: ImageSource.gallery);
                                      if (pickedFile != null) {
                                        setStateDialog(() => selectedImageFile =
                                            File(pickedFile.path));
                                      }
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: selectedImageFile != null
                              ? FileImage(selectedImageFile!)
                              : const AssetImage(
                                      'assets/images/default_avatar.png')
                                  as ImageProvider,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text("Tap to select image",
                          style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 20),

                      // Form Fields
                      _buildTextFormField("Name", nameController,
                          icon: Icons.person,
                          validator: (v) =>
                              v == null || v.isEmpty ? "Enter name" : null),
                      const SizedBox(height: 12),
                      _buildTextFormField("Admin ID", idController,
                          icon: Icons.badge,
                          validator: (v) =>
                              v == null || v.isEmpty ? "Enter ID" : null),
                      const SizedBox(height: 12),
                      _buildTextFormField(
                        "Email",
                        emailController,
                        icon: Icons.email,
                        inputType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Enter email";
                          if (!RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$')
                              .hasMatch(v)) return "Enter valid Gmail address";
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildTextFormField(
                        "Phone",
                        phoneController,
                        icon: Icons.phone,
                        inputType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return "Enter phone number";
                          if (!RegExp(r'^[0-9]{10}$').hasMatch(v))
                            return "Enter 10-digit number";
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Password
                      TextFormField(
                        controller: passwordController,
                        obscureText: !isPasswordVisible,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Password",
                          hintStyle: const TextStyle(color: Colors.white60),
                          filled: true,
                          fillColor: Colors.white10,
                          prefixIcon:
                              const Icon(Icons.lock, color: Colors.cyanAccent),
                          suffixIcon: IconButton(
                            icon: Icon(
                                isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.white),
                            onPressed: () => setStateDialog(
                                () => isPasswordVisible = !isPasswordVisible),
                          ),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Enter password";
                          String pattern =
                              r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$&*~%^()_+=\-{};:"<>,.?/]).{8,}$';
                          if (!RegExp(pattern).hasMatch(v))
                            return "Password must be 8+ chars with A-Z, a-z, 0-9 & special char";
                          return null;
                        },
                      ),
                      const SizedBox(height: 25),

                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent.shade400,
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 14),
                            ),
                            onPressed: () async {
                              if (!_formKey.currentState!.validate()) return;
                              if (selectedImageFile == null) {
                                Fluttertoast.showToast(
                                  msg:
                                      "Please select an image before creating admin",
                                  backgroundColor: Colors.orange,
                                  textColor: Colors.white,
                                );
                                return;
                              }

                              // Show loader
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.cyanAccent),
                                ),
                              );

                              final name = nameController.text.trim();
                              final id = idController.text.trim();
                              final adminid = _adminidcontroller.text.trim();
                              final email = emailController.text.trim();
                              final phone = phoneController.text.trim();
                              final password = passwordController.text.trim();

                              try {
                                final docSnapshot = await FirebaseFirestore
                                    .instance
                                    .collection('Admin_Profiles')
                                    .doc(email)
                                    .get();

                                if (docSnapshot.exists) {
                                  Navigator.pop(context);
                                  Fluttertoast.showToast(
                                    msg: "Admin with this email already exists",
                                    backgroundColor: Colors.orange,
                                    textColor: Colors.white,
                                  );
                                  return;
                                }

                                _imageNotifiers[email] =
                                    ValueNotifier<ImageProvider<Object>>(
                                  FileImage(selectedImageFile!),
                                );

                                await FirebaseFirestore.instance
                                    .collection('Admin_Profiles')
                                    .doc(email)
                                    .set({
                                  'name': name,
                                  'adminid': adminid,
                                  'id': id,
                                  'email': email,
                                  'phone': phone,
                                  'password': password,
                                  'image': '', // placeholder
                                  'createdAt': FieldValue.serverTimestamp(),
                                });

                                setState(() {
                                  admins[email] = {
                                    'name': name,
                                    'adminid': adminid,
                                    'id': id,
                                    'email': email,
                                    'phone': phone,
                                    'password': password,
                                    'image': '',
                                  };
                                  _imageNotifiers[email] =
                                      ValueNotifier<ImageProvider<Object>>(
                                    FileImage(selectedImageFile!),
                                  );
                                });

                                Navigator.pop(context);
                                Navigator.pop(context);

                                _showFancySnackBar(
                                    context,
                                    "Admin created successfully",
                                    Icons.check_circle);

                                final imageUrl = await _uploadImageToStorage(
                                    email, selectedImageFile!);
                                if (imageUrl != null) {
                                  await FirebaseFirestore.instance
                                      .collection('Admin_Profiles')
                                      .doc(email)
                                      .update({'image': imageUrl});

                                  // Update notifier to network image
                                  _imageNotifiers[email]!.value =
                                      NetworkImage(imageUrl)
                                          as ImageProvider<Object>;
                                }
                              } catch (e) {
                                Navigator.pop(context);
                                Fluttertoast.showToast(
                                  msg: "Error: $e",
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                );
                              }
                            },
                            child: const Text("Create",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black)),
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent.shade400,
                              side:
                                  BorderSide(color: Colors.redAccent.shade400),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 14),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF0f2027),
        elevation: 6,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.cyanAccent), // back button
          onPressed: () {
            Navigator.pop(context); // go back
          },
        ),
        title: const Text(
          "Admin Profiles",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.cyanAccent,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.person_add, size: 20),
              label: const Text(
                "Add New",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
              onPressed: _showCreateAdminDialog,
            ),
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.cyan),
      ),
      body: Container(
        color: Colors.white,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Admin_Profiles')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No Admin Profiles Found"));
            }

            final admins = snapshot.data!.docs;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: admins.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildAdminCard(doc.id, data);
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.cyanAccent),
    filled: true,
    fillColor: Colors.white.withOpacity(0.1),
    prefixIcon: Icon(icon, color: Colors.cyanAccent),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.cyanAccent),
      borderRadius: BorderRadius.circular(12),
    ),
  );
}

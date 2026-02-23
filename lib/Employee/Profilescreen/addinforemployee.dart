import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:techlead/Employee/Homescreen/EmpHomescreen.dart';

class AddProfilePage extends StatefulWidget {
  const AddProfilePage({super.key});

  @override
  State<AddProfilePage> createState() => _AddProfilePageState();
}

class _AddProfilePageState extends State<AddProfilePage> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  XFile? _imageFile;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _empIdController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _qualificationController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dateOfJoiningController = TextEditingController();

  bool _isSubmitting = false;

  final List<String> _categories = [
    'Digital Marketing', 'Sales', 'Installation', 'Human Resource',
    'Reception', 'Account','Finance','Management', 'Services', 'Social Media'
  ];

  Map<String, bool> _selectedCategories = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    for (var category in _categories) {
      _selectedCategories[category] = false;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fullNameController.dispose();
    _empIdController.dispose();
    _dobController.dispose();
    _qualificationController.dispose();
    _addressController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _dateOfJoiningController.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Pick from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    }
    catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to pick image: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    DateTime initialDate = DateTime.now();
    DateTime firstDate = DateTime(1900);
    DateTime lastDate = DateTime.now();
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (selectedDate != null) {
      controller.text = DateFormat('dd MMMM yyyy').format(selectedDate);
    }
  }

  // ✅ SAFE FCM TOKEN RETRIEVAL (Works for Web PWA)
  Future<String?> _getSafeFcmToken() async {
    try {
      if (kIsWeb) {
        // Web/PWA: Check if messaging is supported
        bool isSupported = await FirebaseMessaging.instance.isSupported();
        if (!isSupported) {
          print("⚠️ FCM not supported on this browser/device (likely iOS PWA)");
          return "web_not_supported"; // Placeholder token
        }
      }

      // Try to get FCM token with timeout
      String? token = await FirebaseMessaging.instance
          .getToken()
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print("⏱️ FCM token request timed out");
          return null;
        },
      );

      return token ?? "token_unavailable";
    } catch (e) {
      print("❌ Error getting FCM token: $e");
      return "token_error"; // Placeholder for error cases
    }
  }

  // ✅ SAFE TOKEN REFRESH (Only if supported)
  Future<void> _refreshAndSaveFcmToken({
    required String userId,
    required bool isAdmin,
  }) async {
    try {
      if (kIsWeb) {
        bool isSupported = await FirebaseMessaging.instance.isSupported();
        if (!isSupported) {
          print("⚠️ FCM refresh not available on iOS PWA");
          return;
        }
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        if (newToken.isEmpty) return;

        final collection = isAdmin ? 'Admin_Profiles' : 'EmpProfile';

        await FirebaseFirestore.instance
            .collection(collection)
            .doc(userId)
            .set({'fcmToken': newToken}, SetOptions(merge: true));

        print("✅ FCM token refreshed and saved in $collection: $newToken");
      });
    } catch (e) {
      print("❌ Error saving refreshed FCM token: $e");
    }
  }

  Future<void> _submitData() async {
    if (_imageFile == null) {
      Fluttertoast.showToast(
        msg: "Please select a profile image.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in.");

      // ✅ USE SAFE FCM TOKEN RETRIEVAL
      String? fcmToken = await _getSafeFcmToken();
      print("📱 FCM Token: $fcmToken");

      final userId = user.uid;
      List<String> selectedCategories = _selectedCategories.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      // 🔥 Duplicate check
      var duplicateCheck = await FirebaseFirestore.instance
          .collection('EmpProfile')
          .where('empId', isEqualTo: _empIdController.text.trim())
          .get();

      if (duplicateCheck.docs.isNotEmpty) {
        Fluttertoast.showToast(
          msg: "This Employee ID already exists!",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      // email duplicate check
      var emailCheck = await FirebaseFirestore.instance
          .collection('EmpProfile')
          .where('email', isEqualTo: _emailController.text.trim())
          .get();

      if (emailCheck.docs.isNotEmpty) {
        Fluttertoast.showToast(
          msg: "This Email already exists!",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      // mobile duplicate check
      var mobileCheck = await FirebaseFirestore.instance
          .collection('EmpProfile')
          .where('mobile', isEqualTo: _mobileController.text.trim())
          .get();

      if (mobileCheck.docs.isNotEmpty) {
        Fluttertoast.showToast(
          msg: "This Mobile Number already exists!",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      // Upload image
      String? imageUrl;
      if (_imageFile != null) {
        if (kIsWeb) {
          // For web, use bytes
          final bytes = await _imageFile!.readAsBytes();
          final ref = FirebaseStorage.instance
              .ref()
              .child('profile_images')
              .child('$userId.jpg');
          await ref.putData(bytes);
          imageUrl = await ref.getDownloadURL();
        } else {
          // For mobile
          final ref = FirebaseStorage.instance
              .ref()
              .child('profile_images')
              .child('$userId.jpg');
          await ref.putFile(File(_imageFile!.path));
          imageUrl = await ref.getDownloadURL();
        }
      }

      final Map<String, dynamic> profileData = {
        'userId': userId,
        'fullName': _fullNameController.text.trim(),
        'empId': _empIdController.text.trim(),
        'dob': _dobController.text.trim(),
        'qualification': _qualificationController.text.trim(),
        'categories': selectedCategories,
        'address': _addressController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'email': _emailController.text.trim(),
        'dateOfJoining': _dateOfJoiningController.text.trim(),
        'profileImage': imageUrl ?? '',
        'fcmToken': fcmToken ?? 'not_available',
        'platform': kIsWeb ? 'web' : Platform.operatingSystem,
      };

      await FirebaseFirestore.instance
          .collection('EmpProfile')
          .doc(userId)
          .set(profileData);

      await _refreshAndSaveFcmToken(userId: userId, isAdmin: false);

      Fluttertoast.showToast(
        msg: "Employee Profile added successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      setState(() {
        _isSubmitting = false;
      });

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(initialIndex: 4),
        ),
            (route) => false,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error adding profile: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Employee Profile Info",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, fontFamily: "Times New Roman", color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.cyan, Colors.indigo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        elevation: 8,
      ),
      body: Form(
        key: _formKey,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade50, Colors.cyan.shade100],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 15,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _showImageSourceDialog,
                        onTapDown: (_) => _animationController.forward(),
                        onTapUp: (_) => _animationController.reverse(),
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 1 + (_animationController.value * 0.1),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 160,
                                    height: 160,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [Colors.cyan, Colors.indigo],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.shade400,
                                          blurRadius: 15,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                  ),
                                  CircleAvatar(
                                    radius: 75,
                                    backgroundColor: Colors.white,
                                    child: _imageFile == null
                                        ? const Icon(Icons.camera_alt, size: 50, color: Colors.indigo)
                                        : ClipOval(
                                      child: kIsWeb
                                          ? Image.network(
                                        _imageFile!.path,
                                        fit: BoxFit.cover,
                                        width: 150,
                                        height: 150,
                                      )
                                          : Image.file(
                                        File(_imageFile!.path),
                                        fit: BoxFit.cover,
                                        width: 150,
                                        height: 150,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Divider(
                        thickness: 2,
                        color: Colors.indigo.shade200,
                        endIndent: 30,
                        indent: 30,
                      ),
                      _buildDecoratedField(
                        controller: _fullNameController,
                        label: 'Full Name',
                        icon: Icons.person,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Full name is required.';
                          }
                          return null;
                        },
                      ),
                      _buildDecoratedField(
                        controller: _empIdController,
                        label: 'Employee ID',
                        icon: Icons.badge,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Employee ID is required.';
                          }
                          return null;
                        },
                      ),
                      _buildDecoratedField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required.';
                          } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Enter a valid email address.';
                          }
                          return null;
                        },
                      ),
                      _buildDecoratedField(
                        controller: _mobileController,
                        label: 'Mobile Number',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(10),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Mobile number is required.';
                          } else if (value.length != 10) {
                            return 'Mobile number must be 10 digits.';
                          } else if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                            return 'Enter a valid 10-digit number.';
                          }
                          return null;
                        },
                      ),

                      _buildDecoratedField(
                        controller: _dobController,
                        label: 'Date of Birth',
                        icon: Icons.calendar_today,
                        onTap: () => _selectDate(_dobController),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Date of birth is required.';
                          }
                          return null;
                        },
                      ),
                      _buildDecoratedField(
                        controller: _dateOfJoiningController,
                        label: 'Date of Joining',
                        icon: Icons.calendar_today,
                        onTap: () => _selectDate(_dateOfJoiningController),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Date of joining is required.';
                          }
                          return null;
                        },
                      ),
                      _buildDecoratedField(
                        controller: _qualificationController,
                        label: 'Qualification',
                        icon: Icons.school,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Qualification is required.';
                          }
                          return null;
                        },
                      ),
                      _buildDecoratedField(
                        controller: _addressController,
                        label: 'Address',
                        icon: Icons.location_on,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Address is required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.grey.shade100,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade300,
                              blurRadius: 5,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: Text(
                                  'Select Categories:',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 5,
                                children: _categories.map((category) {
                                  return FilterChip(
                                    label: Text(category),
                                    selected: _selectedCategories[category]!,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedCategories[category] = selected;
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _isSubmitting ? null : _submitData,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.cyan, Colors.indigo],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 70),
                          child: _isSubmitting
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                            'Submit',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDecoratedField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        readOnly: onTap != null,
        textInputAction: TextInputAction.next,
        onEditingComplete: () => FocusScope.of(context).nextFocus(),
        onTap: onTap,
        keyboardType: keyboardType,
        validator: validator,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.indigo),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.indigo, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
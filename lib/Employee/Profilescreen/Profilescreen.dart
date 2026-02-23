import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as legacy_provider;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techlead/Employee/Authentication/EnLoginPage.dart';
import 'package:techlead/Employee/Authentication/Enteredscreen.dart';
import '../../Default/Themeprovider.dart';
import 'addinforemployee.dart';

class ProfileScreen extends StatefulWidget {
  final String category;
  const ProfileScreen({Key? key, required this.category, required String userId}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  bool _hasProfile = false;
  bool _showAddIcon = false;
  bool _loading = true;
  late AnimationController _animationController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _empIdController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _qualificationController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dateOfJoiningController = TextEditingController();


  final List<String> _categories = [
    'Digital Marketing', 'Sales', 'Installation', 'Human Resource Dev',
    'Reception', 'Accountant', 'Services', 'Social Media Marketing'
  ];

  final Map<String, bool> _selectedCategories = {};
  @override
  void initState() {
    super.initState();
    _initializeCategories();
    userId = FirebaseAuth.instance.currentUser!.uid;
    _checkProfile();
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

  void _initializeCategories() {
    for (var category in _categories) {
      _selectedCategories[category] = false;
    }
  }

  Future<void> _checkProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('EmpProfile')
        .doc(user.uid)
        .get();

    setState(() {
      _hasProfile = doc.exists && (doc.data() != null && (doc.data() as Map).isNotEmpty);
      _showAddIcon = !_hasProfile;
      _loading = false;
    });
  }

  String userId = FirebaseAuth.instance.currentUser!.uid;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Employee Profile',
            style: TextStyle(
              fontFamily: "Times New Roman",
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.blue.shade900,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            // Add Profile button (conditional)
            if (_showAddIcon)
              IconButton(
                icon: const Icon(Icons.person_add, color: Colors.white),
                tooltip: 'Add Profile',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddProfilePage()),
                  );
                  _checkProfile();
                },
              ),
            // Logout button (always visible)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'Logout',
              onPressed: () {
                showLogoutConfirmationDialog(context);
              },
            ),
          ],
        ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('EmpProfile')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading profile.'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists || (snapshot.data!.data() as Map).isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_off, size: 80, color: Colors.grey),
                    const SizedBox(height: 10),
                    const Text(
                      'No profile found!\nPlease add your profile!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: "Times New Roman",
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_add),
                      label: const Text("Add Profile"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AddProfilePage()),
                        );
                        _checkProfile();
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          return _buildProfileContent(data);
        },
      ),


    );
  }
  Widget _buildProfileContent(Map<String, dynamic> data) {
    final profileData = {
      'fullName': data['fullName'] ?? 'N/A',
      'empId': data['empId'] ?? 'N/A',
      'email': data['email'] ?? 'N/A',
      'mobile': data['mobile'] ?? 'N/A',
      'categories': (data['categories'] as List?)?.cast<String>() ?? [],
      'address': data['address'] ?? 'N/A',
      'dob': data['dob'] ?? 'N/A',
      'qualification': data['qualification'] ?? 'N/A',
      'dateOfJoining': data['dateOfJoining'] ?? 'N/A',
      'profileImage': data['profileImage'] ?? '',
    };

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildProfileCard(profileData),
          const SizedBox(height: 20),
          _buildInfoCards(profileData),
        ],
      ),
    );
  }


  Widget _buildProfileCard(Map<String, dynamic> profileData) {
    return Container(
      width: 330,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Color(0xFF15489C),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              final imageUrl = profileData['profileImage'];
              if (imageUrl != null && imageUrl.toString().isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImageView(imageUrl: imageUrl),
                  ),
                );
              }
            },
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              backgroundImage: (profileData['profileImage'] != null &&
                  profileData['profileImage'].toString().isNotEmpty)
                  ? NetworkImage(profileData['profileImage'])
                  : null,
              child: (profileData['profileImage'] == null ||
                  profileData['profileImage'].toString().isEmpty)
                  ? const Icon(Icons.person, size: 50, color: Colors.grey)
                  : null,
            ),
          ),

          const SizedBox(height: 10),
          Text(
            profileData['fullName'] ?? 'N/A',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.sunny, color: Colors.white),
                onPressed: () {
                  final themeProvider = Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  );

                  themeProvider.toggleTheme();

                  final isDarkMode = themeProvider.isDarkMode;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.green,
                      content: Text(
                        isDarkMode ? 'Dark mode enabled!' : 'Light mode enabled!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),

              const Spacer(),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () {
                  showLogoutConfirmationDialog(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards(Map<String, dynamic> profileData) {
    return Column(
      children: [
        _buildInfoCard(
          title: 'Personal Information',
          icon: Icons.person,
          fields: [
            _buildInfoRow('Employee ID', profileData['empId']),
            _buildInfoRow('Email', profileData['email']),
            _buildInfoRow('Contact', profileData['mobile']),
            _buildInfoRow('Department', (profileData['categories'] as List<dynamic>).join(', ')),
            _buildInfoRow('Address', profileData['address']),
            _buildInfoRow('Date of Birth', profileData['dob']),
          ],
        ),
        const SizedBox(height: 20),
        _buildInfoCard(
          title: 'Work Experience',
          icon: Icons.work,
          fields: [
            _buildInfoRow('Qualification', profileData['qualification']),
            _buildInfoRow('Date of Joining', profileData['dateOfJoining']),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required List<Widget> fields}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 4,
        color: const Color(0xFF15489C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...fields,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // void _showEditProfileSheet(Map<String, dynamic> profileData) {
  //   final GlobalKey<FormState> _editFormKey = GlobalKey<FormState>();
  //
  //   final TextEditingController fullNameController = TextEditingController(text: profileData['fullName']);
  //   final TextEditingController empIdController = TextEditingController(text: profileData['empId']);
  //   final TextEditingController dobController = TextEditingController(text: profileData['dob']);
  //   final TextEditingController qualificationController = TextEditingController(text: profileData['qualification']);
  //   final TextEditingController addressController = TextEditingController(text: profileData['address']);
  //   final TextEditingController mobileController = TextEditingController(text: profileData['mobile']);
  //   final TextEditingController emailController = TextEditingController(text: profileData['email']);
  //   final TextEditingController dateOfJoiningController = TextEditingController(text: profileData['dateOfJoining']);
  //
  //   String imageUrl = profileData['profileImage'] ?? '';
  //   File? selectedImage;
  //
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.white,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (context) {
  //       return Padding(
  //         padding: EdgeInsets.only(
  //           top: 20,
  //           left: 16,
  //           right: 16,
  //           bottom: MediaQuery.of(context).viewInsets.bottom + 20,
  //         ),
  //         child: StatefulBuilder(builder: (context, setState) {
  //           return SingleChildScrollView(
  //             child: Form(
  //               key: _editFormKey,
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.center,
  //                 children: [
  //                   // Top blue back button
  //                   Row(
  //                     children: [
  //                       IconButton(
  //                         icon: Icon(Icons.arrow_back, color: Colors.blueAccent),
  //                         onPressed: () => Navigator.pop(context),
  //                       ),
  //                       const Spacer(),
  //                       const Text(
  //                         'Edit Profile',
  //                         style: TextStyle(
  //                           fontSize: 22,
  //                           fontWeight: FontWeight.bold,
  //                           color: Colors.blueAccent,
  //                         ),
  //                       ),
  //                       const Spacer(flex: 2),
  //                     ],
  //                   ),
  //                   const SizedBox(height: 20),
  //                   Stack(
  //                     alignment: Alignment.bottomRight,
  //                     children: [
  //                       CircleAvatar(
  //                         radius: 50,
  //                         backgroundImage: selectedImage != null
  //                             ? FileImage(selectedImage!)
  //                             : imageUrl.isNotEmpty
  //                             ? NetworkImage(imageUrl)
  //                             : const AssetImage('assets/images/gallery.png') as ImageProvider,
  //                       ),
  //                       IconButton(
  //                         icon: const Icon(Icons.edit, color: Colors.blueAccent),
  //                         onPressed: () async {
  //                           final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
  //                           if (picked != null) {
  //                             setState(() {
  //                               selectedImage = File(picked.path);
  //                             });
  //                           }
  //                         },
  //                       ),
  //                     ],
  //                   ),
  //                   const SizedBox(height: 20),
  //                   _buildInput(fullNameController, 'Full Name', validator: (val) => val!.isEmpty ? 'Enter name' : null),
  //                   _buildInput(empIdController, 'Employee ID', validator: (val) => val!.isEmpty ? 'Enter Employee ID' : null),
  //                   _buildInput(dobController, 'Date of Birth',
  //                       readOnly: true,
  //                       onTap: () async {
  //                         final pickedDate = await showDatePicker(
  //                           context: context,
  //                           initialDate: DateTime.tryParse(dobController.text) ?? DateTime.now(),
  //                           firstDate: DateTime(1950),
  //                           lastDate: DateTime.now(),
  //                         );
  //                         if (pickedDate != null) {
  //                           dobController.text = pickedDate.toString().split(' ')[0];
  //                         }
  //                       },
  //                       validator: (val) => val!.isEmpty ? 'Pick DOB' : null),
  //                   _buildInput(qualificationController, 'Qualification',
  //                       validator: (val) => val!.isEmpty ? 'Enter qualification' : null),
  //                   _buildInput(addressController, 'Address', validator: (val) => val!.isEmpty ? 'Enter address' : null),
  //                   _buildInput(mobileController, 'Mobile',
  //                       keyboardType: TextInputType.phone,
  //                       validator: (val) {
  //                         if (val == null || val.isEmpty) return 'Enter mobile number';
  //                         if (!RegExp(r'^[0-9]{10}$').hasMatch(val)) return 'Enter valid 10-digit number';
  //                         return null;
  //                       }),
  //                   _buildInput(emailController, 'Email',
  //                       keyboardType: TextInputType.emailAddress,
  //                       validator: (val) {
  //                         if (val == null || val.isEmpty) return 'Enter email';
  //                         if (!RegExp(r'^[\w-\.]+@gmail\.com$').hasMatch(val)) return 'Enter valid Gmail ID';
  //                         return null;
  //                       }),
  //                   _buildInput(dateOfJoiningController, 'Date of Joining',
  //                       readOnly: true,
  //                       onTap: () async {
  //                         final pickedDate = await showDatePicker(
  //                           context: context,
  //                           initialDate: DateTime.tryParse(dateOfJoiningController.text) ?? DateTime.now(),
  //                           firstDate: DateTime(2000),
  //                           lastDate: DateTime.now(),
  //                         );
  //                         if (pickedDate != null) {
  //                           dateOfJoiningController.text = pickedDate.toString().split(' ')[0];
  //                         }
  //                       },
  //                       validator: (val) => val!.isEmpty ? 'Pick joining date' : null),
  //                   const SizedBox(height: 20),
  //                   ElevatedButton.icon(
  //                     icon: const Icon(Icons.update),
  //                     label: const Text('Update Profile'),
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: Colors.blueAccent,
  //                       foregroundColor: Colors.white,
  //                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  //                       textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //                     ),
  //                     onPressed: () async {
  //                       if (_editFormKey.currentState!.validate()) {
  //                         String? newImageUrl;
  //
  //                         if (selectedImage != null) {
  //                           final storageRef = FirebaseStorage.instance
  //                               .ref('profile_images/${DateTime.now().millisecondsSinceEpoch}');
  //                           await storageRef.putFile(selectedImage!);
  //                           newImageUrl = await storageRef.getDownloadURL();
  //                         }
  //
  //                         final updatedData = {
  //                           'fullName': fullNameController.text,
  //                           'empId': empIdController.text,
  //                           'dob': dobController.text,
  //                           'qualification': qualificationController.text,
  //                           'address': addressController.text,
  //                           'mobile': mobileController.text,
  //                           'email': emailController.text,
  //                           'dateOfJoining': dateOfJoiningController.text,
  //                           'logoUrl': newImageUrl ?? imageUrl,
  //                         };
  //
  //                         await _updateProfile(updatedData);
  //                         Navigator.pop(context);
  //                       }
  //                     },
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           );
  //         }),
  //       );
  //     },
  //   );
  // }

  void showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.logout, color: Colors.blueAccent),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Logout Techlead App?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Times New Roman',
                    ),
                  ),
                ),
              ],
            ),
            content: const Text('Are you sure you want to logout?',
                style: TextStyle(fontSize: 16)),
            actionsPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => Enteredscreen()),
                        (route) => false,
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }
}

class FullScreenImageView extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageView({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:techlead/Widgeets/custom_app_bar.dart';
import 'package:techlead/core/app_bar_provider.dart';

class AllEmpEditProfiles extends ConsumerStatefulWidget {
  final Map<String, dynamic> profileData;
  final VoidCallback onUpdateSuccess;

  const AllEmpEditProfiles({
    Key? key,
    required this.profileData,
    required this.onUpdateSuccess,
  }) : super(key: key);

  @override
  ConsumerState<AllEmpEditProfiles> createState() => _AllEmpEditProfilesState();
}

class _AllEmpEditProfilesState extends ConsumerState<AllEmpEditProfiles> {
  late TextEditingController fullNameController;
  late TextEditingController empIdController;
  late TextEditingController dobController;
  late TextEditingController qualificationController;
  late TextEditingController addressController;
  late TextEditingController mobileController;
  late TextEditingController emailController;
  late TextEditingController dateOfJoiningController;

  String imageUrl = '';
  File? selectedImage;
  bool isUploading = false;
  final _editFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final profileData = widget.profileData;
    fullNameController = TextEditingController(text: profileData['fullName']);
    empIdController = TextEditingController(text: profileData['empId']);
    dobController = TextEditingController(text: profileData['dob']);
    qualificationController =
        TextEditingController(text: profileData['qualification']);
    addressController = TextEditingController(text: profileData['address']);
    mobileController = TextEditingController(text: profileData['mobile']);
    emailController = TextEditingController(text: profileData['email']);
    dateOfJoiningController =
        TextEditingController(text: profileData['dateOfJoining']);
    imageUrl = profileData['profileImage'] ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appBarTitleProvider.notifier).state = 'Edit Profile';
      ref.read(appBarGradientColorsProvider.notifier).state = [
        const Color(0xFF0A2A5A),
        const Color(0xFF15489C),
        const Color(0xFF1E64D8),
      ];
      ref.read(customTitleWidgetProvider.notifier).state = null;
    });
  }

  @override
  void dispose() {
    fullNameController.dispose();
    empIdController.dispose();
    dobController.dispose();
    qualificationController.dispose();
    addressController.dispose();
    mobileController.dispose();
    emailController.dispose();
    dateOfJoiningController.dispose();
    Future.microtask(() {
      if (mounted) {
        resetAppBar(ref);
      }
    });
    super.dispose();
  }

  void _pickDate(BuildContext context, TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Widget _buildInput(
    TextEditingController controller,
    String label, {
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    void Function()? onTap,
    String? Function(String?)? validator,
        List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.blue.shade900,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
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
            child: TextFormField(
              controller: controller,
              readOnly: readOnly,
              onTap: onTap,
              keyboardType: keyboardType,
              validator: validator,
              inputFormatters: inputFormatters,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: '', // no hint or label inside
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: Colors.transparent,
              ),
              cursorColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Scaffold(
        // Dark Indigo
        appBar: CustomAppBar(),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              top: 20,
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Form(
              key: _editFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Circle Avatar with gradient shining border
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4), // Border thickness
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.shade900, // White border color
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.7),
                              blurRadius: 9,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),

                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: selectedImage != null
                              ? FileImage(selectedImage!)
                              : imageUrl.isNotEmpty
                                  ? NetworkImage(imageUrl)
                                  : const AssetImage(
                                          'assets/images/gallery.png')
                                      as ImageProvider,
                          child: (selectedImage == null && imageUrl.isEmpty)
                              ? const Icon(Icons.person,
                                  size: 50, color: Colors.grey)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 1,
                        child: Container(
                            height: 35,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF0A2A5A),
                                  Color(0xFF15489C),
                                  Color(0xFF1E64D8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.cyanAccent.withOpacity(0.7),
                                  blurRadius: 12,
                                  spreadRadius: 3,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                                icon: const Icon(Icons.camera_enhance_outlined,
                                    color: Colors.white),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    // Needed for gradient background
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20)),
                                    ),
                                    builder: (context) {
                                      return Container(
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
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(20)),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16, horizontal: 16),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              leading: const Icon(
                                                  Icons.camera_alt,
                                                  color: Colors.white),
                                              title: const Text(
                                                'Take a Photo',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _pickImage(ImageSource.camera);
                                              },
                                            ),
                                            const Divider(
                                                color: Colors.white54),
                                            ListTile(
                                              leading: const Icon(
                                                  Icons.folder_open,
                                                  color: Colors.white),
                                              title: const Text(
                                                'Choose from Files',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _pickImage(ImageSource.gallery);
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                })),
                      )
                    ],
                  ),

                  const SizedBox(height: 20),

                  if (isUploading) const CircularProgressIndicator(),

                  _buildInput(fullNameController, 'Full Name',
                      validator: (val) => val!.isEmpty ? 'Enter name' : null),
                  _buildInput(empIdController, 'Employee ID',
                      validator: (val) =>
                          val!.isEmpty ? 'Enter Employee ID' : null),
                  _buildInput(dobController, 'DOB',
                      readOnly: true,
                      onTap: () => _pickDate(context, dobController),
                      validator: (val) => val!.isEmpty ? 'Pick DOB' : null),
                  _buildInput(qualificationController, 'Qualification',
                      validator: (val) =>
                          val!.isEmpty ? 'Enter qualification' : null),
                  _buildInput(addressController, 'Address',
                      validator: (val) =>
                          val!.isEmpty ? 'Enter address' : null),
                  _buildInput(mobileController, 'Mobile',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(10),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (val) {
                    if (val == null || val.isEmpty)
                      return 'Enter mobile number';
                    if (!RegExp(r'^[0-9]{10}$').hasMatch(val))
                      return 'Enter valid 10-digit number';
                    return null;
                  }),
                  _buildInput(emailController, 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter email';
                    if (!RegExp(r'^[\w-\.]+@gmail\.com$').hasMatch(val))
                      return 'Enter valid Gmail ID';
                    return null;
                  }),
                  _buildInput(dateOfJoiningController, 'Joining Date',
                      readOnly: true,
                      onTap: () => _pickDate(context, dateOfJoiningController),
                      validator: (val) =>
                          val!.isEmpty ? 'Pick joining date' : null),

                  const SizedBox(height: 20),

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
                    child: SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 12),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50, vertical: 14),
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: isUploading
                              ? null
                              : () async {
                                  if (_editFormKey.currentState?.validate() ??
                                      false) {
                                    setState(() => isUploading = true);

                                    try {
                                      String? newImageUrl = imageUrl;

                                      if (selectedImage != null) {
                                        final fileName =
                                            'profile_images/${DateTime.now().millisecondsSinceEpoch}_${widget.profileData['empId']}.jpg';
                                        final ref = FirebaseStorage.instance
                                            .ref()
                                            .child(fileName);
                                        await ref.putFile(selectedImage!);
                                        newImageUrl = await ref.getDownloadURL();
                                      }

                                      final updatedData = {
                                        'fullName': fullNameController.text.trim(),
                                        'empId': empIdController.text.trim(),
                                        'dob': dobController.text.trim(),
                                        'qualification':
                                            qualificationController.text.trim(),
                                        'address': addressController.text.trim(),
                                        'mobile': mobileController.text.trim(),
                                        'email': emailController.text.trim(),
                                        'dateOfJoining':
                                            dateOfJoiningController.text.trim(),
                                        'profileImage': newImageUrl ?? '',
                                      };

                                      await FirebaseFirestore.instance
                                          .collection('EmpProfile')
                                          .doc(widget.profileData['docId'])
                                          .update(updatedData);

                                      setState(() => isUploading = false);

                                      widget
                                          .onUpdateSuccess(); // Call success callback
                                      Navigator.pop(context); // Close the form/page
                                    } catch (e) {
                                      setState(() => isUploading = false);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text('Failed to update: $e')),
                                      );
                                    }
                                  }
                                },
                          child: const Text(
                            'Update',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
    );
  }
}

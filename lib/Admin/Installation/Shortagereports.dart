import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:shared_preferences/shared_preferences.dart';

class ShortageOfProductAdmin extends StatefulWidget {
  const ShortageOfProductAdmin({super.key});

  @override
  State<ShortageOfProductAdmin> createState() => _ShortageOfProductAdminState();
}

class _ShortageOfProductAdminState extends State<ShortageOfProductAdmin> with TickerProviderStateMixin {

  bool _isSubmitting = false;
  bool _isSuccess = false;


  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _requiredQuantityController = TextEditingController();
  final TextEditingController _availableQuantityController = TextEditingController();
  final TextEditingController _siteLocationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactInfoController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _assignedTechnicianController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _animation;
  late AnimationController _iconAnimationController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _iconSizeAnimation;
  late Animation<Color?> _iconColorAnimation;

  List<File> selectedFiles = [];
  List<String> fileNames = [];
  List<String> fileTypes = [];
  List<TextEditingController> fileNameControllers = [];
  List<File> files = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();


  String? _requiredValidator(String? value) {
    if (value == null || value
        .trim()
        .isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    if (value == null || value
        .trim()
        .isEmpty) return 'Phone number is required';
    if (!RegExp(r'^\d{10}$').hasMatch(value))
      return 'Enter a valid 10-digit phone number';
    return null;
  }


  Future<void> _loadAdminData() async {
    final prefs = await SharedPreferences.getInstance();

    final name = prefs.getString('name') ?? '';

    if (mounted) {
      setState(() {
        _assignedTechnicianController.text = name;
      });
    }
  }



  @override
  void initState() {
    super.initState();

    _loadAdminData();

    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )
      ..forward();

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );


    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      lowerBound: 0.9,
      upperBound: 1.0,
    )
      ..forward();

    _buttonScaleAnimation = CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    );


    _iconAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )
      ..repeat(reverse: true);


    _iconSizeAnimation = Tween<double>(begin: 30, end: 35).animate(
      CurvedAnimation(
          parent: _iconAnimationController, curve: Curves.easeInOut),
    );


    _iconColorAnimation =
        ColorTween(begin: Colors.white, end: Colors.yellowAccent).animate(
          CurvedAnimation(
              parent: _iconAnimationController, curve: Curves.easeInOut),
        );
  }



  void showCustomSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade600],
              // Bluish gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Report submitted successfully!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        duration: Duration(seconds: 3), // Duration for the SnackBar to stay
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20), // Optional: space from the edge
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            AlertDialog(
              backgroundColor: Colors.transparent,
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 6, // Thicker spinner line
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.cyan), // Custom spinner color
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Submitting...",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Container(),
            ),
      );

      setState(() {
        _isSubmitting = true;
      });

      String productName = _productNameController.text.trim();
      String requiredQuantity = _requiredQuantityController.text.trim();
      String availableQuantity = _availableQuantityController.text.trim();
      String siteLocation = _siteLocationController.text.trim();
      String description = _descriptionController.text.trim();
      String contactInfo = _contactInfoController.text.trim();
      String address = _addressController.text.trim();
      String assignedTechnician = _assignedTechnicianController.text.trim();

      // Upload files in parallel using Futures
      List<Future<TaskSnapshot>> uploadTasks = [];
      List<Map<String, dynamic>> fileData = [];

      for (int i = 0; i < selectedFiles.length; i++) {
        File file = selectedFiles[i];
        String fileName = fileNames[i];

        String filePath = 'product_files/${DateTime
            .now()
            .millisecondsSinceEpoch}_${fileName}';
        uploadTasks.add(FirebaseStorage.instance.ref(filePath).putFile(file));
      }

      List<TaskSnapshot> uploadResults = await Future.wait(uploadTasks);

      for (int i = 0; i < uploadResults.length; i++) {
        TaskSnapshot uploadTask = uploadResults[i];
        String downloadUrl = await uploadTask.ref.getDownloadURL();
        fileData.add({
          'file_name': fileNames[i],
          'file_url': downloadUrl,
          'file_type': fileTypes[i],
        });
      }

      // Save data to Firestore
      await FirebaseFirestore.instance
          .collection('product_shortage_reports')
          .add({
        'product_name': productName,
        'required_quantity': requiredQuantity,
        'available_quantity': availableQuantity,
        'site_location': siteLocation,
        'description': description,
        'contact_info': contactInfo,
        'address': address,
        'assigned_technician': assignedTechnician,
        'files': fileData,
        'created_at': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isSuccess = true; // Show success
        _isSubmitting = false; // Re-enable the button after submission
      });


      // Show success message
      // Inside your submit form success handler

      showCustomSnackBar(context);


      // Optionally clear the form
      _clearForm();

      // Close the loading spinner dialog after successful submission
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit report!')));

      Navigator.of(context).pop();
    }
  }


  void _clearForm() {
    _productNameController.clear();
    _requiredQuantityController.clear();
    _availableQuantityController.clear();
    _siteLocationController.clear();
    _descriptionController.clear();
    _contactInfoController.clear();
    _addressController.clear();
    setState(() {
      selectedFiles.clear();
      fileNames.clear();
      fileTypes.clear();
      fileNameControllers.clear();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _buttonAnimationController.dispose();
    _iconAnimationController.dispose();
    _buttonAnimationController.dispose();
    _productNameController.dispose();
    _requiredQuantityController.dispose();
    _availableQuantityController.dispose();
    _siteLocationController.dispose();
    _descriptionController.dispose();
    _contactInfoController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true);
    if (result != null) {
      for (var file in result.files) {
        selectedFiles.add(File(file.path!));
        fileNames.add(file.name);
        fileTypes.add(file.extension ?? '');
        fileNameControllers.add(TextEditingController(text: file.name));
      }
      setState(() {});
    }
  }

  void openFile(File file) async {
    await OpenFile.open(file.path);
  }

  void renameFile(int index) {
    setState(() {
      fileNames[index] = fileNameControllers[index].text.isNotEmpty
          ? fileNameControllers[index].text
          : fileNames[index];
      fileNameControllers[index].clear();
    });
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller, {
        TextInputType? keyboardType,
        IconData? icon,
        String? Function(String?)? validator,
        int? maxLength,
        bool readOnly = false, // 🔹 added parameter
      }) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(_animation),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
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
              border: Border.all(
                color: Colors.white,
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              validator: validator,
              maxLength: maxLength,
              readOnly: readOnly, // 🔹 applied here
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              cursorColor: Colors.cyanAccent,
              textInputAction:
              readOnly ? TextInputAction.none : TextInputAction.next,
              onEditingComplete: readOnly
                  ? null
                  : () => FocusScope.of(context).nextFocus(),
              inputFormatters: label.contains("Phone") ||
                  label.contains("Contact")
                  ? [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ]
                  : null,
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                prefixIcon:
                icon != null ? Icon(icon, color: Colors.white) : null,
                border: InputBorder.none,
                counterText: "",
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  Future<String> _loadExcelPreview(File file) async {
    try {
      var bytes = file.readAsBytesSync();
      var workbook = excel.Excel.decodeBytes(bytes);

      var sheet = workbook.tables.keys.first;
      var rows = workbook.tables[sheet]?.rows;

      // Generating a preview string
      String preview = "";
      for (int i = 0; i < (rows?.length ?? 0) && i < 5; i++) {
        preview +=
            rows![i].map((cell) => cell?.value.toString() ?? "").join(", ") +
                "\n";
      }

      return preview.isNotEmpty ? preview : "Empty Excel File";
    } catch (e) {
      return "Failed to read Excel file";
    }
  }

  void removeFile(int index) {
    setState(() {
      selectedFiles.removeAt(index);
      fileTypes.removeAt(index);
      fileNames.removeAt(index);
      fileNameControllers.removeAt(index);
    });
  }



  Widget _buildFilePreview(File file, String fileType) {
    if (fileType == 'jpg' || fileType == 'jpeg' || fileType == 'png') {
      // 🖼 Image Preview
      return Image.file(
        file,
        width: 100,
        height: 80,
        fit: BoxFit.cover,
      );
    } else if (fileType == 'txt' || fileType == 'json' || fileType == 'csv') {
      // 📝 Text File Preview
      return FutureBuilder<String>(
        future: file.readAsString(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Text("Error loading text file");
          } else {
            return Container(
              width: 100,
              height: 80,
              padding: const EdgeInsets.all(8),
              color: Colors.blueGrey,
              child: Text(
                snapshot.data!.length > 100
                    ? snapshot.data!.substring(0, 100) + '...'
                    : snapshot.data!,
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            );
          }
        },
      );
    } else if (fileType == 'xls' || fileType == 'xlsx') {
      // 📊 XLS/XLSX Preview
      return FutureBuilder<String>(
        future: _loadExcelPreview(file),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Text("Error loading Excel file");
          } else {
            return Container(
              width: 100,
              height: 80,
              padding: const EdgeInsets.all(8),
              color: Colors.green.shade700,
              child: Text(
                snapshot.data!,
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            );
          }
        },
      );
    }
    else if (fileType == 'pdf') {
      return FutureBuilder<pdfx.PdfDocument>(
        future: pdfx.PdfDocument.openFile(file.path),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Text("Error loading PDF");
          } else if (snapshot.hasData) {
            // Use the document correctly
            return pdfx.PdfView(
              controller: pdfx.PdfController(
                document: Future.value(snapshot.data!), // Wrap in Future.value
              ),
            );
          } else {
            return const Text("No PDF available");
          }
        },
      );
    }
    else {
      // 🚫 Unsupported File Type
      return const Icon(Icons.insert_drive_file, size: 50, color: Colors.cyan);
    }
  }

  void replaceImage(int index) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any, // Allow all file types
    );

    if (result != null) {
      setState(() {
        selectedFiles[index] = File(result.files.single.path!);
        fileNames[index] = result.files.single.name;
        fileTypes[index] = result.files.single.extension ?? '';
        fileNameControllers[index].text = result.files.single.name;
      });
    }
  }

  Widget _buildFileList() {
    return selectedFiles.isNotEmpty
        ? SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(selectedFiles.length, (index) {
          File file = selectedFiles[index];
          String fileType = fileTypes[index];

          return Stack(
            children: [
              Container(
                width: 160,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0F52BA),
                      Color(0xFF002147),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      offset: const Offset(0, 4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 140,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildFilePreview(file, fileType),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      fileNames[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 140,
                      child: TextField(
                        controller: fileNameControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Rename',
                          labelStyle: TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.15),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12),
                        ),
                        style: const TextStyle(color: Colors.white),
                        cursorColor: Colors.cyanAccent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildActionButton(
                          label: 'Rename',
                          icon: Icons.edit,
                          onPressed: () => renameFile(index),
                        ),
                        _buildActionButton(
                          label: 'Replace',
                          icon: Icons.swap_horiz,
                          onPressed: () => replaceImage(index),
                        ),
                        _buildActionButton(
                          label: 'Open',
                          icon: Icons.open_in_new,
                          onPressed: () => openFile(file),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Red close (X) button
              Positioned(
                right: 4,
                top: 4,
                child: GestureDetector(
                  onTap: () => removeFile(index),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    )
        : const Center(
      child: Text(
        "No files selected yet.",
        style: TextStyle(color: Colors.black, fontSize: 16,fontFamily: "Times New Roman"),
      ),
    );
  }

// Helper for consistent styled buttons with icon and label
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 100, // Fixed width for consistency
      height: 36,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 18,
          color: Colors.black,
        ),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.black,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyanAccent,
          foregroundColor: Colors.black,
          elevation: 3,
          shadowColor: Colors.black45,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
      ),
    );
  }



  Widget _buildChooseFilesButton() {
    return ScaleTransition(
      scale: _buttonScaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _buttonAnimationController.reverse(),
        onTapUp: (_) {
          _buttonAnimationController.forward();
          pickFiles();
        },
        child: Center(
          child: Container(
            width: 200,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF000F89), // Royal Blue
                  Color(0xFF0F52BA), // Cobalt Blue
                  Color(0xFF002147), // Dark Blue
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Choose Files',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ScaleTransition(
      scale: _buttonScaleAnimation,
      child: GestureDetector(
        onTap: _isSubmitting ? null : _submitForm, // ✅ Let _submitForm handle validation
        child: Center(
          child: Container(
            width: 270,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            decoration: BoxDecoration(
              gradient: _isSubmitting
                  ? null
                  : const LinearGradient(
                colors: [
                  Color(0xFF000F89), // Royal Blue
                  Color(0xFF0F52BA), // Cobalt Blue
                  Color(0xFF002147), // Dark Blue
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              color: _isSubmitting ? Colors.grey : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _isSubmitting
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : const Center(
              child: Text(
                'Submit',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      appBar: AppBar(
        title: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _iconAnimationController,
                builder: (context, child) {
                  return FaIcon(
                    FontAwesomeIcons.boxOpen,
                    color: _iconColorAnimation.value,
                    size: _iconSizeAnimation.value,
                  );
                },
              ),
              const SizedBox(width: 10),
              const Text(
                'Product Shortage Report',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.blue.shade900,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 10,
      ),

      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(0, 4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF000F89), // Royal Blue
                          Color(0xFF0F52BA), // Cobalt Blue
                          Color(0xFF002147), // Dark Blue
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.assignment_turned_in, // Report icon
                          color: Colors.white,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Report Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  _buildTextField(
                    'Product Name *',
                    _productNameController,
                    icon: Icons.shopping_bag,
                    validator: _requiredValidator,
                  ),

                  _buildTextField(
                    'Required Quantity *',
                    _requiredQuantityController,
                    icon: Icons.calculate,
                    validator: _requiredValidator,
                  ),

                  _buildTextField(
                    'Available Quantity',
                    _availableQuantityController,
                    icon: Icons.inventory,
                    validator: _requiredValidator,
                  ),

                  const SizedBox(height: 20),
                  _buildChooseFilesButton(),
                  const SizedBox(height: 20),
                  _buildFileList(),
                  const SizedBox(height: 20),

                  _buildTextField(
                    'Site Location *',
                    _siteLocationController,
                    icon: Icons.place,
                    validator: _requiredValidator,
                  ),

                  _buildTextField(
                    'Description',
                    _descriptionController,
                    icon: Icons.text_snippet,
                    validator: _requiredValidator,
                  ),

                  _buildTextField(
                    'Phone Number *',
                    _contactInfoController,
                    keyboardType: TextInputType.phone,
                    icon: Icons.phone_android,
                    validator: _phoneValidator,
                    maxLength: 10,
                  ),

                  _buildTextField(
                    'Address',
                    _addressController,
                    icon: Icons.map,
                    validator: _requiredValidator,
                  ),

                  _buildTextField(
                    readOnly:true,
                    'Assigned Technician',
                    _assignedTechnicianController,
                    icon: Icons.build_circle,
                    validator: _requiredValidator,
                  ),

                  const SizedBox(height: 20),
                  _buildSubmitButton(),
                  const SizedBox(height: 20),


                ],
              ),
            ),
          ),
        ),
      ),

    );
  }
}
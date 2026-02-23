import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:techlead/Widgeets/custom_app_bar.dart';
import '../../core/app_bar_provider.dart';

class AdminFetchDataPiePage extends ConsumerStatefulWidget {
  const AdminFetchDataPiePage({super.key});

  @override
  ConsumerState<AdminFetchDataPiePage> createState() => _AdminFetchDataPiePageState();
}

class _AdminFetchDataPiePageState extends ConsumerState<AdminFetchDataPiePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appBarTitleProvider.notifier).state = "Add Data for Piechart";
      ref.read(appBarGradientColorsProvider.notifier).state = [
        Color(0xFF0D3B66),
        Color(0xFF115293),
        Color(0xFF3B7CA8),
      ]
      ;
    });
  }
  String? selectedCategoryName;
  String? selectedProjectStatus;
  final TextEditingController projectNameController = TextEditingController();
  final TextEditingController landmarkController = TextEditingController();
  final TextEditingController percentageController = TextEditingController();

  bool isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitData() async {
    if (selectedCategoryName == null ||
        selectedProjectStatus == null ||
        projectNameController.text.isEmpty ||
        landmarkController.text.isEmpty ||
        percentageController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please fill in all the fields",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await _firestore.collection('projects').add({
        'category': selectedCategoryName,
        'projectName': projectNameController.text,
        'status': selectedProjectStatus,
        'landmark': landmarkController.text,
        'completionPercentage': int.parse(percentageController.text),
        'timestamp': FieldValue.serverTimestamp(),
      });

      Fluttertoast.showToast(
        msg: "Project Graph Data submitted successfully!",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      setState(() {
        selectedCategoryName = null;
        selectedProjectStatus = null;
        projectNameController.clear();
        landmarkController.clear();
        percentageController.clear();
      });
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error submitting data: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Project Information'),
                const SizedBox(height: 20),
                _buildFormCard(),
                const SizedBox(height: 25),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Center(
      child: Text(
        title,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
          letterSpacing: 1.5,
          shadows: [
            BoxShadow(
              color: Colors.deepPurpleAccent.withOpacity(0.5),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to build the form card with stylish UI
  Widget _buildFormCard() {
    return Card(
      elevation: 10,
      shadowColor: Colors.deepPurpleAccent.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white, // White background for the form card
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDropdownField('Department', selectedCategoryName, _getDepartments(), (newValue) {
              setState(() {
                selectedCategoryName = newValue;
              });
            }),
            const SizedBox(height: 16.0),
            _buildTextField(projectNameController, 'Project Name',),
            const SizedBox(height: 16.0),
            _buildDropdownField('Project Status', selectedProjectStatus, ['In Progress', 'Completed'], (newValue) {
              setState(() {
                selectedProjectStatus = newValue;
              });
            }),
            const SizedBox(height: 16.0),
            _buildTextField(landmarkController, 'Landmark'),
            const SizedBox(height: 16.0),
            _buildTextField(percentageController, 'Task Completion %', isNumber: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField(
      String label,
      String? value,
      List<String> items,
      ValueChanged<String?> onChanged,
      ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(
          label,
          style: TextStyle(color: Colors.white),
        ),
        items: items
            .map(
              (item) => DropdownMenuItem<String>(
            value: item,
            child: Row(
              children: [
                Icon(_getDepartmentIcon(item), color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  item,
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        )
            .toList(),
        onChanged: onChanged,
        dropdownColor: Colors.blue.shade900,
        iconEnabledColor: Colors.white,
        iconDisabledColor: Colors.white,
        decoration: InputDecoration(
          contentPadding:
          const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.blue.shade900,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade900),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade700),
          ),
        ),
        style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
      ),
    );
  }


// Helper function to create text form fields with blue background and white text
  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        bool isNumber = false,
      }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.blue.shade900,
          labelStyle: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
        ),
        style: TextStyle(color: Colors.white),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: isNumber
            ? [
          FilteringTextInputFormatter.digitsOnly,
          _NumberRangeFormatter(0, 100),
        ]
            : null,
      ),
    );
  }




  // Helper function to create submit button with smooth transitions
  Widget _buildSubmitButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : submitData,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade900, // Purple background for the button
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: isLoading ? 0 : 6,
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Submit", style: TextStyle(fontSize: 16, color: Colors.white)), // White text for submit button
      ),
    );
  }

  // Input decoration style for form fields
  InputDecoration _inputDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.deepPurpleAccent.withOpacity(0.1), // Light purple background for inputs
    );
  }

  // Function to get the corresponding department icon
  IconData _getDepartmentIcon(String departmentName) {
    switch (departmentName) {
      case 'HR': return Icons.people;
      case 'Finance': return Icons.account_balance;
      case 'Development': return Icons.code;
      case 'Digital Marketing': return Icons.campaign;
      case 'Reception': return Icons.phone;
      case 'Account': return Icons.book;
      case 'Human Resources': return Icons.group;
      case 'Management': return Icons.business;
      case 'Sales': return Icons.shopping_cart;
      case 'Installation': return Icons.build;
      case 'Services': return Icons.miscellaneous_services;
      case 'Social Media Marketing': return Icons.share;
      default: return Icons.help;
    }
  }

  // Function to return a list of departments
  List<String> _getDepartments() {
    return [
      'HR', 'Finance', 'Development', 'Digital Marketing', 'Reception', 'Account',
      'Human Resources', 'Management', 'Sales', 'Installation', 'Services', 'Social Media Marketing'
    ];
  }
}
class _NumberRangeFormatter extends TextInputFormatter {
  final int min;
  final int max;

  _NumberRangeFormatter(this.min, this.max);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    try {
      final intValue = int.parse(newValue.text);
      if (intValue < min || intValue > max) {
        return oldValue; // Reject changes outside range
      }
      return newValue;
    } catch (e) {
      return oldValue; // Reject invalid input
    }
  }
}

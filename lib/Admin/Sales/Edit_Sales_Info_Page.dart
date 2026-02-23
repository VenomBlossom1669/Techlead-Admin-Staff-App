import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class EditSalesInfoPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> initialData;

  EditSalesInfoPage({required this.docId, required this.initialData});

  @override
  _EditSalesInfoPageState createState() => _EditSalesInfoPageState();
}

class _EditSalesInfoPageState extends State<EditSalesInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final FocusNode leadSourceFocus = FocusNode();
  final FocusNode leadTypeFocus = FocusNode();
  final FocusNode propertyTypeFocus = FocusNode();
  final FocusNode currentHomeAutomationFocus = FocusNode();
  final FocusNode budgetRangeFocus = FocusNode();

  var gradientColors = [
    Color(0xFF000F89), // Royal Blue
    Color(0xFF0F52BA), // Cobalt Blue
    Color(0xFF002147), // Navy Blue
  ];



  @override
  void dispose() {
    leadSourceFocus.dispose();
    leadTypeFocus.dispose();
    propertyTypeFocus.dispose();
    currentHomeAutomationFocus.dispose();
    budgetRangeFocus.dispose();
    super.dispose();
  }


  late String fullName,
     whatsappNumber,
      contactNumber,
      email,
      preferredContactMethod,
      leadSource,
      leadType,
      propertyType,
      propertySize,
      currentHomeAutomation,
      budgetRange,
      additionalDetails;

  // List of lead sources with text and icons
  final List<Map<String, dynamic>> leadSources = [
    {'text': 'Website', 'icon': FontAwesomeIcons.globe},
    {'text': 'Social Media', 'icon': FontAwesomeIcons.instagram},
    {'text': 'Personal Reference', 'icon': FontAwesomeIcons.userFriends},
    {'text': 'Advertisement', 'icon': FontAwesomeIcons.ad},
    {'text': 'Event', 'icon': FontAwesomeIcons.calendarAlt},
    {'text': 'Indiamart', 'icon': FontAwesomeIcons.shoppingCart},
    {'text': 'Facebook', 'icon': FontAwesomeIcons.facebook},
    {'text': 'Architect Interior', 'icon': FontAwesomeIcons.building},
    {'text': 'Builder', 'icon': FontAwesomeIcons.hammer},
    {'text': 'Walkthrough', 'icon': FontAwesomeIcons.walking},
    {'text': 'Electrician', 'icon': FontAwesomeIcons.lightbulb},
    {'text': 'Dealer', 'icon': FontAwesomeIcons.store},
  ];

  // List of lead types with text and icons
  final List<Map<String, dynamic>> leadTypes = [
    {'text': 'New Inquiry', 'icon': FontAwesomeIcons.userPlus},
    {'text': 'Returning Customer', 'icon': FontAwesomeIcons.recycle},
    {'text': 'Referral', 'icon': FontAwesomeIcons.peopleArrows},
    {'text': 'Contacted', 'icon': FontAwesomeIcons.phone,},
    {'text': 'Nurture', 'icon': FontAwesomeIcons.seedling,},
    {'text': 'Qualified', 'icon': FontAwesomeIcons.checkCircle,},
    {'text': 'Unqualified', 'icon': FontAwesomeIcons.timesCircle,},
    {'text': 'Junk', 'icon': FontAwesomeIcons.trash,},
  ];

  // List of property types with text and icons
  final List<Map<String, dynamic>> propertyTypes = [
    {'text': 'Apartment', 'icon': FontAwesomeIcons.city},
    {'text': 'House', 'icon': FontAwesomeIcons.home},
    {'text': 'Office', 'icon': FontAwesomeIcons.building},
  ];

  // List of current home automation options with text and icons
  final List<Map<String, dynamic>> homeAutomationOptions = [
    {'text': 'None', 'icon': FontAwesomeIcons.timesCircle},
    {'text': 'Partial', 'icon': FontAwesomeIcons.expand},
    {'text': 'Fully Automated', 'icon': FontAwesomeIcons.robot},
    {'text': 'Interested in Upgrading', 'icon': FontAwesomeIcons.arrowUp},
  ];


  @override
  void initState() {
    super.initState();
    fullName = widget.initialData['fullName'] ?? '';
    whatsappNumber = widget.initialData['whatsappNumber'] ?? '';
    contactNumber = widget.initialData['contactNumber'] ?? '';
    email = widget.initialData['email'] ?? '';
    preferredContactMethod = widget.initialData['preferredContactMethod'] ??
        'Email'; // Assuming default value
    leadSource = widget.initialData['leadSource'] ??
        leadSources[0]['text']; // Set default to the first option
    leadType = widget.initialData['leadType'] ??
        leadTypes[0]['text']; // Set default to the first option
    propertyType = widget.initialData['propertyType'] ??
        propertyTypes[0]['text']; // Set default to the first option
    propertySize = widget.initialData['propertySize'] ?? '';
    currentHomeAutomation = widget.initialData['currentHomeAutomation'] ??
        homeAutomationOptions[0]['text']; // Set default to the first option
    budgetRange = widget.initialData['budgetRange'] ??
      ''; // Set default to the first option
    additionalDetails = widget.initialData['additionalDetails'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.penNib,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Text(
              "Edit Sales Page",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 1.5,
                color: Colors.white,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 8,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade900, Colors.indigo.shade700],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF000F89), // Royal Blue
                  Color(0xFF0F52BA), // Cobalt Blue (replacing Indigo)
                  Color(0xFF002147),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 100),
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          buildTextFormField(
                            'Full Name',
                            fullName,
                            Icons.person,
                                (value) => fullName = value,   // 🔥 Add this
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Full name is required';
                              return null;
                            },
                          ),

                          buildTextFormField(
                            'Contact Number',
                            contactNumber,
                            Icons.phone,
                                (value) => contactNumber = value,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Contact number is required';
                              if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) return 'Enter a valid 10-digit contact number';
                              return null;
                            },
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(10),
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          buildTextFormField(
                            'Whatsapp Number',
                            whatsappNumber,
                            keyboardType: TextInputType.number,
                            Icons.phone_android,
                                (value) => whatsappNumber = value,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Whatsapp number is required';
                              if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) return 'Enter a valid 10-digit whatsapp number';
                              return null;
                            },
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(10),
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),


                          buildTextFormField(
                            'Email',
                            email,
                            Icons.email,
                                (value) => email = value,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Email is required';
                              if (!RegExp(
                                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
                              ).hasMatch(value)) {
                                return 'Please enter a valid email address';
                              }

                              return null;
                            },
                          ),

                          buildDropdownField(
                            'Lead Source',
                            leadSource,
                            FontAwesomeIcons.digitalOcean,
                            leadSources,
                                (newValue) => setState(() => leadSource = newValue!),
                            validator: (value) =>
                            value == null || value.isEmpty ? 'Please select lead source' : null,
                            currentFocus: leadSourceFocus,
                            nextFocus: leadTypeFocus,
                          ),

                          buildDropdownField(
                            'Lead Type',
                            leadType,
                            FontAwesomeIcons.user,
                            leadTypes,
                                (newValue) => setState(() => leadType = newValue!),
                            validator: (value) =>
                            value == null || value.isEmpty ? 'Please select lead type' : null,
                            currentFocus: leadTypeFocus,
                            nextFocus: propertyTypeFocus,
                          ),

                          buildDropdownField(
                            'Type of Property',
                            propertyType,
                            FontAwesomeIcons.home,
                            propertyTypes,
                                (newValue) => setState(() => propertyType = newValue!),
                            validator: (value) =>
                            value == null || value.isEmpty ? 'Please select property type' : null,
                            currentFocus: propertyTypeFocus,
                          ),


                          buildTextFormField(
                            'Property Size',
                            propertySize,
                            Icons.square_foot,
                                (value) => propertySize = value,
                            validator: (value) => value == null || value.trim().isEmpty ? 'Enter property size' : null,
                          ),

                          buildDropdownField(
                            'Current Home Automation',
                            currentHomeAutomation,
                            FontAwesomeIcons.cogs,
                            homeAutomationOptions,
                                (newValue) => setState(() => currentHomeAutomation = newValue!),
                            validator: (value) => value == null || value.isEmpty ? 'Please select an option' : null,
                            currentFocus: currentHomeAutomationFocus,
                            nextFocus: budgetRangeFocus,
                          ),

                          // buildDropdownField(
                          //   'Budget Range',
                          //   budgetRange,
                          //   FontAwesomeIcons.wallet,
                          //   budgetRanges,
                          //       (newValue) => setState(() => budgetRange = newValue!),
                          //   validator: (value) => value == null || value.isEmpty ? 'Please select a budget range' : null,
                          //   currentFocus: budgetRangeFocus,
                          // ),


                          buildTextFormField(
                            'Budget Range',
                            budgetRange,
                            keyboardType: TextInputType.number,
                            FontAwesomeIcons.wallet,
                                (value) => budgetRange = value,
                            validator: (value) => value == null || value.trim().isEmpty ? 'Enter budget range' : null,
                          ),

                          buildTextFormField(
                            'Additional Details',
                            additionalDetails,
                            Icons.details,
                                (value) => additionalDetails = value,
                            validator: (value) => value == null || value.trim().isEmpty ? 'Enter additional details' : null,
                          ),

                          SizedBox(height: 20),
                          Align(
                            alignment: Alignment
                                .center, // or Alignment.center for center alignment
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: gradientColors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 12),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 30, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: _updateRecord,
                                    child: Text(
                                      'Update',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _updateRecord,
        backgroundColor: Colors.blue.shade900,
        child: Icon(Icons.save, size: 30, color: Colors.white),
      ),
    );
  }

  // Dropdown field with icons
  Widget buildDropdownField(
      String label,
      String value,
      IconData icon,
      List<Map<String, dynamic>> items,
      ValueChanged<String?> onChanged, {
        String? Function(String?)? validator,
        FocusNode? currentFocus,
        FocusNode? nextFocus,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF000F89), // Royal Blue
              Color(0xFF0F52BA), // Cobalt Blue
              Color(0xFF002147), // Navy Blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Focus(
          focusNode: currentFocus,
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            dropdownColor: const Color(0xFF002147),
            value: items.any((item) => item['text'] == value) ? value : null,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
              ),
              prefixIcon: Icon(icon, color: Colors.cyanAccent),
              border: InputBorder.none,
            ),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            iconEnabledColor: Colors.cyanAccent,
            onChanged: (val) {
              onChanged(val);
              // Move to next field if provided
              if (nextFocus != null) {
                Future.delayed(Duration(milliseconds: 100), () {
                  FocusScope.of(currentFocus!.context!).requestFocus(nextFocus);
                });
              }
            },
            validator: validator,
            items: items.map<DropdownMenuItem<String>>((item) {
              return DropdownMenuItem<String>(
                value: item['text'],
                child: Row(
                  children: [
                    Icon(item['icon'], color: Colors.cyanAccent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item['text'],
                        style: const TextStyle(color: Colors.white),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }


  // Text form field
  Widget buildTextFormField(
      String label,
      String initialValue,
      IconData icon,
      Function(String)? onChanged, {
        String? Function(String?)? validator,
        bool readOnly = false,
        List<TextInputFormatter>? inputFormatters,
        TextInputType? keyboardType, // <-- Add this
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
          border: Border.all(color: Colors.white),
        ),
        child: TextFormField(
          initialValue: initialValue,
          readOnly: readOnly,
          inputFormatters: inputFormatters,
          keyboardType: keyboardType, // <-- use here
          textInputAction: TextInputAction.next,
          onEditingComplete: () => FocusScope.of(context).nextFocus(),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
            ),
            prefixIcon: Icon(icon, color: Colors.cyanAccent),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            errorStyle: const TextStyle(color: Colors.cyanAccent),
          ),
          onChanged: readOnly ? null : onChanged,
          validator: validator,
        ),
      ),
    );
  }

  // Update the record in Firestore
  void _updateRecord() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance
            .collection('Salesinfo')
            .doc(widget.docId)
            .update({
          'fullName': fullName,
          'contactNumber': contactNumber,
          'whatsappNumber':whatsappNumber,
          'email': email,
          'preferredContactMethod': preferredContactMethod,
          'leadSource': leadSource,
          'leadType': leadType,
          'propertyType': propertyType,
          'propertySize': propertySize,
          'currentHomeAutomation': currentHomeAutomation,
          'budgetRange': budgetRange,
          'additionalDetails': additionalDetails,
          'reportedDateTime': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Record updated successfully',
              style: TextStyle(color: Colors.white), // ✅ White text
            ),
            backgroundColor: Colors.green, // ✅ Green background
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error updating record: $e',
              style: const TextStyle(color: Colors.white), // ✅ White text
            ),
            backgroundColor: Colors.red, // ✅ Red background
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
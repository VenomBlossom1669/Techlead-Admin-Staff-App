import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:open_file/open_file.dart';
import '../../../Default/customwidget.dart';

class InstallationPage extends StatefulWidget {
  const InstallationPage({super.key});

  @override
  State<InstallationPage> createState() => _InstallationPageState();
}

class _InstallationPageState extends State<InstallationPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController technicianNameController = TextEditingController();
  TextEditingController installationSiteController = TextEditingController();
  TextEditingController customerNameController = TextEditingController();
  TextEditingController customerContactController = TextEditingController();
  TextEditingController customerwhatsappContactController = TextEditingController();
  TextEditingController serviceDescriptionController = TextEditingController();
  TextEditingController remarksController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  List<File> selectedFiles = [];
  List<String> fileNames = [];
  List<String> fileTypes = [];
  bool isLoading = false;
  List<TextEditingController> fileNameControllers = [];
  String? selectedProduct;
  String? selectedServiceStatus;
  String? selectedMaterial;

  bool _isSubmitting = false;

  final Map<String, IconData> products = {
    'Smart Lights': FontAwesomeIcons.lightbulb,
    'Smart Thermostat': FontAwesomeIcons.thermometerHalf,
    'Security Cameras': FontAwesomeIcons.video,
    'Smart Plugs': FontAwesomeIcons.plug,
    'Smart Door Locks': FontAwesomeIcons.lock,
    'Smart Smoke Detectors': FontAwesomeIcons.cloud,
    'Smart Speakers': FontAwesomeIcons.volumeUp,
    'Smart Blinds': FontAwesomeIcons.windowMaximize,
    'Home Security Systems': FontAwesomeIcons.shieldAlt,
    'Smart Doorbells': FontAwesomeIcons.bell,
    'Motion Sensors': FontAwesomeIcons.walking,
    'Smart Cameras': FontAwesomeIcons.camera,
    'Smart Switches': FontAwesomeIcons.toggleOn,
    'Smart Air Purifiers': FontAwesomeIcons.wind,
    'Smart Fans': FontAwesomeIcons.fan,
    'Smart Heaters': FontAwesomeIcons.fire,
    'Smart Humidifiers': FontAwesomeIcons.cloudRain,
    'Smart Radiators': FontAwesomeIcons.radiation,
    'Smart Refrigerators': FontAwesomeIcons.iceCream,
    'Smart Ovens': FontAwesomeIcons.breadSlice,
    'Smart Washing \n Machines': FontAwesomeIcons.soap,
    'Smart Dishwashers': FontAwesomeIcons.handsWash,
    'Smart Coffee Makers': FontAwesomeIcons.mugHot,
    'Smart Projectors': FontAwesomeIcons.projectDiagram,
    'Streaming Devices': FontAwesomeIcons.stream,
    'Smart Remotes': FontAwesomeIcons.contao,
    'Smart Hubs': FontAwesomeIcons.networkWired,
    'Smart Meters': FontAwesomeIcons.tachometerAlt,
    'Solar Energy Systems': FontAwesomeIcons.solarPanel,
    'Smart Batteries': FontAwesomeIcons.batteryFull,
    'Smart Chargers': FontAwesomeIcons.chargingStation,
    'Smart Curtains': FontAwesomeIcons.windowRestore,
    'Robotic Vacuums': FontAwesomeIcons.robot,
    'Smart Window Openers': FontAwesomeIcons.windowMaximize,
    'Smart Home \n Automation Hubs': FontAwesomeIcons.home,
    'Smart Security Systems': FontAwesomeIcons.shieldVirus,
    'Smart Light Panels': FontAwesomeIcons.lightbulb,
    'LED Strips': FontAwesomeIcons.ribbon,
    'Smart Home Assistants': FontAwesomeIcons.headset,
    'Voice Assistants': FontAwesomeIcons.microphone,
    'Automated Home \n Theater Systems': FontAwesomeIcons.tv,
    'Automated Shades': FontAwesomeIcons.accusoft,
    'Automatic \n Watering Systems': FontAwesomeIcons.water,
    'Smart Smoke Alarms': FontAwesomeIcons.bell,
    'Smart Leak Detectors': FontAwesomeIcons.water,
    'Smart Water Heaters': FontAwesomeIcons.fire,
    'Smart Air Conditioners': FontAwesomeIcons.snowflake,
    'Smart Vacuum Cleaners': FontAwesomeIcons.robot,
    'Smart Bed Frames': FontAwesomeIcons.bed,
    'Home Automation \n Controller Systems': FontAwesomeIcons.server,
  };

  List<String> serviceStatuses = ["Pending", "In Progress", "Completed"];
  final Map<String, List<String>> productMaterials = {
    'Smart Lights': ['Smart bulbs', 'Switches', 'Wiring', 'Drill', 'Screwdriver'],
    'Smart Thermostat': ['Thermostat', 'Wiring tools', 'Screwdriver', 'Wall anchors'],
    'Security Cameras': ['Cameras', 'Mounting brackets', 'Screws', 'Drill'],
    'Smart Plugs': ['Smart plug device', 'Smartphone for setup'],
    'Smart Door Locks': ['Smart lock', 'Screws', 'Drill', 'Smartphone for pairing'],
    'Smart Smoke Detectors': ['Smoke detector', 'Screws', 'Batteries'],
    'Smart Speakers': ['Smart speaker', 'Power cables'],
    'Smart Blinds': ['Motorized blinds', 'Mounting brackets', 'Screws'],
    'Home Security Systems': ['Cameras', 'Sensors', 'Control hub', 'Batteries'],
    'Smart Doorbells': ['Doorbell', 'Mounting bracket', 'Power adapter'],
    'Motion Sensors': ['Motion sensor', 'Batteries'],
    'Smart Cameras': ['Camera', 'Mounting brackets', 'Drill'],
    'Smart Switches': ['Smart switch', 'Screwdriver'],
    'Smart Air Purifiers': ['Air purifier', 'Filter'],
    'Smart Fans': ['Smart fan', 'Remote control'],
    'Smart Heaters': ['Heater', 'Power cord'],
    'Smart Humidifiers': ['Humidifier', 'Filter'],
    'Smart Radiators': ['Radiator', 'Power cable'],
    'Smart Refrigerators': ['Refrigerator', 'Manual'],
    'Smart Ovens': ['Oven', 'Manual'],
    'Smart Washing Machines': ['Washing machine', 'Detergent tray'],
    'Smart Dishwashers': ['Dishwasher', 'Drain pipes', 'Manual'],
    'Smart Coffee Makers': ['Coffee maker', 'Filter', 'Power cord'],
    'Smart Projectors': ['Projector', 'Mounting kit'],
    'Streaming Devices': ['Streaming device', 'Power cable'],
    'Smart Remotes': ['Remote', 'Batteries'],
    'Smart Hubs': ['Hub', 'Adapter'],
    'Smart Meters': ['Smart meter', 'Tools'],
    'Solar Energy Systems': ['Solar panels', 'Mounting hardware'],
    'Smart Batteries': ['Battery pack', 'Charger'],
    'Smart Chargers': ['Charger', 'Power cord'],
    'Smart Curtains': ['Curtains', 'Motorized rail system'],
    'Robotic Vacuums': ['Vacuum', 'Charger'],
    'Smart Window Openers': ['Window opener', 'Mounting kit'],
    'Smart Home Automation Hubs': ['Hub', 'Power supply'],
    'Smart Security Systems': ['Sensors', 'Control panel'],
    'Smart Light Panels': ['Light panels', 'Mounting kit'],
    'LED Strips': ['LED strips', 'Power adapter'],
    'Smart Home Assistants': ['Assistant device', 'Power cable'],
    'Voice Assistants': ['Voice assistant', 'Power cable'],
    'Automated Home Theater Systems': ['Projector', 'Speakers', 'Cables'],
    'Automated Shades': ['Shades', 'Motorized system'],
    'Automatic Watering Systems': ['Watering system', 'Hoses'],
    'Smart Smoke Alarms': ['Smoke alarm', 'Batteries'],
    'Smart Leak Detectors': ['Leak detector', 'Batteries'],
    'Smart Water Heaters': ['Water heater', 'Power supply'],
    'Smart Air Conditioners': ['AC unit', 'Installation tools'],
    'Smart Vacuum Cleaners': ['Vacuum cleaner', 'Charger'],
    'Smart Bed Frames': ['Bed frame', 'Power adapter'],
    'Home Automation Controller Systems': ['Controller unit', 'Wires', 'Adapters'],
  };

  // Date Picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserName();
  }



  Future<void> fetchUserName() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("No authenticated user found.");
        return;
      }

      String userId = user.uid;
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('EmpProfile')
          .doc(userId)
          .get();

      if (userSnapshot.exists && userSnapshot.data() != null) {
        setState(() {
          technicianNameController.text =
              userSnapshot.get('fullName') ?? "Unknown";
        });
        print(
            "Fetched Data: ${technicianNameController.text},");
      } else {
        print("No user data found for userId: $userId");
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }


  // Time Picker
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  String? validateField(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  void pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);

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
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

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

  Future<void> uploadFiles() async {
    setState(() {
      isLoading = true;
    });

    try {
      for (int index = 0; index < selectedFiles.length; index++) {
        String fileName = fileNames[index];
        File file = selectedFiles[index];
        String fileType = fileTypes[index];

        // Ensure correct MIME type for images
        Uint8List fileBytes = await file.readAsBytes();

        // Create a Firebase Storage reference
        Reference storageRef = _storage.ref().child("TaskAssign/$fileName");

        // Upload file
        UploadTask uploadTask = storageRef.putData(fileBytes, SettableMetadata(
          contentType: _getContentType(fileType),
        ));

        // Get download URL
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        await _firestore.collection('Installation').add({
          'fileName': fileName,
          'fileType': fileType,
          'downloadUrl': downloadUrl,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Files uploaded successfully!')),
      );
    } catch (e) {
      print("Error uploading files: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading files: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'mp4':
      case 'mov':
      case 'avi':
        return 'video/mp4';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }


  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User not logged in'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      final formData = {
        'uid': user.uid,
        'technician_name': technicianNameController.text.trim(),
        'installation_site': installationSiteController.text.trim(),
        'customer_name': customerNameController.text.trim(),
        'customer_contact': customerContactController.text.trim(),
        'whasapp_contact': customerwhatsappContactController.text.trim(),
        'service_description': serviceDescriptionController.text.trim(),
        'remarks': remarksController.text.trim(),
        'installation_date': selectedDate?.toIso8601String(),
        'service_time': selectedTime?.format(context),
        'selected_product': selectedProduct,
        'service_status': selectedServiceStatus,
        'selected_material': selectedMaterial,
        'files': [],
        'timestamp': FieldValue.serverTimestamp(),
      };

      try {
        // Upload files first
        List<Map<String, String>> uploadedFiles = [];

        for (int index = 0; index < selectedFiles.length; index++) {
          String fileName = fileNames[index];
          File file = selectedFiles[index];
          String fileType = fileTypes[index];

          Uint8List fileBytes = await file.readAsBytes();

          Reference storageRef = _storage.ref().child("TaskAssign/$fileName");

          UploadTask uploadTask = storageRef.putData(fileBytes, SettableMetadata(
            contentType: _getContentType(fileType),
          ));

          TaskSnapshot snapshot = await uploadTask;
          String downloadUrl = await snapshot.ref.getDownloadURL();

          uploadedFiles.add({
            'fileName': fileName,
            'fileType': fileType,
            'downloadUrl': downloadUrl,
          });
        }

        formData['files'] = uploadedFiles;

        await FirebaseFirestore.instance.collection('Installation').add(formData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Installation data and files stored successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        _clearFormFields();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error storing data: $e"),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _deleteRecord(String docId) async {
    try {
      await _firestore.collection('ReceptionPage').doc(docId).delete();
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Reception Record deleted successfully',
            style: TextStyle(fontFamily: "Times New Roman", color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Error deleting record: $e',
            style: TextStyle(fontFamily: "Times New Roman", color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearFormFields() {
    installationSiteController.clear();
    customerNameController.clear();
    customerwhatsappContactController.clear();
    customerContactController.clear();
    serviceDescriptionController.clear();
    remarksController.clear();

    setState(() {
      selectedDate = null;
      selectedTime = null;
      selectedProduct = null;
      selectedServiceStatus = null;
      selectedMaterial = null;
      selectedFiles.clear();
      fileNames.clear();
      fileTypes.clear();
      fileNameControllers.clear();
    });
  }

  Future<void> replaceFile(int index) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'mp4',
        'mov',
        'avi',
        'mkv',
        'gif'
      ],
    );

    if (result != null) {
      PlatformFile file = result.files.first;

      setState(() {
        selectedFiles[index] = File(file.path!);
        fileNames[index] = file.name;
        fileTypes[index] = file.extension ?? 'unknown';
      });
    } else {
      print("No file selected.");
    }
  }


  void closeFile(int index) {
    setState(() {
      selectedFiles.removeAt(index);
      fileNames.removeAt(index);
      fileTypes.removeAt(index);
      fileNameControllers.removeAt(index);
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.toolbox,
              color: Colors.white,
            ),
            SizedBox(width: 15),
            Text(
              "Installation At Site",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.5,
                color: Colors.white,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
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
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      buildTextField(
                        context: context,
                        readOnly: true,
                        controller: technicianNameController,
                        labelText: "Technician/Executive Name",
                        icon: Icons.person,
                        validator: validateField,
                      ),
                      SizedBox(height: 16),
                      buildTextField(
                        context: context,
                        controller: installationSiteController,
                        labelText: "Installation Site",
                        icon: Icons.location_on,
                        validator: validateField,
                      ),
                      SizedBox(height: 16),
                      buildDatePickerField(
                        context,
                        label: "Installation Date",
                        date: selectedDate,
                        onTap: () => _selectDate(context),
                        validator: validateField,
                      ),
                      SizedBox(height: 16),
                      buildTimePickerField(
                        context,
                        label: "Service Time",
                        time: selectedTime,
                        onTap: () => _selectTime(context),
                        validator: validateField,
                      ),
                      SizedBox(height: 16),
                      buildDropdownField(
                        labelText: "Home Automation Product",
                        context: context,
                        icon: Icons.devices,
                        value: selectedProduct,
                        items: products.entries
                            .map((entry) => {'text': entry.key, 'icon': entry.value})
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedProduct = value;
                            selectedMaterial = null;
                          });
                        },
                        validator: validateField,
                      ),
                      if (selectedProduct != null) ...[
                        SizedBox(height: 16),
                        Text(
                          "Materials Required for $selectedProduct:",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        ...productMaterials[selectedProduct]!
                            .map((material) => Card(
                          elevation: 4,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(material),
                            leading: Icon(Icons.build),
                          ),
                        ))
                            .toList(),
                      ],
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: pickFiles,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(200, 30),
                          backgroundColor: Colors.blue.shade900,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 5,
                          shadowColor: Colors.grey.withOpacity(0.5),
                          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                        ),
                        child: MouseRegion(
                          onEnter: (_) {
                            setState(() {});
                          },
                          onExit: (_) {
                            setState(() {});
                          },
                          child: Text(
                            "Choose Files",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      selectedFiles.isNotEmpty
                          ? Container(
                        padding: EdgeInsets.all(16),
                        margin: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children:
                            List.generate(selectedFiles.length, (index) {
                              return Container(
                                margin: EdgeInsets.all(10),
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                  Border.all(color: Colors.blue, width: 1),
                                ),
                                width:
                                120,
                                child: Stack(
                                  children: [
                                    Column(
                                      children: [
                                        if (fileTypes[index] == 'jpg' ||
                                            fileTypes[index] == 'png' ||
                                            fileTypes[index] == 'jpeg')
                                          Image.file(
                                            selectedFiles[index],
                                            width: 100,
                                            height: 80,
                                            fit: BoxFit.cover,
                                          )
                                        else if (fileTypes[index] == 'mp4' ||
                                            fileTypes[index] == 'mov' ||
                                            fileTypes[index] == 'avi' ||
                                            fileTypes[index] == 'mkv')
                                          Icon(
                                            Icons.video_file,
                                            size: 50,
                                            color: Colors.blue,
                                          )
                                        else if (fileTypes[index] == 'gif')
                                            Image.file(
                                              selectedFiles[index],
                                              width: 100,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            )
                                          else
                                            Icon(
                                              Icons.insert_drive_file,
                                              size: 50,
                                              color: Colors.blue,
                                            ),
                                        SizedBox(height: 10),

                                        Text(
                                          fileNames[index],
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 5),

                                        SizedBox(
                                          width: 100,
                                          child: TextField(
                                            controller:
                                            fileNameControllers[index],
                                            decoration: InputDecoration(
                                              labelText: 'Rename',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                BorderRadius.circular(10),
                                              ),
                                              filled: true,
                                              fillColor: Colors.blue.shade50,
                                            ),
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        SizedBox(height: 5),

                                        // Rename button
                                        ElevatedButton(
                                          onPressed: () => renameFile(index),
                                          style: ElevatedButton.styleFrom(
                                            minimumSize: Size(100, 30),
                                            backgroundColor:
                                            Colors.blue.shade900,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text(
                                            "Rename",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => replaceFile(index),
                                          style: ElevatedButton.styleFrom(
                                            minimumSize: Size(100, 30),
                                            backgroundColor: Colors.blue.shade900,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text(
                                            "Replace",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        // Open file button
                                        ElevatedButton(
                                          onPressed: () =>
                                              openFile(selectedFiles[index]),
                                          style: ElevatedButton.styleFrom(
                                            minimumSize: Size(100, 30),
                                            backgroundColor:
                                            Colors.blue.shade900,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text(
                                            "Open",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    Positioned(
                                      top: -8,
                                      right: -5,
                                      child: CircleAvatar(
                                        radius:
                                        16,
                                        backgroundColor: Colors
                                            .white,
                                        child: IconButton(
                                          icon: const Icon(Icons.close,
                                              color: Colors.red, size: 19),
                                          onPressed: () => closeFile(index),
                                        ),
                                      ),
                                    ),

                                    // Replace file button

                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      )
                          : Text("No files selected yet."),

                      SizedBox(height: 16),
                      buildDropdownField(
                        labelText: "Service Status",
                        context: context,
                        icon: Icons.assignment,
                        value: selectedServiceStatus,
                        items: serviceStatuses
                            .map((status) => {'text': status, 'icon': Icons.assignment})
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedServiceStatus = value;
                          });
                        },
                        validator: validateField,
                      ),
                      SizedBox(height: 16),
                      buildTextField(
                        context: context,
                        controller: customerNameController,
                        labelText: "Customer Name",
                        icon: Icons.person,
                        validator: validateField,
                      ),
                      SizedBox(height: 16),
                      buildTextField(
                        context: context,
                        controller: customerContactController,
                        labelText: "Customer Contact",
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
                      SizedBox(height: 16),
                      buildTextField(
                        context: context,
                        controller: customerwhatsappContactController,
                        labelText: "Customer Whatsapp",
                        icon: FontAwesomeIcons.whatsapp,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(10),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Whatsapp number is required.';
                          } else if (value.length != 10) {
                            return 'Whatsapp number must be 10 digits.';
                          } else if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                            return 'Enter a valid 10-digit Whatsapp number.';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      buildTextField(
                        context: context,
                        controller: serviceDescriptionController,
                        labelText: "Service Description",
                        icon: Icons.description,
                        maxLines: 3,
                        validator: validateField,
                      ),
                      SizedBox(height: 16),
                      buildTextField(
                        context: context,
                        controller: remarksController,
                        labelText: "Remarks or Notes",
                        icon: Icons.notes,
                        maxLines: 3,
                        validator: validateField,
                      ),
                      SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 12),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade900,
                              shadowColor: Colors.purpleAccent.shade100,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            ),
                            onPressed: _isSubmitting ? null : _submitForm,
                            child: _isSubmitting
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                              "Submit",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: "Times New Roman",
                                color: Colors.white,
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
        ),
      ),
    );
  }
}

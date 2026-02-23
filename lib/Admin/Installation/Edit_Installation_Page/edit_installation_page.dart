import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:techlead/Employee/Homescreen/Date_And_Time_Code/Customize_Date_001.dart';
import 'package:techlead/Employee/Homescreen/Date_And_Time_Code/Customize_Time_001.dart';

class Editinstallationpage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> initialData;

  Editinstallationpage({required this.docId, required this.initialData});

  @override
  _EditinstallationpageState createState() => _EditinstallationpageState();
}

class _EditinstallationpageState extends State<Editinstallationpage> {
  final _formKey = GlobalKey<FormState>();
  FocusNode dropdownFocus = FocusNode();
  List<TextEditingController> fileNameControllers = [];
  List<Map<String, dynamic>> files = [];
  List<File?> selectedFiles = [];
  int? selectedFileIndex;
  FocusNode nextFieldFocus = FocusNode();
  late String fullName,
      whatsappNumber,
      contactNumber,
      email,
      preferredContactMethod,
      remarks,
      leadSource,
      leadType,
      taskstatus,
      meetingcstatus,
      propertyType,
      propertySize,
      currentHomeAutomation,
      budgetRange,
      additionalDetails;

  List<String> serviceStatusOptions = ["Pending", "In Progress", "Completed"];
  late String selectedServiceStatus;

  late TextEditingController _dateController;
  late TextEditingController _timeController;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

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

  List<String> fileNames = [];
  List<String> fileTypes = [];
  @override
  void initState() {
    super.initState();

    fullName = widget.initialData['technician_name'] ?? '';
    whatsappNumber = widget.initialData['whasapp_contact'] ?? '';
    contactNumber = widget.initialData['installation_site'] ?? '';
    email = widget.initialData['installation_date'] ?? '';
    preferredContactMethod = widget.initialData['service_time'] ?? '';
    leadSource = widget.initialData['selected_product'] ?? products.keys.first;
    selectedServiceStatus = widget.initialData['service_status'] ?? 'Pending';
    additionalDetails = widget.initialData['customer_name'] ?? '';
    taskstatus = widget.initialData['customer_contact'] ?? '';
    meetingcstatus = widget.initialData['service_description'] ?? '';
    remarks = widget.initialData['remarks'] ?? '';
    files = (widget.initialData['files'] as List? ?? []).map((e) {
      return {
        'fileName': e['fileName'],
        'fileType': e['fileType'],
        'downloadUrl': e['downloadUrl'],
        'isLocal': false,
      };
    }).toList();

    fileNameControllers = files
        .map((f) => TextEditingController(text: f['fileName'] ?? ''))
        .toList();
    selectedFiles = List<File?>.filled(files.length, null, growable: true);
    fileNames = files.map((f) => f['fileName'] as String).toList();
    fileTypes = files.map((f) => f['fileType'] as String).toList();

    _selectedDate = email.isNotEmpty
        ? DateTime.tryParse(email) ?? DateTime.now()
        : DateTime.now();

    _selectedTime = preferredContactMethod.isNotEmpty
        ? TimeOfDay(
            hour: int.tryParse(preferredContactMethod.split(':')[0]) ?? 0,
            minute: int.tryParse(preferredContactMethod.split(':')[1]) ?? 0)
        : TimeOfDay.now();

    _dateController = TextEditingController();
    _timeController = TextEditingController();
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
        // Replace the file entry in `files` list
        files[index] = {
          'fileName': file.name,
          'fileType': file.extension ?? 'unknown',
          'downloadUrl': file.path!, // Local file path
          'isLocal': true, // Mark as local file
        };

        // Optional: Also update controller text if you're using it
        if (index < fileNameControllers.length) {
          fileNameControllers[index].text = file.name;
        } else {
          fileNameControllers.add(TextEditingController(text: file.name));
        }
      });
    } else {
      print("No file selected.");
    }
  }

  void renameFile(int index) {
    final newName = fileNameControllers[index].text.trim();

    if (newName.isNotEmpty) {
      setState(() {
        files[index]['fileName'] = newName;
        fileNameControllers[index].clear();
      });
    }
  }

  void closeFile(int index) {
    setState(() {
      files.removeAt(index);
      fileNameControllers.removeAt(index);

      if (selectedFileIndex == index) {
        selectedFileIndex = null;
      } else if (selectedFileIndex != null && selectedFileIndex! > index) {
        selectedFileIndex = selectedFileIndex! - 1;
      }
    });
  }

  void openFile(String pathOrUrl, bool isLocal) async {
    if (isLocal) {
      await OpenFile.open(pathOrUrl);
    } else {
      await OpenFile.open(pathOrUrl);
    }
  }

  void closeDetailPanel(int index) {
    setState(() {
      selectedFileIndex = null;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _dateController.text = DateFormat('dd MMMM yyyy').format(_selectedDate);
    _timeController.text = _selectedTime.format(context);
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
              "Edit Installation Page",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
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
              colors: [
                Color(0xFF0A2A5A), // Deep navy blue
                Color(0xFF15489C), // Strong steel blue
                Color(0xFF1E64D8), // Vivid rich blue
              ],
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
                  Color(0xFF0A2A5A), // Deep navy blue
                  Color(0xFF15489C), // Strong steel blue
                  Color(0xFF1E64D8), // Vivid rich blue
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
                          buildTextFormField('Technician Name', fullName,readOnly: true,
                              Icons.person, (value) => fullName = value),

                          buildTextFormField('Installation Site', contactNumber,
                              Icons.phone, (value) => contactNumber = value),

                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Installation Date',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () => showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => buildGradientCalendar(
                                      context,
                                      _selectedDate,
                                      (pickedDate) {
                                        setState(() {
                                          _selectedDate = pickedDate;
                                          email = pickedDate
                                              .toIso8601String(); // Save for Firestore
                                          _dateController.text =
                                              DateFormat('dd MMMM yyyy').format(
                                                  pickedDate); // Display format
                                        });
                                      },
                                    ),
                                  ),
                                  child: AbsorbPointer(
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
                                        controller: _dateController,
                                        style: GoogleFonts.poppins(
                                            fontSize: 16, color: Colors.white),
                                        decoration: const InputDecoration(
                                          prefixIcon: Icon(Icons.calendar_today,
                                              color: Colors.cyanAccent),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 14),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Service Time',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () {
                                // 🔹 Minimum selectable time = current time
                                TimeOfDay now = TimeOfDay.now();

                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => buildGradientTimePicker(
                                    context,
                                    _selectedTime,
                                    onTimeSelected: (pickedTime) {
                                      final pickedDateTime = DateTime(
                                        DateTime.now().year,
                                        DateTime.now().month,
                                        DateTime.now().day,
                                        pickedTime.hour,
                                        pickedTime.minute,
                                      );

                                      final nowDateTime = DateTime.now();

                                      // 🔹 Prevent selecting time before current time
                                      if (pickedDateTime.isBefore(nowDateTime)) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Cannot select time before current time",
                                              style: TextStyle(color: Colors.white),
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

                                      setState(() {
                                        _selectedTime = pickedTime;
                                        preferredContactMethod =
                                        "${pickedTime.hour}:${pickedTime.minute}";
                                        _timeController.text = pickedTime.format(context);
                                      });
                                    },
                                    minTime: now, // 🔹 Restrict past times
                                  ),
                                );
                              },
                              child: AbsorbPointer(
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
                                    controller: _timeController,
                                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                                    decoration: const InputDecoration(
                                      prefixIcon: Icon(Icons.access_time, color: Colors.cyanAccent),
                                      border: InputBorder.none,
                                      contentPadding:
                                      EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            ],
                            ),
                          ),

                          buildDropdownField(
                            'Home Automation Product',
                            leadSource,
                            FontAwesomeIcons.user,
                            products.entries
                                .map((entry) =>
                                    {'text': entry.key, 'icon': entry.value})
                                .toList(),
                            (newValue) =>
                                setState(() => leadSource = newValue!),
                            currentFocus: dropdownFocus,
                            nextFocus: nextFieldFocus,
                          ),

                          buildDropdownField(
                            'Service Status',
                            selectedServiceStatus,
                            Icons.info,
                            serviceStatusOptions
                                .map((status) =>
                                    {'text': status, 'icon': Icons.info})
                                .toList(),
                            (newValue) => setState(
                                () => selectedServiceStatus = newValue!),
                            currentFocus: dropdownFocus,
                            nextFocus: nextFieldFocus,
                          ),

                          buildTextFormField(
                              'Customer Name',
                              additionalDetails,
                              Icons.details,
                              (value) => additionalDetails = value),

                          buildTextFormField(
                            'Customer Contact',
                            taskstatus,
                            Icons.phone,
                            (val) => taskstatus = val,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Please enter contact number';
                              if (!RegExp(r'^\d{10}$').hasMatch(value))
                                return 'Contact number must be exactly 10 digits';
                              return null;
                            },
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(10),
                              // ⬅ Limits max length
                              FilteringTextInputFormatter.digitsOnly,
                              // ⬅ Allows only digits
                            ],
                          ),


                          buildTextFormField(
                            'Customer Whatsapp',
                            whatsappNumber,
                            Icons.phone_android,
                                (val) => whatsappNumber = val,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Please enter whatsapp number';
                              if (!RegExp(r'^\d{10}$').hasMatch(value))
                                return 'Whatsapp number must be exactly 10 digits';
                              return null;
                            },
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(10),
                              // ⬅ Limits max length
                              FilteringTextInputFormatter.digitsOnly,
                              // ⬅ Allows only digits
                            ],
                          ),

                          buildTextFormField(
                              'Service Description',
                              meetingcstatus,
                              Icons.details,
                              (value) => meetingcstatus = value),

                          buildTextFormField('Remarks', remarks, Icons.details,
                              (value) => remarks = value),

                          SizedBox(height: 20),

                          // Existing attached files (uploaded files from Firebase)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Attached Files:',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          SizedBox(
                            height: 130,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: files.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                final file = files[index];
                                final url = file['downloadUrl'] ?? '';
                                final fileName = file['fileName'] ?? '';
                                final ext = (file['fileType'] ?? '')
                                    .toString()
                                    .toLowerCase();
                                final isLocal = file['isLocal'] == true;
                                Widget iconWidget;

                                if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp']
                                    .contains(ext)) {
                                  iconWidget = isLocal
                                      ? Image.file(
                                          File(url),
                                          width: 100,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.network(
                                          url,
                                          width: 100,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(
                                                Icons.broken_image,
                                                size: 50,
                                                color: Colors.grey);
                                          },
                                        );
                                } else if (['mp4', 'mov', 'avi']
                                    .contains(ext)) {
                                  iconWidget = const Icon(Icons.videocam,
                                      size: 50, color: Colors.blue);
                                } else if (ext == 'pdf') {
                                  iconWidget = const Icon(Icons.picture_as_pdf,
                                      size: 50, color: Colors.red);
                                } else {
                                  iconWidget = const Icon(
                                      Icons.insert_drive_file,
                                      size: 50,
                                      color: Colors.grey);
                                }

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedFileIndex = index;
                                    });
                                  },
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 120,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.blue.shade400,
                                              width: 1),
                                        ),
                                        child: Column(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: iconWidget,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              fileName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              files.removeAt(index);
                                              fileNameControllers
                                                  .removeAt(index);

                                              if (files.isEmpty) {
                                                selectedFileIndex =
                                                    null; // reset if no files
                                              } else if (selectedFileIndex ==
                                                  index) {
                                                selectedFileIndex =
                                                    null; // close panel if removed selected file
                                              } else if (selectedFileIndex !=
                                                      null &&
                                                  selectedFileIndex! > index) {
                                                selectedFileIndex =
                                                    selectedFileIndex! -
                                                        1; // adjust index if needed
                                              }
                                            });
                                          },
                                          child: const CircleAvatar(
                                            radius: 14,
                                            backgroundColor: Colors.red,
                                            child: Icon(Icons.close,
                                                size: 16, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            "🔴 Note:\nNeed extra files?\nTap the any Attached FIles to add any file!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              fontFamily: "Times New Roman",
                            ),
                          ),

                          const SizedBox(height: 10),

                          if (selectedFileIndex != null)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: Colors.blue, width: 2),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ...List.generate(files.length, (index) {
                                          final info = files[index];
                                          final ext =
                                              (info['fileType'] as String? ??
                                                      '')
                                                  .toLowerCase();
                                          final isLocal =
                                              info['isLocal'] == true;
                                          final url = info['downloadUrl'];

                                          Widget preview;
                                          if (['jpg', 'jpeg', 'png', 'gif']
                                              .contains(ext)) {
                                            preview = isLocal
                                                ? Image.file(
                                                    File(url),
                                                    width: 120,
                                                    height: 90,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Image.network(
                                                    url,
                                                    width: 120,
                                                    height: 90,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __,
                                                            ___) =>
                                                        const Icon(
                                                            Icons.broken_image,
                                                            size: 50,
                                                            color: Colors.grey),
                                                  );
                                          } else if ([
                                            'mp4',
                                            'mov',
                                            'avi',
                                            'mkv'
                                          ].contains(ext)) {
                                            preview = const Icon(Icons.videocam,
                                                size: 50, color: Colors.blue);
                                          } else if (ext == 'pdf') {
                                            preview = const Icon(
                                                Icons.picture_as_pdf,
                                                size: 50,
                                                color: Colors.red);
                                          } else {
                                            preview = const Icon(
                                                Icons.insert_drive_file,
                                                size: 50,
                                                color: Colors.grey);
                                          }

                                          return Container(
                                            margin: const EdgeInsets.all(10),
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: Colors.blue, width: 1),
                                            ),
                                            width: 140,
                                            child: Stack(
                                              children: [
                                                Column(
                                                  children: [
                                                    preview,
                                                    const SizedBox(height: 10),
                                                    Text(
                                                      info['fileName'] ?? '',
                                                      style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 5),
                                                    SizedBox(
                                                      width: 120,
                                                      child: TextField(
                                                        controller:
                                                            fileNameControllers[
                                                                index],
                                                        decoration:
                                                            InputDecoration(
                                                          labelText: 'Rename',
                                                          border:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                          ),
                                                          filled: true,
                                                          fillColor: Colors
                                                              .blue.shade50,
                                                        ),
                                                        style: const TextStyle(
                                                            fontSize: 12),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 5),
                                                    ElevatedButton(
                                                      onPressed: () =>
                                                          renameFile(index),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        minimumSize:
                                                            const Size(120, 30),
                                                        backgroundColor: Colors
                                                            .blue.shade900,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                      ),
                                                      child: const Text(
                                                          "Rename",
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .white)),
                                                    ),
                                                    const SizedBox(height: 5),
                                                    ElevatedButton(
                                                      onPressed: () =>
                                                          replaceFile(index),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        minimumSize:
                                                            const Size(120, 30),
                                                        backgroundColor: Colors
                                                            .blue.shade900,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                      ),
                                                      child: const Text(
                                                          "Replace",
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .white)),
                                                    ),
                                                    const SizedBox(height: 5),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        openFile(url, isLocal);
                                                      },
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        minimumSize:
                                                            const Size(120, 30),
                                                        backgroundColor: Colors
                                                            .blue.shade900,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                      ),
                                                      child: const Text("Open",
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .white)),
                                                    ),
                                                  ],
                                                ),
                                                Positioned(
                                                  top: -8,
                                                  right: -5,
                                                  child: CircleAvatar(
                                                    radius: 16,
                                                    backgroundColor:
                                                        Colors.white,
                                                    child: IconButton(
                                                      icon: const Icon(
                                                          Icons.close,
                                                          color: Colors.red,
                                                          size: 19),
                                                      onPressed: () =>
                                                          closeDetailPanel(
                                                              index),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),

                                        // 👇 ADD FILE BUTTON HERE
                                        GestureDetector(
                                          onTap: () async {
                                            FilePickerResult? result =
                                                await FilePicker.platform
                                                    .pickFiles(
                                              type: FileType.any,
                                              allowMultiple: false,
                                            );

                                            if (result != null &&
                                                result.files.isNotEmpty) {
                                              final file = result.files.first;
                                              final filePath = file.path!;
                                              final fileName = file.name;
                                              final ext = file.extension ?? '';

                                              final newFile = {
                                                'fileName': fileName,
                                                'fileType': ext,
                                                'isLocal': true,
                                                'downloadUrl': filePath,
                                              };

                                              final newController =
                                                  TextEditingController(
                                                      text: fileName);

                                              // 👇 Insert right after selected index
                                              final insertIndex =
                                                  selectedFileIndex! + 1;

                                              setState(() {
                                                files.insert(
                                                    insertIndex, newFile);
                                                fileNameControllers.insert(
                                                    insertIndex, newController);

                                                // Optionally, update the selected index to highlight new file
                                                selectedFileIndex = insertIndex;
                                              });

                                              // Optional: Scroll to new item here if you're using a ScrollController
                                            }
                                          },
                                          child: Container(
                                            width: 140,
                                            height: 220,
                                            margin: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                  color: Colors.grey,
                                                  width: 2,
                                                  style: BorderStyle.solid),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Center(
                                              child: Icon(Icons.add,
                                                  size: 40, color: Colors.blue),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          SizedBox(
                            height: 20,
                          ),

                          Container(
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
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                child: ElevatedButton(
                                  onPressed: _updateRecord,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
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
    required FocusNode currentFocus,
    FocusNode? nextFocus,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          const SizedBox(height: 6),
          Container(
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Focus(
              focusNode: currentFocus,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                value:
                    items.any((item) => item['text'] == value) ? value : null,
                decoration: const InputDecoration(
                  prefixIcon:
                      Icon(Icons.arrow_drop_down, color: Colors.cyanAccent),
                  border: InputBorder.none,
                  errorStyle: TextStyle(color: Colors.cyanAccent),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                dropdownColor: const Color(0xFF002147),
                iconEnabledColor: Colors.cyanAccent,
                onChanged: (val) {
                  onChanged(val);
                  // Move focus to next field if specified
                  if (nextFocus != null) {
                    FocusScope.of(currentFocus.context!)
                        .requestFocus(nextFocus);
                  }
                },
                validator: validator,
                items: items.map<DropdownMenuItem<String>>((item) {
                  return DropdownMenuItem<String>(
                    value: item['text'],
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
        ],
      ),
    );
  }

  // Text form field
  Widget buildTextFormField(
    String label,
    String initialValue,
    IconData icon,
    Function(String) onChanged, {
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          const SizedBox(height: 6),
          Container(
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
            child: TextFormField(
              initialValue: initialValue,
              readOnly: readOnly,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: Colors.cyanAccent),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                errorStyle: const TextStyle(
                    color: Colors.cyanAccent), // ✅ Error text color
              ),
              onChanged: readOnly ? null : onChanged,
              validator: validator,
              inputFormatters: inputFormatters,
              textInputAction: TextInputAction.next,
              onEditingComplete: () => FocusScope.of(context).nextFocus(),
              keyboardType: inputFormatters != null
                  ? TextInputType.number
                  : TextInputType.text,
            ),
          ),
        ],
      ),
    );
  }

  void _updateRecord() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance
            .collection('Installation')
            .doc(widget.docId)
            .update({
          'technician_name': fullName,
          'installation_site': contactNumber,
          'installation_date': email,
          'service_time': preferredContactMethod,
          'selected_product': leadSource,
          'service_status': selectedServiceStatus,
          'customer_name': additionalDetails,
          'customer_contact': taskstatus,
          'whasapp_contact':whatsappNumber,
          'service_description': meetingcstatus,
          'remarks': remarks,
          'files': files,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            elevation: 6,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF28A745), Color(0xFF218838)],
                  // Green gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_circle_outline,
                      color: Colors.white, size: 26),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Installation Record updated successfully',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        Navigator.of(context).pop();
      } catch (e) {
        // ❌ Error Snackbar with red gradient
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            elevation: 6,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                  // Red gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.white, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Error updating record: $e',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

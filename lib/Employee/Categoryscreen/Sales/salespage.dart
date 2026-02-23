import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../Default/customwidget.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final _formKey = GlobalKey<FormState>();
  FocusNode checkbox1Focus = FocusNode();
  FocusNode checkbox2Focus = FocusNode();
  FocusNode checkbox3Focus = FocusNode();
  FocusNode checkbox4Focus = FocusNode();
  FocusNode checkbox5Focus = FocusNode();
  FocusNode checkbox6Focus = FocusNode();
  FocusNode checkbox7Focus = FocusNode();
  FocusNode checkbox8Focus = FocusNode();
  FocusNode checkbox9Focus = FocusNode();
  FocusNode checkbox10Focus = FocusNode();
  FocusNode checkbox11Focus = FocusNode();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _executivenameController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _WhatsappNumberController =
  TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _additionalDetailsController =
      TextEditingController();
  final TextEditingController _propertySizeController = TextEditingController();
  final TextEditingController _budgetrangeController =
  TextEditingController();

  String? _preferredContactMethod;
  String? _leadSource;
  String? _leadType;
  String? _propertyType;
  String? _currentHomeAutomation;
  String? _budgetRange;

  bool _touchswitchboard = false;
  bool _rfremos = false;
  bool _digitaldoorlock = false;
  bool _curtainautomation = false;
  bool _hometheatre = false;
  bool _vbusautomation = false;
  bool _gateautomation = false;
  bool _cctv = false;
  bool _videodoorphone = false;
  bool _boombarrier = false;
  bool _others = false;
  bool _isLoading = false;
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
          _executivenameController.text =
              userSnapshot.get('fullName') ?? "Unknown";
        });
        print(
            "Fetched Data: ${_executivenameController.text},");
      } else {
        print("No user data found for userId: $userId");
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sales Lead Form',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: "Times New Roman",
              color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade900,
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Card(
            elevation: 20,
            shadowColor: Colors.cyan.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildTextField(
                      context: context,
                      readOnly: true,
                      controller: _executivenameController,
                      labelText: 'Lead Owner Name',
                      icon: Icons.person_3_rounded,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                        {
                          return 'Please enter your lead owner name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    buildTextField(
                      context: context,
                      controller: _fullNameController,
                      labelText: 'Full Name',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    buildTextField(
                      context: context,
                      controller: _contactNumberController,
                      labelText: 'Contact Number',
                      icon: Icons.phone_outlined,
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
                    SizedBox(height: 15),
                    buildTextField(
                      context: context,
                      controller: _WhatsappNumberController,
                      labelText: 'Whatsapp Number',
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
                          return 'Enter a valid 10-digit number.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    buildTextField(
                      context: context,
                      controller: _emailController,
                      labelText: 'Email Address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email address';
                        }
                        if (!RegExp(
                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
                        ).hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    buildDropdownField(
                      context: context,
                      labelText: 'Preferred Contact Method',
                      icon: Icons.contact_phone_outlined,
                      value: _preferredContactMethod,
                      items: [
                        {'text': 'Phone', 'icon': Icons.phone_android},
                        {'text': 'Email', 'icon': Icons.email},
                        {'text': 'Text', 'icon': Icons.message},
                        {'text': 'WhatsApp', 'icon': FontAwesomeIcons.whatsapp},
                      ],
                      onChanged: (value) {
                        setState(() {
                          _preferredContactMethod = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a preferred contact method';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    buildDropdownField(
                      context: context,
                      labelText: 'Lead Source',
                      icon: Icons.source_outlined,
                      value: _leadSource,
                      items: [
                        {'text': 'Website', 'icon': FontAwesomeIcons.globe},
                        {
                          'text': 'Social Media',
                          'icon': FontAwesomeIcons.instagram
                        },
                        {
                          'text': 'Personal Reference',
                          'icon': FontAwesomeIcons.userFriends
                        },
                        {'text': 'Advertisement', 'icon': FontAwesomeIcons.ad},
                        {'text': 'Event', 'icon': FontAwesomeIcons.calendarAlt},
                        {
                          'text': 'Indiamart',
                          'icon': FontAwesomeIcons.shoppingCart
                        },
                        {'text': 'Facebook', 'icon': FontAwesomeIcons.facebook},
                        {
                          'text': 'Architect Interior',
                          'icon': FontAwesomeIcons.building
                        },
                        {'text': 'Builder', 'icon': FontAwesomeIcons.hammer},
                        {
                          'text': 'Walkthrough',
                          'icon': FontAwesomeIcons.walking
                        },
                        {
                          'text': 'Electrician',
                          'icon': FontAwesomeIcons.lightbulb
                        },
                        {'text': 'Dealer', 'icon': FontAwesomeIcons.store},
                      ],
                      onChanged: (value) {
                        setState(() {
                          _leadSource = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a lead source';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    buildDropdownField(
                      context: context,
                      labelText: 'Lead Type',
                      icon: FontAwesomeIcons.userTag,
                      value: _leadType,
                      items: [
                        {
                          'text': 'New Inquiry',
                          'icon': FontAwesomeIcons.userPlus
                        },
                        {
                          'text': 'Returning Customer',
                          'icon': FontAwesomeIcons.recycle
                        },
                        {
                          'text': 'Referral',
                          'icon': FontAwesomeIcons.peopleArrows
                        },
                        {
                          'text': 'Contacted',
                          'icon': FontAwesomeIcons.phone,
                        },
                        {
                          'text': 'Nurture',
                          'icon': FontAwesomeIcons.seedling,
                        },
                        {
                          'text': 'Qualified',
                          'icon': FontAwesomeIcons.checkCircle,
                        },
                        {
                          'text': 'Unqualified',
                          'icon': FontAwesomeIcons.timesCircle,
                        },
                        {
                          'text': 'Junk',
                          'icon': FontAwesomeIcons.trash,
                        },
                      ],
                      onChanged: (value) {
                        setState(() {
                          _leadType = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a lead type';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 30),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Services Interested In:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.deepPurple,
                          ),
                        ),
                        buildCustomCheckboxTile(
                          title: 'Touch Switchboard',
                          value: _touchswitchboard,
                          onChanged: (value) {
                            setState(() {
                              _touchswitchboard = value ?? false;
                            });
                          },
                          icon: Icons.lightbulb,
                          focusNode: checkbox1Focus,
                          color: Colors.amber,
                        ),
                        buildCustomCheckboxTile(
                          title: 'Rf Remos',
                          value: _rfremos,
                          onChanged: (value) {
                            setState(() {
                              _rfremos = value ?? false;
                            });
                          },
                          icon: Icons.settings_remote_rounded,
                          color: Colors.blue,
                          focusNode: checkbox2Focus,
                        ),
                        buildCustomCheckboxTile(
                          title: 'Digital Door Lock',
                          value: _digitaldoorlock,
                          onChanged: (value) {
                            setState(() {
                              _digitaldoorlock = value ?? false;
                            });
                          },
                          icon: Icons.door_back_door_rounded,
                          focusNode: checkbox3Focus,
                          color: Colors.red,
                        ),
                        buildCustomCheckboxTile(
                          title: 'Curtain Automation',
                          value: _curtainautomation,
                          onChanged: (value) {
                            setState(() {
                              _curtainautomation = value ?? false;
                            });
                          },
                          icon: Icons.curtains_closed,
                          focusNode: checkbox4Focus,
                          color: Colors.purple,
                        ),
                        buildCustomCheckboxTile(
                          title: 'Home Theatre',
                          value: _hometheatre,
                          onChanged: (value) {
                            setState(() {
                              _hometheatre = value ?? false;
                            });
                          },
                          icon: FontAwesomeIcons.tv,
                          focusNode: checkbox5Focus,
                          color: Colors.green,
                        ),
                        buildCustomCheckboxTile(
                          title: 'V Bus Automation',
                          value: _vbusautomation,
                          onChanged: (value) {
                            setState(() {
                              _vbusautomation = value ?? false;
                            });
                          },
                          icon: Icons.tv,
                          color: Colors.purple,
                          focusNode: checkbox6Focus,
                        ),
                        buildCustomCheckboxTile(
                          title: 'Gate Automation',
                          value: _gateautomation,
                          onChanged: (value) {
                            setState(() {
                              _gateautomation = value ?? false;
                            });
                          },
                          icon: Icons.door_back_door_sharp,
                          color: Colors.purple,
                          focusNode: checkbox7Focus,
                        ),
                        buildCustomCheckboxTile(
                          title: 'CCTV',
                          value: _cctv,
                          onChanged: (value) {
                            setState(() {
                              _cctv = value ?? false;
                            });
                          },
                          icon: Icons.video_camera_back_sharp,
                          color: Colors.purple,
                          focusNode: checkbox8Focus,
                        ),
                        buildCustomCheckboxTile(
                          title: 'Video Door Phone',
                          value: _videodoorphone,
                          onChanged: (value) {
                            setState(() {
                              _videodoorphone = value ?? false;
                            });
                          },
                          icon: Icons.phone_android,
                          color: Colors.purple,
                          focusNode: checkbox9Focus,
                        ),
                        buildCustomCheckboxTile(
                          title: 'Boom Barrier',
                          value: _boombarrier,
                          onChanged: (value) {
                            setState(() {
                              _boombarrier = value ?? false;
                            });
                          },
                          icon: Icons.desk_sharp,
                          color: Colors.purple,
                          focusNode: checkbox10Focus,
                        ),
                        buildCustomCheckboxTile(
                          title: 'Others',
                          value: _others,
                          onChanged: (value) {
                            setState(() {
                              _others = value ?? false;
                            });
                          },
                          icon: Icons.devices_other_outlined,
                          color: Colors.purple,
                          focusNode: checkbox11Focus,
                        ),
                      ],
                    ),
                    SizedBox(height: 30),
                    buildTextField(
                      context: context,
                      controller: _additionalDetailsController,
                      labelText: 'Additional Details',
                      icon: FontAwesomeIcons.infoCircle,
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please provide additional details';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    buildDropdownField(
                      context: context,
                      labelText: 'Type of Property',
                      icon: FontAwesomeIcons.building,
                      value: _propertyType,
                      items: [
                        {'text': 'Apartment', 'icon': FontAwesomeIcons.city},
                        {'text': 'House', 'icon': FontAwesomeIcons.home},
                        {'text': 'Office', 'icon': FontAwesomeIcons.building},
                      ],
                      onChanged: (value) {
                        setState(() {
                          _propertyType = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a type of property';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    buildTextField(
                      context: context,
                      controller: _propertySizeController,
                      labelText: 'Size of Property (sq ft)',
                      icon: FontAwesomeIcons.ruler,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the size of the property';
                        }
                        if (!RegExp(r'^\d+$').hasMatch(value)) {
                          return 'Please enter a valid size in square feet';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    buildDropdownField(
                      context: context,
                      labelText: 'Current Home Automation Setup',
                      icon: FontAwesomeIcons.robot,
                      value: _currentHomeAutomation,
                      items: [
                        {'text': 'None', 'icon': FontAwesomeIcons.timesCircle},
                        {'text': 'Partial', 'icon': FontAwesomeIcons.expand},
                        {
                          'text': 'Fully Automated',
                          'icon': FontAwesomeIcons.robot
                        },
                        {
                          'text': 'Interested in Upgrading',
                          'icon': FontAwesomeIcons.arrowUp
                        },
                      ],
                      onChanged: (value) {
                        setState(() {
                          _currentHomeAutomation = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a current home automation setup';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    // buildDropdownField(
                    //   context: context,
                    //   labelText: 'Budget Range',
                    //   icon: FontAwesomeIcons.moneyBillWave,
                    //   value: _budgetRange,
                    //   items: [
                    //     {
                    //       'text': 'Below \$1,000',
                    //       'icon': FontAwesomeIcons.dollarSign
                    //     },
                    //     {
                    //       'text': '\$1,000 - \$5,000',
                    //       'icon': FontAwesomeIcons.dollarSign
                    //     },
                    //     {
                    //       'text': 'Above \$5,000',
                    //       'icon': FontAwesomeIcons.dollarSign
                    //     },
                    //   ],
                    //   onChanged: (value) {
                    //     setState(() {
                    //       _budgetRange = value;
                    //     });
                    //   },
                    //   validator: (value) {
                    //     if (value == null || value.isEmpty) {
                    //       return 'Please select a budget range';
                    //     }
                    //     return null;
                    //   },
                    // ),
                    buildTextField(
                      context: context,
                      controller: _budgetrangeController,
                      labelText: 'Budget Range',
                      keyboardType: TextInputType.number,
                      icon:FontAwesomeIcons.moneyBillWave,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select budget range';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade900,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))),
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'Submit',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
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
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (!_touchswitchboard &&
          !_rfremos &&
          !_digitaldoorlock &&
          !_curtainautomation &&
          !_hometheatre &&
          !_vbusautomation &&
          !_gateautomation &&
          !_cctv &&
          !_videodoorphone &&
          !_boombarrier &&
          !_others) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select at least one service'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
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
          _isLoading = false;
        });
        return;
      }

      Map<String, dynamic> formData = {
        'uid': user.uid,
        'reportedDateTime': FieldValue.serverTimestamp(),
        'executivename': _executivenameController.text.trim(),
        'fullName': _fullNameController.text.trim(),
        'contactNumber': _contactNumberController.text.trim(),
        'whatsappNumber': _WhatsappNumberController.text.trim(),
        'email': _emailController.text.trim(),
        'preferredContactMethod': _preferredContactMethod,
        'leadSource': _leadSource,
        'leadType': _leadType,
        'propertyType': _propertyType,
        'propertySize': _propertySizeController.text.trim(),
        'currentHomeAutomation': _currentHomeAutomation,
        'budgetRange': _budgetrangeController.text.trim(),
        'additionalDetails': _additionalDetailsController.text.trim(),
        'servicesInterestedIn': {
          'Touch Switchboard': _touchswitchboard,
          'Rf Remos': _rfremos,
          'Digital Door Lock': _digitaldoorlock,
          'Curtain Automation': _curtainautomation,
          'Home Theatre': _hometheatre,
          'V Bus Automation': _vbusautomation,
          'Gate Automation': _gateautomation,
          'CCTV': _cctv,
          'Video Door Phone': _videodoorphone,
          'Boom Barrier': _boombarrier,
          'Others': _others,
        },
      };

      try {
        await _firestore.collection('Salesinfo').add(formData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Sales Form submitted successfully!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        _formKey.currentState!.reset();
        _resetForm();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error submitting form: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetForm() {
    // _executivenameController.clear();
    _fullNameController.clear();
    _contactNumberController.clear();
    _WhatsappNumberController.clear();
    _emailController.clear();
    _budgetrangeController.clear();
    _additionalDetailsController.clear();
    _propertySizeController.clear();
    setState(() {
      _preferredContactMethod = null;
      _leadSource = null;
      _leadType = null;
      _propertyType = null;
      _currentHomeAutomation = null;
      _touchswitchboard = false;
      _rfremos = false;
      _digitaldoorlock = false;
      _curtainautomation = false;
      _hometheatre = false;
      _vbusautomation = false;
      _gateautomation = false;
      _cctv = false;
      _videodoorphone = false;
      _boombarrier = false;
      _others = false;
    });
  }
}

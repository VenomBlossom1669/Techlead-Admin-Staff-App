import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:techlead/Admin/Installation/Showinstallationdata.dart';
import 'package:techlead/Admin/Leavescreen/leaveinfo.dart';
import 'package:techlead/Admin/Meetingmanagement/reception.dart';
import 'package:techlead/Admin/Sales/salespage.dart';
import 'package:techlead/Admin/Taskdetails/Admintaskassigneddata.dart';
import 'package:techlead/Admin/Taskdetails/reportsendtoadminside.dart';
import 'package:techlead/Admin/Meetingsection/showreceptiondata.dart';
import 'package:techlead/Admin/Taskdetails/taskassignpage.dart';
import 'package:techlead/Calendar_Ui/Reports_of_Admin_cal/Admin_Meetings_Calendar.dart';
import 'package:techlead/Calendar_Ui/Task_Report_Model/SyncFunction_Task.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Authentication/Admin_Profiles/Admin_Profiles.dart';
import 'Employeedetails/Empshowdata.dart';
import 'Employeedetails/EnSignUpPage.dart';
import 'Employeedetails/Showemployees.dart';
import 'Employeedetails/forgotpassword.dart';
import 'Guildlines/Adminviewguildlines.dart';
import 'Guildlines/Guildlinesassign.dart';
import 'Installation/Shortagereports.dart';
import 'Installation/Siteinstallationpage.dart';
import 'Installation/fetchedshortagereport.dart';
import 'package:techlead/Employee/Authentication/Enteredscreen.dart';
import 'Attendance/Showattendancedata.dart';
import 'Sales/Showsalesdata.dart';
import 'package:techlead/Default/Themeprovider.dart';
import 'package:techlead/Employee/Categoryscreen/Services/Servicepage.dart';
import 'Birthdaydetails/empwishform.dart';

class AdminHomeScreeen extends StatefulWidget {
  const AdminHomeScreeen({super.key});

  @override
  State<AdminHomeScreeen> createState() => _AdminHomeScreeenState();
}

class _AdminHomeScreeenState extends State<AdminHomeScreeen>
    with SingleTickerProviderStateMixin {
  bool isLoading = true;
  String selectedPage = 'Meetings';
  String _adminName = 'TechLead The Engineering Solutions!';
  String _adminImage = 'assets/images/enteredscreen.png';
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _askPermission();
    _loadAdminProfile();
    Future.delayed(const Duration(seconds: 0), () {
      setState(() {
        isLoading = false;
      });
    });
  }


  Future<void> _loadAdminProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email') ?? '';

      if (email.isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('Admin_Profiles')
            .doc(email)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _adminName = data['name'] ?? 'Admin';
            _adminImage = data['image'] ?? 'assets/images/default_avatar.png';
            _isLoadingProfile = false;
          });
        } else {
          setState(() {
            _isLoadingProfile = false;
          });
        }
      } else {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      print('Error loading admin profile: $e');
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }



  Future<void> _launchPhone(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri url = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _launchMap(String address) async {
    final Uri url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }


  Future<void> _askPermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        final photos = await Permission.photos.request();
        final videos = await Permission.videos.request();
        final audio = await Permission.audio.request();
        final manage = await Permission.manageExternalStorage.request();

        if (photos.isGranted ||
            videos.isGranted ||
            audio.isGranted ||
            manage.isGranted) {
          debugPrint("✅ Media/Files permission granted (Android 13+)");
        } else {
          debugPrint("❌ Media/Files permission denied (Android 13+)");
        }
      } else {
        final storage = await Permission.storage.request();
        if (storage.isGranted) {
          debugPrint("✅ Storage permission granted (Android 12-)");
        } else {
          debugPrint("❌ Storage permission denied (Android 12-)");
        }
      }
    } else if (Platform.isIOS) {
      final photos = await Permission.photos.request();
      if (photos.isGranted) {
        debugPrint("✅ Photos permission granted (iOS)");
      } else {
        debugPrint("❌ Photos permission denied (iOS)");
      }
    }
  }

  @override
  Future<bool> _onWillPop(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.blueAccent),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Exit Techlead App?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: "Times New Roman",
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to exit?',
          style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.exit_to_app),
            label: const Text('Exit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await FirebaseAuth.instance.signOut();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Enteredscreen()),
    );
  }

  Widget _serviceCard(String title, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.9), color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5.w,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 40.sp),
          SizedBox(height: 10.h),
          Expanded(
            child: Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _quickAccessCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.7),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _statsCard(String title, String value, IconData icon, Color color) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
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
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontSize: 16),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              Navigator.of(context).pop();
              _logout(context);
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(text, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 3
      ),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.amberAccent,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _navigate(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade900, Colors.indigo.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
              AppBar(
                automaticallyImplyLeading: true,
                title: const Text(
                  "Techlead Admin Panel",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black38,
                        offset: Offset(2, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                centerTitle: true,
                elevation: 8,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.shade700,
                        Colors.indigo.shade800,
                        Colors.blue.shade900,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              )

            ],
          ),
        ),
        drawer: Drawer(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0A2A5A),
                  Color(0xFF15489C),
                  Color(0xFF1E64D8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 40, bottom: 14),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 110,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF1E64D8), Color(0xFF1E64D8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF005F73), Color(0xFF0A9396)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: ClipOval(
                            child: _isLoadingProfile
                                ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : (_adminImage.startsWith('http') || _adminImage.startsWith('https'))
                                ? Image.network(
                              _adminImage,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/default_avatar.png',
                                  fit: BoxFit.cover,
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                            )
                                : Image.asset(
                              _adminImage,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/default_avatar.png',
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      _isLoadingProfile
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Text(
                        _adminName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Times New Roman",
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white, thickness: 2,  height: 3,),
                Expanded(
                  child: ListView(
                    children: [
                      _buildSectionHeader('Project Information'),
                      _buildDrawerItem(
                        icon: FontAwesomeIcons.userShield,
                        text: 'Admin Profiles',
                        onTap: () => _navigate(context, const AdminProfiles()),
                      ),
                      _buildDrawerItem(
                        icon: Icons.task,
                        text: 'Employees Daily Task Reports',
                        onTap: () => _navigate(context, const ReportSendToAdminSide()),
                      ),
                      _buildDrawerItem(
                        icon: Icons.add,
                        text: 'Admin Task Assign',
                        onTap: () => _navigate(context, const TaskAssignPageDE()),
                      ),
                      _buildDrawerItem(
                        icon: Icons.report,
                        text: 'Admin Task Reports',
                        onTap: () => _navigate(context, const Admintaskassigneddata()),
                      ),
                      const Divider(color: Colors.white54),
                      _buildSectionHeader('Employees Project Data'),
                      _buildDrawerItem(
                        icon: Icons.person_add_alt_1,
                        text: 'Employee Registration',
                        onTap: () => _navigate(context, const SignUpPage2()),
                      ),
                      _buildDrawerItem(
                        icon: Icons.people_alt,
                        text: 'Employee Authentication',
                        onTap: () => _navigate(context, const Showemployees()),
                      ),
                      _buildDrawerItem(
                        icon: Icons.people_outline,
                        text: 'Employee Profiles',
                        onTap: () => _navigate(context, const EmpShowData()),
                      ),
                      _buildDrawerItem(
                        icon: Icons.lock_reset,
                        text: 'Employee Forgot Password',
                        onTap: () => _navigate(context, const ForgotPasswordPage()),
                      ),
                      _buildDrawerItem(
                        icon: Icons.note_alt_sharp,
                        text: 'Add Guidelines',
                        onTap: () => _navigate(context, const AddGuidelines()),
                      ),
                      _buildDrawerItem(
                        icon: Icons.view_agenda,
                        text: 'View Guidelines',
                        onTap: () => _navigate(context, const AdminGuideLines()),
                      ),
                      const Divider(color: Colors.white54),
                      _buildSectionHeader('Installation'),
                      _buildDrawerItem(
                          icon: Icons.install_desktop,
                          text: 'Site Installation',
                          onTap: () => _navigate(context, Siteinstallationpage())),
                      _buildDrawerItem(
                          icon: Icons.description_outlined,
                          text: 'Installation Shortage',
                          onTap: () => _navigate(context, ShortageOfProductAdmin())),
                      _buildDrawerItem(
                        icon: Icons.settings_applications,
                        text: 'Installation Reports',
                        onTap: () => _navigate(context,  Showinstallationdata()),
                      ),
                      _buildDrawerItem(
                        icon: Icons.report_problem,
                        text: 'Installation Shortage Reports',
                        onTap: () => _navigate(context,  FetchedProductPage()),
                      ),
                      const Divider(color: Colors.white54),
                      _buildSectionHeader('Sales'),
                      _buildDrawerItem(
                        icon: Icons.generating_tokens_rounded,
                        text: 'Sales Lead',
                        onTap: () => _navigate(context, const AdminSalesPage()),
                      ),
                      _buildDrawerItem(
                        icon: Icons.shopping_cart,
                        text: 'Sales Reports',
                        onTap: () => _navigate(context,  SalesInfoPage()),
                      ),
                      const Divider(color: Colors.white54),
                      _buildSectionHeader('Meetings'),
                      _buildDrawerItem(
                        icon: Icons.meeting_room,
                        text: 'Meeting Assign',
                        onTap: () => _navigate(context,  ReceptionPage()),
                      ),
                      _buildDrawerItem(
                        icon: Icons.meeting_room_outlined,
                        text: 'Meeting Reports',
                        onTap: () => _navigate(context,  Showreceptiondata()),
                      ),
                      const Divider(color: Colors.white54),
                      _buildSectionHeader('HR & Admin'),
                      _buildDrawerItem(
                        icon: Icons.cake,
                        text: 'Birthday Page',
                        onTap: () => _navigate(context, const EmpWishForm()),
                      ),
                      _buildDrawerItem(
                        icon: Icons.show_chart,
                        text: 'Attendance Reports',
                        onTap: () => _navigate(context, const Attendance()),
                      ),
                      _buildDrawerItem(
                        icon: Icons.leave_bags_at_home,
                        text: 'Leave Reports',
                        onTap: () => _navigate(context, const LeaveInfo()),
                      ),
                      _buildDrawerItem(
                        icon: Icons.support_agent,
                        text: 'Services',
                        onTap: () => _navigate(context, const ServicePageList()),
                      ),
                      _buildDrawerItem(
                        icon: Icons.sunny_snowing,
                        text: 'Theme',
                        onTap: () {
                          // ✅ Drawer band karva
                          Navigator.pop(context);

                          final themeProvider =
                          Provider.of<ThemeProvider>(context, listen: false);
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

                      _buildDrawerItem(
                        icon: Icons.logout,
                        text: 'Logout',
                        onTap: () => showLogoutConfirmationDialog(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        body: isLoading
            ? Center(
          child: Shimmer.fromColors(
            baseColor: Colors.blue.shade300,
            highlightColor: Colors.blue.shade100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 150,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
        )
            : SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade50,
                  Colors.blue.shade50,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade900,
                          Colors.indigo.shade700,
                          Colors.purple.shade600,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade900.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                FontAwesomeIcons.crown,
                                color: Colors.amberAccent,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Welcome Back, Admin!",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Manage your TechLead operations efficiently",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Calendar Section
                  Text(
                    "Calendar Access",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.indigo.shade700, Colors.blue.shade900],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          color: Colors.amberAccent,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Select Calendar View",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonHideUnderline(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: DropdownButton<String>(
                              value: selectedPage,
                              isExpanded: true,
                              borderRadius: BorderRadius.circular(16),
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                              dropdownColor: Colors.blue.shade900,
                              elevation: 6,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Meetings',
                                  child: Row(
                                    children: [
                                      FaIcon(FontAwesomeIcons.userTie, color: Colors.greenAccent),
                                      SizedBox(width: 10),
                                      Text(
                                        'Admin Calendar',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Tasks',
                                  child: Row(
                                    children: [
                                      FaIcon(FontAwesomeIcons.users, color: Colors.greenAccent),
                                      SizedBox(width: 10),
                                      Text(
                                        'Employee Calendar',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == 'Meetings') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const AdminMeetingShow()),
                                  );
                                } else if (value == 'Tasks') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const TaskCalendarPage()),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                    Text(
                      "Quick Access",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),
                Column(
                  children: [
                    _quickAccessCard(
                      "Employee Management",
                      Icons.people_alt,
                      Colors.blue.shade600,
                          () => _navigate(context, const Showemployees()),
                    ),
                    const SizedBox(height: 12),
                    _quickAccessCard(
                      "Task Assignment",
                      Icons.assignment,
                      Colors.green.shade600,
                          () => _navigate(context, const TaskAssignPageDE()),
                    ),
                    const SizedBox(height: 12),
                    _quickAccessCard(
                      "Sales Reports",
                      Icons.trending_up,
                      Colors.orange.shade600,
                          () => _navigate(context, SalesInfoPage()),
                    ),
                    const SizedBox(height: 12),
                    _quickAccessCard(
                      "Meeting Management",
                      Icons.meeting_room,
                      Colors.purple.shade600,
                          () => _navigate(context, ReceptionPage()),
                    ),
                  ],
                ),

                  const SizedBox(height: 30),

                  // TechLead Services Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.indigo.shade700,
                        Colors.blue.shade900,
                        Colors.purple.shade700,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              FontAwesomeIcons.rocket,
                              color: Colors.amberAccent,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // 👇 Wrap enable with Expanded
                          const Expanded(
                            child: Text(
                              "TechLead Services", // long text hoy to next line ma wrap thase
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              softWrap: true,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Text(
                        "Comprehensive engineering solutions for modern businesses",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      /// GRIDVIEW REPLACE WRAP
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 15,
                        crossAxisSpacing: 15,
                        childAspectRatio: 1.2, // 👈 Adjust as per screen
                        children: [
                          _serviceCard("Smart Homes", Colors.purple.shade500, Icons.home_filled),
                          _serviceCard("Energy Solutions", Colors.green.shade500, Icons.energy_savings_leaf),
                          _serviceCard("Security Systems", Colors.red.shade500, Icons.security),
                          _serviceCard("Tech Support", Colors.orange.shade500, Icons.support_agent),
                          _serviceCard("Project Management", Colors.blue.shade500, Icons.engineering),
                          _serviceCard("Installation Services", Colors.teal.shade500, Icons.construction),
                        ],
                      ),

                    ],
                  ),
                ),


                const SizedBox(height: 30),

                  // Company Information Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.teal.shade700,
                          Colors.cyan.shade600,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.business,
                                color: Colors.amberAccent,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // 👇 Wrap enable with Expanded
                            const Expanded(
                              child: Text(
                                "Company Overview", // long text hoy to wrap thase next line ma
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        const Text(
                          "TechLead is a pioneering engineering solutions company dedicated to transforming businesses through innovative technology implementations. We specialize in smart automation, energy-efficient systems, and comprehensive technical support.",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Founded",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    "2020",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Projects Completed",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    "500+",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Contact Information Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurple.shade700,
                          Colors.indigo.shade600,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.contact_support,
                                color: Colors.amberAccent,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              "Get In Touch",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.phone, color: Colors.white70, size: 20),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => _launchPhone("+919586889988"),
                              child: const Text(
                                "+91 95868 89988",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            const Icon(Icons.email, color: Colors.white70, size: 20),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => _launchEmail("info@techleadsolution.in"),
                              child: const Text(
                                "info@techleadsolution.in",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, color: Colors.white70, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _launchMap(
                                    "A-303, S.G.Business Hub, Sarkhej - Gandhinagar Highway, Gota, Ahmedabad, Gujarat 380060"), // ✅ map redirect
                                child: const Text(
                                  "A-303, S.G.Business Hub, Sarkhej - Gandhinagar Highway, Gota, Ahmedabad, Gujarat 380060",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Footer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Column(
                      children: [
                        Text(
                          "TechLead Engineering Solutions",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "© 2026 TechLead. All rights reserved.",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          "Version 2.0.1 | Admin Panel",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),

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
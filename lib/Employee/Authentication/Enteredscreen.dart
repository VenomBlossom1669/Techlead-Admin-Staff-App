import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techlead/Employee/Authentication/EnLoginPage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Admin/Authentication/Admin_login_repository/Admin_login_Screen.dart';

class Enteredscreen extends StatefulWidget {
  const Enteredscreen({super.key});

  @override
  State<Enteredscreen> createState() => _EnteredscreenState();
}

class _EnteredscreenState extends State<Enteredscreen> with TickerProviderStateMixin {
  late AnimationController _textController;
  late AnimationController _imageController;

  late Animation<double> _techleadAnimation;
  late Animation<double> _theAnimation;
  late Animation<double> _engineeringAnimation;
  late Animation<double> _solutionAnimation;
  late Animation<double> _flipAnimation;


  final List<Map<String, String>> _socialButtons = [
    {
      'asset': 'assets/images/globe.png',
      'label': 'Website',
      'url': 'https://techleadsolution.in/',
    },
    {
      'asset': 'assets/images/facebook.png',
      'label': 'Facebook',
      'url': 'https://www.facebook.com/techleadtheengineeringsolution/',
    },
    {
      'asset': 'assets/images/instagram.png',
      'label': 'Instagram',
      'url': 'https://www.instagram.com/techleadhomeautomation/',
    },
    {
      'asset': 'assets/images/linkedin.png',
      'label': 'LinkedIn',
      'url': 'https://in.linkedin.com/company/techlead-the-engineering-solutions',
    },
    {
      'asset': 'assets/images/youtubem.png',
      'label': 'YouTube',
      'url': 'https://www.youtube.com/@techleadautomation2120',
    },
  ];

  @override
  void initState() {
    super.initState();

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    _techleadAnimation = Tween(begin: -200.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _theAnimation = Tween(begin: 200.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _engineeringAnimation = Tween(begin: -200.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _solutionAnimation = Tween(begin: 200.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _imageController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _flipAnimation = Tween<double>(begin: 0.0, end: 3.1416).animate(
      CurvedAnimation(parent: _imageController, curve: Curves.easeInOut),
    );

    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_imageController.status == AnimationStatus.completed ||
          _imageController.status == AnimationStatus.dismissed) {
        _imageController.forward(from: 0.0);
      }
    });

  }

  @override
  void dispose() {
    _textController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Widget _buildCard(Widget content, VoidCallback onTap, double width, double height) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.all(10.0),
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
          borderRadius: BorderRadius.circular(30.0),
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.9),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;
    final double cardWidth = screenWidth * 0.4;
    final double cardHeight = screenWidth * 0.45;
    final double imageWidth = screenWidth * 0.3;
    final double imageHeight = screenWidth * 0.2;
    final double titleSize = isSmall ? 12 : 14;

    return Scaffold(
      body: SizedBox.expand(
        child: Container(
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
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Center(
                      child: Image.asset(
                        "assets/images/enteredscreen.png",
                        height: screenWidth * 0.4,
                        width: screenWidth * 0.8,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        childAspectRatio: 1,
                        children: [
                          _buildCard(
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  "assets/images/adminloginpic.png",
                                  height: imageHeight,
                                  width: imageWidth,
                                  fit: BoxFit.fitHeight,
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  "Admin Login",
                                  style: TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                                () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                              );
                            },
                            cardWidth,
                            cardHeight,
                          ),
                          _buildCard(
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  "assets/images/employeeloginpic.png",
                                  height: imageHeight,
                                  width: imageWidth,
                                  fit: BoxFit.fitHeight,
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  "Employee Login",
                                  style: TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                                () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => LoginPage()),
                              );
                            },
                            cardWidth,
                            cardHeight,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 70),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16.0,
                      runSpacing: 16.0,
                      children: _socialButtons.map((item) {
                        return SocialButton(
                          assetPath: item['asset']!,
                          label: item['label']!,
                          url: item['url']!,
                        );
                      }).toList(),
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

class SocialButton extends StatelessWidget {
  final String assetPath;
  final String label;
  final String url;

  const SocialButton({
    Key? key,
    required this.assetPath,
    required this.label,
    required this.url,
  }) : super(key: key);

  Future<void> _launchURL(BuildContext context) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $label')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _launchURL(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: ClipOval(
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

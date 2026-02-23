import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUs extends StatefulWidget {
  const ContactUs({super.key});

  @override
  State<ContactUs> createState() => _ContactUsState();
}

class _ContactUsState extends State<ContactUs>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _fadeInAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _responsiveFontSize(BuildContext context, double base) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return base * 1.8;
    if (width > 900) return base * 1.5;
    if (width > 600) return base * 1.2;
    return base;
  }

  EdgeInsets _responsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return const EdgeInsets.all(40);
    if (width > 900) return const EdgeInsets.all(32);
    if (width > 600) return const EdgeInsets.all(24);
    return const EdgeInsets.all(16);
  }

  double _getAppBarBottomHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (kIsWeb) {
      if (width > 1200) return 190;
      if (width > 900) return 180;
      if (width > 600) return 170;
      return 160;
    }
    return 160;
  }

  double _getContentTopPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 60;
    if (width > 900) return 55;
    if (width > 600) return 50;
    return 45;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: false,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_in_talk_rounded,
                color: Colors.white, size: _responsiveFontSize(context, 22)),
            const SizedBox(width: 8),
            Text(
              "Contact Us",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: _responsiveFontSize(context, 20),
                shadows: const [
                  Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 2,
                      color: Colors.black26),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF144E8C), Color(0xFF0A2540)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        // 🔹 FIXED BOTTOM (NO FIXED HEIGHT)
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Image.asset(
                    'assets/images/enteredscreen.png',
                    width: MediaQuery.of(context).size.width > 900 ? 120 : 90,
                    height: MediaQuery.of(context).size.width > 900 ? 120 : 90,
                    fit: BoxFit.contain,
                  ),
                ),
                const Divider(
                    color: Colors.white54, thickness: 1, indent: 20, endIndent: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    "We're here to assist you with all your inquiries",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: _responsiveFontSize(context, 14),
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    "Reach out to us for expert advice on Home automation solutions!",
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontSize: _responsiveFontSize(context, 16),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF144E8C), Color(0xFF0A2540)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: _responsivePadding(context),
            child: FadeTransition(
              opacity: _fadeInAnimation,
              child: Column(
                children: [
                  SizedBox(height: _getContentTopPadding(context)),

                  /// Layout builder for responsive structure
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 900) {
                        return _buildGridLayout(context);
                      } else {
                        return _buildStackedLayout(context);
                      }
                    },
                  ),

                  const Divider(color: Colors.white54, thickness: 1, height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "Ride the wave of the future with our trendsetting home automation services. Seamlessly integrate smart technology, stay ahead.",
                      style: GoogleFonts.openSans(
                        color: Colors.white,
                        fontSize: _responsiveFontSize(context, 16),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    "Follow Us on Social",
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: _responsiveFontSize(context, 20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 28,
                    runSpacing: 20,
                    children: const [
                      SocialButton(
                        assetPath: 'assets/images/facebook.png',
                        label: "Facebook",
                        url:
                        "https://www.facebook.com/techleadtheengineeringsolution/",
                      ),
                      SocialButton(
                        assetPath: 'assets/images/instagram.png',
                        label: "Instagram",
                        url:
                        "https://www.instagram.com/techleadhomeautomation/",
                      ),
                      SocialButton(
                        assetPath: 'assets/images/linkedin.png',
                        label: "LinkedIn",
                        url:
                        "https://in.linkedin.com/company/techlead-the-engineering-solutions",
                      ),
                      SocialButton(
                        assetPath: 'assets/images/youtubem.png',
                        label: "YouTube",
                        url: "https://www.youtube.com/@techleadautomation2120",
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 Grid Layout for large screens
  Widget _buildGridLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double cardWidth = (screenWidth / 2) - 80;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        SizedBox(
          width: cardWidth,
          child: ContactDetail(
            icon: Icons.location_on,
            title: "Address",
            detail:
            "A-303, S.G.Business Hub, Sarkhej - Gandhinagar Highway, Gota, Ahmedabad, Gujarat 380060",
            actionUrl:
            "https://www.google.com/maps/search/?api=1&query=A-303,+S.G.Business+Hub,+Sarkhej+-+Gandhinagar+Highway,+Gota,+Ahmedabad,+Gujarat+380060",
            fontSize: _responsiveFontSize(context, 15),
          ),
        ),
        SizedBox(
          width: cardWidth,
          child: ContactDetail(
            icon: Icons.email,
            title: "Email",
            detail: "info@techleadsolution.in",
            actionUrl: "mailto:info@techleadsolution.in",
            fontSize: _responsiveFontSize(context, 15),
          ),
        ),
        SizedBox(
          width: cardWidth,
          child: ContactDetail(
            icon: Icons.phone,
            title: "Phone",
            detail: "+91 9586 889988",
            actionUrl: "tel:+919586889988",
            fontSize: _responsiveFontSize(context, 15),
          ),
        ),
        SizedBox(
          width: cardWidth,
          child: ContactDetail(
            icon: Icons.language,
            title: "Website",
            detail: "https://techleadsolution.in",
            actionUrl: "https://techleadsolution.in",
            fontSize: _responsiveFontSize(context, 15),
          ),
        ),
      ],
    );
  }

  // 🔹 Stacked layout for small screens
  Widget _buildStackedLayout(BuildContext context) {
    return Column(
      children: [
        ContactDetail(
          icon: Icons.location_on,
          title: "Address",
          detail:
          "A-303, S.G.Business Hub, Sarkhej - Gandhinagar Highway, Gota, Ahmedabad, Gujarat 380060",
          actionUrl:
          "https://www.google.com/maps/search/?api=1&query=A-303,+S.G.Business+Hub,+Sarkhej+-+Gandhinagar+Highway,+Gota,+Ahmedabad,+Gujarat+380060",
          fontSize: _responsiveFontSize(context, 15),
        ),
        const SizedBox(height: 12),
        ContactDetail(
          icon: Icons.email,
          title: "Email",
          detail: "info@techleadsolution.in",
          actionUrl: "mailto:info@techleadsolution.in",
          fontSize: _responsiveFontSize(context, 15),
        ),
        const SizedBox(height: 12),
        ContactDetail(
          icon: Icons.phone,
          title: "Phone",
          detail: "+91 9586 889988",
          actionUrl: "tel:+919586889988",
          fontSize: _responsiveFontSize(context, 15),
        ),
        const SizedBox(height: 12),
        ContactDetail(
          icon: Icons.language,
          title: "Website",
          detail: "https://techleadsolution.in",
          actionUrl: "https://techleadsolution.in",
          fontSize: _responsiveFontSize(context, 15),
        ),
      ],
    );
  }
}

// 🔹 Contact Detail Card Widget
class ContactDetail extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final String? actionUrl;
  final double fontSize;

  const ContactDetail({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    this.actionUrl,
    required this.fontSize,
  });

  Future<void> _handleTap(BuildContext context) async {
    if (actionUrl != null) {
      final Uri uri = Uri.parse(actionUrl!);
      try {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Could not open $title'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Card(
        color: Colors.blue.shade900,
        elevation: 4,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF144E8C), Color(0xFF0A2540)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: fontSize + 6),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize)),
                    const SizedBox(height: 6),
                    Text(detail,
                        style: TextStyle(
                            color: Colors.white, fontSize: fontSize - 1),
                        softWrap: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🔹 Social Media Button
class SocialButton extends StatelessWidget {
  final String assetPath;
  final String label;
  final String url;

  const SocialButton({
    super.key,
    required this.assetPath,
    required this.label,
    required this.url,
  });

  Future<void> _launchURL(BuildContext context) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Could not open $label'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double size =
    kIsWeb ? (screenWidth > 900 ? 40 : 35) : (screenWidth > 600 ? 36 : 30);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _launchURL(context),
          child: Container(
            width: size * 2,
            height: size * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.85),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: ClipOval(
              child: Image.asset(assetPath, fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(
                color: Colors.white,
                fontSize: kIsWeb
                    ? (screenWidth > 900 ? 16 : 15)
                    : (screenWidth > 600 ? 15 : 14),
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

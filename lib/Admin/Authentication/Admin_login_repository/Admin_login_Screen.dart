import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techlead/Admin/Adminhomescreen.dart';
import 'login_controller.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({Key? key}) : super(key: key);

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _passwordVisible = false;
  bool _isLoading = false;

  Future<void> _refreshAndSaveFcmToken({
    required String userId,
    required bool isAdmin,
  }) async {
    try {
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        if (newToken.isEmpty) return;

        final collection = isAdmin ? 'Admin_Profiles' : 'EmpProfile';

        await FirebaseFirestore.instance
            .collection(collection)
            .doc(userId)
            .set({'fcmToken': newToken}, SetOptions(merge: true));

        print("✅ FCM token refreshed and saved in $collection: $newToken");
      });
    } catch (e) {
      print("❌ Error saving refreshed FCM token: $e");
    }
  }


  static Future<void> _generateAdminFcmToken(String adminId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('Admin_Profiles')
            .doc(adminId)
            .set({'fcmToken': token}, SetOptions(merge: true));
        print('✅ Admin FCM token saved: $token');
      }
    } catch (e) {
      print('❌ Error generating admin FCM token: $e');
    }
  }

  Future<void> _loginUser(String email, String password) async {
    setState(() => _isLoading = true); // 🔹 Start loading
    try {
      final docId = email.replaceAll('.', ','); // . → ,
      final snapshot = await FirebaseFirestore.instance
          .collection('Admin_Profiles')
          .doc(email)
          .get()
          .timeout(const Duration(seconds: 3), onTimeout: () {
        throw Exception("Network timeout, try again");
      });

      if (!snapshot.exists) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No account found with this email"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final data = snapshot.data()!;
      final storedPassword = data['password'] ?? '';

      if (storedPassword != password) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid password"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setBool('isAdmin', true);
      await prefs.setString('name', data['name'] ?? '');
      await prefs.setString('id', data['id'] ?? '');
      await prefs.setString('email', email);

      await _generateAdminFcmToken(email);

      await _refreshAndSaveFcmToken(userId: email, isAdmin: true);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminHomeScreeen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error during login: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false); // 🔹 Stop loading
    }
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      _loginUser(email, password);
    }
  }

  InputDecoration _fieldDecoration({
    required String hint,
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      prefixIcon: prefix,
      suffixIcon: suffix,
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF7A7A7A)),
      filled: true,
      fillColor: const Color(0xFF161616),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7B61FF)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0F),

      // 🔹 Back button on AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top star + line
                  const Center(
                    child:
                        Icon(Icons.lock_outline, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      "LOGIN TO ADMIN\nYOUR ACCOUNT",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: const  Text(
                      "Enter your login information",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 26),

                  // Email label
                  const Text(
                    "Email",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Email field
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.08),
                          Colors.white.withOpacity(0.03),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      cursorColor: Colors.blueAccent,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          FocusScope.of(context).nextFocus(),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: "Enter your email",
                        hintStyle: const TextStyle(
                            color: Colors.white54, fontSize: 14),
                        prefixIcon: const Icon(Icons.alternate_email,
                            color: Color(0xFFCFCFCF)),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 18),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.28),
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: Colors.blueAccent.shade100,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                              color: Colors.redAccent, width: 1.5),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                              color: Colors.redAccent, width: 1.8),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "Please enter email"
                          : null,
                    ),
                  ),

                  // Password label
                  const Text(
                    "Password",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Password field
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.08),
                          Colors.white.withOpacity(0.03),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: !_passwordVisible,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          FocusScope.of(context).nextFocus(),
                      cursorColor: Colors.blueAccent,
                      decoration: InputDecoration(
                        hintText: "••••••••",
                        hintStyle: const TextStyle(
                            color: Colors.white54, fontSize: 14),
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: Color(0xFFCFCFCF)),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                              () => _passwordVisible = !_passwordVisible),
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: const Color(0xFFCFCFCF),
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 18),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.28),
                              width: 1.2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                              color: Colors.blueAccent.shade100, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                              color: Colors.redAccent, width: 1.5),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                              color: Colors.redAccent, width: 1.8),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? "Please enter password"
                          : null,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : _handleLogin, // disable when loading
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D5BFF),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2D5BFF).withOpacity(0.45),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                              spreadRadius: -4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  "Log In",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Lavish bottom panel
                  _lavishBottomPanel(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _lavishBottomPanel() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B1F3B), Color(0xFF0D0D1A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Brand Divider Accent
          Container(
            height: 4,
            width: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: const LinearGradient(
                colors: [Color(0xFF2D5BFF), Color(0xFF00C9FF)],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Company tagline
          const Text(
            "TechLead – The Engineering Solutions",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: 0.8,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          // About / Mission
          const Text(
            "Smart Home • Automation • Engineering\n"
                "Innovating comfort & security for modern living.",
            style: TextStyle(
              color: Color(0xFFC9C9C9),
              fontSize: 13,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Feature Chips
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              _chip("🏠 Smart Homes"),
              _chip("⚡ Energy Efficiency"),
              _chip("🔒 Secure Living"),
              _chip("🤝 Professional Support"),
            ],
          ),
        ],
      ),
    );
  }
  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF845EC2), Color(0xFF2A1B4A)],
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techlead/Employee/Homescreen/EmpHomescreen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

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

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid Gmail address';
    return null;
  }

  String? _validatePassword(String? v) {
    v = v?.trim();
    if (v == null || v.isEmpty) return 'Confirm your password';
    return (v != _passwordController.text.trim())
        ? 'Passwords do not match'
        : null;
  }

  void _showToast(String message, Color bgColor) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: bgColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user == null) {
        _showToast("Login failed. Please try again!", Colors.red);
        return;
      }

      await user.reload();
      user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        await FirebaseAuth.instance.signOut();
        _showToast("Your account has been deleted by Admin.", Colors.red);
        return;
      }

      DocumentSnapshot profileDoc = await FirebaseFirestore.instance
          .collection('EmpProfile')
          .doc(user.uid)
          .get();

      bool hasProfile = profileDoc.exists &&
          (profileDoc.data() as Map?)?.containsKey('fullName') == true;

      await _refreshAndSaveFcmToken(
        userId: user.uid,
        isAdmin: false,
      );

      _showToast("Login successful!", Colors.green);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            initialIndex: hasProfile ? 0 : 4,
          ),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _errorMessage = "Your account has been deleted by Admin.";
      } else if (e.code == 'wrong-password') {
        _errorMessage = "Incorrect password. Please try again!";
      } else {
        _errorMessage = "Username and password do not match. Please try again!";
      }
      _showToast(_errorMessage!, Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void showLavishToast(BuildContext context, String message,
      {bool success = true}) {
    final color =
        success ? Colors.greenAccent.shade400 : Colors.redAccent.shade400;
    final icon = success ? Icons.check_circle : Icons.error;

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 80,
        left: 20,
        right: 20,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 30),
                child: child,
              ),
            );
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.95),
                    success
                        ? Colors.tealAccent.shade400.withOpacity(0.8)
                        : Colors.deepOrangeAccent.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.6),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.2),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.8),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        shadows: [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 4,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3)).then((_) {
      overlayEntry.remove();
    });
  }

  Widget _entryField(
    String hintText, {
    bool isPassword = false,
    TextEditingController? controller,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10), // ✅ Reduced from 12
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
        controller: controller,
        validator: validator,
        obscureText: isPassword && !_isPasswordVisible,
        keyboardType: isPassword
            ? TextInputType.visiblePassword
            : TextInputType.emailAddress,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        textInputAction: TextInputAction.next,
        onEditingComplete: () => FocusScope.of(context).nextFocus(),
        cursorColor: Colors.blueAccent,
        decoration: InputDecoration(
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelText: hintText,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: Colors.transparent,
          prefixIcon: Icon(
            isPassword ? Icons.lock_outline : Icons.email_outlined,
            color: Colors.blueAccent.shade100,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )
              : null,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.3),
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
              color: Colors.redAccent,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: Colors.redAccent,
              width: 1.8,
            ),
          ),
          hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 16), // ✅ Reduced from 18
        ),
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50, // ✅ Reduced from 52
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D5BFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _handleLogin,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "LOGIN",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _lavishBottomPanel() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16), // ✅ Reduced from 24
      padding: const EdgeInsets.all(16), // ✅ Reduced from 20
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
        mainAxisSize: MainAxisSize.min, // ✅ Important!
        children: [
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
          const SizedBox(height: 12), // ✅ Reduced from 14

          const Text(
            "TechLead – The Engineering Solutions",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15, // ✅ Reduced from 16
              letterSpacing: 0.8,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8), // ✅ Reduced from 10

          const Text(
            "Smart Home • Automation • Engineering\n"
            "Innovating comfort & security for modern living.",
            style: TextStyle(
              color: Color(0xFFC9C9C9),
              fontSize: 12, // ✅ Reduced from 13
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12), // ✅ Reduced from 16

          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8, // ✅ Reduced from 10
            runSpacing: 6, // ✅ Reduced from 8
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
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // ✅ Reduced
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
          fontSize: 11, // ✅ Added font size
        ),
      ),
    );
  }

  Widget _title() {
    return Column(
      mainAxisSize: MainAxisSize.min, // ✅ Important!
      children: const [
        SizedBox(height: 10), // ✅ Reduced from 20
        Icon(Icons.lock_outline,
            size: 50, color: Colors.white), // ✅ Reduced from 60
        SizedBox(height: 8), // ✅ Reduced from 10
        Text(
          "LOGIN TO EMPLOYEE\nYOUR ACCOUNT",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22, // ✅ Reduced from 24
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 6), // ✅ Reduced from 10
        Text(
          "Enter your login information",
          style:
              TextStyle(fontSize: 13, color: Colors.grey), // ✅ Reduced from 14
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.06,
                    vertical: height * 0.02, // ✅ Reduced from 0.03
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // ✅ Critical fix!
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Back Button
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios,
                              color: Colors.white,
                              size: 24), // ✅ Reduced from 28
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),

                      SizedBox(height: height * 0.02), // ✅ Reduced from 0.03

                      _title(),
                      SizedBox(height: height * 0.03), // ✅ Reduced from 0.05

                      // Form Fields
                      Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // ✅ Important!
                          children: [
                            _entryField(
                              "Email",
                              controller: _emailController,
                              validator: _validateEmail,
                            ),
                            _entryField(
                              "Password",
                              isPassword: true,
                              controller: _passwordController,
                              validator: _validatePassword,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: height * 0.03), // ✅ Reduced from 0.04

                      _submitButton(),

                      SizedBox(height: height * 0.02), // ✅ Added spacing

                      _lavishBottomPanel(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

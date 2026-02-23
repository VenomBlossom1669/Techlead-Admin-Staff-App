import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techlead/Admin/Adminhomescreen.dart';

import '../../Loginui/beizercontainer.dart';
import '../../Loginui/beizercontainerbottom.dart';
import '../../Loginui/beizercontainerleft.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isVerified = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

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

  Future<void> _verifyEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Empauth')
          .where('email', isEqualTo: _emailController.text.trim())
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() => _isVerified = true);
        _showToast(
            "Email verified! Please enter a new password.", Colors.green);
      } else {
        _showToast("Email not found Please try again.",
            Colors.red);
      }
    } catch (e) {
      _showToast("Error: ${e.toString()}", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Check user in Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('Empauth')
          .where('email', isEqualTo: _emailController.text.trim())
          .get();

      if (snapshot.docs.isEmpty) {
        _showToast("Email not found in Empauth collection.", Colors.red);
        return;
      }

      final userDoc = snapshot.docs.first;
      final docId = userDoc.id;

      // 2. Re-authenticate user with old password (needed for password update in Firebase)
      final oldPassword = userDoc['password'];
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: oldPassword,
      );

      // 3. Update password in FirebaseAuth
      await userCredential.user!
          .updatePassword(_newPasswordController.text.trim());

      // 4. Update password in Firestore
      await FirebaseFirestore.instance
          .collection('Empauth')
          .doc(docId)
          .update({'password': _newPasswordController.text.trim()});

      // 5. Update SharedPreferences (optional)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('password', _newPasswordController.text.trim());

      // 6. Sign out after reset
      await FirebaseAuth.instance.signOut();

      _showToast("Password reset successful!", Colors.green);

      _formKey.currentState!.reset();
      _emailController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      Navigator.pop(context); // back to login screen
    } on FirebaseAuthException catch (e) {
      _showToast(e.message ?? "Password reset failed", Colors.red);
    } catch (e) {
      _showToast("Error: ${e.toString()}", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    bool obscureText = false,
    VoidCallback? toggleVisibility,
    bool readOnly = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 5,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            label == 'Email' ? Icons.email : Icons.lock,
            color: Colors.blue.shade900,
          ),
          suffixIcon: (label == 'New Password' || label == 'Confirm Password')
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility : Icons.visibility_off,
                    color: Colors.pink,
                  ),
                  onPressed: toggleVisibility,
                )
              : null,
          border: OutlineInputBorder(borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.blue.withOpacity(0.1),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.symmetric(vertical: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.blue.shade800, Colors.blue.shade900],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade200,
              blurRadius: 5,
              offset: const Offset(2, 4),
              spreadRadius: 2,
            ),
          ],
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                label,
                style: const TextStyle(fontSize: 20, color: Colors.white),
              ),
      ),
    );
  }

  Widget _backButton() {
    return InkWell(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: const [
            Padding(
              padding: EdgeInsets.only(left: 0, top: 10, bottom: 10),
              child: Icon(Icons.keyboard_arrow_left, color: Colors.white),
            ),
            Text('Back',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white))
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0F2027), // Deep Blue-Grey
              Color(0xFF203A43), // Dark Blue
              Color(0xFF2C5364), // Rich Blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                             Text(
                              'Forgot Password',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900),
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              label: 'Email',
                              controller: _emailController,
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'Email is required';
                                if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(value)) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                              readOnly: _isVerified,
                            ),
                            if (_isVerified) ...[
                              _buildTextField(
                                label: 'New Password',
                                controller: _newPasswordController,
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Password is required';
                                  if (!RegExp(
                                          r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$')
                                      .hasMatch(value)) {
                                    return 'Password must contain letters, numbers, and symbols';
                                  }
                                  return null;
                                },
                                obscureText: !_showNewPassword,
                                toggleVisibility: () => setState(
                                    () => _showNewPassword = !_showNewPassword),
                              ),
                              _buildTextField(
                                label: 'Confirm Password',
                                controller: _confirmPasswordController,
                                validator: (value) {
                                  if (value != _newPasswordController.text)
                                    return 'Passwords do not match';
                                  return null;
                                },
                                obscureText: !_showConfirmPassword,
                                toggleVisibility: () => setState(() =>
                                    _showConfirmPassword =
                                        !_showConfirmPassword),
                              ),
                            ],
                            const SizedBox(height: 30),
                            _buildButton(
                              label: _isVerified
                                  ? 'Reset Password'
                                  : 'Verify Email',
                              onTap:
                                  _isVerified ? _resetPassword : _verifyEmail,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(top: 40, left: 0, child: _backButton()),
          ],
        ),
      ),
    );
  }
}

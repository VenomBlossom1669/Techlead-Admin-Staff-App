  import 'package:flutter/material.dart';
  import 'package:fluttertoast/fluttertoast.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:techlead/Admin/Adminhomescreen.dart';
  
  class SignUpPage2 extends StatefulWidget {
    const SignUpPage2({Key? key}) : super(key: key);
  
    @override
    State<SignUpPage2> createState() => _SignUpPage2State();
  }
  
  class _SignUpPage2State extends State<SignUpPage2> {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _usernameController = TextEditingController();
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();
    final TextEditingController _confirmPasswordController =
    TextEditingController();
  
    final _usernameFocus = FocusNode();
    final _emailFocus = FocusNode();
    final _passwordFocus = FocusNode();
    final _confirmPasswordFocus = FocusNode();
  
    bool _isLoading = false;
    bool _passwordVisible = false;
    bool _confirmPasswordVisible = false;
  
    @override
    void dispose() {
      _usernameController.dispose();
      _emailController.dispose();
      _passwordController.dispose();
      _confirmPasswordController.dispose();
  
      _usernameFocus.dispose();
      _emailFocus.dispose();
      _passwordFocus.dispose();
      _confirmPasswordFocus.dispose();
  
      super.dispose();
    }
  
  
    // ========= VALIDATORS =========
    String? _validateUsername(String? v) =>
        (v == null || v.isEmpty) ? 'Please enter username' : null;
  
    String? _validateEmail(String? v) {
      if (v == null || v.isEmpty) return 'Please enter email';
      final emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      return (!emailRegex.hasMatch(v)) ? 'Enter valid email' : null;
    }
  
    String? _validatePassword(String? value) {
      if (value == null || value.isEmpty) {
        return 'Please enter your password';
      }
      final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
      if (!passwordRegex.hasMatch(value)) {
        return 'Password must be at least 8 characters,\ninclude upper and lower case letters,\n1 number and 1 special character';
      }
      return null;
    }
  
  
    String? _validateConfirmPassword(String? v) {
      if (v == null || v.isEmpty) return 'Confirm your password';
      return (v != _passwordController.text) ? 'Passwords do not match' : null;
    }
  
    void _showToast(String msg, Color color) {
      Fluttertoast.showToast(
          msg: msg,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: color,
          textColor: Colors.white);
    }
    Future<void> _handleSignUp() async {
      if (!_formKey.currentState!.validate()) return;

      setState(() => _isLoading = true);

      try {
        final username = _usernameController.text.trim();
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        // 🔹 Check if user already exists
        final querySnapshot = await FirebaseFirestore.instance
            .collection('Empauth')
            .where('email', isEqualTo: email)
            .get();

        final usernameSnapshot = await FirebaseFirestore.instance
            .collection('Empauth')
            .where('username', isEqualTo: username)
            .get();

        if (querySnapshot.docs.isNotEmpty || usernameSnapshot.docs.isNotEmpty) {
          _showToast("Employee already exists", Colors.orange);
          setState(() => _isLoading = false);
          return;
        }

        // 🔹 Create user in Firebase Auth
        final UserCredential credential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // 🔹 Add user to Firestore
        await FirebaseFirestore.instance
            .collection('Empauth')
            .doc(credential.user!.uid)
            .set({
          'username': username,
          'email': email,
          'password': password,
          'uid': credential.user!.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        _showToast("Registration successful!", Colors.green);

        // 🔹 Clear fields
        _usernameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminHomeScreeen()),
        );

      } on FirebaseAuthException catch (e) {
        _showToast(e.message ?? "Registration failed", Colors.red);
      } catch (e) {
        _showToast("Error: ${e.toString()}", Colors.red);
      } finally {
        setState(() => _isLoading = false);
      }
    }


    Widget _buildTextField({
      required String label,
      required TextEditingController controller,
      required IconData icon,
      FocusNode? focusNode,
      FocusNode? nextFocus,
      String? Function(String?)? validator,
      bool isPassword = false,
      bool isConfirmPassword = false,
    }) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.withOpacity(0.08),
                  Colors.pinkAccent.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: nextFocus != null
                  ? TextInputAction.next
                  : TextInputAction.done,
              onFieldSubmitted: (_) {
                if (nextFocus != null) {
                  FocusScope.of(context).requestFocus(nextFocus);
                } else {
                  FocusScope.of(context).unfocus();
                }
              },
              obscureText: isPassword
                  ? !_passwordVisible
                  : isConfirmPassword
                  ? !_confirmPasswordVisible
                  : false,
              validator: validator,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                contentPadding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                labelText: label,
                labelStyle: TextStyle(
                  color: Colors.deepPurple.shade700,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.only(left: 10, right: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Colors.deepPurple, Colors.pinkAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                suffixIcon: isPassword
                    ? IconButton(
                  icon: Icon(
                    _passwordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.deepPurple,
                  ),
                  onPressed: () =>
                      setState(() => _passwordVisible = !_passwordVisible),
                )
                    : isConfirmPassword
                    ? IconButton(
                  icon: Icon(
                    _confirmPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.deepPurple,
                  ),
                  onPressed: () => setState(() =>
                  _confirmPasswordVisible = !_confirmPasswordVisible),
                )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.9),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: Colors.deepPurple.shade200,
                    width: 1.2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    width: 2.5,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
  
    Widget _submitButton() {
      return GestureDetector(
        onTap: _handleSignUp,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00C9FF), Color(0xFF6A11CB)],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
            ],
          ),
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Register Now",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      );
    }
  
    Widget _title() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Center(
            child: Text("Welcome",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ),
          SizedBox(height: 6),
          Text("Create Your Account",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
        ],
      );
    }
  
    Widget _backgroundShapes(double height, double width) {
      return Stack(
        children: [
          // top wave
          Positioned(
            top: 0,
            child: ClipPath(
              clipper: TopWaveClipper(),
              child: Container(
                height: height * 0.35,
                width: width,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          // bottom curve
          Positioned(
            bottom: 0,
            child: ClipPath(
              clipper: BottomWaveClipper(),
              child: Container(
                height: height * 0.25,
                width: width,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFC466B), Color(0xFF3F5EFB)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    @override
    Widget build(BuildContext context) {
      final height = MediaQuery.of(context).size.height;
      final width = MediaQuery.of(context).size.width;
  
      return Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            /// ✅ 1. Background decoration - Ignore pointer events
            IgnorePointer(child: _backgroundShapes(height, width)),
  
            /// ✅ 2. Scrollable main content - Centered
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 80),
                    _title(),
                    const SizedBox(height: 30),
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 12,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTextField(
                              label: "Username",
                              controller: _usernameController,
                              icon: Icons.person,
                              validator: _validateUsername,
                              focusNode: _usernameFocus,
                              nextFocus: _emailFocus,
                            ),
  
                            _buildTextField(
                              label: "Email",
                              controller: _emailController,
                              icon: Icons.email,
                              validator: _validateEmail,
                              focusNode: _emailFocus,
                              nextFocus: _passwordFocus,
                            ),
  
                            _buildTextField(
                              label: "Password",
                              controller: _passwordController,
                              icon: Icons.lock,
                              isPassword: true,
                              validator: _validatePassword,
                              focusNode: _passwordFocus,
                              nextFocus: _confirmPasswordFocus,
                            ),
  
                            _buildTextField(
                              label: "Confirm Password",
                              controller: _confirmPasswordController,
                              icon: Icons.lock_outline,
                              isConfirmPassword: true,
                              validator: _validateConfirmPassword,
                              focusNode: _confirmPasswordFocus,
                            ),
  
                            const SizedBox(height: 20),
                            _submitButton(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
  
            /// ✅ 3. Back Button - Always on top and interactable
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 10, top: 10),
                child: IconButton(
                  icon:
                  const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      );
  
    }
  
  
  }
  
  // ======= CUSTOM CLIPPERS =======
  class TopWaveClipper extends CustomClipper<Path> {
    @override
    Path getClip(Size size) {
      Path path = Path();
      path.lineTo(0, size.height - 60);
      path.quadraticBezierTo(
          size.width / 2, size.height, size.width, size.height - 60);
      path.lineTo(size.width, 0);
      path.close();
      return path;
    }
  
    @override
    bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
  }
  
  class BottomWaveClipper extends CustomClipper<Path> {
    @override
    Path getClip(Size size) {
      Path path = Path();
      path.moveTo(0, 60);
      path.quadraticBezierTo(size.width / 2, 0, size.width, 60);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      return path;
    }
  
    @override
    bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
  }
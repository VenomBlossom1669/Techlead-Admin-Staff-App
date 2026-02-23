import 'package:flutter/material.dart';
import 'login_controller.dart';

class LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoginAttempted;
  final bool passwordVisible;
  final VoidCallback onTogglePasswordVisibility;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isLoginAttempted,
    required this.passwordVisible,
    required this.onTogglePasswordVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: isLoginAttempted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        children: [
          _buildTextField(
            context: context,
            label: 'Username',
            hint: 'Enter Your Email Address',
            controller: emailController,
            icon: Icons.person_outline,
            validator: LoginController.validateEmail,
            keyboardType: TextInputType.emailAddress, // 👈 email keyboard type
          ),
          const SizedBox(height: 20),
          _buildTextField(
            context: context,
            label: 'Password',
            hint: 'Enter Password',
            controller: passwordController,
            icon: Icons.lock_outline,
            obscureText: !passwordVisible,
            keyboardType: TextInputType.visiblePassword,
            // 👈 password keyboard type
            suffixIcon: IconButton(
              icon: Icon(
                passwordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.white,
              ),
              onPressed: onTogglePasswordVisibility,
            ),
            validator: LoginController.validatePassword,
          ),

        ],
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      textInputAction: TextInputAction.next,
      onEditingComplete: () => FocusScope.of(context).nextFocus(),
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType ?? TextInputType.text,
      // 👈 apply type if provided
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.white),
        suffixIcon: suffixIcon,
        labelStyle: const TextStyle(color: Colors.white),
        hintStyle: const TextStyle(color: Colors.white54),

        // ✅ Borders for all states
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 1.5),
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.cyanAccent),
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.deepOrangeAccent, width: 1.5),
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        errorStyle: const TextStyle(color: Colors.cyanAccent),
      ),
    );
  }
}

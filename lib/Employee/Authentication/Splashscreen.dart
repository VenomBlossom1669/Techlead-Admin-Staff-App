import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../Homescreen/EmpHomescreen.dart';
import 'Enteredscreen.dart';
import '../../Admin/Adminhomescreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _opacity = 1.0;
      });
    });

    Timer(const Duration(seconds: 3), () => checkingTheSavedData(context));
  }

  void checkingTheSavedData(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    User? user = FirebaseAuth.instance.currentUser;

    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AdminHomeScreeen()),
      );
    } else if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Enteredscreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/images/28.gif',
              fit: BoxFit.cover,
            ),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 50),
              child: Image.asset(
                'assets/images/enteredscreen.png',
                height: 150,
                fit: BoxFit.fill,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:techlead/Employee/Categoryscreen/HR/Hrdailytaskreport.dart';
import 'package:techlead/Widgeets/custom_app_bar.dart';
import 'package:techlead/core/app_bar_provider.dart';
import 'package:techlead/Employee/Categoryscreen/A_Shining_Cooper_Animation/shining_cooper.dart';
import 'package:techlead/Employee/Categoryscreen/All_Home_Screen_Card_Ui/All_Home_Screen_Card_Ui.dart';
import 'hrreceivedscreen.dart';

class Hrhomescreen extends ConsumerStatefulWidget {
  const Hrhomescreen({super.key});

  @override
  ConsumerState<Hrhomescreen> createState() => _HrhomescreenState();
}

class _HrhomescreenState extends ConsumerState<Hrhomescreen> {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(appBarTitleProvider.notifier).state = "HR Task Section";
      ref.read(appBarGradientColorsProvider.notifier).state = [
        const Color(0xFF1E3C72),
        const Color(0xFF2A5298),
        const Color(0xFF002147),
      ];
      ref.read(customTitleWidgetProvider.notifier).state = null;
    });
  }

  @override
  void dispose() {

    Future.microtask(() {
      if (mounted) {
        resetAppBar(ref);
      }
    });
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Welcome Banner
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF004FF9),
                          Color(0xFF000000),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.white),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Welcome back! Stay organized and productive today.",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                ShiningCardWrapper(
                  child: MenuCard(
                    color: Colors.blue.shade900,
                    icon: Icons.assignment,
                    label: "Admin Task Report",
                    height: 160,
                    width: 400,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                      bottomRight: Radius.circular(10),
                      topLeft: Radius.circular(10),
                    ),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF004FF9),
                        Color(0xFF000000),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => Hrreceiveddata()),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                ShiningCardWrapper(
                  child: MenuCard(
                    color: Colors.green.shade800,
                    icon: Icons.report,
                    label: "Show Daily-Task",
                    height: 160,
                    width: 400,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(10),
                      topLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                      bottomLeft: Radius.circular(10),
                    ),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF004FF9),
                        Color(0xFF000000),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => Hrdailytaskreport()),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

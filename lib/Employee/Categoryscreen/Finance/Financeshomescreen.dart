import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:techlead/Employee/Categoryscreen/Finance/Financedailytaskreport.dart';
import 'package:techlead/Widgeets/custom_app_bar.dart';
import 'package:techlead/core/app_bar_provider.dart';
import 'package:techlead/Employee/Categoryscreen/A_Shining_Cooper_Animation/shining_cooper.dart';
import 'package:techlead/Employee/Categoryscreen/All_Home_Screen_Card_Ui/All_Home_Screen_Card_Ui.dart';
import 'Financeshowdata.dart';

class Financeshomescreen extends ConsumerStatefulWidget {
  const Financeshomescreen({super.key});

  @override
  ConsumerState<Financeshomescreen> createState() => _FinanceshomescreenState();
}

class _FinanceshomescreenState extends ConsumerState<Financeshomescreen> {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(appBarTitleProvider.notifier).state = "Finance Task Section";
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
                // Welcome Banner (same style)
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
                      MaterialPageRoute(builder: (_) => Financeshowdata()),
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
                      MaterialPageRoute(
                          builder: (_) => Financedailytaskreport()),
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

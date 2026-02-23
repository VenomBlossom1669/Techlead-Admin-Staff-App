import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:techlead/Employee/Categoryscreen/Sales/Showsalesleaddata.dart';
import 'package:techlead/Employee/Categoryscreen/Sales/salespage.dart';
import 'package:techlead/Employee/Categoryscreen/Sales/Receivesaleshdata.dart';
import 'package:techlead/Employee/Categoryscreen/Sales/Salesdailytaskreport.dart';
import 'package:techlead/Widgeets/custom_app_bar.dart';
import '../../../core/app_bar_provider.dart';
import '../All_Home_Screen_Card_Ui/All_Home_Screen_Card_Ui.dart';
import '../A_Shining_Cooper_Animation/shining_cooper.dart';

class Saleshomescreen extends ConsumerStatefulWidget {
  const Saleshomescreen({super.key});

  @override
  ConsumerState<Saleshomescreen> createState() => _SaleshomescreenState();
}

class _SaleshomescreenState extends ConsumerState<Saleshomescreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(appBarTitleProvider.notifier).state = "Sales Task Section";
      ref.read(appBarGradientColorsProvider.notifier).state = [
        const Color(0xFF1E3C72),
        const Color(0xFF2A5298),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Welcome Banner
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
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
                    children: const [
                      Icon(Icons.info_outline, color: Colors.white),
                      SizedBox(width: 10),
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

              const SizedBox(height: 20),

              // Sales Lead
              ShiningCardWrapper(
                child: MenuCard(
                  icon: Icons.assignment,
                  label: "Sales Lead",
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
                    MaterialPageRoute(builder: (_) => SalesPage()),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Sales Report
              ShiningCardWrapper(
                child: MenuCard(
                  icon: Icons.report,
                  label: "Sales Admin Report",
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
                    MaterialPageRoute(builder: (_) => Receivesalesdata()),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Daily Sales Task
              ShiningCardWrapper(
                child: MenuCard(
                  icon: Icons.task,
                  label: "Sales Daily-Task",
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
                    MaterialPageRoute(builder: (_) => DailyReportRecordOfSales()),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              ShiningCardWrapper(
                child: MenuCard(
                  icon: Icons.report,
                  label: "Sales Report",
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
                    MaterialPageRoute(builder: (_) => Showsalesleaddata()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

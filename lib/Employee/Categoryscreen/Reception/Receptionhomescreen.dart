import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:techlead/Employee/Categoryscreen/Reception/Receptionlistdailytaskreport.dart';
import 'package:techlead/Admin/Meetingmanagement/reception.dart';
import 'package:techlead/Admin/Meetingsection/showreceptiondata.dart';
import 'package:techlead/Widgeets/custom_app_bar.dart';
import '../../../core/app_bar_provider.dart';
import '../A_Shining_Cooper_Animation/shining_cooper.dart';
import '../All_Home_Screen_Card_Ui/All_Home_Screen_Card_Ui.dart';
import 'Receptionpage.dart';
import 'Receptionreport.dart';
import 'Receptionshowdata.dart';

class Receptionhomescreen extends ConsumerStatefulWidget {
  const Receptionhomescreen({super.key});

  @override
  ConsumerState<Receptionhomescreen> createState() => _ReceptionhomescreenState();
}

class _ReceptionhomescreenState extends ConsumerState<Receptionhomescreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(appBarTitleProvider.notifier).state = "Reception Task Section";
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
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
                      children: [
                        const Icon(Icons.info_outline, color: Colors.white),
                        const SizedBox(width: 10),
                        const Expanded(
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
                // Admin Report
                ShiningCardWrapper(
                  child: MenuCard(
                    icon: Icons.admin_panel_settings_sharp,
                    label: "Admin Task Report",
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
                      MaterialPageRoute(builder: (_) => Receptionshowdata()),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Meeting Assign
                ShiningCardWrapper(
                  child: MenuCard(
                    icon: Icons.assignment,
                    label: "Meeting Assign",
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
                      MaterialPageRoute(builder: (_) => Receptionpage()),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Meeting Report
                ShiningCardWrapper(
                  child: MenuCard(
                    icon: Icons.report,
                    label: "Meeting Report",
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
                      MaterialPageRoute(builder: (_) => Receptionreport()),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                ShiningCardWrapper(
                  child: MenuCard(
                    icon: Icons.task,
                    label: "Reception Daily-Task",
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
                      MaterialPageRoute(builder: (_) => DailyReportRecordOfReception()),
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

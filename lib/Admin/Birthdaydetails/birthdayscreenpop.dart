import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class BirthdayScreenPop extends StatefulWidget {
  final String employeeName;
  final DateTime birthDate;

  const BirthdayScreenPop({
    super.key,
    required this.employeeName,
    required this.birthDate,
  });

  @override
  _BirthdayScreenPopState createState() => _BirthdayScreenPopState();
}

class _BirthdayScreenPopState extends State<BirthdayScreenPop> {
  final ScreenshotController screenshotController = ScreenshotController();
  bool _hideButtons = false;

  void shareContent(BuildContext context) async {
    setState(() {
      _hideButtons = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    final String message =
        "🎉 Happy Birthday, ${widget.employeeName}! 🎂\n\n"
        "Today is a special day because it's your Birthday! We wish you all the happiness and success in the world. 🎉\n\n"
        "With love and warm wishes, \nTechlead - The Engineering Solution 💼";

    final Uint8List? capturedImage = await screenshotController.capture();
    setState(() {
      _hideButtons = false;
    });

    if (capturedImage != null) {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/birthday_wish.png';
      final file = File(filePath);
      await file.writeAsBytes(capturedImage);
      Share.shareXFiles([XFile(filePath)], text: message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('dd MMMM yyyy').format(widget.birthDate);

    return Scaffold(
      body: Screenshot(
        controller: screenshotController,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.shade800,
                Colors.pink.shade400,
                Colors.orange.shade300,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SingleChildScrollView(
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    width: MediaQuery.of(context).size.width * 0.9,
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B5998).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Text(
                      "Happy Birthday, ${widget.employeeName}!",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Cursive',
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 350,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.pink.withOpacity(0.5),
                              Colors.orange.withOpacity(0.3),
                              Colors.transparent,
                            ],
                            stops: const [0.4, 0.7, 1.0],
                          ),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.asset(
                          'assets/images/bcake.png',
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B5998).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      "🎂 Birth Date: $formattedDate 🎂",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: const [
                        Text(
                          "Today is a special day because it's your Birthday! "
                              "We wish you all the happiness and success in the world. 🎉",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          "With love and warm wishes,\nTechlead - The Engineering Solution 💼",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.yellowAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (!_hideButtons)
                    ElevatedButton(
                      onPressed: () => shareContent(context),
                      child: const Text(
                        'Share Birthday Wishes',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Times New Roman",
                          fontSize: 18,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

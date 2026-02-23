import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ServicePageList extends StatefulWidget {
  const ServicePageList({super.key});

  @override
  State<ServicePageList> createState() => _ServicePageListState();
}

class _ServicePageListState extends State<ServicePageList> {
  final Map<String, Map<String, IconData>> categorizedProducts = {
    'Residential': {
      'Smart Lights': FontAwesomeIcons.lightbulb,
      'Smart Thermostat': FontAwesomeIcons.thermometerHalf,
      'Security Cameras': FontAwesomeIcons.video,
      'Smart Plugs': FontAwesomeIcons.plug,
      'Smart Door Locks': FontAwesomeIcons.lock,
      'Smart Smoke Detectors': FontAwesomeIcons.cloud,
      'Smart Speakers': FontAwesomeIcons.volumeUp,
      'Smart Blinds': FontAwesomeIcons.windowMaximize,
      'Smart Doorbells': FontAwesomeIcons.bell,
      'Motion Sensors': FontAwesomeIcons.walking,
      'Smart Cameras': FontAwesomeIcons.camera,
      'Smart Switches': FontAwesomeIcons.toggleOn,
      'Smart Air Purifiers': FontAwesomeIcons.wind,
      'Smart Fans': FontAwesomeIcons.fan,
      'Smart Heaters': FontAwesomeIcons.fire,
      'Smart Humidifiers': FontAwesomeIcons.cloudRain,
      'Smart Refrigerators': FontAwesomeIcons.iceCream,
      'Smart Washing Machines': FontAwesomeIcons.soap,
      'Smart Dishwashers': FontAwesomeIcons.handsWash,
      'Smart Coffee Makers': FontAwesomeIcons.mugHot,
      'Smart Projectors': FontAwesomeIcons.projectDiagram,
      'Smart Remotes': FontAwesomeIcons.contao,
      'Smart Hubs': FontAwesomeIcons.networkWired,
      'Smart Batteries': FontAwesomeIcons.batteryFull,
      'Smart Chargers': FontAwesomeIcons.chargingStation,
      'Smart Curtains': FontAwesomeIcons.windowRestore,
      'Robotic Vacuums': FontAwesomeIcons.robot,
      'Smart Window Openers': FontAwesomeIcons.windowMaximize,
      'Smart Home Automation Hubs': FontAwesomeIcons.home,
      'Smart Light Panels': FontAwesomeIcons.lightbulb,
      'LED Strips': FontAwesomeIcons.ribbon,
      'Smart Home Assistants': FontAwesomeIcons.headset,
      'Voice Assistants': FontAwesomeIcons.microphone,
      'Automated Home Theater Systems': FontAwesomeIcons.tv,
      'Automated Shades': FontAwesomeIcons.accusoft,
      'Automatic Watering Systems': FontAwesomeIcons.water,
      'Smart Smoke Alarms': FontAwesomeIcons.bell,
      'Smart Leak Detectors': FontAwesomeIcons.water,
      'Smart Water Heaters': FontAwesomeIcons.fire,
      'Smart Air Conditioners': FontAwesomeIcons.snowflake,
      'Smart Vacuum Cleaners': FontAwesomeIcons.robot,
      'Smart Bed Frames': FontAwesomeIcons.bed,
      'Home Automation Controller Systems': FontAwesomeIcons.server,
    },
    'Commercial': {
      'Home Security Systems': FontAwesomeIcons.shieldAlt,
      'Streaming Devices': FontAwesomeIcons.stream,
      'Solar Energy Systems': FontAwesomeIcons.solarPanel,
      'Smart Meters': FontAwesomeIcons.tachometerAlt,
      'Smart Security Systems': FontAwesomeIcons.shieldVirus,
      'Smart Light Panels': FontAwesomeIcons.lightbulb,
      'Smart Doorbells': FontAwesomeIcons.bell,
      'Smart Curtains': FontAwesomeIcons.windowRestore,
      'Smart Window Openers': FontAwesomeIcons.windowMaximize,
      'Robotic Vacuums': FontAwesomeIcons.robot,
      'Smart Fans': FontAwesomeIcons.fan,
      'Smart Air Purifiers': FontAwesomeIcons.wind,
      'Smart Ovens': FontAwesomeIcons.breadSlice,
      'Smart Washing Machines': FontAwesomeIcons.soap,
      'Smart Dishwashers': FontAwesomeIcons.handsWash,
      'Smart Speakers': FontAwesomeIcons.volumeUp,
      'Smart Thermostat': FontAwesomeIcons.thermometerHalf,
      'Smart Hubs': FontAwesomeIcons.networkWired,
      'Smart Cameras': FontAwesomeIcons.camera,
      'Smart Refrigerators': FontAwesomeIcons.iceCream,
      'Smart Light Panels': FontAwesomeIcons.lightbulb,
      'LED Strips': FontAwesomeIcons.ribbon,
      'Smart Projectors': FontAwesomeIcons.projectDiagram,
      'Automated Home Theater Systems': FontAwesomeIcons.tv,
      'Voice Assistants': FontAwesomeIcons.microphone,
    }
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0A2A5A), // Deep navy blue
                Color(0xFF15489C), // Strong steel blue
                Color(0xFF1E64D8), // Vivid rich blue
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Smart Products for\nResidential & Commercial',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins', // Or 'Times New Roman' if you're using a custom font
            fontSize: 19,
            height: 1.4, // Controls spacing between lines
          ),
        ),
      ),


      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: categorizedProducts.entries.map((categoryEntry) {
              String category = categoryEntry.key;
              Map<String, IconData> products = categoryEntry.value;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade900, // same blue background color
                        borderRadius: BorderRadius.circular(8), // rounded corners for style
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade700.withOpacity(0.5),
                            offset: const Offset(0, 3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // white font color
                          letterSpacing: 1.1, // slight spacing for better readability
                        ),
                      ),
                    ),

                    SizedBox(height: 10),
                    Column(
                      children: products.entries.map((productEntry) {
                        String product = productEntry.key;
                        IconData icon = productEntry.value;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0A2A5A),
                                    Color(0xFF15489C),
                                    Color(0xFF1E64D8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                  child: Icon(
                                    icon,
                                    size: 32,
                                    color: Colors.cyanAccent,
                                  ),
                                ),
                                title: Text(
                                  product,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Roboto',
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

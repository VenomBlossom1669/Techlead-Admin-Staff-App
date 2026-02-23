import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MapScreen extends StatefulWidget {
  final LatLng initialPosition;

  MapScreen({required this.initialPosition});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  late LatLng _center;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _center = widget.initialPosition;
    isLoading = true;
    _saveLocationToFirestore(_center);
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _saveLocationToFirestore(LatLng location) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userId = user.uid;
        String date = DateTime.now().toIso8601String();
        await FirebaseFirestore.instance
            .collection('Attendance')
            .doc(userId)
            .set({
          'date': date,
          'maplocation': GeoPoint(location.latitude, location.longitude),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Failed to save location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Live Google Maps',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,),
        ),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 15.0,
        ),
        markers: Set<Marker>.from([
          Marker(
            markerId: MarkerId('current-location'),
            position: _center,
            infoWindow: InfoWindow(
              title: 'Current Location',
            ),
          ),
        ]),
      ),
    );
  }
}

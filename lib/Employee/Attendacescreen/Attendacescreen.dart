  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter/foundation.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:geocoding/geocoding.dart';
  import 'package:geolocator/geolocator.dart';
  import 'package:google_maps_flutter/google_maps_flutter.dart';
  import 'package:http/http.dart' as http;
  import 'dart:convert';
  import 'package:intl/intl.dart';
  import 'package:slide_to_act/slide_to_act.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'dart:async';
  import 'package:techlead/core/app_bar_provider.dart';
  import 'googlescreen.dart';
  import 'package:flutter/foundation.dart' show kIsWeb;
  import 'map_launcher_mobile.dart' if (dart.library.html) 'map_launcher_web.dart';

  class Attendancescreen extends ConsumerStatefulWidget {
    const Attendancescreen({Key? key}) : super(key: key);

    @override
    ConsumerState<Attendancescreen> createState() => _AttendancescreenState();
  }

  class _AttendancescreenState extends ConsumerState<Attendancescreen> {
    late double screenHeight;
    late double screenWidth;
    String userName = '';
    final GlobalKey<SlideActionState> _slideKey = GlobalKey<SlideActionState>();
    bool _showLocationError = false;
    Color attendanceColor = Colors.black;
    String employeeName = '';
    String checkInTime = '--:--';
    String checkInLocation = '';
    String checkOutLocation = '';
    Color _locationMessageColor = Colors.black;
    String checkOutTime = '--:--';
    String attendanceStatus = '';
    bool hasCheckedIn = false;
    bool hasCheckedOut = false;
    bool showEntryCompleteMessage = false;
    late Timer _liveTimeTimer;
    String _currentLocation = '';
    String _currentDateTime = '';
    final _firestore = FirebaseFirestore.instance;
    String? userId;
    late LatLng _center;
    late LatLng initialPosition;
    final userNameProvider = StateProvider<String>((ref) => "Employee");
    StreamSubscription<ServiceStatus>? _locationServiceSubscription;

    Timer? _webLocationRefreshTimer;
    bool _isLocationAvailable = false;
    bool _isRequestingPermission = false;

    static const String GOOGLE_MAPS_API_KEY = "AIzaSyA1IiyMvGZU0bIND5BqwOmMVB_PfEUPkE8";

    @override
    void initState() {
      super.initState();
      _center = LatLng(0.0, 0.0);
      initialPosition = _center;

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userId = user.uid;
        _listenForRealtimeUpdates();
      } else {
        print('No user is logged in.');
      }

      _initializeLocation();

      // 📱 Phone: Location service status monitor
      if (!kIsWeb) {
        _locationServiceSubscription =
            Geolocator.getServiceStatusStream().listen((status) {
              if (status == ServiceStatus.enabled) {
                print('✅ Location service enabled');
                _getLocation();
                if (mounted) {
                  setState(() {
                    _showLocationError = false;
                  });
                }
              } else if (status == ServiceStatus.disabled) {
                print('❌ Location service disabled');
                if (mounted) {
                  setState(() {
                    _currentLocation = "Please turn on location!";
                    _center = const LatLng(0.0, 0.0);
                    _locationMessageColor = Colors.red;
                    _showLocationError = true;
                    _isLocationAvailable = false;
                  });
                }
              }
            });
      } else {
        // 🌐 Web: Periodic location refresh
        _webLocationRefreshTimer =
            Timer.periodic(const Duration(seconds: 10), (timer) {
              if (mounted) {
                _getLocation();
              }
            });
      }

      // Live time update
      _liveTimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          _updateCurrentDateTime();
        }
      });

      // User name listener
      if (user != null) {
        FirebaseFirestore.instance
            .collection('EmpProfile')
            .doc(user.uid)
            .snapshots()
            .listen((snapshot) {
          final name = snapshot.data()?['fullName'] ?? "Employee";
          if (mounted) {
            ref.read(userNameProvider.notifier).state = name;
          }
        });
      }
    }

    @override
    void dispose() {
      _locationServiceSubscription?.cancel();
      _webLocationRefreshTimer?.cancel();
      _liveTimeTimer.cancel();
      Future.microtask(() {
        if (mounted) {
          resetAppBar(ref);
        }
      });
      super.dispose();
    }

    @override
    void didChangeDependencies() {
      super.didChangeDependencies();

      Future.microtask(() {
        ref.read(appBarTitleProvider.notifier).state = "Your Attendance";
        ref.read(appBarGradientColorsProvider.notifier).state = [
          const Color(0xFF1E3C72),
          const Color(0xFF2A5298),
        ];
        ref.read(customTitleWidgetProvider.notifier).state = null;
      });
    }

    // ✅ MAIN INITIALIZATION
    Future<void> _initializeLocation() async {
      if (kIsWeb) {
        print('🌐 Web: Browser will handle location permission');
        await _getLocation();
      } else {
        print('📱 Phone: Checking location permission...');
        await _checkAndRequestLocationPermission();
      }
    }

    // ✅ PHONE: Complete permission & location service check
    Future<void> _checkAndRequestLocationPermission() async {
      if (_isRequestingPermission) return;

      _isRequestingPermission = true;

      try {
        // ⚡ Step 1: Check if location SERVICE is enabled
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

        if (!serviceEnabled) {
          print('❌ Location service is OFF');

          if (mounted) {
            setState(() {
              _currentLocation = "Location service is OFF";
              _locationMessageColor = Colors.red;
              _showLocationError = true;
              _isLocationAvailable = false;
            });
          }

          // 🔥 SHOW DIALOG TO TURN ON LOCATION
          _showLocationServiceDialog();
          _isRequestingPermission = false;
          return;
        }

        print('✅ Location service is ON');

        // Step 2: Check permission status
        LocationPermission permission = await Geolocator.checkPermission();
        print('📍 Current permission: $permission');

        // Step 3: Request permission if needed
        if (permission == LocationPermission.denied) {
          print('📱 Requesting location permission...');
          permission = await Geolocator.requestPermission();
          print('📍 Permission result: $permission');
        }

        // Step 4: Handle permission results
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _currentLocation = "Location permission denied";
              _locationMessageColor = Colors.red;
              _showLocationError = true;
              _isLocationAvailable = false;
            });
          }
          _showPermissionDeniedDialog();
        } else if (permission == LocationPermission.deniedForever) {
          if (mounted) {
            setState(() {
              _currentLocation = "Location permission permanently denied";
              _locationMessageColor = Colors.red;
              _showLocationError = true;
              _isLocationAvailable = false;
            });
          }
          _showOpenSettingsDialog();
        } else {
          // ✅ Permission granted!
          print('✅ Location permission granted');
          await _getLocation();
        }
      } catch (e) {
        print('❌ Permission error: $e');
        if (mounted) {
          setState(() {
            _currentLocation = "Error: $e";
            _locationMessageColor = Colors.red;
            _showLocationError = true;
          });
        }
      } finally {
        _isRequestingPermission = false;
      }
    }

    // 🔥 NEW: Dialog to turn on location service
    void _showLocationServiceDialog() {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF000F89),
                    Color(0xFF0F52BA),
                    Color(0xFF002147),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_off, color: Colors.orange, size: 56),
                  SizedBox(height: 16),
                  Text(
                    'Turn On Location',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Location service is turned off. Please turn it on to use attendance features.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancel',
                            style: TextStyle(color: Colors.white70, fontSize: 16)),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.of(context).pop();

                          // Try to open location settings
                          try {
                            await Geolocator.openLocationSettings();

                            // After 2 seconds, check again
                            Future.delayed(Duration(seconds: 1), () {
                              _checkAndRequestLocationPermission();
                            });
                          } catch (e) {
                            print('Could not open location settings: $e');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        icon: Icon(Icons.settings, color: Colors.white),
                        label: Text('Turn On',
                            style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    // 🔔 Dialog when permission denied
    void _showPermissionDeniedDialog() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF000F89),
                    Color(0xFF0F52BA),
                    Color(0xFF002147),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_off, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Location Permission Required',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'This app needs location permission to track attendance. Please grant permission.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancel', style: TextStyle(color: Colors.white70)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _checkAndRequestLocationPermission();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: Text('Try Again', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    // ⚙️ Dialog to open app settings
    void _showOpenSettingsDialog() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF000F89),
                    Color(0xFF0F52BA),
                    Color(0xFF002147),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.settings, color: Colors.orange, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Open Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Location permission is permanently denied. Please enable it from app settings.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancel', style: TextStyle(color: Colors.white70)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await Geolocator.openAppSettings();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: Text('Open Settings', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    // 🌐 Web: Reverse geocoding
    Future<String> _getAddressFromCoordinatesWeb(double lat, double lng) async {
      try {
        print('🌐 Fetching web address for: $lat, $lng');

        const String LOCATIONIQ_API_KEY = 'pk.2b827409aec268e0af64936c806d1bac';

        final url = Uri.parse(
            'https://us1.locationiq.com/v1/reverse?key=$LOCATIONIQ_API_KEY&lat=$lat&lon=$lng&format=json&addressdetails=1');

        final response = await http.get(url);
        print('📡 LocationIQ response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data.containsKey('address')) {
            var address = data['address'];

            // ✅ Mobile જેવા બધા fields extract કરો
            String road = address['road'] ?? '';
            String houseNumber = address['house_number'] ?? '';
            String neighbourhood = address['neighbourhood'] ?? address['suburb'] ?? '';
            String village = address['village'] ?? '';
            String town = address['town'] ?? '';
            String city = address['city'] ?? '';
            String state = address['state'] ?? '';
            String postcode = address['postcode'] ?? '';
            String country = address['country'] ?? '';

            // ✅ Mobile જેવું exact format બનાવો
            List<String> addressParts = [];

            // Street/Road (જેમ કે mobile માં "Sarkhej - Gandhinagar Hwy")
            if (houseNumber.isNotEmpty && road.isNotEmpty) {
              addressParts.add('$houseNumber, $road');
            } else if (road.isNotEmpty) {
              addressParts.add(road);
            }

            // Sub-locality/Neighbourhood (જેમ કે "Gota")
            if (neighbourhood.isNotEmpty) {
              addressParts.add(neighbourhood);
            }

            // City/Town/Village (જેમ કે "Ahmedabad")
            if (city.isNotEmpty) {
              addressParts.add(city);
            } else if (town.isNotEmpty) {
              addressParts.add(town);
            } else if (village.isNotEmpty) {
              addressParts.add(village);
            }

            // State (જેમ કે "Gujarat")
            if (state.isNotEmpty) {
              addressParts.add(state);
            }

            // Pincode (જેમ કે "380060")
            if (postcode.isNotEmpty) {
              addressParts.add(postcode);
            }

            // Country (જેમ કે "India")
            if (country.isNotEmpty) {
              addressParts.add(country);
            }

            String finalAddress = addressParts.join(', ');
            print('✅ Web address formatted: $finalAddress');

            return finalAddress.isNotEmpty
                ? finalAddress
                : "Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}";
          }
        }

        print('⚠️ LocationIQ failed (${response.statusCode}), trying Nominatim...');

        // ✅ Fallback: Nominatim
        final nominatimUrl = Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&addressdetails=1');

        final nominatimResponse = await http.get(
          nominatimUrl,
          headers: {'User-Agent': 'TechLeadAttendanceApp/1.0'},
        );

        print('📡 Nominatim response status: ${nominatimResponse.statusCode}');

        if (nominatimResponse.statusCode == 200) {
          final nominatimData = json.decode(nominatimResponse.body);

          if (nominatimData.containsKey('address')) {
            var address = nominatimData['address'];

            String road = address['road'] ?? '';
            String houseNumber = address['house_number'] ?? '';
            String neighbourhood = address['neighbourhood'] ?? address['suburb'] ?? '';
            String village = address['village'] ?? '';
            String town = address['town'] ?? '';
            String city = address['city'] ?? '';
            String state = address['state'] ?? '';
            String postcode = address['postcode'] ?? '';
            String country = address['country'] ?? '';

            List<String> addressParts = [];

            if (houseNumber.isNotEmpty && road.isNotEmpty) {
              addressParts.add('$houseNumber, $road');
            } else if (road.isNotEmpty) {
              addressParts.add(road);
            }

            if (neighbourhood.isNotEmpty) addressParts.add(neighbourhood);

            if (city.isNotEmpty) {
              addressParts.add(city);
            } else if (town.isNotEmpty) {
              addressParts.add(town);
            } else if (village.isNotEmpty) {
              addressParts.add(village);
            }

            if (state.isNotEmpty) addressParts.add(state);
            if (postcode.isNotEmpty) addressParts.add(postcode);
            if (country.isNotEmpty) addressParts.add(country);

            String finalAddress = addressParts.join(', ');
            print('✅ Nominatim address formatted: $finalAddress');

            return finalAddress.isNotEmpty
                ? finalAddress
                : "Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}";
          }
        }

        // ❌ Last resort
        print('❌ All geocoding attempts failed, returning coordinates');
        return "Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}";

      } catch (e) {
        print('❌ Geocoding error: $e');
        return "Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}";
      }
    }

    Future<void> _getLocation() async {
      try {
        print('🔍 Getting location...');

        if (kIsWeb) {
          // 🌐 WEB FLOW
          try {
            Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            ).timeout(
              Duration(seconds: 15),
              onTimeout: () {
                throw TimeoutException('Location request timed out');
              },
            );

            print('✅ Web location: ${position.latitude}, ${position.longitude}');

            String address = await _getAddressFromCoordinatesWeb(
              position.latitude,
              position.longitude,
            );

            if (mounted) {
              setState(() {
                _currentLocation = address;
                _center = LatLng(position.latitude, position.longitude);
                initialPosition = _center;
                _locationMessageColor = Colors.white;
                _showLocationError = false;
                _isLocationAvailable = true;
              });
            }
            return;
          } catch (e) {
            print('❌ Web location error: $e');
            if (mounted) {
              setState(() {
                _currentLocation = "Please enable location in your browser!";
                _center = const LatLng(0.0, 0.0);
                _locationMessageColor = Colors.red;
                _showLocationError = true;
                _isLocationAvailable = false;
              });
            }
            return;
          }
        }

        // 📱 PHONE FLOW
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (mounted) {
            setState(() {
              _currentLocation = "Please turn on location!";
              _center = const LatLng(0.0, 0.0);
              _locationMessageColor = Colors.red;
              _showLocationError = true;
              _isLocationAvailable = false;
            });
          }
          return;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (mounted) {
            setState(() {
              _currentLocation = "Location permission required";
              _center = const LatLng(0.0, 0.0);
              _locationMessageColor = Colors.red;
              _showLocationError = true;
              _isLocationAvailable = false;
            });
          }
          return;
        }

        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        print('✅ Phone location: ${position.latitude}, ${position.longitude}');

        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          if (mounted) {
            setState(() {
              _currentLocation =
              "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";
              _center = LatLng(position.latitude, position.longitude);
              initialPosition = _center;
              _locationMessageColor = Colors.white;
              _showLocationError = false;
              _isLocationAvailable = true;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _currentLocation = "Location: ${position.latitude}, ${position.longitude}";
              _center = LatLng(position.latitude, position.longitude);
              initialPosition = _center;
              _locationMessageColor = Colors.white;
              _showLocationError = false;
              _isLocationAvailable = true;
            });
          }
        }
      } catch (e) {
        print('❌ Location error: $e');
        if (mounted) {
          setState(() {
            _currentLocation = kIsWeb
                ? "Please enable location in your browser!"
                : "Please enable location!";
            _center = const LatLng(0.0, 0.0);
            _locationMessageColor = Colors.red;
            _showLocationError = true;
            _isLocationAvailable = false;
          });
        }
      }
    }

    Future<bool> _showCheckoutDialog() async {
      final bool? shouldCheckout = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            insetPadding: EdgeInsets.symmetric(horizontal: 24.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF000F89),
                    Color(0xFF0F52BA),
                    Color(0xFF002147),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Confirm Check Out',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Are you sure you want to check out?',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('No', style: TextStyle(color: Colors.white)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text('Yes', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
      return shouldCheckout ?? false;
    }

    Future<bool> _showCheckInDialog() async {
      final bool? shouldCheckIn = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            insetPadding: EdgeInsets.symmetric(horizontal: 24.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF000F89),
                    Color(0xFF0F52BA),
                    Color(0xFF002147),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Confirm Check In',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Are you sure you want to check in?',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('No', style: TextStyle(color: Colors.white)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text('Yes', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
      return shouldCheckIn ?? false;
    }

    void _updateCurrentDateTime() {
      if (mounted) {
        setState(() {
          _currentDateTime =
              DateFormat('EE, d MMM yyyy, hh:mm:ss a').format(DateTime.now());
        });
      }
    }

    void _listenForRealtimeUpdates() {
      if (userId == null) {
        print('User ID is null, cannot listen for real-time updates.');
        return;
      }

      _firestore
          .collection('Attendance')
          .where('userId', isEqualTo: userId)
          .where('date',
          isEqualTo: DateFormat('dd/MM/yyyy').format(DateTime.now()))
          .snapshots()
          .listen((QuerySnapshot snapshot) {
        if (snapshot.docs.isNotEmpty) {
          DocumentSnapshot doc = snapshot.docs.first;
          Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

          if (data != null && mounted) {
            setState(() {
              checkInTime = data['checkIn'] ?? '--:--';
              checkOutTime = data['checkOut'] ?? '--:--';
              checkInLocation = data['checkInLocation'] ?? '';
              checkOutLocation = data['checkOutLocation'] ?? '';
              hasCheckedIn =
                  data.containsKey('checkIn') && data['checkIn'] != null;
              hasCheckedOut =
                  data.containsKey('checkOut') && data['checkOut'] != null;
              showEntryCompleteMessage = hasCheckedOut;
            });

            if (hasCheckedOut) {
              calculateAttendanceStatus();
            }
          }
        } else {
          _resetAttendance();
        }
      });
    }

    void _resetAttendance() {
      if (mounted) {
        setState(() {
          checkInTime = '--:--';
          checkOutTime = '--:--';
          checkInLocation = '';
          checkOutLocation = '';
          hasCheckedIn = false;
          hasCheckedOut = false;
          showEntryCompleteMessage = false;
        });
      }
    }

    Future<void> storeCheckInOutTime({required bool isCheckIn}) async {
      String currentTime = DateFormat('HH:mm').format(DateTime.now());
      String todayStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

      if (userId != null) {
        DocumentSnapshot userSnapshot =
        await _firestore.collection('EmpProfile').doc(userId).get();
        String employeeName =
        userSnapshot.exists ? userSnapshot['fullName'] : 'Unknown';
        String department =
        userSnapshot.exists ? userSnapshot['address'] : 'Unknown';

        QuerySnapshot snapshot = await _firestore
            .collection('Attendance')
            .where('userId', isEqualTo: userId)
            .where('date', isEqualTo: todayStr)
            .get();

        DocumentReference attendanceRef;
        if (snapshot.docs.isNotEmpty) {
          attendanceRef =
              _firestore.collection('Attendance').doc(snapshot.docs.first.id);
        } else {
          attendanceRef = _firestore.collection('Attendance').doc();
        }

        if (isCheckIn && !hasCheckedIn) {
          await attendanceRef.set({
            'userId': userId,
            'date': todayStr,
            'checkIn': currentTime,
            'checkInLocation': _currentLocation,
            'employeeName': employeeName,
            'department': department,
          }, SetOptions(merge: true));

          if (mounted) {
            setState(() {
              checkInTime = currentTime;
              checkInLocation = _currentLocation;
              hasCheckedIn = true;
              showEntryCompleteMessage = false;
            });
          }
        } else if (!isCheckIn && hasCheckedIn && !hasCheckedOut) {
          await attendanceRef.update({
            'checkOut': currentTime,
            'checkOutLocation': _currentLocation,
            'employeeName': employeeName,
            'maplocation': GeoPoint(_center.latitude, _center.longitude),
          });

          if (mounted) {
            setState(() {
              checkOutTime = currentTime;
              checkOutLocation = _currentLocation;
              hasCheckedOut = true;
              showEntryCompleteMessage = true;
              calculateAttendanceStatus();
            });
          }
        }
      } else {
        print('User ID is null, cannot store attendance data.');
      }
    }

    void calculateAttendanceStatus({
      String? currentCheckoutLocation,
      bool isAutoCheckout = false,
    }) async {
      if (checkInTime != '--:--') {
        DateTime checkIn = DateFormat('HH:mm').parse(checkInTime);
        DateTime now = DateTime.now();
        DateTime currentDayStart = DateTime(now.year, now.month, now.day);

        const String defaultCheckoutLocation =
            'A-303, S.G.Business Hub, Sarkhej - Gandhinagar Hwy, Gota, Ahmedabad, Gujarat 380060';

        if (checkOutTime == '--:--') {
          if (now.isAfter(currentDayStart)) {
            DateTime autoCheckout = checkIn.add(const Duration(hours: 8));
            if (autoCheckout.isAfter(
                currentDayStart.add(const Duration(hours: 23, minutes: 59)))) {
              autoCheckout =
                  currentDayStart.add(const Duration(hours: 23, minutes: 59));
            }
            checkOutTime = DateFormat('HH:mm').format(autoCheckout);
            isAutoCheckout = true;
          } else {
            if (mounted) {
              setState(() {
                attendanceStatus = 'Incomplete Data';
                attendanceColor = Colors.red;
              });
            }
            return;
          }
        }

        DateTime checkOut = DateFormat('HH:mm').parse(checkOutTime);
        Duration duration = checkOut.difference(checkIn);
        int hours = duration.inHours;
        int minutes = duration.inMinutes.remainder(60);

        String status;
        Color color;

        double totalWorkedHours = hours + (minutes / 60);

        if (totalWorkedHours >= 8.0) {
          status = 'Full Day';
          color = Colors.green;
        } else if (totalWorkedHours >= 4.0) {
          status = 'Half Day';
          color = Colors.pink;
        } else {
          status = 'Absent';
          color = Colors.red;
        }

        if (mounted) {
          setState(() {
            attendanceStatus =
            '${hours}Hours: ${minutes}Minutes\nToday\'s Status: $status';
            attendanceColor = color;
          });
        }

        if (userId != null) {
          String today = DateFormat('dd/MM/yyyy').format(DateTime.now());
          QuerySnapshot snapshot = await _firestore
              .collection('Attendance')
              .where('userId', isEqualTo: userId)
              .where('date', isEqualTo: today)
              .get();

          if (snapshot.docs.isNotEmpty) {
            DocumentReference docRef =
            _firestore.collection('Attendance').doc(snapshot.docs.first.id);

            Map<String, dynamic> updateData = {
              'status': status,
              'record': '$hours hours, $minutes minutes',
              'checkOutTime': checkOutTime,
            };

            var docData = snapshot.docs.first.data() as Map<String, dynamic>;
            String existingCheckOut = docData['checkOutTime'] ?? '--:--';

            if (checkOutTime != '--:--' && existingCheckOut == '--:--') {
              updateData['checkOutLocation'] = isAutoCheckout
                  ? defaultCheckoutLocation
                  : currentCheckoutLocation ?? _currentLocation;
            }

            await docRef.update(updateData);
          }
        }
      } else {
        if (mounted) {
          setState(() {
            attendanceStatus = 'Incomplete Data';
            attendanceColor = Colors.red;
          });
        }
      }
    }

    @override
    Widget build(BuildContext context) {
      final gradientColors = ref.watch(appBarGradientColorsProvider);
      screenHeight = MediaQuery.of(context).size.height;
      screenWidth = MediaQuery.of(context).size.width;

      bool isWebLarge = kIsWeb && screenWidth > 1200;
      bool isWebMedium = kIsWeb && screenWidth > 768 && screenWidth <= 1200;
      bool isWebSmall = kIsWeb && screenWidth <= 768;
      double maxWidth = isWebLarge ? 800 : (isWebMedium ? 600 : double.infinity);

      return Scaffold(
        appBar: AppBar(
          title: Text(
            "Your Attendance",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: "Times New Roman",
              fontSize: kIsWeb ? 20 : 16,
            ),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(kIsWeb ? 20.0 : 8.0),
                child: Column(
                  children: [
                    _buildWelcomeMessage(),
                    SizedBox(height: kIsWeb ? 24 : 16),
                    _buildTodaysStatus(),
                    SizedBox(height: kIsWeb ? 24 : 16),
                    _buildDateTime(),
                    SizedBox(height: kIsWeb ? 20 : 15),
                    if (!hasCheckedOut) _buildSlideAction(),
                    if (showEntryCompleteMessage) _buildEntryCompleteMessage(),
                    _buildLocationInfo(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget _buildWelcomeMessage() {
      final userName = ref.watch(userNameProvider);

      return Padding(
        padding: EdgeInsets.only(top: kIsWeb ? 10 : 20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF000F89),
                Color(0xFF0F52BA),
                Color(0xFF002147),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: kIsWeb ? 30.0 : 25.0, horizontal: kIsWeb ? 30.0 : 25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Welcome",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: "NexaRegular",
                    fontSize: kIsWeb ? 28 : screenWidth / 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  userName,
                  style: TextStyle(
                    fontFamily: "NexaBold",
                    fontSize: kIsWeb ? 22 : screenWidth / 18,
                    color: const Color(0xFF00D4FF),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  "Hope you have a productive day!",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: kIsWeb ? 16 : screenWidth / 26,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget buildSectionTitle(String title, IconData icon) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF000F89),
              Color(0xFF0F52BA),
              Color(0xFF002147),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon,
                color: Colors.white, size: kIsWeb ? 24 : screenWidth * 0.06),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontFamily: "NexaBold",
                fontSize: kIsWeb ? 18 : screenWidth / 20,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildTodaysStatus() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle("Today's Status", Icons.fact_check),
          Container(
            margin: EdgeInsets.only(top: 12),
            padding: EdgeInsets.all(kIsWeb ? 20 : 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Color(0xFF000F89),
                  Color(0xFF0F52BA),
                  Color(0xFF002147),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _buildStatusColumn("Check In", checkInTime,
                          isChecked: hasCheckedIn),
                    ),
                    Container(
                      height: 80,
                      width: 1,
                      color: Colors.white,
                    ),
                    Expanded(
                      child: _buildStatusColumn("Check Out", checkOutTime,
                          isChecked: hasCheckedOut),
                    ),
                  ],
                ),
                if (hasCheckedIn || hasCheckedOut) ...[
                  SizedBox(height: 16),
                  Divider(color: Colors.white54, thickness: 1),
                  SizedBox(height: 12),
                  if (hasCheckedIn && checkInLocation.isNotEmpty) ...[
                    _buildLocationRow("Check In Location:", checkInLocation),
                    SizedBox(height: 8),
                  ],
                  if (hasCheckedOut && checkOutLocation.isNotEmpty) ...[
                    _buildLocationRow("Check Out Location:", checkOutLocation),
                  ],
                ],
              ],
            ),
          ),
        ],
      );
    }

    Widget _buildLocationRow(String label, String location) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on, color: Colors.orange, size: kIsWeb ? 20 : 18),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: "NexaBold",
                    fontSize: kIsWeb ? 14 : screenWidth / 24,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  location,
                  style: TextStyle(
                    fontFamily: "NexaRegular",
                    fontSize: kIsWeb ? 12 : screenWidth / 26,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget _buildStatusColumn(String title, String time, {bool isChecked = false}) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: "NexaRegular",
              fontSize: kIsWeb ? 16 : screenWidth / 20,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 5),
          Text(
            time,
            style: TextStyle(
              fontFamily: "NexaBold",
              fontSize: kIsWeb ? 20 : screenWidth / 18,
              color: Colors.white,
            ),
          ),
          if (isChecked) Icon(Icons.check, color: Colors.orange, size: 28),
        ],
      );
    }

    Widget _buildDateTime() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle("Date & Time", Icons.calendar_today),
          Container(
            margin: EdgeInsets.only(top: 12),
            padding: EdgeInsets.all(kIsWeb ? 24 : 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Color(0xFF000F89),
                  Color(0xFF0F52BA),
                  Color(0xFF002147),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _currentDateTime,
                style: TextStyle(
                  fontFamily: "NexaRegular",
                  fontSize: kIsWeb ? 16 : screenWidth / 20,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    Widget _buildSlideAction() {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: kIsWeb ? 16.0 : 10.0),
        child: Column(
          children: [
            if (_showLocationError)
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  kIsWeb
                      ? "Please enable location in your browser then do Check In & Check Out!"
                      : "Please turn on location then do Check In & Check Out!",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: "NexaRegular",
                    fontSize: kIsWeb ? 14 : screenWidth / 22,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF000F89),
                    Color(0xFF0F52BA),
                    Color(0xFF002147),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SlideAction(
                  key: _slideKey,
                  elevation: 0,
                  borderRadius: 20,
                  text: hasCheckedIn ? "Slide to Check Out" : "Slide to Check In",
                  textStyle: TextStyle(
                    fontSize: kIsWeb ? 16 : screenWidth / 22,
                    color: Colors.white,
                    fontFamily: "NexaRegular",
                    letterSpacing: 1.2,
                  ),
                  outerColor: Colors.transparent,
                  innerColor: Colors.white,
                  sliderButtonIcon: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.black,
                    size: 24,
                  ),
                  onSubmit: () async {
                    final userName = ref.read(userNameProvider);

                    if (userName == "Employee" || userName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Please fill profile then do check in",
                            style: TextStyle(
                              fontFamily: "NexaRegular",
                              fontSize: kIsWeb ? 14 : screenWidth / 22,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );

                      await Future.delayed(Duration(milliseconds: 500));
                      _slideKey.currentState?.reset();
                      return;
                    }

                    if (_showLocationError || !_isLocationAvailable) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            kIsWeb
                                ? "Please enable location in your browser!"
                                : "Please enable location permission!",
                            style: TextStyle(
                              fontFamily: "NexaRegular",
                              fontSize: kIsWeb ? 14 : screenWidth / 22,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          action: kIsWeb ? null : SnackBarAction(
                            label: 'Enable',
                            textColor: Colors.white,
                            onPressed: () {
                              _checkAndRequestLocationPermission();
                            },
                          ),
                        ),
                      );

                      await Future.delayed(Duration(milliseconds: 500));
                      _slideKey.currentState?.reset();
                      return;
                    }

                    if (hasCheckedIn) {
                      bool shouldCheckout = await _showCheckoutDialog();
                      if (shouldCheckout) {
                        await storeCheckInOutTime(isCheckIn: false);
                        setState(() {
                          hasCheckedOut = true;
                        });
                      } else {
                        _slideKey.currentState?.reset();
                      }
                    } else {
                      bool shouldCheckIn = await _showCheckInDialog();
                      if (shouldCheckIn) {
                        await storeCheckInOutTime(isCheckIn: true);
                        setState(() {
                          hasCheckedIn = true;
                        });
                      } else {
                        _slideKey.currentState?.reset();
                      }
                    }
                  },
                ),
              ),
            ),
            SizedBox(height: kIsWeb ? 28 : 24),
          ],
        ),
      );
    }

    Widget _buildEntryCompleteMessage() {
      return Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 12),
            child: Text(
              "Entry Complete For Today!",
              style: TextStyle(
                fontFamily: "NexaBold",
                fontSize: kIsWeb ? 20 : screenWidth / 18,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: EdgeInsets.all(kIsWeb ? 24 : 20),
            constraints: BoxConstraints(
              minHeight: kIsWeb ? 180 : 150,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Color(0xFF000F89),
                  Color(0xFF0F52BA),
                  Color(0xFF002147),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "Work Duration:\n",
                          style: TextStyle(
                            fontFamily: "NexaBold",
                            fontSize: kIsWeb ? 18 : screenWidth / 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: attendanceStatus.contains("Hours")
                              ? attendanceStatus.split("\n")[0] + "\n\n"
                              : "",
                          style: TextStyle(
                            fontFamily: "NexaBold",
                            fontSize: kIsWeb ? 20 : screenWidth / 18,
                            color: attendanceColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: "Today's Status:\n",
                          style: TextStyle(
                            fontFamily: "NexaBold",
                            fontSize: kIsWeb ? 18 : screenWidth / 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: attendanceStatus.contains("Today's Status:")
                              ? attendanceStatus.split("Today's Status: ").last
                              : attendanceStatus,
                          style: TextStyle(
                            fontFamily: "NexaBold",
                            fontSize: kIsWeb ? 20 : screenWidth / 18,
                            color: attendanceColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
          if (_isLocationAvailable && initialPosition.latitude != 0.0)
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF000F89),
                        Color(0xFF0F52BA),
                        Color(0xFF002147),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (kIsWeb) {
                        final url =
                            'https://www.google.com/maps/search/?api=1&query=${initialPosition.latitude},${initialPosition.longitude}';
                        await openMapUrl(url);
                      } else {
                        if (initialPosition.latitude != 0.0 &&
                            initialPosition.longitude != 0.0) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MapScreen(initialPosition: initialPosition),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Location not available. Please enable location services.",
                                style: TextStyle(
                                  fontFamily: "NexaRegular",
                                  fontSize: screenWidth / 22,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          kIsWeb ? Icons.open_in_new : Icons.map,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          kIsWeb ? "Open in Google Maps" : "View Live Location",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    Widget _buildLocationInfo() {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Color(0xFF000F89),
              Color(0xFF0F52BA),
              Color(0xFF002147),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(kIsWeb ? 20 : 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.location_on,
              color: _showLocationError ? Colors.red : Colors.greenAccent,
              size: kIsWeb ? 28 : screenWidth * 0.08,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Current Location",
                        style: TextStyle(
                          fontFamily: "NexaBold",
                          color: Colors.white,
                          fontSize: kIsWeb ? 16 : screenWidth / 22,
                        ),
                      ),
                      SizedBox(width: 8),
                      if (_isLocationAvailable)
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _currentLocation.isNotEmpty
                        ? _currentLocation
                        : "Fetching location...",
                    style: TextStyle(
                      fontFamily: "NexaRegular",
                      color: _showLocationError ? Colors.red : Colors.white70,
                      fontSize: kIsWeb ? 14 : screenWidth / 24,
                    ),
                  ),
                  if (_isLocationAvailable && initialPosition.latitude != 0.0) ...[
                    SizedBox(height: 8),
                    Text(
                      "Lat: ${initialPosition.latitude.toStringAsFixed(6)}, Lng: ${initialPosition.longitude.toStringAsFixed(6)}",
                      style: TextStyle(
                        fontFamily: "NexaRegular",
                        color: Colors.white54,
                        fontSize: kIsWeb ? 12 : screenWidth / 26,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  int hexColor(String color) {
    String newColor = '0xff' + color.replaceAll('#', '');
    return int.parse(newColor);
  }
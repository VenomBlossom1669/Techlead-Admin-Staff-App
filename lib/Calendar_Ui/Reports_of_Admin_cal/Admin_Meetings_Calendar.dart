import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'Services/Appoinments/Appointments_Calendar.dart';
import 'Services/services.dart';
import 'dart:math' as math;
class AdminMeetingShow extends StatefulWidget {
  const AdminMeetingShow({super.key});

  @override
  State<AdminMeetingShow> createState() => _AdminMeetingShowState();
}

class _AdminMeetingShowState extends State<AdminMeetingShow> {
  DateTime _selectedDate = DateTime.now();
  final List<MyAppointments> _myAppointments = [];
  bool _isLoading = true;
  final Map<Appointment, MyAppointments> appointmentMap = {};
  final Map<String, Map<String, dynamic>> admins = {};
  final FirestoreService _firestoreService = FirestoreService();
  String? _loggedInAdminId;

  // timeline scroll sync + layout constants
  final ScrollController _timelineScrollController = ScrollController();
  final double _hourHeight = 80.0; // height per hour row (adjust if you want)
  final startHour = 0; // 12 AM
  final endHour = 24; // 12 AM next day
  // last hour shown (8 PM)

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  Color? _filterColor;
  String? _filterAdminId;
  bool _showOnlyMyMeetings = false;

// Bulk selection states
  bool _isBulkSelectMode = false;
  final Set<String> _selectedMeetingIds = {};

  StreamSubscription? _adminsSubscription;
  StreamSubscription? _meetingsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _initializeLoggedInAdmin();
    _listenToAdmins();
    _listenToMeetings();
    await _fetchAdmins();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _adminsSubscription?.cancel();
    _meetingsSubscription?.cancel();
    _timelineScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _listenToAdmins() {
    _adminsSubscription?.cancel();
    _adminsSubscription = FirebaseFirestore.instance
        .collection('Admin_Profiles')
        .snapshots()
        .listen((snapshot) {
      final fetchedAdmins = <String, Map<String, dynamic>>{};
      for (var doc in snapshot.docs) {
        fetchedAdmins[doc.id] = doc.data();
      }
      setState(() {
        admins.clear();
        admins.addAll(fetchedAdmins);
      });
    });
  }

  void _listenToMeetings() {
    _meetingsSubscription?.cancel();
    _meetingsSubscription = FirebaseFirestore.instance
        .collection('meetings')
        .snapshots()
        .listen((snapshot) {
      final appointments = <MyAppointments>[];
      for (var doc in snapshot.docs) {
        final myAppt = MyAppointments.fromFirestore(doc);

        // 🔎 Look up admin name using createdBy
        String? adminName;
        if (myAppt.createdBy != null) {
          final adminData = admins[myAppt.createdBy];
          adminName =
          adminData?['name']; // adjust key if your field is different
        }

        // attach to model (if you added adminName field)
        myAppt.adminName = adminName;

        appointments.add(myAppt);
      }
      setState(() {
        _myAppointments.clear();
        _myAppointments.addAll(appointments);
      });
    });
  }





  List<MyAppointments> _getAppointmentsForDay(DateTime date) {
    // First filter by selected date
    var appointments = _myAppointments.where((appt) {
      return appt.startTime.year == date.year &&
          appt.startTime.month == date.month &&
          appt.startTime.day == date.day;
    }).toList();

    // Apply filters (search, color, admin, etc.)
    appointments = _applyFilters(appointments);

    return appointments;
  }

// New method to get all appointments matching filters (for search across all dates)
  List<MyAppointments> _getAllFilteredAppointments() {
    return _applyFilters(_myAppointments);
  }

  List<MyAppointments> _applyFilters(List<MyAppointments> appointments) {
    var filtered = appointments;

    // ✅ Apply "My Meetings" filter FIRST
    if (_showOnlyMyMeetings && _loggedInAdminId != null) {
      filtered = filtered.where((appt) => appt.createdBy == _loggedInAdminId).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((appt) {
        final searchLower = _searchQuery.toLowerCase();
        return appt.subject.toLowerCase().contains(searchLower) ||
            (appt.location?.toLowerCase().contains(searchLower) ?? false) ||
            (appt.purpose?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    }

    // Date range filter
    if (_filterStartDate != null && _filterEndDate != null) {
      filtered = filtered.where((appt) {
        return appt.startTime.isAfter(_filterStartDate!.subtract(const Duration(days: 1))) &&
            appt.startTime.isBefore(_filterEndDate!.add(const Duration(days: 1)));
      }).toList();
    }

    // ✅ Color filter - now works correctly with other filters
    if (_filterColor != null) {
      filtered = filtered.where((appt) {
        // Match the exact color or check if colors are similar
        return appt.color == _filterColor ||
            (appt.color.value == _filterColor!.value);
      }).toList();
    }

    // Admin filter
    if (_filterAdminId != null) {
      filtered = filtered.where((appt) => appt.createdBy == _filterAdminId).toList();
    }

    return filtered;
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _filterStartDate = null;
      _filterEndDate = null;
      _filterColor = null;
      _filterAdminId = null;
      _showOnlyMyMeetings = false;
    });
  }

  bool get _hasActiveFilters {
    return _searchQuery.isNotEmpty ||
        _filterStartDate != null ||
        _filterEndDate != null ||
        _filterColor != null ||
        _filterAdminId != null ||
        _showOnlyMyMeetings;
  }


  bool _appointmentsOverlap(MyAppointments a, MyAppointments b) {
    return a.startTime.isBefore(b.endTime) && a.endTime.isAfter(b.startTime);
  }

  Map<String, Map<String, int>> _calculateEventPositions(
      List<MyAppointments> appts) {
    final Map<String, Map<String, int>> result = {};

    if (appts.isEmpty) return result;

    final int n = appts.length;

    final List<List<int>> adj = List.generate(n, (_) => []);
    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        if (_appointmentsOverlap(appts[i], appts[j])) {
          adj[i].add(j);
          adj[j].add(i);
        }
      }
    }

    final List<bool> visited = List.filled(n, false);

    for (int i = 0; i < n; i++) {
      if (visited[i]) continue;

      final List<int> comp = [];
      final List<int> queue = [i];
      visited[i] = true;
      while (queue.isNotEmpty) {
        final int u = queue.removeLast();
        comp.add(u);
        for (final v in adj[u]) {
          if (!visited[v]) {
            visited[v] = true;
            queue.add(v);
          }
        }
      }

      comp.sort((a, b) => appts[a].startTime.compareTo(appts[b].startTime));
      final List<List<int>> columns = [];

      for (final idx in comp) {
        final current = appts[idx];
        bool placed = false;
        for (final col in columns) {
          final bool overlapsAny = col.any(
                  (otherIdx) => _appointmentsOverlap(current, appts[otherIdx]));
          if (!overlapsAny) {
            col.add(idx);
            placed = true;
            break;
          }
        }
        if (!placed) {
          columns.add([idx]);
        }
      }

      final int totalCols = columns.length;
      for (int colIndex = 0; colIndex < columns.length; colIndex++) {
        for (final idx in columns[colIndex]) {
          final String idKey = appts[idx].id ?? idx.toString();
          result[idKey] = {'col': colIndex, 'cols': totalCols};
        }
      }
    }

    return result;
  }


// REPLACE your existing _bulkDeleteMeetings method with this:

  Future<void> _bulkDeleteMeetings() async {
    if (_selectedMeetingIds.isEmpty) return;

    final meetingsToDelete = _myAppointments.where((appt) {
      return _selectedMeetingIds.contains(appt.id) &&
          appt.createdBy == _loggedInAdminId;
    }).toList();

    if (meetingsToDelete.isEmpty) {
      _showPremiumSnackBar(
        context: context,
        message: "You can only delete your own meetings",
        icon: Icons.block_rounded,
        backgroundColor: Colors.red,
      );
      return;
    }

    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Bulk Delete Confirmation',
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          ),
          child: FadeTransition(
            opacity: animation,
            child: _buildPremiumDeleteDialog(meetingsToDelete.length),
          ),
        );
      },
    );

    if (confirmed != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildLoadingOverlay(),
    );

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (var appt in meetingsToDelete) {
        batch.delete(FirebaseFirestore.instance.collection('meetings').doc(appt.id));
      }
      await batch.commit();

      Navigator.of(context).pop(); // Close loading

      setState(() {
        _myAppointments.removeWhere((appt) => meetingsToDelete.contains(appt));
        _selectedMeetingIds.clear();
        _isBulkSelectMode = false;
      });

      // ✅ Fixed: Show success message AFTER setState
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _showPremiumSnackBar(
            context: context,
            message: "Successfully deleted ${meetingsToDelete.length} meeting${meetingsToDelete.length > 1 ? 's' : ''}",
            icon: Icons.check_circle_rounded,
            backgroundColor: Colors.green,
          );
        }
      });
    } catch (e) {
      Navigator.of(context).pop(); // Close loading
      _showPremiumSnackBar(
        context: context,
        message: "Failed to delete meetings",
        icon: Icons.error_rounded,
        backgroundColor: Colors.red,
      );
    }
  }
// ADD these three new widget methods to your State class:

  Widget _buildPremiumDeleteDialog(int count) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[900]!,
              Colors.grey[850]!,
              Colors.red[900]!.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 40,
              spreadRadius: 5,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red[400]!, Colors.red[700]!],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Colors.red[300]!, Colors.red[100]!],
                ).createShader(bounds),
                child: const Text(
                  'Confirm Bulk Delete',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Count Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Text(
                  '$count meeting${count > 1 ? 's' : ''} selected',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.red[200],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Warning Message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white.withOpacity(0.7),
                      size: 20,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This action cannot be undone.\nDeleted meetings will be permanently removed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.white.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red,
                        elevation: 8,
                        shadowColor: Colors.red.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_forever, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[900]!,
              Colors.grey[850]!,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C5CE7).withOpacity(0.3),
              blurRadius: 30,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF6C5CE7),
                    ),
                  ),
                ),
                const Icon(
                  Icons.delete_sweep_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Deleting meetings...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPremiumSnackBar({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color backgroundColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.fixed, // ✅ Changed from floating to fixed
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0), // ✅ No rounded corners for fixed
        ),
        elevation: 8,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _scrollToAppointment(MyAppointments appointment) {
    final targetHour = appointment.startTime.hour;
    final targetOffset = targetHour * 80.0; // 80.0 is your fixed slot height

    _timelineScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildQuickAppointmentList() {
    final appointmentsForDay = _getAppointmentsForDay(_selectedDate);

    if (appointmentsForDay.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: appointmentsForDay.length,
        itemBuilder: (context, index) {
          final appointment = appointmentsForDay[index];
          final colors = _getAppointmentColors(appointment);

          return GestureDetector(
            onTap: () => _scrollToAppointment(appointment),
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colors.first.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    appointment.subject,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat.jm().format(appointment.startTime),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }



  Widget _buildTimeSlots() {
    const startHour = 0;
    const endHour = 24;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    final appointmentsForDay = _getAppointmentsForDay(_selectedDate);
    final positions = _calculateEventPositions(appointmentsForDay);

    // Use fixed height slots instead of dynamic
    final timeSlots = _createFixedTimeSlots(startHour, endHour, appointmentsForDay);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[50]!,
            Colors.white,
            Colors.blue[50]!.withOpacity(0.3),
          ],
        ),
      ),
      child: SingleChildScrollView(
        controller: _timelineScrollController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: timeSlots.asMap().entries.map((entry) {
            final index = entry.key;
            final slot = entry.value;

            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 100 + (index * 50)),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: _buildFixedHeightTimeSlot(
                      slot,
                      positions,
                      appointmentsForDay,
                      isMobile,
                      isTablet,
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

// Add this class to represent a time slot

// Add this method to create dynamic time slots
  List<TimeSlot> _createFixedTimeSlots(int startHour, int endHour, List<MyAppointments> appointmentsForDay) {
    final slots = <TimeSlot>[];
    const fixedSlotHeight = 80.0; // Fixed height for all slots

    for (int hour = startHour; hour < endHour; hour++) {
      final slotTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        hour,
      );

      final isCurrentHour = DateTime.now().hour == hour &&
          DateTime.now().day == _selectedDate.day &&
          DateTime.now().month == _selectedDate.month;

      // Find appointments that intersect with this hour
      final appointmentsInHour = appointmentsForDay.where((appt) {
        return (appt.startTime.hour <= hour && appt.endTime.hour > hour) ||
            (appt.startTime.hour == hour);
      }).toList();

      slots.add(TimeSlot(
        hour: hour,
        slotTime: slotTime,
        appointments: appointmentsInHour,
        height: fixedSlotHeight, // Always fixed height
        isCurrentHour: isCurrentHour,
      ));
    }

    return slots;
  }
// Add this method to calculate overlap factor
  double _calculateOverlapFactor(List<MyAppointments> appointments) {
    if (appointments.length <= 1) return 1.0;

    // Simple overlap calculation - in reality, you might want more sophisticated logic
    int maxOverlaps = 1;

    for (int i = 0; i < appointments.length; i++) {
      int currentOverlaps = 1;
      for (int j = 0; j < appointments.length; j++) {
        if (i != j && _appointmentsOverlap(appointments[i], appointments[j])) {
          currentOverlaps++;
        }
      }
      maxOverlaps = math.max(maxOverlaps, currentOverlaps);
    }

    return math.min(
        maxOverlaps * 0.3 + 0.7, 2.0); // Scale factor between 0.7 and 2.0
  }
  Widget _buildSeamlessAppointmentTile(
      MyAppointments appt,
      TimeSlot slot,
      BoxConstraints constraints,
      Map<String, int> position,
      bool isMobile,
      List<MyAppointments> allAppointments,
      ) {
    final hourStart = DateTime(slot.slotTime.year, slot.slotTime.month, slot.slotTime.day, slot.hour);
    final hourEnd = hourStart.add(const Duration(hours: 1));

    final appointmentStartsBeforeSlot = appt.startTime.isBefore(hourStart);
    final appointmentEndsAfterSlot = appt.endTime.isAfter(hourEnd);
    final appointmentStartsInSlot = appt.startTime.hour == slot.hour;

    double topOffset = 0;
    double appointmentHeight = slot.height;

    if (appointmentStartsInSlot && !appointmentEndsAfterSlot) {
      final startOffsetMinutes = appt.startTime.difference(hourStart).inMinutes;
      final durationMinutes = appt.endTime.difference(appt.startTime).inMinutes;
      topOffset = (startOffsetMinutes / 60.0) * slot.height;
      appointmentHeight = math.max((durationMinutes / 60.0) * slot.height, 30.0);
    } else if (appointmentStartsInSlot && appointmentEndsAfterSlot) {
      final startOffsetMinutes = appt.startTime.difference(hourStart).inMinutes;
      topOffset = (startOffsetMinutes / 60.0) * slot.height;
      appointmentHeight = slot.height - topOffset;
    } else if (appointmentStartsBeforeSlot && !appointmentEndsAfterSlot) {
      topOffset = 0;
      final endOffsetMinutes = appt.endTime.difference(hourStart).inMinutes;
      appointmentHeight = (endOffsetMinutes / 60.0) * slot.height;
    } else if (appointmentStartsBeforeSlot && appointmentEndsAfterSlot) {
      topOffset = 0;
      appointmentHeight = slot.height;
    }

    final colors = _getAppointmentColors(appt);
    final totalColumns = position['cols'] ?? 1;
    final currentColumn = position['col'] ?? 0;
    final columnWidth = constraints.maxWidth / totalColumns;
    final leftOffset = currentColumn * columnWidth;
    final tileWidth = columnWidth - 2;

    // ✅ Show full name only in the starting slot
    String textToShow = '';
    bool showText = appointmentStartsInSlot;
    bool showTime = appointmentHeight >= 45; // Only show time if height is sufficient

    if (showText) {
      textToShow = appt.subject.toUpperCase();
    }

    BorderRadius borderRadius;
    if (appointmentStartsBeforeSlot && appointmentEndsAfterSlot) {
      borderRadius = BorderRadius.zero;
    } else if (appointmentStartsInSlot && appointmentEndsAfterSlot) {
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(8),
        topRight: Radius.circular(8),
      );
    } else if (appointmentStartsBeforeSlot && !appointmentEndsAfterSlot) {
      borderRadius = const BorderRadius.only(
        bottomLeft: Radius.circular(8),
        bottomRight: Radius.circular(8),
      );
    } else {
      borderRadius = BorderRadius.circular(8);
    }

    return Positioned(
      left: leftOffset + 1,
      top: topOffset,
      width: tileWidth,
      height: appointmentHeight,
      child: GestureDetector(
        onTap: () => _showAppointmentDetails(appt),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: colors.first.withOpacity(0.3),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: textToShow.isNotEmpty
                ? Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 6.0,
                vertical: appointmentHeight < 35 ? 4.0 : 6.0,
              ),
              child: appointmentHeight < 35
                  ? Center(
                child: Text(
                  textToShow,
                  style: TextStyle(
                    fontSize: isMobile ? 9 : 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                    shadows: const [
                      Shadow(
                        color: Colors.black38,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      textToShow,
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        height: 1.2,
                        shadows: const [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      maxLines: showTime ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showTime) ...[
                    const SizedBox(height: 3),
                    Text(
                      "${DateFormat.jm().format(appt.startTime)} - ${DateFormat.jm().format(appt.endTime)}",
                      style: TextStyle(
                        fontSize: isMobile ? 9 : 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            )
                : const SizedBox(),
          ),
        ),
      ),
    );
  }
// Add this new helper method for larger font sizes
  double _calculateLargeFontSize(double height, double width, bool isMobile) {
    // Base size larger for better visibility
    final baseSize = isMobile ? 16.0 : 20.0;
    final heightFactor = (height / 60).clamp(0.8, 2.0);
    final widthFactor = (width / 80).clamp(0.8, 1.5);
    return (baseSize * heightFactor * widthFactor).clamp(14.0, 32.0);
  }

  Widget _buildDistributedText(String text, double height, double width, bool isMobile, MyAppointments appt, bool showTime) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: _calculateFontSize(height, width, isMobile),
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: text.length < 5 ? 4 : 2, // More spacing for fewer characters
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              maxLines: _calculateMaxLines(height),
              overflow: TextOverflow.visible,
              textAlign: TextAlign.center,
            ),
          ),
          if (showTime) ...[
            const SizedBox(height: 2),
            Text(
              "${DateFormat.jm().format(appt.startTime)} - ${DateFormat.jm().format(appt.endTime)}",
              style: TextStyle(
                fontSize: _calculateFontSize(height, width, isMobile) - 2,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildHorizontalText(String text, bool showTime, MyAppointments appt, bool isMobile, double height, double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: _calculateFontSize(height, width, isMobile),
              fontWeight: FontWeight.w700,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            maxLines: _calculateMaxLines(height),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showTime) ...[
          const SizedBox(height: 2),
          Text(
            "${DateFormat.jm().format(appt.startTime)} - ${DateFormat.jm().format(appt.endTime)}",
            style: TextStyle(
              fontSize: _calculateFontSize(height, width, isMobile) - 2,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  double _calculateVerticalFontSize(double height, bool isMobile) {
    if (height < 100) return isMobile ? 10 : 11;
    if (height < 200) return isMobile ? 12 : 13;
    if (height < 300) return isMobile ? 14 : 15;
    return isMobile ? 16 : 18;
  }


  Widget _buildFixedHeightTimeSlot(
      TimeSlot slot,
      Map<String, Map<String, int>> positions,
      List<MyAppointments> allAppointments,
      bool isMobile,
      bool isTablet,
      ) {
    return GestureDetector(
      onTap: () {
        _showAddMeetingDialog(slot.slotTime);
      },
      child: Container(
        height: slot.height,
        margin: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 16,
          vertical: 0,
        ),
        decoration: BoxDecoration(
          gradient: slot.isCurrentHour
              ? LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF6C5CE7).withOpacity(0.05),
              Color(0xFF00CEC9).withOpacity(0.03),
              Colors.transparent,
            ],
            stops: [0.0, 0.3, 1.0],
          )
              : null,
        ),
        child: Stack(
          children: [
            // Background pattern for current hour
            if (slot.isCurrentHour)
              Positioned.fill(
                child: CustomPaint(
                  painter: _TimeSlotPatternPainter(),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHourLabel(slot.hour, slot.isCurrentHour, isMobile),
                // Vertical separator line
                Container(
                  width: 2,
                  height: slot.height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: slot.isCurrentHour
                          ? [
                        Color(0xFF6C5CE7).withOpacity(0.3),
                        Color(0xFF00CEC9).withOpacity(0.1),
                        Colors.transparent,
                      ]
                          : [
                        Colors.grey[200]!,
                        Colors.grey[100]!,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          for (final appt in slot.appointments)
                            if (positions[appt.id ?? ''] != null)
                              GestureDetector(
                                onTap: () {
                                  if (_isBulkSelectMode) {
                                    if (appt.createdBy == _loggedInAdminId) {
                                      setState(() {
                                        if (_selectedMeetingIds.contains(appt.id)) {
                                          _selectedMeetingIds.remove(appt.id);
                                        } else {
                                          _selectedMeetingIds.add(appt.id!);
                                        }
                                      });
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("You can only select your own meetings"),
                                          duration: Duration(seconds: 1),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Stack(
                                  children: [
                                    _buildSeamlessAppointmentTile(
                                      appt,
                                      slot,
                                      constraints,
                                      positions[appt.id ?? '']!,
                                      isMobile,
                                      allAppointments,
                                    ),
                                    if (_isBulkSelectMode && appt.createdBy == _loggedInAdminId)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _selectedMeetingIds.contains(appt.id)
                                                ? Colors.green
                                                : Colors.white.withOpacity(0.8),
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: _selectedMeetingIds.contains(appt.id)
                                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                                              : null,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


// Helper method to calculate appropriate font size
  double _calculateFontSize(double height, double width, bool isMobile) {
    final baseSize = isMobile ? 9.0 : 11.0;
    final heightFactor = (height / 40).clamp(0.7, 1.3);
    final widthFactor = (width / 100).clamp(0.8, 1.2);
    return (baseSize * heightFactor * widthFactor).clamp(8.0, 16.0);
  }

// Helper method to calculate max lines based on height
  int _calculateMaxLines(double height) {
    if (height < 25) return 1;
    if (height < 45) return 2;
    return 3;
  }




  Widget _buildHourLabel(int hour, bool isCurrentHour, bool isMobile) {
    // Format hour with AM/PM
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final period = hour >= 12 ? 'PM' : 'AM';

    return Container(
      width: isMobile ? 65 : 80,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hour with gradient effect for current hour
          ShaderMask(
            shaderCallback: (bounds) => isCurrentHour
                ? LinearGradient(
              colors: [
                Color(0xFF6C5CE7),
                Color(0xFF00CEC9),
              ],
            ).createShader(bounds)
                : LinearGradient(
              colors: [Colors.grey[700]!, Colors.grey[700]!],
            ).createShader(bounds),
            child: Text(
              displayHour.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: isMobile ? 18 : 22,
                fontWeight: isCurrentHour ? FontWeight.w900 : FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 2),
          // AM/PM indicator with premium styling
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 6 : 8,
              vertical: isMobile ? 2 : 3,
            ),
            decoration: BoxDecoration(
              gradient: isCurrentHour
                  ? LinearGradient(
                colors: [
                  Color(0xFF6C5CE7).withOpacity(0.2),
                  Color(0xFF00CEC9).withOpacity(0.2),
                ],
              )
                  : null,
              color: isCurrentHour ? null : Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isCurrentHour
                    ? Color(0xFF6C5CE7).withOpacity(0.3)
                    : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Text(
              period,
              style: TextStyle(
                fontSize: isMobile ? 9 : 10,
                fontWeight: FontWeight.w700,
                color: isCurrentHour ? Color(0xFF6C5CE7) : Colors.grey[600],
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (isCurrentHour) ...[
            const SizedBox(height: 4),
            // Current time indicator dot
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF6C5CE7).withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _initializeLoggedInAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    if (email != null && email.isNotEmpty) {
      setState(() {
        _loggedInAdminId = email;
      });
    }
  }

  Future<void> _fetchAdmins() async {
    final snapshot =
    await FirebaseFirestore.instance.collection('Admin_Profiles').get();
    final fetchedAdmins = <String, Map<String, dynamic>>{};
    for (var doc in snapshot.docs) {
      fetchedAdmins[doc.id] = doc.data();
    }
    setState(() {
      admins.clear();
      admins.addAll(fetchedAdmins);
    });
  }

  List<Color> _getAppointmentColors(MyAppointments appt) {
    // If appointment has a stored color, use it
    if (appt.color != null) {
      final baseColor = appt.color!;
      // Create a gradient with the stored color
      return [
        baseColor,
        Color.lerp(baseColor, Colors.black, 0.1) ?? baseColor, // Slightly darker shade
      ];
    }

    // Fallback to default colors if no color is stored
    final colorSets = [
      [Colors.purple[400]!, Colors.purple[600]!],
      [Colors.blue[400]!, Colors.blue[600]!],
      [Colors.teal[400]!, Colors.teal[600]!],
      [Colors.orange[400]!, Colors.orange[600]!],
      [Colors.pink[400]!, Colors.pink[600]!],
      [Colors.indigo[400]!, Colors.indigo[600]!],
    ];
    return colorSets[appt.id.hashCode % colorSets.length];
  }


  /// Delete a meeting (only if owned)
  Future<void> _deleteMeeting(MyAppointments appt) async {
    try {
      await FirebaseFirestore.instance
          .collection("meetings")
          .doc(appt.id)
          .delete();

      setState(() {
        _myAppointments.removeWhere((m) => m.id == appt.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Meeting deleted successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete meeting: $e")),
      );
    }
  }

  /// Groups appointments that overlap in time

  /// Show appointment details
  void _showAppointmentDetails(MyAppointments appt) {
    final isOwned = _ownsAppointment(appt);
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1024;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Appointment Details',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isMobile
                  ? screenSize.width * 0.9
                  : isTablet
                  ? 500
                  : 600,
              maxHeight: screenSize.height * 0.8,
            ),
            margin: EdgeInsets.all(isMobile ? 16 : 32),
            child: Material(
              type: MaterialType.transparency,
              child: _buildPremiumDialog(appt, isOwned, isMobile, isTablet),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumDialog(
      MyAppointments appt,
      bool isOwned,
      bool isMobile,
      bool isTablet,
      ) {
    final colors = _getAppointmentColors(appt);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[900]!,
            Colors.blueGrey[900]!,
            Colors.grey[800]!,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: colors.first.withOpacity(0.1),
            blurRadius: 40,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogHeader(appt, colors, isMobile),
            _buildDialogContent(appt, isMobile, isTablet),
            _buildDialogActions(appt, isOwned, isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(
      MyAppointments appt,
      List<Color> colors,
      bool isMobile,
      ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  appt.subject,
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white70),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              "${DateFormat('EEEE, MMM d').format(appt.startTime)}",
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.95),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogContent(
      MyAppointments appt,
      bool isMobile,
      bool isTablet,
      ) {
    return Flexible(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 20 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(
              icon: Icons.schedule_rounded,
              title: "Time",
              content:
              "${DateFormat.jm().format(appt.startTime)} - ${DateFormat.jm().format(appt.endTime)}",
              isMobile: isMobile,
            ),
            if (appt.location?.isNotEmpty ?? false) ...[
              const SizedBox(height: 16),
              _buildInfoCard(
                icon: Icons.location_on_rounded,
                title: "Location",
                content: appt.location!,
                isMobile: isMobile,
              ),
            ],
            if (appt.purpose?.isNotEmpty ?? false) ...[
              const SizedBox(height: 16),
              _buildInfoCard(
                icon: Icons.description_rounded,
                title: "Purpose",
                content: appt.purpose!,
                isMobile: isMobile,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.blue[300],
              size: isMobile ? 18 : 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white60,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogActions(
      MyAppointments appt,
      bool isOwned,
      bool isMobile,
      ) {
    if (isOwned) {
      // Use your existing _buildViewActionButtons method
      return _buildViewActionButtons(
        context: context,
        appointment: appt,
        isMobile: isMobile,
      );
    } else {
      // For non-owned appointments, show close button
      return Container(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildActionButton(
              onPressed: () => Navigator.pop(context),
              icon: Icons.close_rounded,
              label: "Close",
              isPrimary: true,
              isMobile: isMobile,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
    required bool isMobile,
    bool isDestructive = false,
  }) {
    final buttonColor = isDestructive
        ? Colors.red
        : isPrimary
        ? Colors.blue
        : Colors.grey;

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: isMobile ? 16 : 18),
      label: Text(
        label,
        style: TextStyle(
          fontSize: isMobile ? 12 : 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor.withOpacity(isPrimary ? 0.9 : 0.1),
        foregroundColor: isPrimary ? Colors.white : buttonColor[300],
        elevation: isPrimary ? 4 : 0,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 20,
          vertical: isMobile ? 10 : 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: buttonColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildViewActionButtons({
    required BuildContext context,
    required MyAppointments appointment,
    required bool isMobile,
  }) {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: isMobile
          ? Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit_rounded),
              label: const Text("Edit Meeting"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
                _showEditMeetingDialog(context, appointment);
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.delete_rounded),
              label: const Text("Delete Meeting"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.2),
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.red.withOpacity(0.4),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
                _showDeleteConfirmationDialog(context, appointment);
              },
            ),
          ),
        ],
      )
          : Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit_rounded),
                label: const Text("Edit"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showEditMeetingDialog(context, appointment);
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete_rounded),
                label: const Text("Delete"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.2),
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.red.withOpacity(0.4),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showDeleteConfirmationDialog(context, appointment);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Edit meeting dialog

  bool _ownsAppointment(MyAppointments appt) {
    if (_loggedInAdminId == null) return false;
    return _loggedInAdminId!.trim().toLowerCase() ==
        appt.adminId.trim().toLowerCase();
  }

  Future<void> _saveMeeting({
    required String subject,
    required String location,
    required String purpose,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required Color color,
    required String adminId,
  }) async {
    try {
      // Create Firestore document
      final docRef = await FirebaseFirestore.instance.collection("meetings").add({
        "subject": subject,
        "location": location,
        "purpose": purpose,
        "startTime": startDateTime,
        "endTime": endDateTime,
        "color": color.value,
        "adminId": _loggedInAdminId,
        "createdBy": _loggedInAdminId,
        "createdAt": FieldValue.serverTimestamp(),
      });

      // Create local model
      final newAppt = MyAppointments(
        id: docRef.id,
        subject: subject,
        startTime: startDateTime,
        endTime: endDateTime,
        location: location,
        purpose: purpose,
        color: color,
        adminId: _loggedInAdminId!,
        createdBy: _loggedInAdminId,
      );

      // Update local lists + map
      setState(() {
        _myAppointments.add(newAppt);
        appointmentMap[Appointment(
          startTime: newAppt.startTime,
          endTime: newAppt.endTime,
          subject: newAppt.subject,
          color: newAppt.color,
          location: newAppt.location,
          notes: newAppt.purpose,
        )] = newAppt;
      });

      // ✅ Fixed: Changed to SnackBarBehavior.fixed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Meeting created successfully!",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.fixed, // ✅ Changed from floating to fixed
          elevation: 8,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to save task: $e"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.fixed, // ✅ Changed from floating to fixed
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  Future<void> _updateMeeting(
      MyAppointments existingAppt, {
        required String subject,
        required String location,
        required String purpose,
        required DateTime startDateTime,
        required DateTime endDateTime,
        required Color color,
      }) async {
    try {
      await FirebaseFirestore.instance
          .collection('meetings')
          .doc(existingAppt.id)
          .update({
        'subject': subject,
        'location': location,
        'purpose': purpose,
        'startTime': startDateTime,
        'endTime': endDateTime,
        'color': color.value,
        'adminId': _loggedInAdminId,
      });

      // Update local state immediately after Firestore update
      final updatedAppt = MyAppointments(
        id: existingAppt.id,
        subject: subject,
        startTime: startDateTime,
        endTime: endDateTime,
        location: location,
        purpose: purpose,
        color: color, // This is the key - use the new color
        adminId: existingAppt.adminId,
        createdBy: existingAppt.createdBy,
      );

      setState(() {
        // Update the appointments list
        final index = _myAppointments.indexWhere((a) => a.id == existingAppt.id);
        if (index != -1) {
          _myAppointments[index] = updatedAppt;
        }

        // Update the appointment map
        appointmentMap.updateAll((key, value) {
          if (value.id == existingAppt.id) {
            return updatedAppt;
          }
          return value;
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Meeting updated successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update meeting: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  void _showProfileZoomView(String? profileImageUrl) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Profile View',
      barrierColor: Colors.black.withOpacity(0.9),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.elasticOut,
            ),
            child: FadeTransition(
              opacity: animation,
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  margin: const EdgeInsets.all(40),
                  constraints: const BoxConstraints(
                    maxWidth: 500,
                    maxHeight: 500,
                  ),
                  child: Stack(
                    children: [
                      // Main profile image
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF6C5CE7),
                              Color(0xFF00CEC9),
                              Color(0xFF74B9FF),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C5CE7).withOpacity(0.5),
                              blurRadius: 60,
                              spreadRadius: 10,
                            ),
                            BoxShadow(
                              color: const Color(0xFF00CEC9).withOpacity(0.3),
                              blurRadius: 40,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 200,
                            backgroundColor: Colors.grey[100],
                            backgroundImage: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                                ? NetworkImage(profileImageUrl)
                                : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                            child: (profileImageUrl == null || profileImageUrl.isEmpty)
                                ? Icon(
                              Icons.person_rounded,
                              color: Colors.grey[400],
                              size: 120,
                            )
                                : null,
                          ),
                        ),
                      ),

                      // Close button
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C5CE7).withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                            onPressed: () => Navigator.of(context).pop(),
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),

                      // Admin info overlay
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 40),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.95),
                                Colors.white.withOpacity(0.85),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)],
                                ).createShader(bounds),
                                child: Text(
                                  admins[_loggedInAdminId]?['name'] ?? 'Admin',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _loggedInAdminId ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchAndFilterBar(),
              if (_hasActiveFilters) _buildActiveFiltersChips(),
              // Show search results when searching, otherwise show calendar
              if (_searchQuery.isNotEmpty || _showOnlyMyMeetings || _filterStartDate != null || _filterEndDate != null || _filterColor != null || _filterAdminId != null)
                Expanded(child: _buildSearchResults())
              else ...[
                _buildWeekCalendar(),
                _buildQuickAppointmentList(),
                if (_isBulkSelectMode) _buildBulkActionBar(),
                Expanded(child: _buildTimeSlots()),
              ],
            ],
          )
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildSearchResults() {
    final filteredAppointments = _getAllFilteredAppointments();

    if (filteredAppointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No meetings found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // Group by date - optimized
    final groupedByDate = <String, List<MyAppointments>>{};
    for (var appt in filteredAppointments) {
      final dateKey = '${appt.startTime.year}-${appt.startTime.month}-${appt.startTime.day}';
      groupedByDate.putIfAbsent(dateKey, () => []).add(appt);
    }

    final sortedKeys = groupedByDate.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${filteredAppointments.length} meeting${filteredAppointments.length > 1 ? 's' : ''} found',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF6C5CE7)),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sortedKeys.length,
            itemBuilder: (context, index) {
              final dateKey = sortedKeys[index];
              final appointments = groupedByDate[dateKey]!;
              final date = appointments.first.startTime;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      DateFormat('EEE, MMM d, yyyy').format(date),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF2D3436)),
                    ),
                  ),
                  ...appointments.map((appt) => _buildSearchResultCard(appt)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultCard(MyAppointments appt) {
    final colors = _getAppointmentColors(appt);
    final isOwned = _ownsAppointment(appt);

    return GestureDetector(
      onTap: () {
        // ✅ Show appointment details dialog instead of just navigating
        _showAppointmentDetails(appt);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              appt.subject,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2D3436),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isOwned)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Mine',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${DateFormat.jm().format(appt.startTime)} - ${DateFormat.jm().format(appt.endTime)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (appt.location?.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  appt.location!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // ✅ Add tap indicator icon
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeNavigationBar() {
    final currentHour = DateTime.now().hour;

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTimeJumpButton("Morning", 8, Icons.wb_sunny),
          _buildTimeJumpButton("Afternoon", 14, Icons.wb_sunny_outlined),
          _buildTimeJumpButton("Evening", 18, Icons.nightlight),
          _buildTimeJumpButton("Now", currentHour, Icons.access_time),
        ],
      ),
    );
  }


  Widget _buildSearchAndFilterBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 8),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search meetings...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6C5CE7)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _showFilterDialog,
            icon: Stack(
              children: [
                const Icon(Icons.filter_list_rounded, color: Color(0xFF6C5CE7)),
                if (_hasActiveFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildActiveFiltersChips() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (_showOnlyMyMeetings)
            _buildFilterChip(
              'My Meetings',
              Icons.person,
                  () => setState(() => _showOnlyMyMeetings = false),
            ),
          if (_filterStartDate != null && _filterEndDate != null)
            _buildFilterChip(
              '${DateFormat('MMM d').format(_filterStartDate!)} - ${DateFormat('MMM d').format(_filterEndDate!)}',
              Icons.date_range,
                  () => setState(() {
                _filterStartDate = null;
                _filterEndDate = null;
              }),
            ),
          if (_filterColor != null)
            _buildFilterChip(
              'Color',
              Icons.palette,
                  () => setState(() => _filterColor = null),
              color: _filterColor,
            ),
          if (_filterAdminId != null)
            _buildFilterChip(
              admins[_filterAdminId]?['name'] ?? 'Admin',
              Icons.person_outline,
                  () => setState(() => _filterAdminId = null),
            ),
          if (_hasActiveFilters)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear All'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, VoidCallback onRemove, {Color? color}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        avatar: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color ?? const Color(0xFF6C5CE7).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 12, color: color ?? const Color(0xFF6C5CE7)),
        ),
        label: Text(label),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onRemove,
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.grey[300]!),
      ),
    );
  }

  Widget _buildBulkActionBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_selectedMeetingIds.length} selected',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          if (_selectedMeetingIds.isNotEmpty)
            ElevatedButton.icon(
              onPressed: _bulkDeleteMeetings,
              icon: const Icon(Icons.delete, size: 18),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _isBulkSelectMode = false;
                _selectedMeetingIds.clear();
              });
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    // ✅ Get unique colors from existing meetings
    Set<Color> availableColors = {};

    // Apply "My Meetings" filter first if active
    List<MyAppointments> meetingsToCheck = _showOnlyMyMeetings && _loggedInAdminId != null
        ? _myAppointments.where((appt) => appt.createdBy == _loggedInAdminId).toList()
        : _myAppointments;

    // Extract unique colors from filtered meetings
    for (var appt in meetingsToCheck) {
      if (appt.color != null) {
        availableColors.add(appt.color!);
      }
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // ✅ Recalculate available colors when "My Meetings" toggle changes
          Set<Color> currentAvailableColors = {};
          List<MyAppointments> currentMeetingsToCheck = _showOnlyMyMeetings && _loggedInAdminId != null
              ? _myAppointments.where((appt) => appt.createdBy == _loggedInAdminId).toList()
              : _myAppointments;

          for (var appt in currentMeetingsToCheck) {
            if (appt.color != null) {
              currentAvailableColors.add(appt.color!);
            }
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1a1a2e),
                    const Color(0xFF16213e),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withOpacity(0.3),
                    blurRadius: 40,
                    spreadRadius: 0,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header (keep existing)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6C5CE7),
                          const Color(0xFF8B5CF6),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.filter_alt_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Filter Meetings',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // My Meetings Toggle
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _showOnlyMyMeetings
                                    ? const Color(0xFF6C5CE7)
                                    : Colors.white.withOpacity(0.1),
                                width: 2,
                              ),
                            ),
                            child: SwitchListTile(
                              title: const Text(
                                'Show only my meetings',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              value: _showOnlyMyMeetings,
                              activeColor: const Color(0xFF6C5CE7),
                              activeTrackColor: const Color(0xFF6C5CE7).withOpacity(0.3),
                              inactiveThumbColor: Colors.grey[600],
                              inactiveTrackColor: Colors.grey[800],
                              onChanged: (value) {
                                setDialogState(() {
                                  _showOnlyMyMeetings = value;
                                  // ✅ Clear color filter if it's not available anymore
                                  if (_filterColor != null && value) {
                                    List<MyAppointments> myMeetings = _myAppointments
                                        .where((appt) => appt.createdBy == _loggedInAdminId)
                                        .toList();
                                    bool colorExists = myMeetings.any((appt) => appt.color == _filterColor);
                                    if (!colorExists) {
                                      _filterColor = null;
                                    }
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Date Range Filter (keep existing)
                          _buildSectionLabel('Date Range', Icons.date_range_rounded),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDateButton(
                                  context,
                                  setDialogState,
                                  _filterStartDate,
                                  'Start Date',
                                  true,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6C5CE7).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward,
                                    color: Color(0xFF6C5CE7),
                                    size: 16,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _buildDateButton(
                                  context,
                                  setDialogState,
                                  _filterEndDate,
                                  'End Date',
                                  false,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ✅ Color Filter - Only show available colors
                          _buildSectionLabel('Meeting Color', Icons.palette_rounded),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: currentAvailableColors.isEmpty
                                ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  _showOnlyMyMeetings
                                      ? 'No meetings with colors found'
                                      : 'No meetings available',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                                : Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: currentAvailableColors.map((color) {
                                final isSelected = _filterColor?.value == color.value;
                                return GestureDetector(
                                  onTap: () {
                                    setDialogState(() {
                                      _filterColor = isSelected ? null : color;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.transparent,
                                        width: 3,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                        BoxShadow(
                                          color: color.withOpacity(0.6),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                          : [],
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    )
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Admin Filter (keep existing)
                          _buildSectionLabel('Created By', Icons.person_rounded),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _filterAdminId,
                              dropdownColor: const Color(0xFF1a1a2e),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                prefixIcon: Icon(
                                  Icons.admin_panel_settings_rounded,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                              hint: Text(
                                'Select Admin',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('All Admins'),
                                ),
                                ...admins.entries.map((entry) {
                                  return DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(entry.value['name'] ?? entry.key),
                                  );
                                }).toList(),
                              ],
                              onChanged: (value) {
                                setDialogState(() {
                                  _filterAdminId = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Action Buttons (keep existing)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              setDialogState(() {
                                _showOnlyMyMeetings = false;
                                _filterStartDate = null;
                                _filterEndDate = null;
                                _filterColor = null;
                                _filterAdminId = null;
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 2,
                                ),
                              ),
                            ),
                            child: const Text(
                              'Clear All',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                // Filters are already applied via setDialogState
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFF6C5CE7),
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shadowColor: const Color(0xFF6C5CE7).withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'Apply Filters',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.check_circle_rounded, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6C5CE7),
                const Color(0xFF8B5CF6),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildDateButton(
      BuildContext context,
      StateSetter setDialogState,
      DateTime? date,
      String label,
      bool isStart,
      ) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Color(0xFF6C5CE7),
                  surface: Color(0xFF1a1a2e),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setDialogState(() {
            if (isStart) {
              _filterStartDate = picked;
            } else {
              _filterEndDate = picked;
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: date != null
              ? const Color(0xFF6C5CE7).withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: date != null
                ? const Color(0xFF6C5CE7)
                : Colors.white.withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: date != null
                  ? const Color(0xFF6C5CE7)
                  : Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              date != null ? DateFormat('MMM d\nyyyy').format(date) : 'Select',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeJumpButton(String label, int hour, IconData icon) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          final targetOffset = hour * 80.0;
          _timelineScrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: const Color(0xFF6C5CE7)),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6C5CE7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final adminData =
    _loggedInAdminId != null ? admins[_loggedInAdminId] : null;
    final profileImageUrl = adminData?['image'];
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      margin: EdgeInsets.all(isMobile ? 12 : 16),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 16 : 20,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF8F9FA),
            Color(0xFFE3F2FD),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.1),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            spreadRadius: -4,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.9),
            blurRadius: 1,
            spreadRadius: 0,
            offset: const Offset(-1, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildPremiumBackButton(isMobile),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(child: _buildPremiumTitle(isMobile)),
          SizedBox(width: isMobile ? 12 : 16),
          _buildHeaderActions(profileImageUrl, isMobile),
        ],
      ),
    );
  }

  Widget _buildPremiumTitle(bool isMobile) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          Color(0xFF6C5CE7),
          Color(0xFF00CEC9),
          Color(0xFF6C5CE7),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(bounds),
      child: Text(
        'Task Schedule',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: isMobile ? 20 : 24,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.5,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderActions(String? profileImageUrl, bool isMobile) {
    return Row(
      children: [
        _buildPremiumProfile(profileImageUrl, isMobile),
      ],
    );
  }



  Widget _buildPremiumProfile(String? profileImageUrl, bool isMobile) {
    return GestureDetector(
      onTap: () {
        _showProfileZoomView(profileImageUrl);
      },
      child: Container(
        width: isMobile ? 48 : 52,
        height: isMobile ? 48 : 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6C5CE7),
              Color(0xFF00CEC9),
              Color(0xFF74B9FF),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C5CE7).withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 1,
              offset: const Offset(-2, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: isMobile ? 20 : 22,
            backgroundColor: Colors.grey[100],
            backgroundImage:
            (profileImageUrl != null && profileImageUrl.isNotEmpty)
                ? NetworkImage(profileImageUrl)
                : const AssetImage('assets/images/default_avatar.png')
            as ImageProvider,
            child: (profileImageUrl == null || profileImageUrl.isEmpty)
                ? Icon(
              Icons.person_rounded,
              color: Colors.grey[400],
              size: isMobile ? 24 : 28,
            )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumBackButton(bool isMobile) {
    return Container(
      width: isMobile ? 44 : 48,
      height: isMobile ? 44 : 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 1,
            offset: const Offset(-1, -1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).pop(),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: isMobile ? 18 : 20,
            color: const Color(0xFF2D3436),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekCalendar() {
    final DateTime now = DateTime.now();
    final int initialPage = 10000;
    final PageController _pageController =
    PageController(initialPage: initialPage);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      height: isMobile ? 130 : 150,
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF8F9FA),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.8),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C5CE7).withOpacity(0.08),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              spreadRadius: -2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: PageView.builder(
          controller: _pageController,
          itemBuilder: (context, index) {
            final int weekOffset = index - initialPage;
            final DateTime currentWeekStart = now.subtract(
              Duration(days: now.weekday % 7),
            );
            final DateTime weekStart =
            currentWeekStart.add(Duration(days: weekOffset * 7));
            final DateTime midWeek = weekStart.add(const Duration(days: 3));
            final String monthName =
                "${_monthNames[midWeek.month - 1]} ${midWeek.year}";

            return Column(
              children: [
                _buildMonthHeader(monthName, isMobile),
                Expanded(child: _buildWeekDays(weekStart, now, isMobile)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMonthHeader(String monthName, bool isMobile) {
    return Container(
      padding: EdgeInsets.only(
        top: isMobile ? 16 : 20,
        bottom: isMobile ? 12 : 16,
      ),
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [
            Color(0xFF6C5CE7),
            Color(0xFF00CEC9),
          ],
        ).createShader(bounds),
        child: Text(
          monthName,
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildWeekDays(DateTime weekStart, DateTime now, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (dayIndex) {
          final date = weekStart.add(Duration(days: dayIndex));
          final isSelected = _selectedDate.day == date.day &&
              _selectedDate.month == date.month &&
              _selectedDate.year == date.year;
          final isToday = now.day == date.day &&
              now.month == date.month &&
              now.year == date.year;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  ['S', 'M', 'T', 'W', 'T', 'F', 'S'][dayIndex],
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 10 : 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isToday
                        ? const Color(0xFF6C5CE7)
                        : const Color(0xFF636E72)),
                  ),
                ),
                SizedBox(height: isMobile ? 4 : 6),
                Container(
                  width: isMobile ? 28 : 32,
                  height: isMobile ? 28 : 32,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : (isToday
                        ? const Color(0xFF6C5CE7).withOpacity(0.1)
                        : Colors.transparent),
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      date.day.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? const Color(0xFF6C5CE7)
                            : (isToday
                            ? const Color(0xFF6C5CE7)
                            : const Color(0xFF2D3436)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

// Helper for month names
  final List<String> _monthNames = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
  ];

  void _showAddMeetingDialog(
      DateTime selectedDate, {
        MyAppointments? existingAppt, // 👈 Add or Edit
      }) async {
    // 🔒 Access Restriction
// At the top of _showAddMeetingDialog - Access denied messages
    if (_loggedInAdminId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to determine logged-in admin."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.fixed, // ✅ Add this
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (existingAppt != null && existingAppt.adminId != _loggedInAdminId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Access denied: You can only edit your own meetings."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.fixed, // ✅ Add this
        ),
      );
      return;
    }
    // Controllers
    final TextEditingController _subjectController =
    TextEditingController(text: existingAppt?.subject ?? "");
    final TextEditingController _locationController =
    TextEditingController(text: existingAppt?.location ?? "");
    final TextEditingController _purposeController =
    TextEditingController(text: existingAppt?.purpose ?? "");

    // Time values
    TimeOfDay _startTime = existingAppt != null
        ? TimeOfDay.fromDateTime(existingAppt.startTime)
        : TimeOfDay.fromDateTime(selectedDate);

    TimeOfDay _endTime = existingAppt != null
        ? TimeOfDay.fromDateTime(existingAppt.endTime)
        : _startTime.replacing(hour: (_startTime.hour + 1) % 24);

    Color selectedColor = existingAppt?.color ?? Colors.deepPurple;

    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final screenSize = MediaQuery.of(context).size;
            final isTablet = screenSize.width > 600;
            final isMobile = screenSize.width < 480;

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(
                horizontal: isMobile
                    ? 16
                    : isTablet
                    ? 40
                    : 80,
                vertical: isMobile ? 20 : 40,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 600 : 500,
                  maxHeight: screenSize.height * 0.9,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.08),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Gradient Header
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 16 : 20,
                              horizontal: isMobile ? 16 : 24,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.deepPurple.shade600,
                                  Colors.deepPurple.shade800,
                                  Colors.indigo.shade700,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.event_available_rounded,
                                    color: Colors.white,
                                    size: isMobile ? 22 : 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        existingAppt == null
                                            ? "Add New Meeting"
                                            : "Edit Meeting",
                                        style: TextStyle(
                                          fontSize: isMobile ? 18 : 22,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('EEEE, MMM dd, yyyy')
                                            .format(selectedDate),
                                        style: TextStyle(
                                          fontSize: isMobile ? 12 : 13,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.close_rounded,
                                      color: Colors.white),
                                ),
                              ],
                            ),
                          ),

                          // Scrollable content
                          Flexible(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.all(isMobile ? 16 : 24),
                              child: Form(
                                key: _formKey,
                                autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionHeader("Meeting Details",
                                        Icons.info_outline_rounded),
                                    const SizedBox(height: 16),

                                    _buildEnhancedTextField(
                                      context: context,
                                      controller: _subjectController,
                                      label: "Subject",
                                      icon: Icons.title,
                                      hint: "Enter meeting subject",
                                      isMobile: isMobile,
                                    ),
                                    SizedBox(height: isMobile ? 16 : 20),
                                    _buildEnhancedTextField(
                                      context: context,
                                      controller: _locationController,
                                      label: "Location",
                                      icon: Icons.location_on,
                                      hint: "Enter meeting location",
                                      isMobile: isMobile,
                                    ),
                                    SizedBox(height: isMobile ? 16 : 20),
                                    _buildEnhancedTextField(
                                      context: context,
                                      controller: _purposeController,
                                      label: "Purpose",
                                      icon: Icons.event_note,
                                      hint: "Enter meeting purpose",
                                      maxLines: 3,
                                      isMobile: isMobile,
                                    ),
                                    SizedBox(height: isMobile ? 24 : 32),

                                    _buildSectionHeader("Time & Settings",
                                        Icons.access_time_rounded),
                                    const SizedBox(height: 16),

                                    _buildTimePickers(
                                      context: context,
                                      startTime: _startTime,
                                      endTime: _endTime,
                                      onStartTimePicked: (picked) =>
                                      _startTime = picked,
                                      onEndTimePicked: (picked) =>
                                      _endTime = picked,
                                      selectedDate: selectedDate,
                                      isMobile: isMobile,
                                    ),

                                    SizedBox(height: isMobile ? 20 : 24),

                                    _buildEnhancedColorPicker(
                                      context: context,
                                      selectedColor: selectedColor,
                                      isMobile: isMobile,
                                      onColorChanged: (color) {
                                        setState(() {
                                          selectedColor = color;
                                        });
                                      },
                                    ),

                                    SizedBox(height: isMobile ? 24 : 32),

                                    // Save/Cancel/Delete Buttons
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (existingAppt != null)
                                          TextButton.icon(
                                            onPressed: () async {
                                              await _deleteMeeting(
                                                  existingAppt);
                                              Navigator.pop(context);
                                            },
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            label: const Text("Delete",
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ),
                                        const Spacer(),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text("Cancel"),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              if (existingAppt == null) {
                                                await _saveMeeting(
                                                  subject:
                                                  _subjectController.text,
                                                  location:
                                                  _locationController.text,
                                                  purpose:
                                                  _purposeController.text,
                                                  startDateTime: DateTime(
                                                    selectedDate.year,
                                                    selectedDate.month,
                                                    selectedDate.day,
                                                    _startTime.hour,
                                                    _startTime.minute,
                                                  ),
                                                  endDateTime: DateTime(
                                                    selectedDate.year,
                                                    selectedDate.month,
                                                    selectedDate.day,
                                                    _endTime.hour,
                                                    _endTime.minute,
                                                  ),
                                                  color: selectedColor,
                                                  adminId: _loggedInAdminId!,
                                                );
                                              } else {
                                                await _updateMeeting(
                                                  existingAppt,
                                                  subject:
                                                  _subjectController.text,
                                                  location:
                                                  _locationController.text,
                                                  purpose:
                                                  _purposeController.text,
                                                  startDateTime: DateTime(
                                                    selectedDate.year,
                                                    selectedDate.month,
                                                    selectedDate.day,
                                                    _startTime.hour,
                                                    _startTime.minute,
                                                  ),
                                                  endDateTime: DateTime(
                                                    selectedDate.year,
                                                    selectedDate.month,
                                                    selectedDate.day,
                                                    _endTime.hour,
                                                    _endTime.minute,
                                                  ),
                                                  color: selectedColor,
                                                );
                                              }
                                              Navigator.pop(context);
                                            }
                                          },
                                          icon: const Icon(Icons.check),
                                          label: Text(existingAppt == null
                                              ? "Save"
                                              : "Update"),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
            letterSpacing: 0.3,
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(left: 16),
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePickers({
    required BuildContext context,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required Function(TimeOfDay) onStartTimePicked,
    required Function(TimeOfDay) onEndTimePicked,
    required DateTime selectedDate,
    required bool isMobile,
  }) {
    if (isMobile) {
      return Column(
        children: [
          // Start Time
          _buildEnhancedTimePicker(
            label: "Start Time",
            time: startTime,
            context: context,
            isMobile: isMobile,
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: startTime,
                builder: (context, child) => Theme(
                  data: ThemeData.light().copyWith(
                    colorScheme:
                    const ColorScheme.light(primary: Colors.deepPurple),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                onStartTimePicked(picked);

                // ✅ Auto-focus End Time
                Future.delayed(const Duration(milliseconds: 200), () {
                  FocusScope.of(context).nextFocus();
                });
              }
            },
          ),
          const SizedBox(height: 16),
          // End Time
          _buildEnhancedTimePicker(
            label: "End Time",
            time: endTime,
            context: context,
            isMobile: isMobile,
            isLast: true,
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: endTime,
              );
              if (picked != null) {
                final pickedDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  picked.hour,
                  picked.minute,
                );
                final startDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  startTime.hour,
                  startTime.minute,
                );

                if (pickedDateTime.isBefore(startDateTime) ||
                    pickedDateTime.isAtSameMomentAs(startDateTime)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("End time must be after start time."),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                onEndTimePicked(picked);
              }
            },
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: _buildEnhancedTimePicker(
              label: "Start Time",
              time: startTime,
              context: context,
              isMobile: isMobile,
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: startTime,
                  builder: (context, child) => Theme(
                    data: ThemeData.light().copyWith(
                      colorScheme:
                      const ColorScheme.light(primary: Colors.deepPurple),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) onStartTimePicked(picked);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildEnhancedTimePicker(
              label: "End Time",
              time: endTime,
              context: context,
              isMobile: isMobile,
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: endTime,
                );
                if (picked != null) {
                  final pickedDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    picked.hour,
                    picked.minute,
                  );
                  final startDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    startTime.hour,
                    startTime.minute,
                  );
                  if (pickedDateTime.isBefore(startDateTime) ||
                      pickedDateTime.isAtSameMomentAs(startDateTime)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("End time must be after start time."),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  onEndTimePicked(picked);
                }
              },
            ),
          ),
        ],
      );
    }
  }

  Widget _buildFloatingActionButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (!_isBulkSelectMode)
          FloatingActionButton(
            heroTag: 'bulk_select',
            mini: true,
            onPressed: () {
              setState(() {
                _isBulkSelectMode = !_isBulkSelectMode;
                _selectedMeetingIds.clear();
              });
            },
            backgroundColor: Colors.orange,
            child: Icon(
              _isBulkSelectMode ? Icons.close : Icons.checklist_rounded,
              color: Colors.white,
            ),
          ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C5CE7).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton(
            heroTag: 'add_meeting',
            onPressed: () => _showAddMeetingDialog(_selectedDate),
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }


  void _showEditMeetingDialog(BuildContext context, MyAppointments myAppt) {
    // Ownership check
    if (!_ownsAppointment(myAppt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Access denied: You can only edit your own meetings."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final parentContext = context;

    final subjectController = TextEditingController(text: myAppt.subject);
    final locationController =
    TextEditingController(text: myAppt.location ?? "");
    final purposeController = TextEditingController(text: myAppt.purpose ?? "");

    TimeOfDay startTime = TimeOfDay.fromDateTime(myAppt.startTime);
    TimeOfDay endTime = TimeOfDay.fromDateTime(myAppt.endTime);
    Color selectedColor = myAppt.color;

    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: parentContext,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, dialogSetState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              elevation: 24,
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(dialogContext).size.width > 600 ? 100 : 20,
                vertical: 40,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 600,
                  maxHeight: MediaQuery.of(dialogContext).size.height * 0.9,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.grey.shade50,
                      Colors.white,
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 40,
                      offset: Offset(0, 20),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Color(0xFF6A5AE0).withOpacity(0.1),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                      spreadRadius: 0,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.8),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(dialogContext).viewInsets.bottom,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(
                        MediaQuery.of(dialogContext).size.width > 600 ? 40 : 24,
                      ),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header Section
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF6A5AE0).withOpacity(0.1),
                                    Color(0xFF9C88FF).withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFF6A5AE0), Color(0xFF9C88FF)],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0xFF6A5AE0).withOpacity(0.3),
                                          blurRadius: 20,
                                          offset: Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.edit_calendar_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    "Edit Meeting",
                                    style: TextStyle(
                                      fontSize: MediaQuery.of(dialogContext).size.width > 600 ? 28 : 24,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2D1B69),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Modify your meeting details",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 32),

                            // Form Fields Section
                            _buildPremiumTextField(
                              label: "Meeting Subject",
                              controller: subjectController,
                              icon: Icons.title_rounded,
                              context: dialogContext,
                            ),

                            SizedBox(height: 20),

                            _buildPremiumTextField(
                              label: "Meeting Location",
                              controller: locationController,
                              icon: Icons.location_on_rounded,
                              context: dialogContext,
                            ),

                            SizedBox(height: 20),

                            _buildPremiumTextField(
                              label: "Meeting Purpose",
                              controller: purposeController,
                              icon: Icons.assignment_turned_in_rounded,
                              maxLines: 3,
                              context: dialogContext,
                            ),

                            SizedBox(height: 32),

                            // Time Selection Section
                            Container(
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Color(0xFF6A5AE0).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.access_time_rounded,
                                          color: Color(0xFF6A5AE0),
                                          size: 20,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        "Time Schedule",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2D1B69),
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 20),

                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      if (constraints.maxWidth > 400) {
                                        return Row(
                                          children: [
                                            Expanded(
                                              child: _buildPremiumTimePicker(
                                                label: 'Start Time',
                                                time: startTime,
                                                context: dialogContext,
                                                onChanged: (picked) {
                                                  dialogSetState(() {
                                                    startTime = picked;
                                                    if (_compareTime(endTime, startTime) <= 0) {
                                                      endTime = _addMinutes(startTime, 30);
                                                    }
                                                  });
                                                },
                                              ),
                                            ),
                                            SizedBox(width: 20),
                                            Expanded(
                                              child: _buildPremiumTimePicker(
                                                label: 'End Time',
                                                time: endTime,
                                                context: dialogContext,
                                                onChanged: (picked) {
                                                  dialogSetState(() {
                                                    endTime = picked;
                                                    if (_compareTime(endTime, startTime) <= 0) {
                                                      startTime = _addMinutes(endTime, -30);
                                                    }
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        );
                                      } else {
                                        return Column(
                                          children: [
                                            _buildPremiumTimePicker(
                                              label: 'Start Time',
                                              time: startTime,
                                              context: dialogContext,
                                              onChanged: (picked) {
                                                dialogSetState(() {
                                                  startTime = picked;
                                                  if (_compareTime(endTime, startTime) <= 0) {
                                                    endTime = _addMinutes(startTime, 30);
                                                  }
                                                });
                                              },
                                            ),
                                            SizedBox(height: 16),
                                            _buildPremiumTimePicker(
                                              label: 'End Time',
                                              time: endTime,
                                              context: dialogContext,
                                              onChanged: (picked) {
                                                dialogSetState(() {
                                                  endTime = picked;
                                                  if (_compareTime(endTime, startTime) <= 0) {
                                                    startTime = _addMinutes(endTime, -30);
                                                  }
                                                });
                                              },
                                            ),
                                          ],
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 32),

                            Container(
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: selectedColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.palette_rounded,
                                          color: selectedColor,
                                          size: 20,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        "Meeting Color",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2D1B69),
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 20),

                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: dialogContext,
                                        builder: (colorPickerContext) {
                                          Color tempSelectedColor = selectedColor;

                                          return StatefulBuilder(
                                            builder: (context, setColorPickerState) {
                                              return AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(24),
                                                ),
                                                title: Text(
                                                  "Pick Meeting Color",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF2D1B69),
                                                  ),
                                                ),
                                                content: SingleChildScrollView(
                                                  child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      // Preview of selected color
                                                      Container(
                                                        width: 60,
                                                        height: 60,
                                                        margin: EdgeInsets.only(bottom: 20),
                                                        decoration: BoxDecoration(
                                                          color: tempSelectedColor,
                                                          borderRadius: BorderRadius.circular(16),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: tempSelectedColor.withOpacity(0.3),
                                                              blurRadius: 8,
                                                              offset: Offset(0, 4),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      // Color picker
                                                      BlockPicker(
                                                        pickerColor: tempSelectedColor,
                                                        onColorChanged: (color) {
                                                          setColorPickerState(() {
                                                            tempSelectedColor = color;
                                                          });
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.of(colorPickerContext).pop(),
                                                    child: Text(
                                                      "Cancel",
                                                      style: TextStyle(color: Colors.grey.shade600),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      // Update the main dialog state
                                                      dialogSetState(() {
                                                        selectedColor = tempSelectedColor;
                                                      });
                                                      Navigator.of(colorPickerContext).pop();
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: tempSelectedColor,
                                                      foregroundColor: Colors.white,
                                                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      "Select Color",
                                                      style: TextStyle(fontWeight: FontWeight.w600),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: selectedColor.withOpacity(0.3),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: selectedColor.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: selectedColor,
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: selectedColor.withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Meeting Color",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey.shade800,
                                                  ),
                                                ),
                                                Text(
                                                  "Tap to change color",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            color: Colors.grey.shade400,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 40),

                            // Action Buttons
                            LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth > 400) {
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: _buildSecondaryButton(
                                          onPressed: () => Navigator.of(dialogContext).pop(),
                                          text: "Cancel",
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        flex: 2,
                                        child: _buildPrimaryButton(
                                          onPressed: () async {
                                            if (!_formKey.currentState!.validate()) return;

                                            final startDateTime = DateTime(
                                              myAppt.startTime.year,
                                              myAppt.startTime.month,
                                              myAppt.startTime.day,
                                              startTime.hour,
                                              startTime.minute,
                                            );
                                            final endDateTime = DateTime(
                                              myAppt.endTime.year,
                                              myAppt.endTime.month,
                                              myAppt.endTime.day,
                                              endTime.hour,
                                              endTime.minute,
                                            );

                                            if (endDateTime.isBefore(startDateTime)) {
                                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                                const SnackBar(
                                                  content: Text("End time must be after start time."),
                                                  backgroundColor: Colors.redAccent,
                                                ),
                                              );
                                              return;
                                            }

                                            // Close dialog first
                                            Navigator.of(dialogContext).pop();

// Then update the meeting
                                            await _updateMeeting(
                                              myAppt,
                                              subject: subjectController.text.trim(),
                                              location: locationController.text.trim(),
                                              purpose: purposeController.text.trim(),
                                              startDateTime: startDateTime,
                                              endDateTime: endDateTime,
                                              color: selectedColor,
                                            );
                                          },
                                          text: "Save Changes",
                                        ),

                                      ),
                                    ],
                                  );
                                } else {
                                  return Column(
                                    children: [
                                      _buildPrimaryButton(
                                        onPressed: () async {
                                          if (!_formKey.currentState!.validate()) return;

                                          final startDateTime = DateTime(
                                            myAppt.startTime.year,
                                            myAppt.startTime.month,
                                            myAppt.startTime.day,
                                            startTime.hour,
                                            startTime.minute,
                                          );
                                          final endDateTime = DateTime(
                                            myAppt.endTime.year,
                                            myAppt.endTime.month,
                                            myAppt.endTime.day,
                                            endTime.hour,
                                            endTime.minute,
                                          );

                                          if (endDateTime.isBefore(startDateTime)) {
                                            ScaffoldMessenger.of(parentContext).showSnackBar(
                                              const SnackBar(
                                                content: Text("End time must be after start time."),
                                                backgroundColor: Colors.redAccent,
                                              ),
                                            );
                                            return;
                                          }

                                          // Close dialog first
                                          Navigator.of(dialogContext).pop();

// Then update the meeting
                                          await _updateMeeting(
                                            myAppt,
                                            subject: subjectController.text.trim(),
                                            location: locationController.text.trim(),
                                            purpose: purposeController.text.trim(),
                                            startDateTime: startDateTime,
                                            endDateTime: endDateTime,
                                            color: selectedColor,
                                          );
                                        },
                                        text: "Save Changes",
                                      ),

                                      SizedBox(height: 12),
                                      _buildSecondaryButton(
                                        onPressed: () => Navigator.of(dialogContext).pop(),
                                        text: "Cancel",
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPremiumTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required BuildContext context,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D1B69),
            letterSpacing: 0.2,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D1B69),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
          decoration: InputDecoration(
            prefixIcon: Container(
              margin: EdgeInsets.all(12),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF6A5AE0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Color(0xFF6A5AE0),
                size: 20,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Color(0xFF6A5AE0), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red.shade400, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red.shade400, width: 2),
            ),
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumTimePicker({
    required String label,
    required TimeOfDay time,
    required BuildContext context,
    required Function(TimeOfDay) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D1B69),
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: time,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    timePickerTheme: TimePickerThemeData(
                      backgroundColor: Colors.white,
                      hourMinuteShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      dayPeriodShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              onChanged(picked);
            }
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time.format(context),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D1B69),
                  ),
                ),
                Icon(
                  Icons.access_time_rounded,
                  color: Color(0xFF6A5AE0),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback onPressed,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF6A5AE0),
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: Color(0xFF6A5AE0).withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save_rounded, size: 22),
            SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required VoidCallback onPressed,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Color(0xFF6A5AE0),
          side: BorderSide(color: Color(0xFF6A5AE0), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

// Save Handler Method

  bool isGibberish(String input) {
    final trimmed = input.trim();

    // Reject empty input
    if (trimmed.isEmpty) return true;

    // Split into words
    final words = trimmed.split(RegExp(r'\s+'));

    // Require at least one non-empty word with 2+ characters
    if (!words.any((word) => word.length >= 2)) return true;

    // Require at least one vowel
    if (!RegExp(r'[aeiouAEIOU]').hasMatch(trimmed)) return true;

    // Reject if contains 4+ consonants in a row (e.g., 'xdfgh')
    if (RegExp(r'[bcdfghjklmnpqrstvwxyz]{4,}', caseSensitive: false).hasMatch(trimmed)) return true;

    // Reject if too short (less than 8 characters total)
    if (trimmed.length < 8) return true;

    // Reject if too numeric (more than 40% digits)
    final digitCount = RegExp(r'\d').allMatches(trimmed).length;
    final ratio = digitCount / trimmed.length;
    if (ratio > 0.4) return true;

    // Reject if all words are 1 character or less
    if (words.every((word) => word.length < 2)) return true;

    return false; // Valid input
  }

  /// helper: compare two times
  int _compareTime(TimeOfDay a, TimeOfDay b) =>
      (a.hour * 60 + a.minute) - (b.hour * 60 + b.minute);

  /// helper: add minutes to a time
  TimeOfDay _addMinutes(TimeOfDay t, int minutes) {
    final total = t.hour * 60 + t.minute + minutes;
    return TimeOfDay(hour: (total ~/ 60) % 24, minute: total % 60);
  }

  Widget _buildEnhancedTimePicker({
    required String label,
    required TimeOfDay time,
    required BuildContext context,
    required bool isMobile,
    required VoidCallback onPressed,
    bool isLast = false, // 👈 last field ma Done button show karva mate
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 14 : 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          readOnly: true,
          // 👈 user type na kare, only picker open thay
          controller: TextEditingController(text: time.format(context)),
          textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
          onTap: onPressed,
          // 👈 tap kare to picker open
          onEditingComplete: () => isLast
              ? FocusScope.of(context).unfocus()
              : FocusScope.of(context).nextFocus(),
          style: TextStyle(
            fontSize: isMobile ? 15 : 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
          decoration: InputDecoration(
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.schedule_rounded,
                size: 20,
                color: Colors.deepPurple,
              ),
            ),
            suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValidatedTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputAction inputAction = TextInputAction.next,
    VoidCallback? onEditingComplete,
    required bool filled, // required
  }) {
    return TextFormField(
      controller: controller,
      textInputAction: inputAction,
      onEditingComplete: onEditingComplete ??
              () {
            if (inputAction == TextInputAction.next) {
              FocusScope.of(context).nextFocus();
            } else {
              FocusScope.of(context).unfocus();
            }
          },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Please enter $label";
        }
        if (isGibberish(value.trim())) {
          return "Please enter a valid and meaningful $label";
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            fontWeight: FontWeight.w600, color: Colors.deepPurple),
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        filled: filled,
        // ✅ correct placement
        fillColor: filled ? Colors.deepPurple.shade50 : null,
        // ✅ correct
        contentPadding:
        const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      style: const TextStyle(fontSize: 16, color: Colors.black87),
    );
  }

  Widget _buildEnhancedTextField({
    required BuildContext context, // 👈 Add this
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required bool isMobile,
    int? maxLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 14 : 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          textInputAction: TextInputAction.next,
          // 👈 Shows Next button in keyboard
          onEditingComplete: () => FocusScope.of(context).nextFocus(),
          // 👈 Moves to next field
          maxLines: maxLines ?? 1,
          style: TextStyle(
            fontSize: isMobile ? 14 : 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Colors.deepPurple,
              ),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: isMobile ? 13 : 14,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: maxLines != null ? 16 : 12,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter $label';
            }
            if (isGibberish(value)) {
              return 'Please enter meaningful text for $label';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay time,
    required BuildContext
    safeContext, // use parentContext here, not dialogContext
    required Function(TimeOfDay) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3436),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showTimePicker(
              context: safeContext, // picker opens fine
              initialTime: time,
            );
            if (picked != null) {
              onChanged(picked);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Color(0xFF6C5CE7)),
                const SizedBox(width: 12),
                Text(
                  time.format(Navigator.of(safeContext)
                      .context), // ✅ ensure valid context
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF2D3436),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedColorPicker({
    required Color selectedColor,
    required BuildContext context,
    required bool isMobile,
    required ValueChanged<Color> onColorChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Meeting Color",
          style: TextStyle(
            fontSize: isMobile ? 14 : 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
// In your _buildEnhancedColorPicker method, replace the InkWell onTap with this:

          onTap: () {
            Color tempColor = selectedColor;
            showDialog(
              context: context,
              builder: (ctx) => StatefulBuilder(
                builder: (context, setColorState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    "Pick Meeting Color",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  content: SingleChildScrollView(
                    child: BlockPicker(
                      pickerColor: tempColor,
                      onColorChanged: (color) {
                        setColorState(() {
                          tempColor = color;
                        });
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onColorChanged(tempColor);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Select"),
                    ),
                  ],
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 14 : 16,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.palette_rounded,
                    size: 20,
                    color: Colors.deepPurple,
                  ),
                ),
                Expanded(
                  child: Text(
                    "Tap to select color",
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 15,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext rootContext, MyAppointments myAppt) {
    if (!_ownsAppointment(myAppt)) {
      ScaffoldMessenger.of(rootContext).showSnackBar(
        const SnackBar(
          content: Text("Access denied: You can only delete your own appointments."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.fixed, // ✅ Changed to fixed
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    showDialog(
      context: rootContext,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 20,
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 480),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF232526), Color(0xFF414345)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 36),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Confirm Delete",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "Are you sure you want to delete this appointment?\nThis action cannot be undone.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.cancel, color: Colors.white),
                        label: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          side: BorderSide(color: Colors.white.withOpacity(0.6), width: 1.2),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.delete_forever, color: Colors.white),
                        label: const Text(
                          "Delete",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          shadowColor: Colors.black54,
                          elevation: 6,
                        ),
                        onPressed: () async {
                          try {
                            await FirebaseFirestore.instance
                                .collection("meetings")
                                .doc(myAppt.id)
                                .delete();

                            if (mounted) {
                              setState(() {
                                appointmentMap.removeWhere((_, v) => v.id == myAppt.id);
                                _myAppointments.removeWhere((appt) => appt.id == myAppt.id);
                              });
                            }

                            Navigator.of(dialogContext).pop();

                            // ✅ Success SnackBar - fixed behavior
                            Future.delayed(const Duration(milliseconds: 100), () {
                              if (mounted) {
                                ScaffoldMessenger.of(rootContext).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: const [
                                        Icon(Icons.check_circle, color: Colors.white),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            "Appointment deleted successfully!",
                                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 3),
                                    behavior: SnackBarBehavior.fixed, // ✅ Changed to fixed
                                  ),
                                );
                              }
                            });
                          } catch (e, st) {
                            if (Navigator.of(dialogContext).canPop()) {
                              Navigator.of(dialogContext).pop();
                            }

                            // ✅ Error SnackBar - fixed behavior
                            ScaffoldMessenger.of(rootContext).showSnackBar(
                              SnackBar(
                                content: Text("Failed to delete appointment: $e"),
                                backgroundColor: Colors.redAccent,
                                duration: const Duration(seconds: 3),
                                behavior: SnackBarBehavior.fixed, // ✅ Changed to fixed
                              ),
                            );

                            debugPrint("Delete Error: $e\n$st");
                          }
                        },
                      ),
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
}

class TimeSlot {
  final int hour;
  final DateTime slotTime;
  final List<MyAppointments> appointments;
  final double height;
  final bool isCurrentHour;

  TimeSlot({
    required this.hour,
    required this.slotTime,
    required this.appointments,
    required this.height,
    required this.isCurrentHour,
  });
}
class _TimeEvent {
  final DateTime time;
  final bool isStart;
  final MyAppointments appointment;

  _TimeEvent(this.time, this.isStart, this.appointment);
}
class _TimeSlotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Color(0xFF6C5CE7).withOpacity(0.02),
          Color(0xFF00CEC9).withOpacity(0.01),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Draw subtle diagonal lines
    final path = Path();
    for (double i = -size.height; i < size.width; i += 30) {
      path.moveTo(i, 0);
      path.lineTo(i + size.height, size.height);
    }

    final linePaint = Paint()
      ..color = Color(0xFF6C5CE7).withOpacity(0.02)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
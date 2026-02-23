import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class TaskDataSource extends CalendarDataSource {
  TaskDataSource(List<Appointment> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) => appointments![index].startTime;

  @override
  DateTime getEndTime(int index) => appointments![index].endTime;

  @override
  String getSubject(int index) => appointments![index].subject;

  @override
  Color getColor(int index) => appointments![index].color;

  @override
  bool isAllDay(int index) => appointments![index].isAllDay;
}

class TaskCalendarPage extends StatefulWidget {
  const TaskCalendarPage({Key? key}) : super(key: key);

  @override
  State<TaskCalendarPage> createState() => _TaskCalendarPageState();
}

class _TaskCalendarPageState extends State<TaskCalendarPage>
    with TickerProviderStateMixin {
  late Stream<TaskDataSource> _appointmentsStream;
  CalendarView _calendarView = CalendarView.week;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  Appointment? _selectedAppointment;
  bool _showCard = false;
  Appointment? _visibleAppointment;
  List<OverlayEntry> _activeBubbles = [];
  final GlobalKey _calendarKey = GlobalKey();
  final Map<Appointment, GlobalKey> _appointmentKeys = {};
  final Map<Appointment, LayerLink> _appointmentLinks = {};

  // Enhanced filtering
  String _statusFilter = 'All';
  String _departmentFilter = 'All';
  String _employeeFilter = 'All';
  List<Appointment> _allAppointments = [];
  double _timeIntervalHeight = 120.0;
  bool _isDarkMode = false;

  // Theme colors
  late ColorScheme _colorScheme;
  late TextTheme _textTheme;

  final List<Color> taskColors = [
    const Color(0xFF6366F1), // Indigo
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEC4899), // Pink
    const Color(0xFFEF4444), // Red
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF10B981), // Emerald
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF7C3AED), // Violet
    const Color(0xFFF97316), // Orange
  ];

  @override
  void initState() {
    super.initState();
    _appointmentsStream = _createAppointmentsStream();


    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeInOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _colorScheme = _isDarkMode
        ? const ColorScheme.dark(
      primary: Color(0xFF6366F1),
      secondary: Color(0xFF8B5CF6),
      surface: Color(0xFF1F2937),
      background: Color(0xFF111827),
      onSurface: Color(0xFFE5E7EB),
      onBackground: Color(0xFFF9FAFB),
    )
        : const ColorScheme.light(
      primary: Color(0xFF6366F1),
      secondary: Color(0xFF8B5CF6),
      surface: Colors.white,
      background: Color(0xFFF9FAFB),
      onSurface: Color(0xFF374151),
      onBackground: Color(0xFF111827),
    );

    _textTheme = Theme.of(context).textTheme;
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  DateTime? parseDateString(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateFormat('d MMMM yyyy').parse(dateString);
    } catch (e) {
      print('Date parsing failed for "$dateString": $e');
      return null;
    }
  }

  String extractField(String notes, String fieldName) {
    final lines = notes.split('\n');
    for (var line in lines) {
      if (line.startsWith('$fieldName:')) {
        return line.replaceFirst('$fieldName:', '').trim();
      }
    }
    return 'N/A';
  }

  Stream<TaskDataSource> _createAppointmentsStream() {
    return FirebaseFirestore.instance
        .collection('TaskAssign')
        .snapshots()
        .map((snapshot) {
      try {
        List<Appointment> appts = [];

        for (var doc in snapshot.docs) {
          final data = doc.data();
          final assignedDateStr = data['date'] as String?;
          final deadlineStr = data['deadlineDate'] as String?;

          DateTime parsedDate = parseDateString(assignedDateStr) ?? DateTime.now();

          // Parse the time from the database or use a default time
          String assignedTimeStr = data['time'] as String? ?? '09:00';
          DateTime start;

          try {
            // Handle both 12-hour format (8:56 PM) and 24-hour format (20:56)
            DateTime timeOnly;
            if (assignedTimeStr.contains('AM') || assignedTimeStr.contains('PM')) {
              // Parse 12-hour format
              timeOnly = DateFormat('h:mm a').parse(assignedTimeStr);
            } else {
              // Parse 24-hour format
              final timeParts = assignedTimeStr.split(':');
              if (timeParts.length >= 2) {
                final hour = int.parse(timeParts[0]);
                final minute = int.parse(timeParts[1]);
                timeOnly = DateTime(2000, 1, 1, hour, minute);
              } else {
                timeOnly = DateTime(2000, 1, 1, 9, 0);
              }
            }

            start = DateTime(
                parsedDate.year,
                parsedDate.month,
                parsedDate.day,
                timeOnly.hour,
                timeOnly.minute
            );
          } catch (e) {
            print('Time parsing failed for "$assignedTimeStr": $e');
            start = DateTime(parsedDate.year, parsedDate.month, parsedDate.day, 9);
          }

          final end = start.add(const Duration(hours: 1));

          final deadline = parseDateString(deadlineStr);
          final taskDescription = data['taskDescription'] ?? 'No Title';
          final employeeNamesList = data['employeeNames'];
          final employeeDescription = data['employeeDescription'] ?? 'N/A';

          final employeeNames = (employeeNamesList is List && employeeNamesList.isNotEmpty)
              ? employeeNamesList.join(', ')
              : (employeeNamesList?.toString() ?? 'Unknown');

          final subject = '$taskDescription - Assigned to $employeeNames\n'
              'Employee description: $employeeDescription';

          // final List<dynamic> employeeNamesList = data['employeeNames'] ?? [];
          // final String employeeNames = employeeNamesList.isNotEmpty ? employeeNamesList.join(', ') : 'N/A';

          final notes = '''
Admin ID: ${data['adminId'] ?? 'N/A'}
Admin Name: ${data['adminName'] ?? 'N/A'}
Project Name: ${data['projectName'] ?? 'N/A'}
Assigned Date: ${assignedDateStr ?? 'N/A'}
Assigned Time: ${data['time'] ?? 'N/A'}
Deadline Date: ${deadlineStr ?? 'N/A'}
Department: ${data['department'] ?? 'N/A'}
Employee Description: ${data['employeeDescription'] ?? 'N/A'}
Employee Names: $employeeNames
Task Description: ${data['taskDescription'] ?? 'N/A'}
Task Status: ${data['taskstatus'] ?? 'N/A'}
''';

          final status = (data['taskstatus'] as String?)?.toLowerCase() ?? '';
          final color = getStatusColor(status);

          appts.add(Appointment(
            startTime: start,
            endTime: end,
            subject: subject,
            notes: notes,
            color: color,
          ));
        }

        _allAppointments = appts;
        return TaskDataSource(appts);
      } catch (e) {
        print('Error processing appointments: $e');
        return TaskDataSource([]);
      }
    });
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF10B981); // Emerald
      case 'in progress':
        return const Color(0xFFF59E0B); // Amber
      case 'pending':
      default:
        return const Color(0xFFEF4444); // Red
    }
  }

  Color getAppointmentColor(Appointment appointment) {
    final notes = appointment.notes ?? '';
    final status = extractField(notes, 'Task Status').toLowerCase();

    switch (status) {
      case 'completed':
        return const Color(0xFF10B981);
      case 'in progress':
        return const Color(0xFFF59E0B);
      case 'pending':
        return const Color(0xFFEF4444);
      default:
        final hash = appointment.subject.hashCode;
        return taskColors[hash.abs() % taskColors.length];
    }
  }

  Widget _buildShimmerLoader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(6, (index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              height: 20,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDetailSection({
    required IconData icon,
    required String title,
    required String content,
    Gradient? backgroundGradient,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: backgroundGradient ?? LinearGradient(
          colors: [
            _colorScheme.primary.withOpacity(0.1),
            _colorScheme.primary.withOpacity(0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: _colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: _textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: _textTheme.bodyMedium?.copyWith(
                    color: _colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Gradient getStatusGradient(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
      case 'in progress':
        return const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
      case 'pending':
      default:
        return const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
    }
  }

  void _showAppointmentDetails(BuildContext context, Appointment appointment) {
    final statusText = extractField(appointment.notes ?? '', 'Task Status');
    final statusGradient = getStatusGradient(statusText);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: _colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with color indicator
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  getAppointmentColor(appointment),
                                  getAppointmentColor(appointment).withOpacity(0.7),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Task Details',
                                  style: _textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  extractField(appointment.notes ?? '', 'Task Description'),
                                  style: _textTheme.bodyLarge?.copyWith(
                                    color: _colorScheme.onSurface.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Status with special styling
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: statusGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: getAppointmentColor(appointment).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white24,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getStatusIcon(statusText),
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Status',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    statusText.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Task details sections
                      _buildDetailSection(
                        icon: Icons.person_outline,
                        title: 'Admin',
                        content: '${extractField(appointment.notes ?? '', 'Admin Name')} (${extractField(appointment.notes ?? '', 'Admin ID')})',
                      ),

                      _buildDetailSection(
                        icon: Icons.groups_outlined,
                        title: 'Assigned To',
                        content: extractField(appointment.notes ?? '', 'Employee Names'),
                      ),

                      _buildDetailSection(
                        icon: Icons.work_outline,
                        title: 'Project',
                        content: extractField(appointment.notes ?? '', 'Project Name'),
                      ),

                      _buildDetailSection(
                        icon: Icons.business_outlined,
                        title: 'Department',
                        content: extractField(appointment.notes ?? '', 'Department'),
                      ),

                      _buildDetailSection(
                        icon: Icons.calendar_today_outlined,
                        title: 'Assigned Date',
                        content: '${extractField(appointment.notes ?? '', 'Assigned Date')} at ${extractField(appointment.notes ?? '', 'Assigned Time')}',
                      ),

                      _buildDetailSection(
                        icon: Icons.event_outlined,
                        title: 'Deadline',
                        content: extractField(appointment.notes ?? '', 'Deadline Date'),
                      ),

                      _buildDetailSection(
                        icon: Icons.description_outlined,
                        title: 'Employee Notes',
                        content: extractField(appointment.notes ?? '', 'Employee Description'),
                      ),

                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                              label: const Text('Close'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'in progress':
        return Icons.hourglass_empty_outlined;
      case 'pending':
      default:
        return Icons.pending_outlined;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour == 0 ? 12 : dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour < 12 ? 'AM' : 'PM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildEnhancedCalendar(TaskDataSource dataSource) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) => FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: _colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SfCalendar(
                view: _calendarView,
                dataSource: dataSource,
                backgroundColor: _colorScheme.surface,
                showDatePickerButton: true,
                headerHeight: 80,

                headerStyle: CalendarHeaderStyle(
                  backgroundColor: _colorScheme.surface,
                  textAlign: TextAlign.center,
                  textStyle: TextStyle(
                    fontSize: 18,
                    color: _colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),

                monthViewSettings: MonthViewSettings(
                  monthCellStyle: MonthCellStyle(
                    backgroundColor: _colorScheme.surface,
                    todayBackgroundColor: _colorScheme.primary.withOpacity(0.1),
                    trailingDatesBackgroundColor: _colorScheme.surface,
                    leadingDatesBackgroundColor: _colorScheme.surface,
                    textStyle: TextStyle(
                      color: _colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    todayTextStyle: TextStyle(
                      color: _colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    leadingDatesTextStyle: TextStyle(
                      color: _colorScheme.onSurface.withOpacity(0.4),
                      fontSize: 14,
                    ),
                    trailingDatesTextStyle: TextStyle(
                      color: _colorScheme.onSurface.withOpacity(0.4),
                      fontSize: 14,
                    ),
                  ),
                  appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
                  appointmentDisplayCount: 4,
                  showAgenda: true,
                  agendaViewHeight: 200,
                  agendaStyle: AgendaStyle(
                    backgroundColor: _colorScheme.background,
                    appointmentTextStyle: TextStyle(
                      color: _colorScheme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    dateTextStyle: TextStyle(
                      color: _colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    dayTextStyle: TextStyle(
                      color: _colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),

                viewHeaderStyle: ViewHeaderStyle(
                  backgroundColor: _colorScheme.surface,
                  dayTextStyle: TextStyle(
                    color: _colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                  dateTextStyle: TextStyle(
                    color: _colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),

                todayHighlightColor: _colorScheme.primary,

                selectionDecoration: BoxDecoration(
                  color: _colorScheme.primary.withOpacity(0.15),
                  border: Border.all(color: _colorScheme.primary, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),

                timeSlotViewSettings: TimeSlotViewSettings(
                  startHour: 0,
                  endHour: 24,
                  timeIntervalHeight: _timeIntervalHeight,
                  timeInterval: const Duration(hours: 1),
                  timeTextStyle: TextStyle(
                    color: _colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),

                // Custom appointment builder for different views (excluding month view)
                appointmentBuilder: _calendarView == CalendarView.month ? null : (context, details) {
                  final appointments = details.appointments!.cast<Appointment>().toList();
                  if (appointments.isEmpty) return const SizedBox.shrink();

                  final isTimelineMonth = _calendarView == CalendarView.timelineMonth;
                  final isTimelineWeek = _calendarView == CalendarView.timelineWeek;
                  final isTimelineDay = _calendarView == CalendarView.timelineDay;
                  final isScheduleView = _calendarView == CalendarView.schedule;

                  // For schedule view, return enhanced visibility layout
                  if (isScheduleView) {
                    final appointment = appointments.first;
                    return Container(
                      height: 32,
                      margin: const EdgeInsets.symmetric(vertical: 1),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            getAppointmentColor(appointment).withOpacity(0.1),
                            getAppointmentColor(appointment).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: getAppointmentColor(appointment).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 20,
                            decoration: BoxDecoration(
                              color: getAppointmentColor(appointment),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  extractField(appointment.notes ?? '', 'Task Description'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  extractField(appointment.notes ?? '', 'Task Status'),
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: _colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: getAppointmentColor(appointment),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              extractField(appointment.notes ?? '', 'Task Status').length > 3
                                  ? extractField(appointment.notes ?? '', 'Task Status').substring(0, 3).toUpperCase()
                                  : extractField(appointment.notes ?? '', 'Task Status').toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Timeline views - enhanced size and responsiveness
                  if (isTimelineDay || isTimelineWeek || isTimelineMonth) {
                    final maxVisible = isTimelineMonth ? 2 : 3;
                    final visibleApps = appointments.length > maxVisible
                        ? appointments.sublist(0, maxVisible)
                        : appointments;
                    final hiddenCount = appointments.length - visibleApps.length;

                    return Container(
                      padding: const EdgeInsets.all(3),
                      constraints: BoxConstraints(
                        maxWidth: isTimelineMonth ? 80 : isTimelineWeek ? 120 : 150,
                        maxHeight: isTimelineMonth ? 70 : 80,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...visibleApps.map((appt) => Container(
                              margin: const EdgeInsets.only(bottom: 2),
                              height: isTimelineMonth ? 16 : 20,
                              decoration: BoxDecoration(
                                color: getAppointmentColor(appt),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: getAppointmentColor(appt).withOpacity(0.3),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 3,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        extractField(appt.notes ?? '', 'Task Description'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                            if (hiddenCount > 0)
                              Container(
                                height: 12,
                                margin: const EdgeInsets.only(top: 1),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: _colorScheme.primary.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    '+$hiddenCount more',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 8,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Day and Week views - full appointments with clipping
                  return ClipRect(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: appointments.take(3).map((appt) =>
                            _buildAppointmentCard(appt, isCompact: false)
                        ).toList(),
                      ),
                    ),
                  );
                },



                onTap: (CalendarTapDetails details) {
                  final appointments = details.appointments?.cast<Appointment>();
                  if (appointments == null || appointments.isEmpty) return;

                  if (appointments.length == 1) {
                    _showAppointmentDetails(context, appointments.first);
                  } else {
                    _showMultipleAppointmentsDialog(context, appointments);
                  }
                },

                onViewChanged: (ViewChangedDetails details) {
                  // Simply track the view change without triggering animations
                  // This prevents interference with the view switching process
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment, {bool isCompact = false}) {
    final color = getAppointmentColor(appointment);

    return Container(
      margin: EdgeInsets.only(bottom: isCompact ? 3 : 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: isCompact ? 4 : 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
          onTap: () => _showAppointmentDetails(context, appointment),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 8 : 12,
              vertical: isCompact ? 4 : 8,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Check available width to decide what to show
                final availableWidth = constraints.maxWidth;
                final showStatusBadge = availableWidth > 80;
                final showAssignedTo = availableWidth > 120 && !isCompact;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Only show indicator dot if we have enough space
                    if (availableWidth > 30) ...[
                      Container(
                        width: isCompact ? 4 : 6,
                        height: isCompact ? 4 : 6,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: isCompact ? 2 : 4),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            extractField(appointment.notes ?? '', 'Task Description'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: availableWidth < 50 ? 8 : (isCompact ? 10 : 12),
                              letterSpacing: 0.1,
                            ),
                          ),
                          if (showAssignedTo)
                            Text(
                              'Assigned to: ${extractField(appointment.notes ?? '', 'Employee Names')}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 9,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Only show status badge if we have enough space
                    if (showStatusBadge && extractField(appointment.notes ?? '', 'Task Status').isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                        constraints: BoxConstraints(
                          maxWidth: (availableWidth * 0.3).clamp(20, 50),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          extractField(appointment.notes ?? '', 'Task Status').length > 4
                              ? '${extractField(appointment.notes ?? '', 'Task Status').substring(0, 4)}'
                              : extractField(appointment.notes ?? '', 'Task Status'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: availableWidth < 100 ? 6 : 7,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showMultipleAppointmentsDialog(BuildContext context, List<Appointment> appointments) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Multiple Tasks (${appointments.length})',
          style: _textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: getAppointmentColor(appointment),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  title: Text(
                    extractField(appointment.notes ?? '', 'Task Description'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${extractField(appointment.notes ?? '', 'Task Status')}'),
                      Text('Assigned to: ${extractField(appointment.notes ?? '', 'Employee Names')}'),
                    ],
                  ),
                  trailing: Icon(
                    _getStatusIcon(extractField(appointment.notes ?? '', 'Task Status')),
                    color: getAppointmentColor(appointment),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showAppointmentDetails(context, appointment);
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _colorScheme.primary,
            _colorScheme.primary.withOpacity(0.8),
            _colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              Icons.view_agenda_outlined,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              'View:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<CalendarView>(
                  value: _calendarView,
                  dropdownColor: _colorScheme.primary,
                  iconEnabledColor: Colors.white,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  items: const [
                    DropdownMenuItem(value: CalendarView.day, child: Text('Day View')),
                    DropdownMenuItem(value: CalendarView.week, child: Text('Week View')),
                    DropdownMenuItem(value: CalendarView.workWeek, child: Text('Work Week')),
                    DropdownMenuItem(value: CalendarView.month, child: Text('Month View')),
                    DropdownMenuItem(value: CalendarView.schedule, child: Text('Schedule')),
                    DropdownMenuItem(value: CalendarView.timelineDay, child: Text('Timeline Day')),
                    DropdownMenuItem(value: CalendarView.timelineWeek, child: Text('Timeline Week')),
                    DropdownMenuItem(value: CalendarView.timelineMonth, child: Text('Timeline Month')),
                  ],
                  onChanged: (view) {
                    if (view != null && view != _calendarView) {
                      setState(() {
                        _calendarView = view;
                        // Refresh data when view changes
                        _appointmentsStream = _createAppointmentsStream();
                        // Trigger smooth animation for view change
                        _scaleController.reset();
                        _scaleController.forward();
                      });
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorScheme.background,
      appBar: AppBar(
        title: const Text(
          'Task Calendar',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            fontFamily: 'Poppins',
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF6A11CB),
                Color(0xFF2575FC),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 10,
        shadowColor: Colors.black45,
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: StreamBuilder<TaskDataSource>(
        stream: _appointmentsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoader();
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: _colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Error loading tasks: ${snapshot.error}",
                    style: TextStyle(
                      fontSize: 18,
                      color: _colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: _colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No task data available.",
                    style: TextStyle(
                      fontSize: 18,
                      color: _colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          final dataSource = snapshot.data!;

          return Column(
            children: [
              _buildViewSelector(),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  child: _buildEnhancedCalendar(dataSource),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
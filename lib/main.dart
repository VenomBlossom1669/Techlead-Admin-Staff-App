import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'web/web_notification_stub.dart'
if (dart.library.html) 'web/web_notification_web.dart';
import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'Admin/Taskdetails/Admintaskassigneddata.dart';
import 'Employee/Authentication/Splashscreen.dart';
import 'Employee/Categoryscreen/categoryscreen.dart';
import 'Default/Themeprovider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
GlobalKey<ScaffoldMessengerState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb) return;

  await Firebase.initializeApp();
  final taskId = message.data['taskId']?.toString() ?? '';
  final screen = message.data['screen']?.toString() ?? '';
  final title = message.data['title'] ?? message.notification?.title ?? 'New Task';
  final body = message.data['body'] ?? message.notification?.body ?? 'You have a new task';

  String payload;
  if (screen == 'Admintaskassigneddata') {
    payload = 'Admintaskassigneddata|$taskId';
  } else {
    payload = 'Categoryscreen|$taskId';
  }

  await _showBackgroundNotification(taskId, title, body, payload);
}

Future<void> _showBackgroundNotification(
    String taskId,
    String title,
    String body,
    String payload
    ) async {
  if (kIsWeb) return;

  const androidDetails = AndroidNotificationDetails(
    'default_channel',
    'Task Notifications',
    channelDescription: 'For task updates',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('custom_sound'),
    icon: '@mipmap/ic_launcher',
    enableVibration: true,
    visibility: NotificationVisibility.public,
    fullScreenIntent: true,
  );

  const notificationDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    notificationDetails,
    payload: payload,
  );
}

Future<void> _initializeWebMessaging() async {
  if (!kIsWeb) return;

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  FirebaseMessaging.onMessage.listen((msg) {
    final title = msg.notification?.title ?? 'New Task';
    final body = msg.notification?.body ?? '';
    showWebNotification(title, body);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider('6LeI5-MrAAAAAM6cGPKYDmFIZrvwjNnHD6CUe7wl'),
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  if (!kIsWeb) {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
    InitializationSettings(android: androidSettings);

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) async {
        final payload = response.payload ?? '';
        if (payload.isNotEmpty) {
          final parts = payload.split('|');
          final screen = parts.isNotEmpty ? parts[0] : '';
          final taskId = parts.length > 1 ? parts[1] : '';

          print("🔔 Notification tapped - Screen: $screen, TaskId: $taskId");

          if (screen == 'Admintaskassigneddata' && taskId.isNotEmpty) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => Admintaskassigneddata(
                  highlightedTaskId: taskId,
                  unreadCount: 1,
                ),
              ),
            );
          }

          else if (screen == 'Categoryscreen') {
            navigatorKey.currentState?.pushNamed('/Categoryscreen');
          }
        }
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'default_channel',
      'Task Notifications',
      description: 'For task updates',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('custom_sound'),
      enableVibration: true,
      showBadge: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  await _initializeWebMessaging();

  runApp(
    riverpod.ProviderScope(
      child: ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (!kIsWeb) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {

      await _refreshAndSaveFcmToken(userId: user.uid, isAdmin: false);
      _setupTokenRefresh();
      _checkAndStoreProfile();
    }

    _setupFirebaseListeners();
    setState(() => _loading = false);
  }

  Future<void> _refreshAndSaveFcmToken({
    required String userId,
    required bool isAdmin,
  }) async {
    try {
      print("🔄 Starting FCM token refresh for user: $userId");

      await FirebaseMessaging.instance.deleteToken();
      print("✅ Old token deleted");

      await Future.delayed(const Duration(seconds: 1));

      final newToken = await FirebaseMessaging.instance.getToken();

      if (newToken == null || newToken.isEmpty) {
        print("⚠️ FCM Token is null or empty");
        return;
      }

      print("✅ New FCM Token: $newToken");

      final collection = isAdmin ? 'Admin_Profiles' : 'EmpProfile';

      await FirebaseFirestore.instance
          .collection(collection)
          .doc(userId)
          .set({'fcmToken': newToken}, SetOptions(merge: true));

      print("✅ FCM Token saved successfully for user: $userId");
    } catch (e) {
      print("❌ Error refreshing FCM token: $e");
    }
  }

  void _setupTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && newToken.isNotEmpty) {
        print("🔄 Token refreshed: $newToken");
        await FirebaseFirestore.instance
            .collection('EmpProfile')
            .doc(user.uid)
            .set({'fcmToken': newToken}, SetOptions(merge: true));
      }
    });
  }

  void _checkAndStoreProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('EmpProfile')
        .doc(user.uid)
        .get();
    if (!doc.exists) return;

    final empId = doc['empId']?.toString() ?? '';
    final categories = doc['categories'];
    final catString =
    (categories is List) ? (categories as List).join(',') : categories.toString();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('empId', empId);
    await prefs.setString('categories', catString);
  }

  void _setupFirebaseListeners() {

    FirebaseMessaging.onMessage.listen((msg) {
      if (kIsWeb) return;
      _handleNotification(msg);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((msg) async {
      if (kIsWeb) return;
      final data = msg.data;
      final screen = data['screen']?.toString() ?? '';
      final taskId = data['taskId']?.toString() ?? '';

      print("🔔 App opened from notification - Screen: $screen");

      if (screen == 'Admintaskassigneddata' && taskId.isNotEmpty) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => Admintaskassigneddata(
              highlightedTaskId: taskId,
              unreadCount: 1,
            ),
          ),
        );
      }

      else if (screen == 'Categoryscreen') {
        navigatorKey.currentState?.pushNamed('/Categoryscreen');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, child) {
        return MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          navigatorKey: navigatorKey,
          title: 'Techlead The Engineering Solutions',
          theme: Provider.of<ThemeProvider>(context).currentTheme,
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
          routes: {
            '/Categoryscreen': (_) => const Categoryscreen(),
          },
        );
      },
    );
  }
}

Future<void> _handleNotification(RemoteMessage message) async {
  if (kIsWeb) return;

  final prefs = await SharedPreferences.getInstance();
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final profile = await FirebaseFirestore.instance
      .collection('EmpProfile')
      .doc(user.uid)
      .get();
  if (!profile.exists) return;

  final currentEmp = profile['empId']?.toString().trim() ?? '';
  final catsRaw = profile['categories'];
  final currentCats = (catsRaw is List)
      ? catsRaw.map((e) => e.toString().trim()).toList()
      : <String>[];

  final data = message.data;
  final taskId = data['taskId']?.toString() ?? '';
  final dept = data['department']?.toString().trim() ?? '';
  final empIdsRaw = data['empIds']?.toString() ?? '';
  final targets = empIdsRaw
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  final empMatch = targets.contains(currentEmp);
  final deptMatch = targets.isEmpty && currentCats.contains(dept);

  if (!empMatch && !deptMatch) return;

  final title = data['title'] ?? message.notification?.title ?? 'New Task';
  final body = data['body'] ?? message.notification?.body ?? 'You have a new task.';

  if (title.isNotEmpty) prefs.setString('notificationTitle', title);

  await _showLocalNotification(taskId, title, body);

  if (navigatorKey.currentContext != null) {
    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      SnackBar(
        content: Text('$title\n$body'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

Future<void> _showLocalNotification(String taskId, String title, String body) async {
  if (kIsWeb) return;

  const androidDetails = AndroidNotificationDetails(
    'default_channel',
    'Task Notifications',
    channelDescription: 'For task updates',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('custom_sound'),
    icon: '@mipmap/ic_launcher',
    enableVibration: true,
    visibility: NotificationVisibility.public,
    fullScreenIntent: true,
  );

  const notificationDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    notificationDetails,
    payload: 'Categoryscreen|$taskId',
  );
}
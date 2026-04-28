import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mini_sosmed_app/services/auth_service.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  DateTime? _appStartTime;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _appStartTime = DateTime.now();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    // Request permissions for Android 13+
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _isInitialized = true;
    _listenToNotifications();
  }

  void _listenToNotifications() {
    final user = AuthService().currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverId', isEqualTo: user.uid)
        // We can't easily order by createdAt and limit to new without a compound index if we don't have it.
        // Instead, we just listen to changes and check the timestamp locally.
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            // Only show push notification for new events that happen AFTER app started
            if (createdAt != null && _appStartTime != null && createdAt.isAfter(_appStartTime!)) {
              _showNotification(data['message'] ?? 'Notifikasi baru');
            }
          }
        }
      }
    });
  }

  Future<void> _showNotification(String message) async {
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'sosmed_channel',
      'Sosmed Notifications',
      channelDescription: 'Notifications for follows and likes',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecond, 
      title: 'Mini Sosmed',
      body: message,
      notificationDetails: notificationDetails,
    );
  }
}

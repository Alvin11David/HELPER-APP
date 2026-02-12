import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:helper/Intro/Splash_Screen.dart';
import 'firebase_options.dart';
import 'package:helper/Components/IncomingCallDialog.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final GlobalKey<NavigatorState> appNavKey = GlobalKey<NavigatorState>();

// Global flag to prevent multiple call dialogs
bool _isCallDialogShowing = false;

// Local notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("=== BACKGROUND MESSAGE HANDLER ===");
  print("Message ID: ${message.messageId}");
  print("Message data: ${message.data}");
  print(
    "Message notification: ${message.notification?.title} - ${message.notification?.body}",
  );

  // For call messages, we can show a notification or handle accordingly
  if (message.data['type'] == 'call') {
    print("Received call notification in background");
    // Since we can't show dialog in background, rely on notification
    // The notification will be shown by FCM, and tapping it can open the app
  } else {
    print("Received non-call notification in background");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Request notification permissions
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Set up global foreground FCM listener for incoming calls
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print('=== GLOBAL FCM onMessage RECEIVED ===');
    print('Message data: ${message.data}');
    print(
      'Message notification: ${message.notification?.title} - ${message.notification?.body}',
    );

    // Handle different message types
    if (message.data['type'] == 'call') {
      print(
        'Call notification detected globally! Call ID: ${message.data['callId']}, Caller: ${message.data['callerName']}',
      );

      // Show snackbar for call message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = appNavKey.currentContext;
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '📞 Incoming call from ${message.data['callerName'] ?? 'Unknown'}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      });

      // Show incoming call dialog using global navigator key
      final context = appNavKey.currentContext;
      if (context != null && !_isCallDialogShowing) {
        _isCallDialogShowing = true;

        showDialog(
          context: context,
          barrierDismissible: false, // Prevent dismissing by tapping outside
          builder: (context) => IncomingCallDialog(
            callId: message.data['callId']!,
            callerName: message.data['callerName']!,
          ),
        ).then((_) => _isCallDialogShowing = false);
      } else {
        print('Call dialog already showing or context is null');

        // Show error snackbar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final context = appNavKey.currentContext;
          if (context != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isCallDialogShowing
                      ? '⚠️ Call dialog already showing'
                      : '❌ Context is null',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });
      }
    } else if (message.data['type'] == 'escrow_cancellation_code') {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'default',
            'Default Notifications',
            channelDescription: 'Default notification channel',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false,
          );
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        message.notification?.title ?? 'Cancellation Code',
        message.notification?.body ?? 'You received a cancellation code.',
        platformChannelSpecifics,
      );
    } else if (message.data['type'] == 'support_reply') {
      // Show local notification for support reply
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'default', // Use the default channel we created
            'Default Notifications',
            channelDescription: 'Default notification channel',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false,
          );
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      await flutterLocalNotificationsPlugin.show(
        0, // Notification ID
        message.notification?.title ?? 'Support Reply',
        message.notification?.body ?? 'You have a new support reply',
        platformChannelSpecifics,
      );
    } else {
      // Show local notification for other types (e.g., general notifications)
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'default', // Use the default channel we created
            'Default Notifications',
            channelDescription: 'Default notification channel',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false,
          );
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/
            1000, // Unique ID based on timestamp
        message.notification?.title ?? 'Notification',
        message.notification?.body ?? 'You have a new notification',
        platformChannelSpecifics,
      );
    }
  });

  // Handle when app is opened from notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('=== FCM onMessageOpenedApp RECEIVED ===');
    print('Message data: ${message.data}');

    if (message.data['type'] == 'call') {
      print('App opened from call notification: ${message.data['callId']}');
      // Could navigate to call screen or show dialog here if needed
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavKey,
      debugShowCheckedModeBanner: false,
      title: 'Helper\'s App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SplashScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

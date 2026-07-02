import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'drive_service.dart';
import 'auth_service.dart';
import '../../data/models/milk_entry.dart';
import '../../data/models/expense_entry.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await dotenv.load(fileName: ".env");
      await Hive.initFlutter();

      // Register Adapters
      if (!Hive.isAdapterRegistered(0))
        Hive.registerAdapter(MilkEntryAdapter());
      if (!Hive.isAdapterRegistered(1))
        Hive.registerAdapter(ExpenseEntryAdapter());
      if (!Hive.isAdapterRegistered(2))
        Hive.registerAdapter(ExpenseCategoryAdapter());

      final authService = AuthService();
      await authService.init();

      if (!authService.isLoggedIn) return Future.value(true);

      final driveService = DriveService(authService);

      BackupFrequency freq = BackupFrequency.daily;
      if (task.contains('weekly')) freq = BackupFrequency.weekly;
      if (task.contains('monthly')) freq = BackupFrequency.monthly;

      bool due = await driveService.isBackupDue(freq);
      if (due) {
        await driveService.backupHive(frequency: freq);
      }
      return Future.value(true);
    } catch (e) {
      debugPrint("Workmanager error: $e");
      return Future.value(false);
    }
  });
}

class BackgroundService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 1. Initialize Timezone
    tz.initializeTimeZones();
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo));
    } catch (e) {
      debugPrint("Timezone initialization failed: $e");
    }

    // 2. Initialize Workmanager
    try {
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    } catch (e) {
      debugPrint("Workmanager initialization failed: $e");
    }

    // 3. Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> updateBackupTask(
    bool enabled,
    BackupFrequency? frequency,
  ) async {
    if (enabled && frequency != null) {
      Duration freqDuration;
      switch (frequency) {
        case BackupFrequency.daily:
          freqDuration = const Duration(days: 1);
          break;
        case BackupFrequency.weekly:
          freqDuration = const Duration(days: 7);
          break;
        case BackupFrequency.monthly:
          freqDuration = const Duration(days: 30);
          break;
      }
      await Workmanager().registerPeriodicTask(
        "autoBackupTask", // overwrite any existing
        "autoBackupTask_${frequency.name}",
        frequency: freqDuration,
        constraints: Constraints(
          networkType: NetworkType.connected, // Only when internet available
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
    } else {
      await Workmanager().cancelByUniqueName("autoBackupTask");
    }
  }

  static Future<void> scheduleMilkReminders(bool hasEntryToday) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isEnabled = prefs.getBool('milk_reminder_enabled') ?? false;

      // Cancel all pending reminders
      final pending = await flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
      for (var req in pending) {
        if (req.id >= 100 && req.id <= 130) {
          await flutterLocalNotificationsPlugin.cancel(req.id);
        }
      }

      if (!isEnabled) {
        return;
      }

      final int hour = prefs.getInt('milk_reminder_hour') ?? 20;
      final int minute = prefs.getInt('milk_reminder_minute') ?? 0;

      final now = DateTime.now();
      for (int i = 0; i < 30; i++) {
        final targetDate = now.add(Duration(days: i));
        var scheduledTime = tz.TZDateTime(
          tz.local,
          targetDate.year,
          targetDate.month,
          targetDate.day,
          hour,
          minute,
        );

        // If scheduled time is in the past, skip
        if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
          continue;
        }

        // If today and we already have an entry, skip
        if (i == 0 && hasEntryToday) {
          continue;
        }

        await flutterLocalNotificationsPlugin.zonedSchedule(
          100 + i,
          'Milk Entry Reminder',
          "Please add today's milk entry.",
          scheduledTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'milk_reminder',
              'Milk Reminder',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (e) {
      debugPrint("Reminder scheduling failed: $e");
    }
  }
}

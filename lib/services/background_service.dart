import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'drive_service.dart';
import 'auth_service.dart';
// Note: Adapters generated
import '../../data/models/milk_entry.dart';
import '../../data/models/expense_entry.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await dotenv.load(fileName: ".env");
      await Hive.initFlutter();

      // Register Adapters
      Hive.registerAdapter(MilkEntryAdapter());
      Hive.registerAdapter(ExpenseEntryAdapter());
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
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (e) {
      debugPrint("Timezone initialization failed: $e");
    }

    // 2. Initialize Workmanager
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

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
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
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
    // Cancel all pending reminders
    try {
      final pending = await flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
      for (var req in pending) {
        if (req.id >= 100 && req.id <= 130) {
          await flutterLocalNotificationsPlugin.cancel(id: req.id);
        }
      }

      final now = DateTime.now();
      for (int i = 0; i < 30; i++) {
        final targetDate = now.add(Duration(days: i));
        var scheduledTime = tz.TZDateTime(
          tz.local,
          targetDate.year,
          targetDate.month,
          targetDate.day,
          20, // 8:00 PM
          0,
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
          id: 100 + i,
          title: 'Milk Entry Reminder',
          body: "Milk entry for today has not been recorded. Please update it.",
          scheduledDate: scheduledTime,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'milk_reminder',
              'Milk Reminder',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint("Reminder scheduling failed: $e");
    }
  }
}

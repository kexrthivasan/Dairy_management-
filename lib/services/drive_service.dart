import 'dart:io';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'auth_service.dart';

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

/// Backup frequency options.
enum BackupFrequency { daily, weekly, monthly }

class DriveService {
  static const _folderName = 'DairyAppBackup';

  // SharedPreferences keys for each frequency
  static const _dailyBackupTimeKey = 'last_daily_backup_time';
  static const _weeklyBackupTimeKey = 'last_weekly_backup_time';
  static const _monthlyBackupTimeKey = 'last_monthly_backup_time';

  static const _dailyBackupEnabledKey = 'daily_backup_enabled';
  static const _weeklyBackupEnabledKey = 'weekly_backup_enabled';
  static const _monthlyBackupEnabledKey = 'monthly_backup_enabled';

  // Legacy keys (keep for migration)
  static const _legacyBackupKey = 'last_backup_time';
  static const _legacyAutoBackupKey = 'auto_backup_enabled';

  // Restore timestamp key
  static const _restoreTimeKey = 'last_restore_time';

  final AuthService _authService;

  DriveService(this._authService);

  Future<drive.DriveApi?> _getDriveApi() async {
    try {
      if (!_authService.isLoggedIn) {
        debugPrint('DriveService: User not logged in.');
        return null;
      }

      final authHeaders = await _authService.getAuthHeaders();
      if (authHeaders == null) {
        debugPrint('DriveService: Could not get auth headers.');
        return null;
      }

      final authenticateClient = GoogleAuthClient(authHeaders);
      return drive.DriveApi(authenticateClient);
    } catch (e, stackTrace) {
      debugPrint("Error initializing Drive API: $e");
      debugPrint("Stack trace: $stackTrace");
      return null;
    }
  }

  Future<String?> _getBackupFolderId(drive.DriveApi driveApi) async {
    try {
      final folders = await driveApi.files.list(
        q: "mimeType = 'application/vnd.google-apps.folder' and name = '$_folderName' and trashed = false",
        spaces: 'drive',
      );

      if (folders.files != null && folders.files!.isNotEmpty) {
        return folders.files!.first.id;
      }

      // Create folder if not found
      var folder = drive.File()
        ..name = _folderName
        ..mimeType = 'application/vnd.google-apps.folder';

      var createdFolder = await driveApi.files.create(folder);
      return createdFolder.id;
    } catch (e) {
      debugPrint("Error finding/creating folder: $e");
      return null;
    }
  }

  /// Get the backup file prefix for a given frequency.
  String _getBackupPrefix(BackupFrequency frequency) {
    switch (frequency) {
      case BackupFrequency.daily:
        return 'daily_backup';
      case BackupFrequency.weekly:
        return 'weekly_backup';
      case BackupFrequency.monthly:
        return 'monthly_backup';
    }
  }

  /// Get the SharedPreferences key for last backup time per frequency.
  String _getBackupTimeKey(BackupFrequency frequency) {
    switch (frequency) {
      case BackupFrequency.daily:
        return _dailyBackupTimeKey;
      case BackupFrequency.weekly:
        return _weeklyBackupTimeKey;
      case BackupFrequency.monthly:
        return _monthlyBackupTimeKey;
    }
  }

  /// Get the SharedPreferences key for backup enabled per frequency.
  String _getBackupEnabledKey(BackupFrequency frequency) {
    switch (frequency) {
      case BackupFrequency.daily:
        return _dailyBackupEnabledKey;
      case BackupFrequency.weekly:
        return _weeklyBackupEnabledKey;
      case BackupFrequency.monthly:
        return _monthlyBackupEnabledKey;
    }
  }

  /// Backup Hive data to Google Drive for a specific frequency.
  Future<String> backupHive({BackupFrequency frequency = BackupFrequency.daily}) async {
    if (kIsWeb) {
      return 'Web browser does not support physical file backups.';
    }

    if (!_authService.isLoggedIn) {
      return 'Please login first to backup.';
    }

    // Check internet connection
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return 'No internet connection.';
    }

    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return 'Google authentication failed. Please re-login.';

      final folderId = await _getBackupFolderId(driveApi);
      if (folderId == null) return 'Could not create or find Backup folder.';

      final dir = await getApplicationDocumentsDirectory();
      final prefix = _getBackupPrefix(frequency);

      final filesToBackup = {
        'milk_records.hive': '${prefix}_milk_records.hive',
        'expense_entries.hive': '${prefix}_expense_entries.hive',
      };

      for (var entry in filesToBackup.entries) {
        final localFileName = entry.key;
        final driveFileName = entry.value;
        final filePath = '${dir.path}/$localFileName';
        final file = File(filePath);
        if (!await file.exists()) continue;

        // Check if file already exists in Drive to update
        final currentDriveFiles = await driveApi.files.list(
          q: "'$folderId' in parents and name = '$driveFileName' and trashed = false",
          spaces: 'drive',
        );

        var driveFile = drive.File()
          ..name = driveFileName;

        final media = drive.Media(file.openRead(), file.lengthSync());

        if (currentDriveFiles.files != null && currentDriveFiles.files!.isNotEmpty) {
          final fileId = currentDriveFiles.files!.first.id!;
          // For updates, don't set parents - it's not allowed in update requests
          await driveApi.files.update(
            driveFile,
            fileId,
            uploadMedia: media,
          );
        } else {
          // For new files, set the parent folder
          driveFile.parents = [folderId];
          await driveApi.files.create(
            driveFile,
            uploadMedia: media,
          );
        }
      }

      // Update backup time for this frequency
      final prefs = await SharedPreferences.getInstance();
      final timeKey = _getBackupTimeKey(frequency);
      await prefs.setString(timeKey, DateTime.now().toIso8601String());
      
      // Also update legacy key for backwards compatibility
      await prefs.setString(_legacyBackupKey, DateTime.now().toIso8601String());

      return 'Success';
    } catch (e) {
      debugPrint("Backup Error: $e");
      return 'Error: $e';
    }
  }

  /// Restore Hive data from Google Drive.
  /// Restores from the most recent backup (daily by default).
  Future<String> restoreHive({BackupFrequency frequency = BackupFrequency.daily}) async {
    if (kIsWeb) {
      return 'Web browser does not support physical file restores.';
    }

    if (!_authService.isLoggedIn) {
      return 'Please login first to restore.';
    }

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) return 'No internet connection.';

    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return 'Google authentication failed. Please re-login.';

      final folderId = await _getBackupFolderId(driveApi);
      if (folderId == null) return 'Could not find Backup folder on Drive.';

      final prefix = _getBackupPrefix(frequency);
      final filesToRestore = {
        '${prefix}_milk_records.hive': 'milk_records.hive',
        '${prefix}_expense_entries.hive': 'expense_entries.hive',
      };

      final dir = await getApplicationDocumentsDirectory();
      bool anyRestored = false;

      for (var entry in filesToRestore.entries) {
        final driveFileName = entry.key;
        final localFileName = entry.value;

        final driveFiles = await driveApi.files.list(
          q: "'$folderId' in parents and name = '$driveFileName' and trashed = false",
          spaces: 'drive',
        );

        if (driveFiles.files == null || driveFiles.files!.isEmpty) {
          // Try legacy file names (without prefix) if frequency backup not found
          if (frequency == BackupFrequency.daily) {
            final legacyFiles = await driveApi.files.list(
              q: "'$folderId' in parents and name = '$localFileName' and trashed = false",
              spaces: 'drive',
            );
            if (legacyFiles.files == null || legacyFiles.files!.isEmpty) continue;
            
            final fileId = legacyFiles.files!.first.id!;
            await _downloadAndSave(driveApi, fileId, '${dir.path}/$localFileName');
            anyRestored = true;
            continue;
          }
          continue;
        }

        final fileId = driveFiles.files!.first.id!;
        await _downloadAndSave(driveApi, fileId, '${dir.path}/$localFileName');
        anyRestored = true;
      }

      if (!anyRestored) {
        return 'No backup files found for ${frequency.name} frequency.';
      }

      // Save restore timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_restoreTimeKey, DateTime.now().toIso8601String());

      return 'Success';
    } catch (e) {
      debugPrint("Restore Error: $e");
      return 'Error: $e';
    }
  }

  Future<void> _downloadAndSave(drive.DriveApi driveApi, String fileId, String localPath) async {
    final drive.Media response = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    List<int> dataStore = [];
    await for (var data in response.stream) {
      dataStore.insertAll(dataStore.length, data);
    }

    final localFile = File(localPath);
    await localFile.writeAsBytes(dataStore, flush: true);
  }

  // --- Backup scheduling settings ---

  Future<void> setBackupEnabled(BackupFrequency frequency, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_getBackupEnabledKey(frequency), enabled);
  }

  Future<bool> isBackupEnabled(BackupFrequency frequency) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_getBackupEnabledKey(frequency)) ?? false;
  }

  Future<DateTime?> getLastBackupTime([BackupFrequency? frequency]) async {
    final prefs = await SharedPreferences.getInstance();
    String key;
    if (frequency != null) {
      key = _getBackupTimeKey(frequency);
    } else {
      key = _legacyBackupKey;
    }
    final timeStr = prefs.getString(key);
    if (timeStr != null) {
      return DateTime.tryParse(timeStr);
    }
    return null;
  }

  Future<DateTime?> getLastRestoreTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString(_restoreTimeKey);
    if (timeStr != null) return DateTime.tryParse(timeStr);
    return null;
  }

  /// Check if a backup is due for the given frequency.
  Future<bool> isBackupDue(BackupFrequency frequency) async {
    final enabled = await isBackupEnabled(frequency);
    if (!enabled) return false;

    final lastBackup = await getLastBackupTime(frequency);
    if (lastBackup == null) return true; // Never backed up

    final now = DateTime.now();

    switch (frequency) {
      case BackupFrequency.daily:
        // Due if last backup was not today
        return lastBackup.year != now.year ||
            lastBackup.month != now.month ||
            lastBackup.day != now.day;
      case BackupFrequency.weekly:
        // Due if more than 7 days since last backup
        return now.difference(lastBackup).inDays >= 7;
      case BackupFrequency.monthly:
        // Due if different month or more than 30 days
        return (now.year != lastBackup.year || now.month != lastBackup.month);
    }
  }

  // Legacy compatibility
  Future<void> setAutoBackup(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_legacyAutoBackupKey, enabled);
    // Also set daily backup
    await setBackupEnabled(BackupFrequency.daily, enabled);
  }

  Future<bool> getAutoBackup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_legacyAutoBackupKey) ?? false;
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'drive_service.dart';
import 'auth_service.dart';

/// BackupScheduler monitors connectivity and triggers pending backups
/// for enabled frequencies when the app comes online.
class BackupScheduler {
  final DriveService _driveService;
  final AuthService _authService;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isRunning = false;

  BackupScheduler(this._driveService, this._authService);

  /// Start monitoring connectivity and check for pending backups.
  void start() {
    if (_isRunning) return;
    _isRunning = true;

    // Check immediately on start
    _checkAndRunPendingBackups();

    // Listen for connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        // We're online, check for pending backups
        _checkAndRunPendingBackups();
      }
    });
  }

  /// Stop monitoring.
  void stop() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _isRunning = false;
  }

  /// Check all frequencies and run any pending backups.
  Future<void> _checkAndRunPendingBackups() async {
    if (!_authService.isLoggedIn) return;

    // Check connectivity first
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) return;

    for (final frequency in BackupFrequency.values) {
      try {
        final isDue = await _driveService.isBackupDue(frequency);
        if (isDue) {
          debugPrint('BackupScheduler: ${frequency.name} backup is due. Running...');
          final result = await _driveService.backupHive(frequency: frequency);
          debugPrint('BackupScheduler: ${frequency.name} backup result: $result');
        }
      } catch (e) {
        debugPrint('BackupScheduler: Error checking/running ${frequency.name} backup: $e');
      }
    }
  }

  /// Dispose resources.
  void dispose() {
    stop();
  }
}

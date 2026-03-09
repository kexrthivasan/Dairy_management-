import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis/drive/v3.dart' as drive;

/// AuthService manages Google Sign-In for the app.
/// It persists login state and exposes the current user info.
class AuthService extends ChangeNotifier {
  static const _isLoggedInKey = 'is_logged_in';
  static const _userEmailKey = 'user_email';
  static const _userNameKey = 'user_name';
  static const _userPhotoKey = 'user_photo_url';

  late final GoogleSignIn _googleSignIn;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  String? _userEmail;
  String? get userEmail => _userEmail;

  String? _userName;
  String? get userName => _userName;

  String? _userPhotoUrl;
  String? get userPhotoUrl => _userPhotoUrl;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  GoogleSignIn get googleSignIn => _googleSignIn;

  AuthService() {
    final webClientId = dotenv.env['GOOGLE_CLIENT_ID'];
    if (kIsWeb) {
      _googleSignIn = GoogleSignIn(
        clientId: webClientId,
        scopes: [drive.DriveApi.driveAppdataScope, drive.DriveApi.driveFileScope],
      );
    } else {
      _googleSignIn = GoogleSignIn(
        scopes: [drive.DriveApi.driveAppdataScope, drive.DriveApi.driveFileScope],
      );
    }
  }

  /// Initialize: restore login state from SharedPreferences.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    _userEmail = prefs.getString(_userEmailKey);
    _userName = prefs.getString(_userNameKey);
    _userPhotoUrl = prefs.getString(_userPhotoKey);

    // Try silent sign-in to refresh tokens
    if (_isLoggedIn) {
      try {
        final account = await _googleSignIn.signInSilently();
        if (account != null) {
          _updateUserInfo(account);
        } else {
          // Token expired or revoked, keep cached info but mark as needing re-auth
          debugPrint('Silent sign-in returned null, cached user info preserved.');
        }
      } catch (e) {
        debugPrint('Silent sign-in failed: $e');
      }
    }
    notifyListeners();
  }

  /// Sign in with Google.
  Future<bool> signIn() async {
    _isLoading = true;
    notifyListeners();

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        _isLoading = false;
        notifyListeners();
        return false; // User cancelled
      }

      _isLoggedIn = true;
      _updateUserInfo(account);
      await _persistUserInfo();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Sign-in error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out from Google.
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Sign-out error: $e');
    }

    _isLoggedIn = false;
    _userEmail = null;
    _userName = null;
    _userPhotoUrl = null;
    await _clearUserInfo();

    _isLoading = false;
    notifyListeners();
  }

  /// Get auth headers for Google API calls (Drive, etc.)
  Future<Map<String, String>?> getAuthHeaders() async {
    try {
      var account = _googleSignIn.currentUser;
      if (account == null) {
        account = await _googleSignIn.signInSilently();
      }
      if (account == null) return null;
      return await account.authHeaders;
    } catch (e) {
      debugPrint('Error getting auth headers: $e');
      return null;
    }
  }

  void _updateUserInfo(GoogleSignInAccount account) {
    _userEmail = account.email;
    _userName = account.displayName;
    _userPhotoUrl = account.photoUrl;
  }

  Future<void> _persistUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, _isLoggedIn);
    if (_userEmail != null) await prefs.setString(_userEmailKey, _userEmail!);
    if (_userName != null) await prefs.setString(_userNameKey, _userName!);
    if (_userPhotoUrl != null) await prefs.setString(_userPhotoKey, _userPhotoUrl!);
  }

  Future<void> _clearUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userPhotoKey);
  }
}

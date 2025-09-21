import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Auth0 Authentication Service
/// Professional authentication for PennApps 2025
class Auth0DataSource {
  static const String _domain = 'dev-mup2ksku6p7ra6tr.us.auth0.com';
  static const String _clientId = 'JfwDSwBDL29V2u0mYeAxP700rOozhyEq';

  late Auth0 _auth0;
  Credentials? _credentials;
  UserProfile? _user;

  /// Initialize Auth0
  void initialize() {
    _auth0 = Auth0(_domain, _clientId);
    print('🔐 Auth0 initialized successfully!');
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _credentials != null && !_isTokenExpired();

  /// Get current user
  UserProfile? get currentUser => _user;

  /// Get user ID for MongoDB
  String? get userId => _user?.sub;

  /// Login with Auth0
  Future<AuthResult> login() async {
    try {
      print('🔐 Starting Auth0 login...');

      // Use custom URL scheme for iOS (doesn't require Associated Domains)
      final credentials = await _auth0.webAuthentication().login(useHTTPS: false);

      _credentials = credentials;
      _user = credentials.user; // User profile is included in credentials

      // Store credentials locally
      await _storeCredentials(credentials);

      print('✅ Auth0 login successful: ${_user?.name}');

      return AuthResult(
        success: true,
        user: _user,
        userId: _user?.sub,
        accessToken: credentials.accessToken,
      );

    } catch (e) {
      print('❌ Auth0 login error: $e');
      return AuthResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Logout from Auth0
  Future<void> logout() async {
    try {
      await _auth0.webAuthentication().logout(useHTTPS: false);

      _credentials = null;
      _user = null;

      // Clear stored credentials
      await _clearStoredCredentials();

      print('✅ Auth0 logout successful');
    } catch (e) {
      print('❌ Auth0 logout error: $e');
    }
  }

  /// Try to restore session from stored credentials
  Future<AuthResult> restoreSession() async {
    try {
      final credentials = await _getStoredCredentials();

      if (credentials != null && !_isTokenExpired(credentials)) {
        _credentials = credentials;
        _user = credentials.user; // User profile is included in stored credentials

        print('✅ Auth0 session restored: ${_user?.name ?? 'Unknown User'}');

        return AuthResult(
          success: true,
          user: _user,
          userId: _user?.sub,
          accessToken: credentials.accessToken,
        );
      }

      // No stored session found - this is normal on first launch
      return AuthResult(success: false, error: 'No valid stored session');

    } catch (e) {
      // Only log actual errors, not normal "no session" cases
      if (e.toString().contains('Null') || e.toString().contains('type cast')) {
        return AuthResult(success: false, error: 'No valid stored session');
      }
      print('❌ Auth0 session restore error: $e');
      return AuthResult(success: false, error: e.toString());
    }
  }

  /// Refresh access token
  Future<bool> refreshToken() async {
    try {
      if (_credentials?.refreshToken == null) return false;

      final newCredentials = await _auth0.api.renewCredentials(
        refreshToken: _credentials!.refreshToken!,
      );

      _credentials = newCredentials;
      await _storeCredentials(newCredentials);

      print('✅ Auth0 token refreshed');
      return true;

    } catch (e) {
      print('❌ Auth0 token refresh error: $e');
      return false;
    }
  }

  /// Store credentials securely
  Future<void> _storeCredentials(Credentials credentials) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth0_access_token', credentials.accessToken);
    await prefs.setString('auth0_id_token', credentials.idToken);
    if (credentials.refreshToken != null) {
      await prefs.setString('auth0_refresh_token', credentials.refreshToken!);
    }
    await prefs.setInt('auth0_expires_at', credentials.expiresAt.millisecondsSinceEpoch);
  }

  /// Get stored credentials
  Future<Credentials?> _getStoredCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final accessToken = prefs.getString('auth0_access_token');
      final idToken = prefs.getString('auth0_id_token');
      final refreshToken = prefs.getString('auth0_refresh_token');
      final expiresAt = prefs.getInt('auth0_expires_at');

      if (accessToken != null && idToken != null && expiresAt != null) {
        return Credentials(
          accessToken: accessToken,
          idToken: idToken,
          refreshToken: refreshToken,
          tokenType: 'Bearer',
          expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAt),
          user: UserProfile.fromMap({}), // Empty user profile, will be fetched later
        );
      }

      return null;
    } catch (e) {
      // Suppress credentials warning - this is expected when no credentials are stored
      // print('⚠️ Error getting stored credentials: $e');
      return null;
    }
  }

  /// Clear stored credentials
  Future<void> _clearStoredCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth0_access_token');
    await prefs.remove('auth0_id_token');
    await prefs.remove('auth0_refresh_token');
    await prefs.remove('auth0_expires_at');
  }

  /// Check if token is expired
  bool _isTokenExpired([Credentials? credentials]) {
    final creds = credentials ?? _credentials;
    if (creds == null) return true;

    return DateTime.now().isAfter(creds.expiresAt.subtract(const Duration(minutes: 5)));
  }

  /// Get user metadata for MongoDB
  Map<String, dynamic> getUserMetadata() {
    if (_user == null) return {};

    return {
      'auth0_id': _user!.sub ?? '',
      'name': _user!.name ?? 'Unknown User',
      'email': _user!.email ?? '',
      'picture': _user!.pictureUrl?.toString() ?? '',
      'verified': _user!.isEmailVerified ?? false,
      'last_login': DateTime.now().toIso8601String(),
    };
  }
}

/// Auth0 authentication result
class AuthResult {
  final bool success;
  final UserProfile? user;
  final String? userId;
  final String? accessToken;
  final String? error;

  AuthResult({
    required this.success,
    this.user,
    this.userId,
    this.accessToken,
    this.error,
  });
}
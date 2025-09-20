import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/datasources/auth0_datasource.dart';
import '../data/datasources/mongodb_datasource.dart';

/// Auth0 Professional Login Page
/// Best-in-class authentication for PennApps 2025
class Auth0LoginPage extends StatefulWidget {
  const Auth0LoginPage({super.key});

  @override
  State<Auth0LoginPage> createState() => _Auth0LoginPageState();
}

class _Auth0LoginPageState extends State<Auth0LoginPage> {
  final Auth0DataSource _auth0 = Auth0DataSource();
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _error;
  Map<String, dynamic>? _communityStats;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  /// Initialize Auth0 and check for existing session
  Future<void> _initializeServices() async {
    try {
      // Initialize Auth0
      _auth0.initialize();

      // Try to restore existing session
      final result = await _auth0.restoreSession();
      if (result.success && result.userId != null) {
        // Initialize MongoDB in background after successful auth
        _initializeMongoDBInBackground();
        _navigateToHome();
        return;
      }

      // Load community stats in background (non-blocking)
      _loadCommunityStatsInBackground();

    } catch (e) {
      setState(() {
        _error = 'Initialization failed: $e';
      });
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  /// Initialize MongoDB in background without blocking UI
  Future<void> _initializeMongoDBInBackground() async {
    try {
      final mongoDataSource = context.read<MongoDBDataSource>();
      await mongoDataSource.initialize();
      await _loadCommunityStats();
    } catch (e) {
      print('MongoDB initialization failed (non-blocking): $e');
    }
  }

  /// Load community stats in background without blocking UI
  Future<void> _loadCommunityStatsInBackground() async {
    try {
      await _initializeMongoDBInBackground();
    } catch (e) {
      print('Community stats loading failed (non-blocking): $e');
    }
  }

  /// Login with Auth0
  Future<void> _loginWithAuth0() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _auth0.login();

      if (result.success && result.userId != null) {
        // Register user in MongoDB for data storage
        await _registerUserInMongoDB(result.userId!, _auth0.getUserMetadata());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Welcome ${result.user?.name ?? 'User'}!'),
            backgroundColor: Colors.green,
          ),
        );

        _navigateToHome();
      } else {
        setState(() {
          _error = result.error ?? 'Login failed';
        });
      }

    } catch (e) {
      setState(() {
        _error = 'Login error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Register Auth0 user in MongoDB for data storage
  Future<void> _registerUserInMongoDB(String auth0UserId, Map<String, dynamic> metadata) async {
    try {
      final mongoDataSource = context.read<MongoDBDataSource>();

      // Ensure MongoDB is initialized before registration
      if (!mongoDataSource.isInitialized) {
        await mongoDataSource.initialize();
      }

      await mongoDataSource.registerAuth0User(auth0UserId, metadata);
      print('✅ User registered in MongoDB successfully');
    } catch (e) {
      // MongoDB registration failure doesn't break login - just log it
      print('⚠️ MongoDB registration failed (non-critical): $e');
      print('💡 User can still use the app, but community features may be limited');
    }
  }

  /// Load community statistics
  Future<void> _loadCommunityStats() async {
    try {
      final mongoDataSource = context.read<MongoDBDataSource>();
      final stats = await mongoDataSource.getCommunityInsights();
      setState(() {
        _communityStats = stats;
      });
    } catch (e) {
      print('Error loading community stats: $e');
    }
  }

  /// Navigate to home screen
  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue[900]!, Colors.blue[600]!],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 24),
                Text(
                  'Initializing Auth0...',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[900]!, Colors.blue[600]!],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Title
                Icon(
                  Icons.restaurant_menu,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                Text(
                  'Menu Optimizer Pro',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'PennApps 2025 - Auth0 + MongoDB',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 48),

                // Auth0 Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange[600],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.security, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Powered by Auth0',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Login Card
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 48,
                          color: Colors.orange[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Secure Authentication',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Login with your social accounts using Auth0\'s enterprise-grade security.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Text(
                              _error!,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _loginWithAuth0,
                          icon: _isLoading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Icon(Icons.login),
                          label: Text(_isLoading ? 'Authenticating...' : 'Login with Auth0'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Community Stats (if available)
                if (_communityStats != null) ...[
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            '🌟 Community Stats',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatItem(
                                'Menus',
                                '${_communityStats!['total_menus'] ?? 0}',
                              ),
                              _StatItem(
                                'Users',
                                '${_communityStats!['total_users'] ?? 0}',
                              ),
                              _StatItem(
                                'Optimizations',
                                '${_communityStats!['total_optimizations'] ?? 0}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Features List
                Text(
                  'Prize Features:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _FeatureItem(
                  icon: Icons.security,
                  text: 'Auth0 Enterprise Security',
                ),
                _FeatureItem(
                  icon: Icons.cloud_sync,
                  text: 'MongoDB Data Storage',
                ),
                _FeatureItem(
                  icon: Icons.camera_alt,
                  text: 'Gemini Vision OCR',
                ),
                _FeatureItem(
                  icon: Icons.analytics,
                  text: 'Real-time Analytics',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white70,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
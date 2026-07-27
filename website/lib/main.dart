import 'package:flutter/material.dart';
import 'screens/landing_page.dart';
import 'screens/dashboard_page.dart';
import 'screens/monitoring_page.dart';
import 'screens/history_page.dart';
import 'screens/analytics_page.dart';
import 'screens/profile_page.dart';
import 'services/api_service.dart';

void main() {
  runApp(const PostureFixProWeb());
}

class PostureFixProWeb extends StatelessWidget {
  const PostureFixProWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Posture Fix Pro',
      theme: ThemeData(
        primaryColor: const Color(0xFF0B2917),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B2917),
          primary: const Color(0xFF0B2917),
          secondary: const Color(0xFF10B981),
        ),
        fontFamily: 'Outfit',
        useMaterial3: true,
      ),
      home: const MainOrchestrator(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainOrchestrator extends StatefulWidget {
  const MainOrchestrator({super.key});

  @override
  State<MainOrchestrator> createState() => _MainOrchestratorState();
}

class _MainOrchestratorState extends State<MainOrchestrator> {
  bool _isAuthenticated = false;
  bool _isLoading = true;
  String _currentView = 'landing'; // default view
  String _userDisplayName = 'Local User';
  String _userDisplayEmail = 'localuser@posturefixpro.local';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authed = await ApiService.isAuthenticated();
    if (authed) {
      final user = await ApiService.getUser();
      setState(() {
        _isAuthenticated = true;
        _currentView = 'dashboard';
        _userDisplayName = user?['name'] ?? 'Local User';
        _userDisplayEmail = user?['email'] ?? 'localuser@posturefixpro.local';
        _isLoading = false;
      });
    } else {
      setState(() {
        _isAuthenticated = false;
        _currentView = 'landing';
        _isLoading = false;
      });
    }
  }

  // Bypasses the login form silently inside the Flutter Web project
  Future<void> _silentLogin() async {
    setState(() => _isLoading = true);
    try {
      // Try login
      await ApiService.login(
        'localuser@posturefixpro.local',
        'default_password_12345',
      );
    } catch (e) {
      // If user doesn't exist, register first
      try {
        await ApiService.register(
          'Local User',
          'localuser@posturefixpro.local',
          'default_password_12345',
        );
      } catch (regErr) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to connect to local database server automatically.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    await _checkAuth();
  }

  void _navigateTo(String view) {
    setState(() {
      _currentView = view;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B2917),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
      );
    }

    // Unauthenticated landing page view
    if (!_isAuthenticated || _currentView == 'landing') {
      return LandingPage(onLaunchDashboard: _silentLogin);
    }

    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          _getViewTitle(),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0B2917)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: isMobile
            ? IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF0B2917)),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_circle, color: Color(0xFF10B981)),
            onPressed: () {},
          ),
          const SizedBox(width: 12),
        ],
      ),
      drawer: isMobile ? _buildDrawer() : null,
      bottomNavigationBar: isMobile ? _buildBottomNavBar() : null,
      body: Row(
        children: [
          if (!isMobile) ...[
            _buildSidebar(),
            Container(width: 1, color: const Color(0xFFE5E7EB)),
          ],
          Expanded(
            child: _buildActivePage(),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePage() {
    switch (_currentView) {
      case 'dashboard':
        return DashboardPage(onStartScan: () => _navigateTo('monitoring'));
      case 'monitoring':
        return MonitoringPage(onSessionComplete: () {});
      case 'history':
        return const HistoryPage();
      case 'analytics':
        return const AnalyticsPage();
      case 'profile':
        return const ProfilePage();
      default:
        return DashboardPage(onStartScan: () => _navigateTo('monitoring'));
    }
  }

  String _getViewTitle() {
    switch (_currentView) {
      case 'dashboard':
        return 'Workspace Dashboard';
      case 'monitoring':
        return 'Live AI Posture Monitor';
      case 'history':
        return 'Session History Logs';
      case 'analytics':
        return 'Spinal Health Analytics';
      case 'profile':
        return 'Profile Settings';
      default:
        return 'Posture Fix Pro';
    }
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.run_circle_outlined, color: Color(0xFF10B981), size: 28),
              SizedBox(width: 8),
              Text(
                'PostureFixPro',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0B2917)),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView(
              children: [
                _buildSidebarTile('Dashboard', Icons.dashboard_customize_outlined, 'dashboard'),
                _buildSidebarTile('Live Monitor', Icons.camera_alt_outlined, 'monitoring'),
                _buildSidebarTile('History Logs', Icons.history_toggle_off_outlined, 'history'),
                _buildSidebarTile('Analytics', Icons.analytics_outlined, 'analytics'),
                _buildSidebarTile('Profile Settings', Icons.person_outline, 'profile'),
              ],
            ),
          ),
          const Divider(color: Color(0xFFE5E7EB)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.account_circle, color: Color(0xFF10B981), size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userDisplayName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _userDisplayEmail,
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarTile(String label, IconData icon, String targetView) {
    final isSelected = _currentView == targetView;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        onTap: () => _navigateTo(targetView),
        leading: Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 20),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF0B2917),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor: isSelected ? const Color(0xFF0B2917) : Colors.transparent,
        dense: true,
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.run_circle_outlined, color: Color(0xFF10B981), size: 28),
                SizedBox(width: 8),
                Text(
                  'PostureFixPro',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0B2917)),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Expanded(
              child: ListView(
                children: [
                  _buildSidebarTile('Dashboard', Icons.dashboard_customize_outlined, 'dashboard'),
                  _buildSidebarTile('Live Monitor', Icons.camera_alt_outlined, 'monitoring'),
                  _buildSidebarTile('History Logs', Icons.history_toggle_off_outlined, 'history'),
                  _buildSidebarTile('Analytics', Icons.analytics_outlined, 'analytics'),
                  _buildSidebarTile('Profile Settings', Icons.person_outline, 'profile'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    final views = ['dashboard', 'monitoring', 'history', 'analytics', 'profile'];
    final int selectedIndex = views.indexOf(_currentView);

    return BottomNavigationBar(
      currentIndex: selectedIndex != -1 ? selectedIndex : 0,
      onTap: (index) {
        _navigateTo(views[index]);
      },
      selectedItemColor: const Color(0xFF10B981),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dash'),
        BottomNavigationBarItem(icon: Icon(Icons.camera_alt_outlined), label: 'Track'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Logs'),
        BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Stats'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}

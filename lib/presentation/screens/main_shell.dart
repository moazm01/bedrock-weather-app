import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/bedrock_theme.dart';
import 'weather_screen.dart';
import 'home_screen.dart';
import 'hazard_feed_screen.dart';
import 'profile_screen.dart';
import '../../core/services/accelerometer_service.dart';
import '../../core/services/connectivity_service.dart';

// MainShell acts as the global wrapper layout once authenticated.
// It hosts the BottomNavigationBar and swaps between primary screens.
// It is a StatefulWidget because it has to keep track of the selected tab index.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Keep track of the active index of the bottom navigation bar.
  int _currentIndex = 0;
  final AccelerometerService _accelerometerService = AccelerometerService();
  final ConnectivityService _connectivityService = ConnectivityService();

  bool _isOffline = false;
  late final StreamSubscription<bool> _connectivitySubscription;

  // The list of screens linked to our bottom navigation bar.
  final List<Widget> _screens = const [
    WeatherScreen(), // Samsung Weather Dashboard (Primary Screen)
    HomeScreen(), // Safety Map Dashboard
    HazardFeedScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _accelerometerService.startListening(
      onShockDetected: () {
        _showShockAlertDialog();
      },
    );

    _connectivityService.isConnected().then((connected) {
      setState(() {
        _isOffline = !connected;
      });
    });

    _connectivitySubscription = _connectivityService.onConnectivityChanged
        .listen((connected) {
          setState(() {
            _isOffline = !connected;
          });
        });
  }

  @override
  void dispose() {
    _accelerometerService.stopListening();
    _connectivitySubscription.cancel();
    _connectivityService.dispose();
    super.dispose();
  }

  void _showShockAlertDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: BedrockTheme.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: BedrockTheme.borderSubtle),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
              SizedBox(width: 8),
              Text(
                'Sudden Force Detected',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: const Text(
            'We detected a sudden impact or acceleration. Are you okay? Would you like to report a road accident or hazard?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('I\'m OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/hazard_report');
              },
              child: const Text('Report Accident'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // IndexedStack lays out all child screens on top of each other in a stack.
          // It only renders the child at the specified index, maintaining screen states in memory.
          // Why use IndexedStack instead of body: _screens[_currentIndex]?
          // Answer: Dynamically swapping widgets destroys screen states. IndexedStack preserves
          // scroll offsets, inputs, and map zooms when switching tabs.
          // Reference: https://api.flutter.dev/flutter/widgets/IndexedStack-class.html
          Positioned.fill(
            child: IndexedStack(index: _currentIndex, children: _screens),
          ),
          if (_isOffline)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Offline Mode Active. Displaying cached hazard reports.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 20,
            left: 40,
            right: 40,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: BedrockTheme.cardDark.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: BedrockTheme.borderSubtle.withOpacity(0.6),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(
                        index: 0,
                        icon: Icons.wb_cloudy_outlined,
                        activeIcon: Icons.wb_cloudy,
                        semanticLabel: 'Weather',
                      ),
                      _buildNavItem(
                        index: 1,
                        icon: Icons.map_outlined,
                        activeIcon: Icons.map,
                        semanticLabel: 'Map',
                      ),
                      _buildNavItem(
                        index: 2,
                        icon: Icons.warning_amber_outlined,
                        activeIcon: Icons.warning_rounded,
                        semanticLabel: 'Hazards',
                      ),
                      _buildNavItem(
                        index: 3,
                        icon: Icons.person_outline,
                        activeIcon: Icons.person,
                        semanticLabel: 'Profile',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String semanticLabel,
  }) {
    final isActive = _currentIndex == index;
    return SizedBox(
      width: 50,
      height: 50,
      child: IconButton(
        icon: Icon(isActive ? activeIcon : icon, semanticLabel: semanticLabel),
        color: isActive ? BedrockTheme.accentBlueDark : const Color(0xFF48484A),
        iconSize: 26,
        onPressed: () {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

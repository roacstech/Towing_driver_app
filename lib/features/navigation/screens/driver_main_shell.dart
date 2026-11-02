import 'package:flutter/material.dart';
import '../../home/screens/driver_home_screen.dart';
import '../../jobs/screens/request_list_screen.dart';
import '../../earnings/screens/driver_earnings_screen.dart';
import '../../profile/screens/driver_profile_screen.dart';
import '../widgets/driver_bottom_navigation.dart';

class DriverMainShell extends StatefulWidget {
  const DriverMainShell({super.key});

  @override
  State<DriverMainShell> createState() => _DriverMainShellState();
}

class _DriverMainShellState extends State<DriverMainShell> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DriverHomeScreen(
            onSwitchToProfile: () => _onTabSelected(3),
          ),
          const RequestListScreen(),
          const DriverEarningsScreen(),
          const DriverProfileScreen(),
        ],
      ),
      bottomNavigationBar: DriverBottomNavigation(
        currentIndex: _currentIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}

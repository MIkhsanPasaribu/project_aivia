import 'package:flutter/material.dart';
import 'package:project_aivia/core/constants/app_colors.dart';
import 'package:project_aivia/core/constants/app_strings.dart';
import 'package:project_aivia/core/constants/app_dimensions.dart';
import 'package:project_aivia/presentation/screens/patient/activity/activity_list_screen.dart';
import 'package:project_aivia/presentation/screens/patient/profile_screen.dart';

/// Patient Home Screen dengan Bottom Navigation
class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _selectedIndex = 0;

  // List of screens untuk bottom navigation
  final List<Widget> _screens = [
    const ActivityListScreen(),
    const Center(
      child: Text('Kenali Wajah\n(Coming Soon)', textAlign: TextAlign.center),
    ),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: AppDimensions.elevationM,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: AppDimensions.iconL),
              activeIcon: Icon(Icons.home, size: AppDimensions.iconL),
              label: AppStrings.navHome,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.face_outlined, size: AppDimensions.iconL),
              activeIcon: Icon(Icons.face, size: AppDimensions.iconL),
              label: AppStrings.navRecognizeFace,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outlined, size: AppDimensions.iconL),
              activeIcon: Icon(Icons.person, size: AppDimensions.iconL),
              label: AppStrings.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}

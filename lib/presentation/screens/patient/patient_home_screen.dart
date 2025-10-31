import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_aivia/core/constants/app_strings.dart';
import 'package:project_aivia/core/constants/app_dimensions.dart';
import 'package:project_aivia/presentation/screens/patient/activity/activity_list_screen.dart';
import 'package:project_aivia/presentation/screens/patient/profile_screen.dart';
import 'package:project_aivia/presentation/widgets/emergency/emergency_button.dart';
import 'package:project_aivia/presentation/providers/auth_provider.dart';

/// Patient Home Screen dengan Bottom Navigation
class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
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
    // Get current user ID for emergency button
    final currentUserAsync = ref.watch(currentUserProfileProvider);
    final userId = currentUserAsync.value?.id ?? '';

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: IndexedStack(
          key: ValueKey<int>(_selectedIndex),
          index: _selectedIndex,
          children: _screens,
        ),
      ),
      floatingActionButton: userId.isNotEmpty
          ? EmergencyButton(
              patientId: userId,
              onAlertCreated: () {
                // Optional: Navigate to specific screen after alert created
                // atau refresh data jika diperlukan
              },
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
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

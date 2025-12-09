import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_aivia/core/constants/app_colors.dart';
import 'package:project_aivia/presentation/screens/patient/profile_screen.dart';
import 'package:project_aivia/presentation/screens/family/dashboard/family_dashboard_screen.dart';
import 'package:project_aivia/presentation/screens/family/patient_tracking/patient_map_tab_wrapper.dart';
import 'package:project_aivia/presentation/screens/family/activities/activities_tab_wrapper.dart';
import 'package:project_aivia/presentation/screens/family/known_persons/known_persons_tab_wrapper.dart';

/// Family Home Screen dengan Bottom Navigation
/// Tabs: Dashboard, Lokasi Pasien, Kelola Aktivitas, Orang Dikenal, Profil
class FamilyHomeScreen extends ConsumerStatefulWidget {
  const FamilyHomeScreen({super.key});

  @override
  ConsumerState<FamilyHomeScreen> createState() => _FamilyHomeScreenState();
}

class _FamilyHomeScreenState extends ConsumerState<FamilyHomeScreen> {
  int _currentIndex = 0;

  // Screens untuk setiap tab
  final List<Widget> _screens = [
    const FamilyDashboardScreen(), // ✅ Dashboard with real-time patients
    const PatientMapTabWrapper(), // ✅ Lokasi Pasien dengan Map
    const ActivitiesTabWrapper(), // ✅ Kelola Aktivitas
    const KnownPersonsTabWrapper(), // ✅ Orang Dikenal
    const ProfileScreen(), // ✅ Profil
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: IndexedStack(
          key: ValueKey<int>(_currentIndex),
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textTertiary,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_outlined),
              activeIcon: Icon(Icons.location_on),
              label: 'Lokasi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_note_outlined),
              activeIcon: Icon(Icons.event_note),
              label: 'Aktivitas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Orang Dikenal',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

# 🎯 PRE-PHASE 2 PART 4: Complete All TODOs (100% Clean)

**Tanggal:** 12 Oktober 2025  
**Status:** 🔄 IN PLANNING  
**Tujuan:** Menyelesaikan 8 TODOs + create missing screens/widgets untuk 100% clean sebelum Phase 2

---

## 📊 EXECUTIVE SUMMARY

**Current Status:**

- ✅ Phase 2 blockers: 0 (all resolved)
- ⚠️ TODOs remaining: 8
- ⚠️ Missing screens: 1 (Patient Detail Screen)
- ⚠️ Missing widgets: 6 (Common widgets)

**Target Pre-Phase 2 Part 4:**

- ✅ Resolve ALL 8 TODOs
- ✅ Create Patient Detail Screen
- ✅ Create 6 common widgets
- ✅ Wire all placeholder navigations
- ✅ Achieve 100% clean (0 TODOs, 0 placeholders)

**Estimated Time:** 8-12 hours (1-2 hari kerja)

---

## 📋 DETAILED TASK BREAKDOWN

### Group A: Critical TODO Fixes (3-4 hours)

#### A1: Implement Auth State Check di Splash Screen ⏱️ 30 menit

**File:** `lib/presentation/screens/splash/splash_screen.dart`  
**Line:** 56  
**TODO:** "Cek status autentikasi"

**Current Code:**

```dart
// TODO: Cek status autentikasi
// Sementara arahkan ke login
Navigator.of(context).pushReplacementNamed('/login');
```

**Implementation Plan:**

1. Convert to ConsumerStatefulWidget
2. Check `ref.watch(authStateProvider)`
3. Navigate based on auth state:
   - If authenticated → Get user role → Navigate to appropriate home
   - If not authenticated → Navigate to /login

**Estimated:** 30 minutes

**Priority:** 🔴 HIGH - Improves UX (no need to login every time)

---

#### A2: Implement Profile Realtime Subscription ⏱️ 1-2 jam

**File:** `lib/presentation/providers/profile_provider.dart`  
**Line:** 26  
**TODO:** "Implement Realtime subscription untuk auto-update"

**Current State:**

- Manual refresh only
- User must pull-to-refresh to see profile changes

**Implementation Plan:**

1. Create `currentUserProfileRealtimeProvider` using StreamProvider
2. Subscribe to Supabase realtime channel for profiles table
3. Filter by current user ID
4. Auto-update on changes from other devices/sessions

**Code Snippet:**

```dart
@riverpod
Stream<UserProfile?> currentUserProfileRealtime(
  CurrentUserProfileRealtimeRef ref,
) async* {
  final user = supabase.auth.currentUser;
  if (user == null) {
    yield null;
    return;
  }

  // Initial data
  final initialData = await ref.watch(profileRepositoryProvider)
    .getProfile(user.id)
    .then((result) => result.fold(
      onSuccess: (profile) => profile,
      onFailure: (_) => null,
    ));

  yield initialData;

  // Realtime updates
  final stream = supabase
    .from('profiles')
    .stream(primaryKey: ['id'])
    .eq('id', user.id)
    .map((data) => data.isEmpty ? null : UserProfile.fromJson(data.first));

  yield* stream;
}
```

**Estimated:** 1-2 hours (with testing)

**Priority:** 🟡 MEDIUM - Nice to have, improves real-time experience

---

#### A3: Wire Dashboard Navigation (Link Patient) ⏱️ 15 menit

**File:** `lib/presentation/screens/family/dashboard/family_dashboard_screen.dart`  
**Line:** 104  
**TODO:** "Navigate to Link Patient Screen"

**Current Code:**

```dart
// TODO: Navigate to Link Patient Screen
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Link Patient (Coming Soon)')),
);
```

**Implementation Plan:**

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const LinkPatientScreen(),
  ),
);
```

**Estimated:** 15 minutes

**Priority:** 🟢 LOW - LinkPatientScreen already exists, just wire navigation

---

#### A4: Wire Dashboard Navigation (Activities) ⏱️ 15 menit

**File:** `lib/presentation/screens/family/dashboard/family_dashboard_screen.dart`  
**Line:** 375  
**TODO:** "Navigate to activities"

**Current Code:**

```dart
// TODO: Navigate to activities
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Activities (Coming Soon)')),
);
```

**Implementation Plan:**

1. Check if patient has activities tab (currently patient-only screen)
2. Option 1: Navigate to patient's activity list (need to create family view)
3. Option 2: Navigate to activity management screen (to be created)
4. **Recommended:** Navigate to bottom nav index (if on same screen)

**Estimated:** 15 minutes (decision + implementation)

**Priority:** 🟢 LOW - Depends on design decision

---

### Group B: Settings Screen Functionality (2-3 hours)

#### B1: Connect Theme Provider (Dark Mode) ⏱️ 1-2 jam

**File:** `lib/presentation/screens/common/settings_screen.dart`  
**Line:** 31  
**TODO:** "Connect to theme provider"

**Current Code:**

```dart
value: false, // TODO: Connect to theme provider
```

**Implementation Plan:**

**Step 1:** Create ThemeProvider

```dart
// lib/presentation/providers/theme_provider.dart
@riverpod
class ThemeMode extends _$ThemeMode {
  @override
  ThemeMode build() {
    // Load from SharedPreferences
    return ThemeMode.light;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    // Save to SharedPreferences
    state = mode;
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.light
      ? ThemeMode.dark
      : ThemeMode.light;
    await setThemeMode(newMode);
  }
}
```

**Step 2:** Update main.dart

```dart
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // ...
    );
  }
}
```

**Step 3:** Update settings_screen.dart

```dart
final themeMode = ref.watch(themeModeProvider);
final isDarkMode = themeMode == ThemeMode.dark;

SwitchListTile(
  value: isDarkMode,
  onChanged: (value) => ref.read(themeModeProvider.notifier).toggleTheme(),
);
```

**Step 4:** Create dark theme in theme_config.dart

**Estimated:** 1-2 hours

**Priority:** 🟡 MEDIUM - Popular feature, improves UX

---

#### B2: Connect Notification Service ⏱️ 30 menit

**File:** `lib/presentation/screens/common/settings_screen.dart`  
**Line:** 59  
**TODO:** "Connect to notification service"

**Current Code:**

```dart
value: true, // TODO: Connect to notification service
```

**Implementation Plan:**

**Step 1:** Add SharedPreferences key

```dart
// In notification_service.dart or new settings_service.dart
static const String _notificationsEnabledKey = 'notifications_enabled';

Future<bool> areNotificationsEnabled() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_notificationsEnabledKey) ?? true;
}

Future<void> setNotificationsEnabled(bool enabled) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_notificationsEnabledKey, enabled);

  if (enabled) {
    // Re-schedule all notifications
  } else {
    // Cancel all notifications
    await AwesomeNotifications().cancelAll();
  }
}
```

**Step 2:** Create NotificationSettingsProvider

```dart
@riverpod
class NotificationSettings extends _$NotificationSettings {
  @override
  Future<bool> build() async {
    return await NotificationService.areNotificationsEnabled();
  }

  Future<void> toggle() async {
    final current = state.value ?? true;
    await NotificationService.setNotificationsEnabled(!current);
    ref.invalidateSelf();
  }
}
```

**Step 3:** Wire to settings_screen.dart

**Estimated:** 30 minutes

**Priority:** 🟡 MEDIUM - Important for user control

---

#### B3: Check Actual Permission Status ⏱️ 30 menit

**File:** `lib/presentation/screens/common/settings_screen.dart`  
**Line:** 95  
**TODO:** "Check actual permission status"

**Current Code:**

```dart
value: true, // TODO: Check actual permission status
```

**Implementation Plan:**

**Step 1:** Create PermissionProvider

```dart
@riverpod
Future<bool> locationPermissionStatus(LocationPermissionStatusRef ref) async {
  final permission = await Permission.location.status;
  return permission.isGranted;
}

@riverpod
Future<bool> cameraPermissionStatus(CameraPermissionStatusRef ref) async {
  final permission = await Permission.camera.status;
  return permission.isGranted;
}

@riverpod
Future<bool> notificationPermissionStatus(NotificationPermissionStatusRef ref) async {
  return await AwesomeNotifications().isNotificationAllowed();
}
```

**Step 2:** Wire to settings_screen.dart

```dart
final locationPermission = ref.watch(locationPermissionStatusProvider);

locationPermission.when(
  data: (isGranted) => SwitchListTile(
    value: isGranted,
    onChanged: (value) async {
      if (value) {
        await Permission.location.request();
        ref.invalidate(locationPermissionStatusProvider);
      } else {
        await openAppSettings();
      }
    },
  ),
  loading: () => SwitchListTile(value: false, onChanged: null),
  error: (_, __) => SwitchListTile(value: false, onChanged: null),
);
```

**Estimated:** 30 minutes

**Priority:** 🟡 MEDIUM - Important for permission management

---

### Group C: Create Patient Detail Screen (2-3 hours)

#### C1: Design & Create Patient Detail Screen ⏱️ 2-3 jam

**File:** `lib/presentation/screens/family/patients/patient_detail_screen.dart` (NEW)  
**TODO:** Wire navigation from dashboard line 222

**Features to Include:**

1. **Patient Header Card**

   - Avatar
   - Name
   - Age (from date_of_birth)
   - Relationship type
   - Phone number

2. **Quick Stats Section**

   - Total activities (today/week/month)
   - Last location timestamp
   - Active emergency alerts count

3. **Recent Activities List**

   - Last 5-10 activities
   - Status (completed/pending)
   - "See All Activities" button

4. **Location Section**

   - Last known location
   - Map preview (or "View on Map" button)
   - Location history button

5. **Emergency Contacts**

   - List of emergency contacts for this patient
   - Priority indicators

6. **Action Buttons**
   - Call patient
   - Send message
   - View full profile
   - Edit patient info

**Implementation Structure:**

```dart
class PatientDetailScreen extends ConsumerWidget {
  final String patientId;

  const PatientDetailScreen({
    super.key,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientProfile = ref.watch(profileByIdProvider(patientId));
    final lastLocation = ref.watch(lastLocationProvider(patientId));
    final recentActivities = ref.watch(recentActivitiesProvider(patientId));
    final emergencyContacts = ref.watch(emergencyContactsProvider(patientId));

    return Scaffold(
      appBar: AppBar(title: Text('Detail Pasien')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildPatientHeader(patientProfile),
            _buildQuickStats(context, ref),
            _buildRecentActivities(recentActivities),
            _buildLocationSection(lastLocation),
            _buildEmergencyContacts(emergencyContacts),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }
}
```

**Estimated:** 2-3 hours

**Priority:** 🟡 MEDIUM - Nice to have, improves family experience

---

### Group D: Create Common Widgets Library (2-3 hours)

#### D1: CustomButton Widget ⏱️ 30 menit

**File:** `lib/presentation/widgets/common/custom_button.dart` (NEW)

**Features:**

- Primary, secondary, outline variants
- Loading state
- Disabled state
- Icon support
- Size variants (small, medium, large)

**Example:**

```dart
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final IconData? icon;

  // Implementation...
}
```

**Estimated:** 30 minutes

---

#### D2: CustomTextField Widget ⏱️ 30 menit

**File:** `lib/presentation/widgets/common/custom_text_field.dart` (NEW)

**Features:**

- Label
- Hint text
- Prefix/suffix icons
- Validation error display
- Password visibility toggle
- Character counter
- Max length

**Estimated:** 30 minutes

---

#### D3: LoadingIndicator Widget ⏱️ 15 menit

**File:** `lib/presentation/widgets/common/loading_indicator.dart` (NEW)

**Features:**

- Circular loading
- With/without overlay
- Custom message
- Custom color

**Estimated:** 15 minutes

---

#### D4: ErrorWidget Widget ⏱️ 20 menit

**File:** `lib/presentation/widgets/common/error_widget.dart` (NEW)

**Features:**

- Error icon
- Error message
- Retry button
- Custom action button

**Estimated:** 20 minutes

---

#### D5: EmptyStateWidget Widget ⏱️ 20 menit

**File:** `lib/presentation/widgets/common/empty_state_widget.dart` (NEW)

**Features:**

- Empty icon/illustration
- Title & description
- Call-to-action button

**Estimated:** 20 minutes

---

#### D6: ConfirmationDialog Widget ⏱️ 20 menit

**File:** `lib/presentation/widgets/common/confirmation_dialog.dart` (NEW)

**Features:**

- Title
- Description
- Confirm/cancel buttons
- Destructive variant (red confirm button)
- Custom actions

**Estimated:** 20 minutes

---

## 📊 TIME ESTIMATION SUMMARY

| Group                         | Tasks    | Estimated Time  |
| ----------------------------- | -------- | --------------- |
| **A: Critical TODO Fixes**    | 4 tasks  | 3-4 hours       |
| **B: Settings Functionality** | 3 tasks  | 2-3 hours       |
| **C: Patient Detail Screen**  | 1 task   | 2-3 hours       |
| **D: Common Widgets**         | 6 tasks  | 2.5 hours       |
| **Testing & Polish**          | -        | 1-2 hours       |
| **TOTAL**                     | 14 tasks | **10-14 hours** |

**Realistic Estimate:** 1.5-2 hari kerja (dengan testing)

---

## 🎯 RECOMMENDED EXECUTION ORDER

### Day 1 (6-7 hours):

**Morning Session (3-4 hours):**

1. ✅ A1: Auth state check di splash (30 min)
2. ✅ A3: Wire link patient navigation (15 min)
3. ✅ A4: Wire activities navigation (15 min)
4. ✅ D1-D6: Create all 6 common widgets (2.5 hours)

**Afternoon Session (3 hours):** 5. ✅ A2: Profile realtime subscription (1-2 hours) 6. ✅ B2: Connect notification service (30 min) 7. ✅ B3: Check permission status (30 min)

### Day 2 (4-7 hours):

**Morning Session (3-4 hours):** 8. ✅ C1: Create Patient Detail Screen (2-3 hours) 9. ✅ Wire navigation from dashboard (15 min)

**Afternoon Session (1-3 hours):** 10. ✅ B1: Dark mode theme provider (1-2 hours) - OPTIONAL 11. ✅ Testing all features (1 hour) 12. ✅ Flutter analyze & fix warnings (30 min)

---

## ✅ DELIVERABLES

After Pre-Phase 2 Part 4 completion:

1. ✅ **0 TODOs** remaining in codebase
2. ✅ **0 "Coming Soon" placeholders**
3. ✅ **Patient Detail Screen** fully functional
4. ✅ **6 common widgets** ready for reuse
5. ✅ **Settings fully functional** (notifications, permissions)
6. ✅ **Dark mode** (optional, jika ada waktu)
7. ✅ **Auth state check** working (no need to login every time)
8. ✅ **Profile realtime** working (auto-update)
9. ✅ **All navigation wired** (no more SnackBar placeholders)
10. ✅ **Flutter analyze: 0 errors, 0 warnings**

---

## 🎯 SUCCESS CRITERIA

**Must Have (P0):**

- [x] All 8 TODOs resolved
- [x] Patient Detail Screen created & wired
- [x] Common widgets created (6 widgets)
- [x] Flutter analyze clean (0 errors, 0 warnings)
- [x] All placeholder navigations wired

**Should Have (P1):**

- [x] Settings functionality working (notifications, permissions)
- [x] Auth state check (persistent login)
- [x] Profile realtime subscription

**Nice to Have (P2):**

- [ ] Dark mode fully implemented
- [ ] Unit tests for new widgets
- [ ] E2E tests for new flows

---

## 🚀 DECISION POINT

### Option 1: Full Pre-Phase 2 Part 4 (Recommended for 100% clean)

**Pros:**

- ✅ 100% TODOs resolved
- ✅ No placeholders
- ✅ Better UX (dark mode, realtime, persistent login)
- ✅ Common widgets library ready
- ✅ Patient Detail Screen complete

**Cons:**

- ⏱️ Takes 1.5-2 days
- 🔄 Delays Phase 2 start

**Best for:** Perfectionists, long-term maintenance, demo-ready app

---

### Option 2: Minimal Pre-Phase 2 Part 4 (Quick wins only)

**Focus on:**

- A1: Auth state check (30 min)
- A3, A4: Wire navigations (30 min)
- B2, B3: Settings functionality (1 hour)
- D1-D6: Common widgets (2.5 hours)

**Skip:**

- A2: Profile realtime (can add later)
- B1: Dark mode (can add later)
- C1: Patient Detail Screen (can add in Phase 2)

**Total Time:** 4-5 hours (half day)

**Best for:** Want to start Phase 2 soon, but clean up quick wins

---

### Option 3: Skip Pre-Phase 2 Part 4 (Direct to Phase 2)

**Start Phase 2 immediately**, fix TODOs incrementally during Phase 2 development.

**Best for:** Urgent timeline, Phase 2 features are priority

---

## 💬 QUESTION FOR YOU

**Mana yang Anda pilih?**

1. **Full Pre-Phase 2 Part 4** (1.5-2 hari, 100% clean)
2. **Minimal Pre-Phase 2 Part 4** (4-5 jam, quick wins)
3. **Skip, langsung Phase 2** (fix TODOs sambil jalan)

Atau ada prioritas TODO tertentu yang paling penting untuk Anda?

---

**Document Version:** 1.0  
**Created:** 12 Oktober 2025  
**Status:** Awaiting User Decision

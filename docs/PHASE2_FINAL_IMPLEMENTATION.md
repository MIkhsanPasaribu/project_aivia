# Phase 2 Final Implementation - Tracking Feature Completion

**Tanggal**: 06 Desember 2025  
**Status**: ✅ Database Migration 014 Deployed  
**Objective**: Complete FCM Integration + Geofencing UI untuk Anak & Orang Tua/Wali  
**Testing**: `flutter analyze` only

---

## 📊 Analisis Mendalam

### ✅ Yang Sudah Selesai

1. **Backend Infrastructure** (100% DONE)

   - ✅ Edge Function `send-emergency-fcm` deployed & active
   - ✅ Cron job berjalan setiap 1 menit (pg_cron)
   - ✅ Database migrations 006-014 deployed
   - ✅ Table `pending_notifications` created (migration 014)
   - ✅ Table `notification_delivery_logs` created
   - ✅ Table `fcm_tokens` exists
   - ✅ Table `geofences` exists (dengan PostGIS)
   - ✅ Table `geofence_events` exists
   - ✅ Firebase service account configured
   - ✅ Supabase secrets configured

2. **Flutter Services** (70% DONE)
   - ✅ FCMService class implemented (508 lines)
     - Token management ✅
     - Message handlers ✅
     - Local notifications ✅
   - ✅ FCMRepository implemented (270 lines)
   - ✅ FCMProvider implemented (167 lines)
   - ✅ LocationService implemented (460 lines)
   - ✅ EmergencyButton widget exists (279 lines)

### ❌ Yang Masih Missing

1. **FCM Integration Issues**

   - ❌ FCMService TIDAK dipanggil saat app startup
   - ❌ Login screen tidak initialize FCM
   - ❌ Register screen tidak initialize FCM
   - ❌ Splash screen tidak check FCM token
   - ❌ Notification tap handler belum ada
   - ❌ EmergencyButton belum queue ke `pending_notifications`

2. **Geofencing UI (100% Missing)**

   - ❌ Model: `geofence.dart`, `geofence_event.dart` tidak ada
   - ❌ Repository: `geofence_repository.dart` tidak ada
   - ❌ Service: `geofence_monitoring_service.dart` tidak ada
   - ❌ Screens: Semua geofence screens tidak ada
   - ❌ Widgets: Map picker, geofence card tidak ada
   - ❌ Integration: FamilyHomeScreen tidak ada link ke geofences

3. **Navigation & Integration**
   - ❌ Notification tap tidak navigate ke screen yang tepat
   - ❌ Geofence monitoring tidak terintegrasi dengan LocationService
   - ❌ Parent/Wali tidak bisa manage geofences

---

## 🎯 Implementation Plan (11 Steps)

### **Sprint A: FCM Integration & Models (Steps 1-5)**

#### **Step 1: Buat Data Models** 🆕

**Files to Create**:

1. **`lib/data/models/geofence.dart`**

   - Model untuk geofence (fence_type, center_coordinates, radius, alerts)
   - JSON serialization (fromJson, toJson)
   - GEOGRAPHY parsing (PostGIS POINT)

2. **`lib/data/models/geofence_event.dart`**

   - Model untuk geofence events (enter/exit)
   - Status tracking

3. **`lib/data/models/pending_notification.dart`**
   - Model untuk pending notifications queue
   - notification_type enum
   - status enum

**Quality Standards**:

- ✅ Dartdoc comments (Bahasa Indonesia)
- ✅ Immutable classes dengan @immutable
- ✅ JSON serialization complete
- ✅ Null safety

**Time Estimate**: 1 hour

---

#### **Step 2: Buat GeofenceRepository** 🆕

**File**: `lib/data/repositories/geofence_repository.dart` (NEW)

**Methods**:

```dart
/// Create geofence baru
Future<Result<Geofence>> createGeofence({
  required String patientId,
  required String name,
  required double latitude,
  required double longitude,
  required double radiusMeters,
  required FenceType fenceType,
  bool alertOnEnter = true,
  bool alertOnExit = true,
});

/// Get all geofences untuk patient tertentu
Future<Result<List<Geofence>>> getGeofencesForPatient(String patientId);

/// Update geofence
Future<Result<Geofence>> updateGeofence(Geofence geofence);

/// Delete geofence
Future<Result<void>> deleteGeofence(String geofenceId);

/// Activate/deactivate geofence
Future<Result<void>> toggleGeofenceStatus(String geofenceId, bool isActive);

/// Get geofence events history
Future<Result<List<GeofenceEvent>>> getGeofenceEvents({
  required String patientId,
  DateTime? startDate,
  DateTime? endDate,
});
```

**Quality Standards**:

- ✅ Error handling dengan Result<T>
- ✅ Supabase RLS policies respected
- ✅ Geography ST_MakePoint untuk coordinates
- ✅ Comprehensive logging

**Time Estimate**: 1.5 hours

---

#### **Step 3: Initialize FCM di App Startup** 🔧

**Files to Modify**:

1. **`lib/presentation/screens/auth/login_screen.dart`**

**Changes**:

```dart
// After successful login (line ~50)
result.fold(
  onSuccess: (userProfile) async {
    // ✨ TAMBAHAN: Initialize FCM
    try {
      final fcmService = ref.read(fcmServiceProvider);
      await fcmService.initialize();
      debugPrint('✅ FCM initialized after login');
    } catch (e) {
      debugPrint('⚠️ FCM initialization failed: $e');
      // Don't block navigation
    }

    // Navigate based on user role
    final route = userProfile.userRole == UserRole.patient
        ? '/patient/home'
        : '/family/home';

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(route);
    // ... rest of code
  },
  // ...
);
```

2. **`lib/presentation/screens/auth/register_screen.dart`**

**Changes**: Same as login - initialize FCM after successful registration

3. **`lib/presentation/screens/splash/splash_screen.dart`**

**Changes**:

```dart
// After checking auth state, sebelum navigate (line ~60)
authState.when(
  data: (user) async {
    if (user != null) {
      // ✨ TAMBAHAN: Check & refresh FCM token
      try {
        final fcmService = ref.read(fcmServiceProvider);
        if (fcmService.currentToken == null) {
          await fcmService.initialize();
          debugPrint('✅ FCM token refreshed');
        }
      } catch (e) {
        debugPrint('⚠️ FCM token refresh failed: $e');
      }

      // Continue with profile check...
    }
  },
  // ...
);
```

**Quality Standards**:

- ✅ Non-blocking FCM initialization (jangan block navigation)
- ✅ Error handling comprehensive
- ✅ Logging untuk debugging

**Time Estimate**: 45 minutes

---

#### **Step 4: Implementasi Notification Tap Handler** 🔧

**File**: `lib/data/services/fcm_service.dart` (MODIFY)

**Changes**:

1. Add global navigator key reference
2. Implement `_handleNotificationTap` method
3. Setup `onMessageOpenedApp` listener

**Implementation**:

```dart
// Add near top of class (line ~30)
/// Global navigator key untuk navigation dari background
static GlobalKey<NavigatorState>? navigatorKey;

/// Set navigator key (call from main.dart)
static void setNavigatorKey(GlobalKey<NavigatorState> key) {
  navigatorKey = key;
}

// Add in initialize() method after message handlers (line ~110)
// Setup notification tap handler (app opened from terminated state)
_firebaseMessaging.getInitialMessage().then((message) {
  if (message != null) {
    _handleNotificationTap(message);
  }
});

// Listen for notification taps (app in background)
FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

// Add new method at end of class
/// Handle notification tap - navigate based on type
void _handleNotificationTap(RemoteMessage message) {
  debugPrint('🔔 FCMService: Notification tapped');

  if (navigatorKey == null || navigatorKey!.currentContext == null) {
    debugPrint('⚠️ Navigator key not set, cannot navigate');
    return;
  }

  final data = message.data;
  final type = data['type'] as String?;
  final patientId = data['patient_id'] as String?;

  if (type == null) return;

  switch (type) {
    case 'emergency_alert':
      // Navigate to patient map screen
      if (patientId != null) {
        navigatorKey!.currentState?.pushNamed(
          '/family/patient-map',
          arguments: {'patient_id': patientId},
        );
      }
      break;

    case 'geofence_alert':
      // Navigate to geofence detail
      final geofenceId = data['geofence_id'] as String?;
      if (geofenceId != null) {
        navigatorKey!.currentState?.pushNamed(
          '/family/geofence-detail',
          arguments: {'geofence_id': geofenceId},
        );
      }
      break;

    case 'activity_reminder':
      // Navigate to activity list
      navigatorKey!.currentState?.pushNamed('/patient/activities');
      break;

    default:
      debugPrint('⚠️ Unknown notification type: $type');
  }
}
```

**File**: `lib/main.dart` (MODIFY)

**Changes**:

```dart
// Add near top (line ~10)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// In main() before runApp (line ~25)
void main() async {
  // ... existing initialization

  // ✨ TAMBAHAN: Set navigator key untuk FCM
  FCMService.setNavigatorKey(navigatorKey);

  runApp(const ProviderScope(child: MyApp()));
}

// In MaterialApp (line ~60)
return MaterialApp(
  navigatorKey: navigatorKey, // ✨ TAMBAHAN
  // ... rest of config
);
```

**Quality Standards**:

- ✅ Safe navigation checks (null checks)
- ✅ Type-based routing
- ✅ Arguments passed correctly

**Time Estimate**: 1 hour

---

#### **Step 5: Update EmergencyButton - Queue Notification** 🔧

**File**: `lib/presentation/widgets/emergency/emergency_button.dart` (MODIFY)

**Current Flow**:

```
EmergencyButton → EmergencyRepository.createAlert() → emergency_alerts table
```

**New Flow**:

```
EmergencyButton → EmergencyRepository.createAlert() → emergency_alerts table
                ↓
              Queue notification → pending_notifications table → Cron picks up → Edge Function → FCM
```

**Changes**:

```dart
// Add at top of class (line ~10)
import '../../data/repositories/fcm_repository.dart';

// In _triggerEmergency method, after creating alert (line ~80)
Future<void> _triggerEmergency() async {
  // ... existing code creates alert in emergency_alerts

  result.fold(
    onSuccess: (alert) async {
      // ✨ TAMBAHAN: Queue notification untuk family members
      try {
        final fcmRepository = ref.read(fcmRepositoryProvider);

        // Get emergency contacts
        final contactsResult = await emergencyRepo.getEmergencyContacts(
          widget.patientId,
        );

        await contactsResult.fold(
          onSuccess: (contacts) async {
            // Queue notification untuk setiap contact
            for (final contact in contacts) {
              await fcmRepository.queueNotification(
                recipientUserId: contact.contactId,
                notificationType: 'emergency',
                title: 'PERINGATAN DARURAT!',
                body: '${userProfile.fullName} membutuhkan bantuan segera!',
                data: {
                  'type': 'emergency_alert',
                  'patient_id': widget.patientId,
                  'alert_id': alert.id,
                  'latitude': currentPosition.latitude.toString(),
                  'longitude': currentPosition.longitude.toString(),
                },
                priority: 10, // Max priority
              );
            }

            debugPrint('✅ Emergency notifications queued');
          },
          onFailure: (failure) {
            debugPrint('⚠️ Failed to queue notifications: ${failure.message}');
          },
        );
      } catch (e) {
        debugPrint('⚠️ Error queueing notifications: $e');
      }

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        // ... existing snackbar
      );
    },
    // ... existing error handling
  );
}
```

**File**: `lib/data/repositories/fcm_repository.dart` (ADD METHOD)

**Add Method**:

```dart
/// Queue notification untuk dikirim via Edge Function
///
/// Parameters:
/// - [recipientUserId]: User ID penerima
/// - [notificationType]: 'emergency', 'geofence', 'activity', etc
/// - [title]: Judul notifikasi
/// - [body]: Isi notifikasi
/// - [data]: Data tambahan (JSON)
/// - [priority]: 1-10 (10 = tertinggi)
Future<Result<String>> queueNotification({
  required String recipientUserId,
  required String notificationType,
  required String title,
  required String body,
  Map<String, dynamic>? data,
  int priority = 5,
}) async {
  try {
    final response = await _supabase
        .from('pending_notifications')
        .insert({
          'recipient_user_id': recipientUserId,
          'notification_type': notificationType,
          'title': title,
          'body': body,
          'data': data ?? {},
          'status': 'pending',
          'scheduled_at': DateTime.now().toIso8601String(),
          'priority': priority,
        })
        .select('id')
        .single();

    final notificationId = response['id'] as String;
    debugPrint('✅ Notification queued: $notificationId');

    return Result.success(notificationId);
  } catch (e) {
    return Result.failure(
      RepositoryFailure(
        message: 'Gagal queue notification: ${e.toString()}',
      ),
    );
  }
}
```

**Quality Standards**:

- ✅ Don't block emergency button if queueing fails
- ✅ Queue notification AFTER alert created successfully
- ✅ Priority 10 untuk emergency

**Time Estimate**: 1 hour

---

### **Sprint B: Geofencing UI (Steps 6-10)**

#### **Step 6: Buat GeofenceListScreen (Orang Tua/Wali)** 🆕

**File**: `lib/presentation/screens/family/geofences/geofence_list_screen.dart` (NEW)

**Features**:

- ListView semua geofences untuk patient tertentu
- Filter: Active/Inactive, Fence type (safe/danger)
- FAB untuk add new geofence
- Tap card → Navigate ke detail
- Swipe to delete dengan confirmation

**UI Components**:

- AppBar dengan title "Zona Geografis"
- Search bar untuk filter by name
- Chip filters (Semua, Aman, Bahaya, Home, Hospital, School)
- ListView dengan GeofenceCard widgets
- Empty state jika belum ada geofences
- FloatingActionButton untuk tambah geofence

**State Management**:

- GeofenceListNotifier extends StateNotifier
- Fetch geofences dari GeofenceRepository
- Listen to realtime updates (optional)

**Quality Standards**:

- ✅ Full Bahasa Indonesia
- ✅ Responsive layout
- ✅ Loading & error states
- ✅ Pull-to-refresh
- ✅ Dark mode support

**Time Estimate**: 2 hours

---

#### **Step 7: Buat GeofenceFormScreen dengan Map Picker** 🆕

**File**: `lib/presentation/screens/family/geofences/geofence_form_screen.dart` (NEW)

**Features**:

- Form fields: Name, Type, Radius
- Interactive map picker (FlutterMap atau GoogleMaps)
- Tap map → Set center point
- Draggable marker
- Circle overlay untuk visualisasi radius
- Radius slider (50m - 5000m)
- Alert options: On Enter, On Exit, Both

**Form Fields**:

```dart
- Nama Zona (TextField)
- Jenis Zona (Dropdown: Aman/Bahaya/Home/Hospital/School/Custom)
- Radius (Slider dengan label: 50m, 100m, 250m, 500m, 1km, 2km, 5km)
- Alert saat Masuk (Switch)
- Alert saat Keluar (Switch)
- Deskripsi (TextField multiline, optional)
```

**Map Integration**:

- Use `flutter_map` package (FREE, OpenStreetMap)
- Or `google_maps_flutter` (requires API key)
- Center map to patient's last location
- Draggable marker
- Circle radius overlay

**Quality Standards**:

- ✅ Form validation
- ✅ Map permissions handled
- ✅ Radius in meters (database format)
- ✅ Geography ST_MakePoint format

**Time Estimate**: 3 hours

---

#### **Step 8: Buat GeofenceDetailScreen** 🆕

**File**: `lib/presentation/screens/family/geofences/geofence_detail_screen.dart` (NEW)

**Features**:

- Map view dengan geofence circle
- Patient's current location (if available)
- Geofence info card
- Event history timeline
- Edit & Delete buttons

**Sections**:

1. **Map View** (top half)

   - Geofence circle overlay
   - Patient marker (real-time)
   - Center marker

2. **Info Card**

   - Nama zona
   - Jenis zona (badge)
   - Radius
   - Status (Active/Inactive toggle)
   - Alert settings

3. **Event History** (bottom half)
   - Timeline widget
   - Enter/Exit events
   - Timestamps
   - Location snapshots

**Actions**:

- Edit button → Navigate to form (edit mode)
- Delete button → Confirmation dialog
- Toggle active status

**Quality Standards**:

- ✅ Real-time patient location
- ✅ Event history with pagination
- ✅ Smooth map animations

**Time Estimate**: 2.5 hours

---

#### **Step 9: Buat GeofenceMonitoringService** 🆕

**File**: `lib/data/services/geofence_monitoring_service.dart` (NEW)

**Purpose**: Monitor patient location dan trigger alerts saat enter/exit geofences

**Architecture**:

```
LocationService (GPS updates)
    ↓
GeofenceMonitoringService (check if inside any geofence)
    ↓
GeofenceRepository (create event)
    ↓
FCMRepository (queue notification)
```

**Methods**:

```dart
class GeofenceMonitoringService {
  /// Start monitoring geofences untuk patient tertentu
  Future<void> startMonitoring(String patientId);

  /// Stop monitoring
  Future<void> stopMonitoring();

  /// Check if location is inside any active geofence
  Future<List<GeofenceEvent>> checkGeofences(LatLng location);

  /// Handle geofence enter event
  Future<void> _handleGeofenceEnter(Geofence geofence, LatLng location);

  /// Handle geofence exit event
  Future<void> _handleGeofenceExit(Geofence geofence, LatLng location);

  /// Queue notification untuk family members
  Future<void> _queueGeofenceAlert({
    required String patientId,
    required Geofence geofence,
    required GeofenceEventType eventType,
    required LatLng location,
  });
}
```

**Integration**:

- Listen to LocationService.onLocationUpdate stream
- Use PostGIS ST_DWithin for distance calculation
- Track last known state (inside/outside) untuk setiap geofence
- Create geofence_events record
- Queue notification jika alert enabled

**Quality Standards**:

- ✅ Efficient distance calculation (PostGIS)
- ✅ Debouncing untuk avoid spam notifications
- ✅ Battery-friendly (use location updates from existing service)
- ✅ State persistence (SharedPreferences)

**Time Estimate**: 3 hours

---

#### **Step 10: Integrasi Geofence di FamilyHomeScreen** 🔧

**File**: `lib/presentation/screens/family/family_home_screen.dart` (MODIFY)

**Changes**:

1. Add "Zona Geografis" menu item
2. Show geofence stats in dashboard
3. Add navigation to GeofenceListScreen

**Implementation**:

```dart
// In body, add new menu card (after patient tracking)
_buildMenuCard(
  context: context,
  icon: Icons.location_on_outlined,
  title: 'Zona Geografis',
  subtitle: 'Kelola zona aman & bahaya',
  color: AppColors.secondary,
  onTap: () {
    Navigator.of(context).pushNamed(
      '/family/geofences',
      arguments: {'patient_id': selectedPatientId},
    );
  },
),

// Add in dashboard stats
FutureBuilder(
  future: _geofenceRepository.getGeofencesForPatient(patientId),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final geofences = snapshot.data!;
      return _buildStatCard(
        icon: Icons.shield,
        label: 'Zona Aktif',
        value: '${geofences.where((g) => g.isActive).length}',
      );
    }
    return SizedBox.shrink();
  },
),
```

**Route Setup**:

```dart
// In app_routes.dart, add routes
'/family/geofences': (context) => const GeofenceListScreen(),
'/family/geofence-detail': (context) => const GeofenceDetailScreen(),
'/family/geofence-form': (context) => const GeofenceFormScreen(),
```

**Quality Standards**:

- ✅ Consistent navigation
- ✅ Stats update real-time
- ✅ Bottom nav active state preserved

**Time Estimate**: 1 hour

---

### **Step 11: Testing dengan Flutter Analyze** ✅

**Command**:

```bash
flutter analyze
```

**Expected Output**:

```
Analyzing project_aivia...
No issues found! ✅
```

**If Issues Found**:

1. Review errors & warnings
2. Fix one by one
3. Re-run analyze
4. Ensure 0 errors, 0 warnings

**Quality Checklist**:

- ✅ No unused imports
- ✅ No unused variables
- ✅ No missing return types
- ✅ No missing documentation (public APIs)
- ✅ No deprecated API usage
- ✅ Proper null safety

**Time Estimate**: 30 minutes (fixes if needed)

---

## 📁 File Structure (Final)

```
lib/
├── data/
│   ├── models/
│   │   ├── geofence.dart                      ✨ NEW
│   │   ├── geofence_event.dart                ✨ NEW
│   │   └── pending_notification.dart          ✨ NEW
│   │
│   ├── repositories/
│   │   ├── geofence_repository.dart           ✨ NEW
│   │   └── fcm_repository.dart                🔧 MODIFY (add queueNotification)
│   │
│   └── services/
│       ├── fcm_service.dart                   🔧 MODIFY (add tap handler)
│       └── geofence_monitoring_service.dart   ✨ NEW
│
├── presentation/
│   ├── providers/
│   │   └── geofence_provider.dart             ✨ NEW
│   │
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart              🔧 MODIFY
│   │   │   └── register_screen.dart           🔧 MODIFY
│   │   │
│   │   ├── splash/
│   │   │   └── splash_screen.dart             🔧 MODIFY
│   │   │
│   │   └── family/
│   │       ├── family_home_screen.dart        🔧 MODIFY
│   │       │
│   │       └── geofences/                     ✨ NEW FOLDER
│   │           ├── geofence_list_screen.dart
│   │           ├── geofence_form_screen.dart
│   │           └── geofence_detail_screen.dart
│   │
│   └── widgets/
│       └── geofence/                          ✨ NEW FOLDER
│           ├── geofence_card.dart
│           ├── geofence_map_picker.dart
│           └── event_timeline_widget.dart
│
├── core/
│   └── constants/
│       └── app_routes.dart                    🔧 MODIFY (add geofence routes)
│
└── main.dart                                  🔧 MODIFY (add navigator key)
```

---

## 📊 Progress Tracking

| Step | Task                                                       | Status         | Time |
| ---- | ---------------------------------------------------------- | -------------- | ---- |
| 1    | Buat Models (Geofence, GeofenceEvent, PendingNotification) | ⏳ Not Started | 1h   |
| 2    | Buat GeofenceRepository                                    | ⏳ Not Started | 1.5h |
| 3    | Initialize FCM di login/register/splash                    | ⏳ Not Started | 45m  |
| 4    | Implementasi notification tap handler                      | ⏳ Not Started | 1h   |
| 5    | Update EmergencyButton queue notification                  | ⏳ Not Started | 1h   |
| 6    | Buat GeofenceListScreen                                    | ⏳ Not Started | 2h   |
| 7    | Buat GeofenceFormScreen dengan map picker                  | ⏳ Not Started | 3h   |
| 8    | Buat GeofenceDetailScreen                                  | ⏳ Not Started | 2.5h |
| 9    | Buat GeofenceMonitoringService                             | ⏳ Not Started | 3h   |
| 10   | Integrasi di FamilyHomeScreen                              | ⏳ Not Started | 1h   |
| 11   | Testing dengan flutter analyze                             | ⏳ Not Started | 30m  |

**Total Estimated Time**: ~17 hours

---

## 🎯 Code Quality Standards

### 1. **Bahasa Indonesia (UI Strings)**

```dart
// ✅ BENAR
title: 'Zona Geografis',
subtitle: 'Kelola zona aman & bahaya',
errorMessage: 'Gagal memuat data geofence',

// ❌ SALAH
title: 'Geofences',
subtitle: 'Manage safe & danger zones',
```

### 2. **English (Technical Names)**

```dart
// ✅ BENAR
class GeofenceRepository {}
final geofenceProvider = Provider<Geofence>(...);
String patientId;

// ❌ SALAH
class RepositoriGeofence {}
final providerGeofence = ...;
String idPasien;
```

### 3. **Dartdoc Comments (Bahasa Indonesia)**

```dart
/// Membuat geofence baru untuk patient
///
/// Parameters:
/// - [patientId]: ID pasien yang akan dimonitor
/// - [name]: Nama zona geografis
/// - [latitude]: Latitude center point
/// - [longitude]: Longitude center point
///
/// Returns:
/// - `Result.success(Geofence)` jika berhasil
/// - `Result.failure(Failure)` jika gagal
Future<Result<Geofence>> createGeofence({...}) async {
  // implementation
}
```

### 4. **Error Handling**

```dart
// ✅ BENAR - Always use Result<T>
Future<Result<List<Geofence>>> getGeofences() async {
  try {
    final data = await _supabase.from('geofences').select();
    return Result.success(data.map((e) => Geofence.fromJson(e)).toList());
  } catch (e) {
    return Result.failure(
      RepositoryFailure(message: 'Gagal memuat geofences: $e'),
    );
  }
}
```

### 5. **Null Safety**

```dart
// ✅ BENAR
String? currentToken;
if (currentToken != null) {
  await saveToken(currentToken!);
}

// Use ?? for defaults
final radius = geofence.radius ?? 100.0;
```

### 6. **Immutable Models**

```dart
// ✅ BENAR
@immutable
class Geofence {
  const Geofence({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
}
```

### 7. **Provider Pattern (Riverpod)**

```dart
// ✅ BENAR - Use Provider, StateNotifier, FutureProvider
final geofenceRepositoryProvider = Provider<GeofenceRepository>((ref) {
  return GeofenceRepository();
});

final geofencesProvider = StreamProvider.autoDispose.family<List<Geofence>, String>(
  (ref, patientId) {
    return ref.read(geofenceRepositoryProvider).watchGeofences(patientId);
  },
);
```

---

## 🚀 Implementation Strategy

### **Approach**: Incremental & Testable

1. **Sprint A (Steps 1-5)**: Focus on FCM integration

   - Build models first (foundation)
   - Repository layer (data access)
   - Service integration (UI updates)
   - Test after each step with `flutter analyze`

2. **Sprint B (Steps 6-10)**: Focus on Geofencing UI

   - Build screens progressively (list → form → detail)
   - Test UI rendering at each stage
   - Integrate monitoring service last
   - Final integration with family dashboard

3. **Testing (Step 11)**: Comprehensive analysis
   - Fix all analyzer warnings/errors
   - Ensure consistent code quality
   - Verify all features integrated

### **Priority**:

- 🔴 **HIGH**: Steps 1-5 (FCM critical for notifications)
- 🟠 **MEDIUM**: Steps 6-8 (Geofence UI for usability)
- 🟢 **NORMAL**: Steps 9-10 (Monitoring & integration)

---

## 📝 Notes untuk Developer

### Dependencies yang Diperlukan

Check `pubspec.yaml` sudah ada:

- ✅ `firebase_messaging` - FCM
- ✅ `flutter_local_notifications` - Local notifications
- ✅ `supabase_flutter` - Database
- ✅ `flutter_riverpod` - State management
- ✅ `geolocator` - Location services

Tambahkan jika belum ada:

```yaml
dependencies:
  flutter_map: ^6.0.0 # Untuk map picker (FREE, OpenStreetMap)
  latlong2: ^0.9.0 # Untuk LatLng class
  # ATAU
  google_maps_flutter: ^2.5.0 # Jika prefer Google Maps (requires API key)
```

### Supabase Configuration

Pastikan RLS policies sudah benar:

```sql
-- Geofences: Family dapat manage geofences untuk linked patients
CREATE POLICY "Family can manage patient geofences"
  ON public.geofences FOR ALL
  USING (
    patient_id IN (
      SELECT patient_id FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  );
```

### Firebase Configuration

Pastikan `android/app/google-services.json` sudah ada dan valid.

### Testing Notes

- **Manual testing**: Akan dilakukan setelah fase development complete
- **Automated testing**: Tidak included dalam scope ini
- **flutter analyze**: MUST run dan pass sebelum commit

---

## ✅ Definition of Done

Fitur tracking dianggap **COMPLETE** jika:

1. ✅ Semua 11 steps implemented
2. ✅ `flutter analyze` returns 0 errors, 0 warnings
3. ✅ FCM notifications working (manual test nanti)
4. ✅ Geofence CRUD functional (manual test nanti)
5. ✅ Navigation working (all routes accessible)
6. ✅ Code quality standards met:
   - Bahasa Indonesia untuk UI strings
   - English untuk technical names
   - Dartdoc documentation complete
   - Error handling comprehensive
   - Null safety enforced
7. ✅ Integration points verified:
   - Login/Register initialize FCM
   - Emergency button queues notifications
   - Geofence monitoring active
   - Family dashboard shows geofence stats

---

**Next Action**: Mulai implementasi Step 1 (Buat Models)

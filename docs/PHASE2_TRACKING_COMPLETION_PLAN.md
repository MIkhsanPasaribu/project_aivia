# Phase 2 Tracking Feature - Completion Plan

**Created**: 06 Desember 2025  
**Objective**: Complete FCM Integration + Geofencing UI untuk tracking features  
**Testing**: `flutter analyze` only (no manual testing yet)

---

## 📊 Gap Analysis Summary

### ✅ Backend Infrastructure (DONE)

- Edge Function deployed & active
- Cron job running (every 1 minute)
- Database migrations deployed (006-013)
- Firebase project setup & service account configured

### ❌ Flutter Integration (MISSING)

1. **FCM Service initialization tidak dipanggil saat app startup**
2. **Emergency button belum integrate dengan pending_notifications table**
3. **Notification handler belum ada (tap to navigate)**
4. **Geofencing UI completely missing (no screens)**
5. **Geofence monitoring service belum ada**
6. **Database table `pending_notifications` MISSING** ⚠️ CRITICAL

---

## 🎯 Implementation Roadmap (10 Steps)

### **Sprint A: Database Fix + FCM Integration (Steps 1-5)**

#### **Step 1: Create Missing Database Table** ⚠️ CRITICAL

**File**: `database/014_pending_notifications.sql` (NEW)

**Purpose**: Create `pending_notifications` table yang dibutuhkan Edge Function

**Schema**:

```sql
CREATE TABLE public.pending_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_user_id UUID NOT NULL REFERENCES public.profiles(id),
  notification_type TEXT NOT NULL CHECK (notification_type IN ('emergency', 'geofence', 'activity', 'reminder', 'system')),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB DEFAULT '{}'::jsonb,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed', 'partial')),
  scheduled_at TIMESTAMPTZ DEFAULT NOW(),
  sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Deploy**: Via Supabase SQL Editor

---

#### **Step 2: Initialize FCM Service di App Startup**

**File**: `lib/main.dart` (MODIFY)

**Changes**:

- Add FCM initialization setelah user login
- Save device token ke database
- Setup notification handlers

**Implementation**:

```dart
// Di LoginScreen setelah successful login:
final fcmService = FCMService();
await fcmService.initialize();

// Setup foreground message handler
fcmService.onMessage.listen((RemoteMessage message) {
  _handleForegroundMessage(message);
});
```

**Files to modify**:

- `lib/presentation/screens/auth/login_screen.dart`
- `lib/presentation/screens/auth/register_screen.dart`
- `lib/presentation/screens/splash/splash_screen.dart` (check existing token)

---

#### **Step 3: Update Emergency Button - Integrate dengan pending_notifications**

**File**: `lib/presentation/widgets/emergency/emergency_button.dart` (MODIFY)

**Current flow** (OLD):

```
EmergencyButton → EmergencyRepository.createAlert() → emergency_alerts table
```

**New flow** (CORRECT):

```
EmergencyButton → EmergencyRepository.createAlert() → emergency_alerts table
                                                    ↓ (trigger auto-run)
                                        → pending_notifications table (via function)
                                                    ↓
                                        → Edge Function (via cron)
                                                    ↓
                                        → FCM send notifications
```

**Implementation**:

- Trigger sudah ada di database (011_emergency_notifications.sql)
- Emergency button **TIDAK perlu diubah** - trigger handle auto-queue
- ✅ **STEP INI ACTUALLY SUDAH DONE** (via database trigger)

---

#### **Step 4: Implement Notification Tap Handler**

**File**: `lib/data/services/fcm_service.dart` (MODIFY)

**Purpose**: Navigate ke appropriate screen saat notification diklik

**Implementation**:

```dart
// Handle notification tap (when app is terminated/background)
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  _handleNotificationTap(message);
});

void _handleNotificationTap(RemoteMessage message) {
  final data = message.data;
  final type = data['type'];

  switch (type) {
    case 'emergency_alert':
      // Navigate to patient map dengan location
      navigatorKey.currentState?.pushNamed(
        '/family/patient-map',
        arguments: {
          'patientId': data['patient_id'],
          'latitude': double.parse(data['latitude']),
          'longitude': double.parse(data['longitude']),
        },
      );
      break;
    case 'geofence_alert':
      // Navigate to geofence detail
      break;
    // ... other cases
  }
}
```

**Files to modify**:

- `lib/data/services/fcm_service.dart` - Add `_handleNotificationTap()`
- `lib/main.dart` - Add global `navigatorKey`
- `lib/presentation/screens/family/patient_tracking/patient_map_screen.dart` - Add arguments handling

---

#### **Step 5: Create FCM Provider untuk State Management**

**File**: `lib/presentation/providers/fcm_provider.dart` (EXISTING - VERIFY)

**Purpose**: Manage FCM state dengan Riverpod

**Check current implementation**:

- Verify provider exposes FCM service
- Verify token refresh handled
- Add notification stream provider jika belum ada

**Expected providers**:

```dart
final fcmServiceProvider = Provider<FCMService>((ref) => FCMService());

final fcmTokenProvider = StreamProvider<String?>((ref) {
  final service = ref.watch(fcmServiceProvider);
  return service.onTokenRefresh;
});

final fcmMessageProvider = StreamProvider<RemoteMessage>((ref) {
  final service = ref.watch(fcmServiceProvider);
  return service.onMessage;
});
```

---

### **Sprint B: Geofencing UI Implementation (Steps 6-9)**

#### **Step 6: Create Geofence List Screen**

**File**: `lib/presentation/screens/family/geofences/geofence_list_screen.dart` (NEW)

**Purpose**: Display all geofences untuk selected patient

**UI Components**:

- ListView dengan geofence cards
- Each card shows: Name, Type (safe/danger), Radius, Status (active/inactive)
- FAB untuk add new geofence
- Swipe-to-delete atau edit button
- Filter by type (safe/danger/all)
- Empty state widget

**Features**:

- Pull-to-refresh
- Real-time updates via Supabase Realtime
- Color-coded by type (green=safe, red=danger)

**Repository**:

```dart
class GeofenceRepository {
  Future<List<Geofence>> getGeofences(String patientId);
  Future<void> deleteGeofence(String geofenceId);
  Stream<List<Geofence>> watchGeofences(String patientId);
}
```

---

#### **Step 7: Create Geofence Form Screen (Add/Edit)**

**File**: `lib/presentation/screens/family/geofences/geofence_form_screen.dart` (NEW)

**Purpose**: Create or edit geofence dengan map picker

**Form Fields**:

- Name (TextField)
- Description (TextField multiline)
- Type (Dropdown: safe/danger/home/hospital/school/custom)
- Center Coordinates (Map Picker)
- Radius (Slider: 50m - 10000m dengan visual circle di map)
- Alert Config:
  - Alert on Enter (Switch)
  - Alert on Exit (Switch)
- Priority (Slider: 1-10)
- Active Status (Switch)

**Map Integration**:

```dart
FlutterMap(
  options: MapOptions(
    center: LatLng(selectedLat, selectedLng),
    zoom: 15,
  ),
  children: [
    TileLayer(...), // OpenStreetMap tiles
    CircleLayer(
      circles: [
        CircleMarker(
          point: LatLng(selectedLat, selectedLng),
          radius: radiusInMeters,
          color: Colors.blue.withOpacity(0.3),
          borderColor: Colors.blue,
          borderStrokeWidth: 2,
        ),
      ],
    ),
    MarkerLayer(
      markers: [
        Marker(
          point: LatLng(selectedLat, selectedLng),
          child: Icon(Icons.location_pin, color: Colors.red, size: 40),
        ),
      ],
    ),
  ],
)
```

**Validation**:

- Name required (min 3 char)
- Radius: 50m - 10000m
- Coordinates must be valid GPS

---

#### **Step 8: Create Geofence Detail/Preview Screen**

**File**: `lib/presentation/screens/family/geofences/geofence_detail_screen.dart` (NEW)

**Purpose**: View geofence details dengan map preview & event history

**Sections**:

1. **Header**: Name, Type badge, Active status
2. **Map Preview**: Show geofence circle on map dengan current patient location
3. **Details Card**:
   - Description
   - Radius
   - Address (reverse geocoding)
   - Alert config (enter/exit)
   - Priority
   - Created by & date
4. **Event History List**:
   - Last 20 geofence events (enter/exit)
   - Timestamp, event type
   - Patient location at event time

**Actions**:

- Edit button (navigate to form screen)
- Delete button (with confirmation)
- Toggle active status
- Navigate to full event history screen

---

#### **Step 9: Implement Geofence Monitoring Service**

**File**: `lib/data/services/geofence_monitoring_service.dart` (NEW)

**Purpose**: Monitor patient location & detect geofence entry/exit events

**Architecture**:

```dart
class GeofenceMonitoringService {
  // Check patient location against all active geofences
  Future<void> checkGeofences(Location currentLocation);

  // Calculate if point is inside geofence circle
  bool isInsideGeofence(LatLng point, Geofence fence);

  // Create geofence event di database
  Future<void> createGeofenceEvent({
    required String geofenceId,
    required String eventType, // 'enter' or 'exit'
    required Location location,
  });

  // Queue notification untuk family members
  Future<void> queueGeofenceAlert({
    required String patientId,
    required Geofence geofence,
    required String eventType,
  });
}
```

**Integration**:

- Called by `LocationService` setiap location update
- Uses PostGIS `ST_DWithin()` untuk efficient distance check
- Tracks "last inside" state untuk detect entry/exit transitions

**Algorithm**:

```dart
// Simplified geofence detection
Future<void> monitorGeofences(Location newLocation) async {
  final activeGeofences = await _geofenceRepo.getActiveGeofences(patientId);

  for (final fence in activeGeofences) {
    final isInside = _isInsideCircle(
      newLocation.coordinates,
      fence.centerCoordinates,
      fence.radiusMeters,
    );

    final wasInside = _lastState[fence.id] ?? false;

    if (isInside && !wasInside) {
      // ENTER event
      await _handleGeofenceEvent(fence, 'enter', newLocation);
    } else if (!isInside && wasInside) {
      // EXIT event
      await _handleGeofenceEvent(fence, 'exit', newLocation);
    }

    _lastState[fence.id] = isInside;
  }
}
```

---

#### **Step 10: Update Family Home Screen - Add Geofence Navigation**

**File**: `lib/presentation/screens/family/family_home_screen.dart` (MODIFY)

**Changes**:

- Add "Kelola Zona Aman" tile di dashboard
- Navigate to `GeofenceListScreen`
- Show geofence summary widget: Total zones, Active zones, Recent events

**Dashboard Widget**:

```dart
DashboardCard(
  icon: Icons.explore,
  title: 'Zona Aman/Bahaya',
  subtitle: '${activeGeofences.length} zona aktif',
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => GeofenceListScreen(patientId: selectedPatientId),
    ),
  ),
)
```

---

## 📂 File Structure (NEW FILES)

```
database/
  014_pending_notifications.sql          # NEW - Critical table

lib/
  data/
    models/
      geofence.dart                        # NEW
      geofence_event.dart                  # NEW
      pending_notification.dart            # NEW
    repositories/
      geofence_repository.dart             # NEW
    services/
      geofence_monitoring_service.dart     # NEW

  presentation/
    screens/
      family/
        geofences/                         # NEW FOLDER
          geofence_list_screen.dart        # NEW
          geofence_form_screen.dart        # NEW
          geofence_detail_screen.dart      # NEW
    widgets/
      geofence/                            # NEW FOLDER
        geofence_card.dart                 # NEW
        geofence_map_picker.dart           # NEW
```

---

## 📋 TODO Checklist (Bertahap)

### Sprint A: FCM Integration (Critical)

- [ ] **Step 1**: Create `014_pending_notifications.sql` & deploy via SQL Editor
- [ ] **Step 2**: Modify `login_screen.dart`, `register_screen.dart`, `splash_screen.dart` untuk FCM init
- [ ] **Step 3**: ✅ SKIP (trigger auto-handle)
- [ ] **Step 4**: Modify `fcm_service.dart` untuk notification tap handler + add global navigator key
- [ ] **Step 5**: Verify `fcm_provider.dart` providers complete
- [ ] **Testing**: Run `flutter analyze` setelah semua Sprint A done

### Sprint B: Geofencing UI

- [ ] **Step 6**: Create `geofence_list_screen.dart` + `geofence_repository.dart` + `geofence.dart` model
- [ ] **Step 7**: Create `geofence_form_screen.dart` + `geofence_map_picker.dart` widget
- [ ] **Step 8**: Create `geofence_detail_screen.dart` + `geofence_event.dart` model
- [ ] **Step 9**: Create `geofence_monitoring_service.dart` + integrate dengan `location_service.dart`
- [ ] **Step 10**: Modify `family_home_screen.dart` untuk add geofence navigation
- [ ] **Testing**: Run `flutter analyze` setelah semua Sprint B done

---

## 🎨 Code Quality Requirements (per Copilot Instructions)

### Bahasa

- ✅ **Full Bahasa Indonesia** untuk:
  - Semua string UI (labels, messages, errors)
  - Nama file (`zona_aman_screen.dart` ❌ → `geofence_list_screen.dart` ✅)
  - Nama variabel lokal (`namaZona`, `jenisPeringatan`)
  - Komentar kode

### Code Quality Standards

- ✅ **Clean Architecture**: Separation of concerns (models, repositories, services, UI)
- ✅ **Riverpod State Management**: Consistent provider usage
- ✅ **Error Handling**: Try-catch dengan user-friendly messages (Bahasa Indonesia)
- ✅ **Null Safety**: Proper null checks & assertions
- ✅ **Documentation**: Dartdoc comments untuk public APIs
- ✅ **Readability**: Descriptive names, max 80 char/line
- ✅ **Testability**: Services injectable via constructors

### Flutter Best Practices

- ✅ **Widget Composition**: Break down large widgets
- ✅ **Const Constructors**: Use `const` where possible
- ✅ **Keys**: Proper key usage untuk lists
- ✅ **Async Handling**: FutureBuilder/StreamBuilder dengan loading & error states
- ✅ **Navigation**: Named routes atau MaterialPageRoute
- ✅ **Theme Consistency**: Use `Theme.of(context)` untuk colors/styles

---

## 🔍 Testing Strategy

### Per Step Testing

After EACH step completion:

```bash
flutter analyze
```

### Expected Results

- **0 errors**
- **0 warnings**
- **0 info messages**

### If errors found:

1. Fix immediately before proceeding
2. Re-run `flutter analyze`
3. Verify all green

### Final Testing (After Step 10)

```bash
flutter analyze
flutter pub run dart_code_metrics:metrics analyze lib
```

---

## 📊 Success Metrics

### Completion Criteria

- ✅ All 10 steps implemented
- ✅ `flutter analyze` passes (0 issues)
- ✅ All new files follow naming conventions
- ✅ All strings in Bahasa Indonesia
- ✅ Code documented dengan Dartdoc
- ✅ Error handling comprehensive
- ✅ State management consistent (Riverpod)

### Feature Checklist

- ✅ FCM token saved to database on login
- ✅ Notifications received di foreground/background
- ✅ Notification tap navigates correctly
- ✅ Emergency button creates pending_notification
- ✅ Geofence CRUD complete (Create, Read, Update, Delete)
- ✅ Geofence map picker functional
- ✅ Geofence monitoring detects enter/exit events
- ✅ Geofence alerts queued to pending_notifications

---

## 🚀 Deployment Readiness

### Database

- ✅ All tables created (006-014 migrations)
- ✅ All functions deployed
- ✅ All triggers active
- ✅ RLS policies configured

### Backend

- ✅ Edge Function deployed
- ✅ Cron job active
- ✅ Secrets configured
- ✅ Firebase service account linked

### Flutter App

- ⏳ FCM integration complete (Sprint A)
- ⏳ Geofencing UI complete (Sprint B)
- ⏳ All screens navigable
- ⏳ All providers wired

---

## 📝 Notes

### Priority Order

1. **Sprint A (Steps 1-5)** - CRITICAL untuk notifications work
2. **Sprint B (Steps 6-10)** - IMPORTANT untuk complete tracking feature

### Time Estimate

- Sprint A: 2-3 jam (critical path)
- Sprint B: 4-5 jam (UI heavy)
- **Total**: 6-8 jam development time

### Dependencies

- Flutter SDK: 3.22.x
- Dart: ^3.9.2
- firebase_messaging: latest
- flutter_map: latest (untuk map display)
- geolocator: latest (sudah ada)

---

**Status**: 📋 PLANNING COMPLETE - READY FOR IMPLEMENTATION  
**Next Action**: Start Sprint A, Step 1 (Create pending_notifications table)  
**Testing**: `flutter analyze` after each sprint

---

**Document Version**: 1.0  
**Last Updated**: 06 Desember 2025 21:49 WIB

# 🚀 PHASE 2: ANALISIS KOMPREHENSIF & ROADMAP

**Tanggal Analisis**: 14 Oktober 2025  
**Status Phase 1**: ✅ **100% COMPLETE** (MVP + Dark Mode)  
**Status Pre-Phase 2**: ✅ **100% COMPLETE** (All 4 Parts Done)  
**Target Phase 2**: Location Tracking, Emergency System, Map View  
**Estimasi Durasi**: 5-7 hari kerja

---

## 📊 EXECUTIVE SUMMARY

### 🎯 Status Saat Ini

| Aspek                  | Status      | Detail                                      |
| ---------------------- | ----------- | ------------------------------------------- |
| **Phase 1 MVP**        | ✅ 100%     | Auth, Activity CRUD, Notifications, Profile |
| **Dark Mode**          | ✅ 100%     | 133+ colors fixed, full theme support       |
| **Pre-Phase 2 Part 1** | ✅ 100%     | Family Dashboard & Patient Linking          |
| **Pre-Phase 2 Part 2** | ✅ 100%     | Enhanced Providers & Real-time Sync         |
| **Pre-Phase 2 Part 3** | ✅ 100%     | Location & Emergency Infrastructure         |
| **Pre-Phase 2 Part 4** | ✅ 100%     | Settings, Help, Image Upload                |
| **Database Schema**    | ✅ 100%     | All tables ready (12 tables)                |
| **Flutter Analyze**    | ✅ 0 Issues | Clean codebase                              |

### ✅ Foundation Yang Sudah Siap

**✅ Models (100%)**:

- `UserProfile` ✅
- `Activity` ✅
- `PatientFamilyLink` ✅
- `Location` ✅
- `EmergencyContact` ✅
- `EmergencyAlert` ✅

**✅ Repositories (100%)**:

- `AuthRepository` ✅
- `ActivityRepository` ✅
- `PatientFamilyRepository` ✅
- `ProfileRepository` ✅
- `LocationRepository` ✅
- `EmergencyRepository` ✅

**✅ Providers (100%)**:

- `AuthProvider` (6 providers) ✅
- `ActivityProvider` (5 providers) ✅
- `PatientFamilyProvider` (5 providers) ✅
- `ProfileProvider` (3 providers) ✅
- `LocationProvider` (6 providers) ✅
- `EmergencyProvider` (5 providers) ✅
- `ThemeProvider` (2 providers) ✅
- `NotificationSettingsProvider` ✅

**✅ Database (100%)**:

- PostgreSQL schema ✅
- Row Level Security (RLS) ✅
- Realtime config ✅
- Indexes & triggers ✅
- PostGIS enabled ✅

**✅ UI Screens (Phase 1 - 100%)**:

- Splash Screen ✅
- Login/Register ✅
- Patient Home (Bottom Nav) ✅
- Family Dashboard ✅
- Activity List/Detail/Form ✅
- Profile & Edit Profile ✅
- Settings Screen ✅
- Help Screen ✅
- Link Patient Screen ✅
- Patient Detail Screen ✅

**✅ Services & Utils (100%)**:

- Supabase Config ✅
- Theme Config (Light + Dark) ✅
- Image Upload Service ✅
- Date Formatter ✅
- Validators ✅
- Result Pattern ✅
- Logout Helper ✅

---

## 🎯 PHASE 2 GOALS & SCOPE

### Primary Objectives

**1. Background Location Tracking** 🗺️

- Real-time GPS tracking untuk pasien
- Background service yang reliable
- Battery-efficient implementation
- Geofencing untuk safe zones (future)

**2. Map Visualization** 🗺️

- Real-time map view untuk keluarga
- Patient location markers
- Location history trail
- Distance & time calculations

**3. Emergency System** 🚨

- Panic button implementation
- Instant alert to emergency contacts
- Location-based emergency
- Push notifications (FCM)

**4. Notification System** 🔔

- Push notifications (Firebase Cloud Messaging)
- Local notifications enhancement
- Notification settings & preferences
- Real-time emergency alerts

### Success Criteria

✅ **Must Have (Phase 2.1 - Core)**:

1. Background location tracking aktif ✅
2. Map view menampilkan lokasi real-time ✅
3. Emergency button berfungsi ✅
4. Emergency contacts menerima notifikasi ✅

✅ **Should Have (Phase 2.2 - Enhancement)**: 5. Location history dengan filter tanggal 6. Battery optimization settings 7. Notification preferences management 8. Distance alerts (geofencing)

🔷 **Nice to Have (Phase 2.3 - Future)**: 9. Heatmap untuk aktivitas pasien 10. Route playback (timeline) 11. Location sharing dengan link 12. Emergency contact quick call

---

## 📋 PHASE 2 DEVELOPMENT PLAN

### 🔷 Phase 2.1: Core Location & Emergency (3-4 hari)

#### **Sprint 2.1.1: Background Location Service** (1 hari)

**Tujuan**: Implementasi location tracking yang reliable dan battery-efficient

**Tasks**:

1. ✅ **Setup Flutter Background Geolocation Plugin**

   ```yaml
   # pubspec.yaml
   dependencies:
     geolocator: ^10.1.0
     permission_handler: ^11.0.1
   ```

2. ✅ **Create Location Service** (`lib/data/services/location_service.dart`)

   - Initialize geolocation
   - Request permissions (FINE_LOCATION, BACKGROUND_LOCATION)
   - Start/stop tracking methods
   - Location stream handler
   - Battery optimization settings

3. ✅ **Android Native Configuration**

   - Update `android/app/src/main/AndroidManifest.xml`:
     ```xml
     <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
     <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
     <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
     <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
     <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
     ```
   - Create foreground service
   - Setup notification channel

4. ✅ **Permission Flow UI**

   - Permission request screens
   - Explanation dialogs (Bahasa Indonesia)
   - Settings deep link jika permission denied

5. ✅ **Database Integration**
   - Save location to `locations` table
   - Batch insert untuk efisiensi
   - Error handling & retry logic

**Deliverables**:

- ✅ Location service fully functional
- ✅ Background tracking aktif
- ✅ Permissions properly handled
- ✅ Data tersimpan di database

**Testing**:

- [ ] Test tracking accuracy
- [ ] Test background persistence
- [ ] Test battery impact
- [ ] Test RLS policies

---

#### **Sprint 2.1.2: Map View Implementation** (1-1.5 hari)

**Tujuan**: Tampilkan lokasi pasien di peta real-time

**Tasks**:

1. ✅ **Choose Map Provider**

   - **Option A**: Google Maps (`google_maps_flutter`)

     - Pros: Familiar, good documentation, reliable
     - Cons: Requires API key, billing setup

   - **Option B**: OpenStreetMap (`flutter_map`)

     - Pros: Free, no API key, open source
     - Cons: Slightly complex setup, less features

   - **Recommendation**: Start dengan `flutter_map` (free), migrate ke Google Maps jika needed

2. ✅ **Setup Map Package**

   ```yaml
   # pubspec.yaml (Option B recommended)
   dependencies:
     flutter_map: ^6.0.0
     latlong2: ^0.9.0
   ```

3. ✅ **Create Map Screen** (`lib/presentation/screens/family/map/patient_map_screen.dart`)

   - Map widget dengan zoom controls
   - Patient location marker (custom icon)
   - Real-time location updates via stream
   - Map gestures (pan, zoom, rotate)
   - Center on patient button

4. ✅ **Real-time Location Provider**

   ```dart
   @riverpod
   Stream<Location> patientLocationStream(
     PatientLocationStreamRef ref,
     String patientId,
   ) {
     return ref
       .watch(locationRepositoryProvider)
       .watchLatestLocation(patientId);
   }
   ```

5. ✅ **Location Info Card**

   - Show: Last update time, accuracy, coordinates
   - Distance from family member (if available)
   - Refresh button

6. ✅ **Map Features**
   - Custom patient marker (avatar + status indicator)
   - Location history trail (polyline)
   - Map types selector (Street, Satellite, Terrain)
   - Legend/info overlay

**Deliverables**:

- ✅ Map screen fully functional
- ✅ Real-time location updates
- ✅ Custom markers & overlays
- ✅ Smooth UX with loading states

**Testing**:

- [ ] Test real-time updates
- [ ] Test map performance (60fps)
- [ ] Test different map styles
- [ ] Test error states (no location)

---

#### **Sprint 2.1.3: Emergency Button & Alerts** (0.5 hari)

**Tujuan**: Implementasi panic button dengan instant alerts

**Tasks**:

1. ✅ **Emergency Button Widget** (`lib/presentation/widgets/common/emergency_button.dart`)

   - Floating Action Button (persistent)
   - Red color dengan icon warning/emergency
   - Long press untuk trigger (prevent accidental)
   - Haptic feedback + sound
   - Confirmation dialog (optional)

2. ✅ **Emergency Action Handler**

   ```dart
   Future<void> triggerEmergency() async {
     // 1. Get current location
     final location = await Geolocator.getCurrentPosition();

     // 2. Create emergency alert
     await emergencyRepository.createAlert(
       patientId: currentUser.id,
       location: location,
       message: 'DARURAT! Butuh bantuan segera!',
     );

     // 3. Send notifications (handled by Supabase trigger + Edge Function)

     // 4. Show confirmation to user
     showSnackBar('Peringatan darurat terkirim!');
   }
   ```

3. ✅ **UI Integration**

   - Add emergency button to PatientHomeScreen
   - Position: Bottom-right, always visible
   - Overlay on bottom navigation
   - Animation on trigger (pulse, shake)

4. ✅ **Emergency Alert Model** (Already created ✅)
   - Alert status tracking
   - Location snapshot
   - Timestamp

**Deliverables**:

- ✅ Emergency button visible & functional
- ✅ Alerts created in database
- ✅ User confirmation feedback

**Testing**:

- [ ] Test button accessibility
- [ ] Test alert creation
- [ ] Test location accuracy
- [ ] Test error handling

---

#### **Sprint 2.1.4: Push Notifications (FCM)** (1 hari)

**Tujuan**: Real-time push notifications untuk emergency alerts

**Tasks**:

1. ✅ **Firebase Setup**

   - Create Firebase project
   - Add Android app to Firebase
   - Download `google-services.json`
   - Setup SHA certificates
   - Enable FCM in Firebase Console

2. ✅ **Flutter FCM Integration**

   ```yaml
   # pubspec.yaml
   dependencies:
     firebase_core: ^2.24.0
     firebase_messaging: ^14.7.6
   ```

3. ✅ **FCM Service** (`lib/data/services/fcm_service.dart`)

   - Initialize Firebase
   - Request notification permission
   - Get FCM token
   - Save token to `fcm_tokens` table
   - Handle foreground/background/terminated messages

4. ✅ **Token Management**

   - Save FCM token on login
   - Update token on refresh
   - Delete token on logout
   - Handle multiple devices

5. ✅ **Notification Handlers**

   ```dart
   // Foreground messages
   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
     // Show local notification
     showNotification(message);
   });

   // Background messages
   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

   // Notification tap handler
   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
     // Navigate to relevant screen
     navigateToEmergency(message.data);
   });
   ```

6. ✅ **Supabase Edge Function** (`supabase/functions/send-emergency-notification/index.ts`)

   ```typescript
   import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
   import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

   serve(async (req) => {
     const { patient_id, alert_id, location } = await req.json();

     // Get emergency contacts
     const { data: contacts } = await supabase
       .from("emergency_contacts")
       .select(
         `
         contact_id,
         profiles!emergency_contacts_contact_id_fkey (
           full_name,
           fcm_tokens (token)
         )
       `
       )
       .eq("patient_id", patient_id)
       .order("priority");

     // Send FCM to each contact
     for (const contact of contacts) {
       for (const token of contact.profiles.fcm_tokens) {
         await sendFCMNotification(token.token, {
           title: "🚨 PERINGATAN DARURAT!",
           body: `${patientName} membutuhkan bantuan segera!`,
           data: {
             type: "emergency_alert",
             alert_id,
             patient_id,
             location: JSON.stringify(location),
           },
         });
       }
     }

     return new Response(JSON.stringify({ success: true }));
   });
   ```

7. ✅ **Database Trigger** (`database/006_emergency_notifications.sql`)

   ```sql
   CREATE OR REPLACE FUNCTION notify_emergency_contacts()
   RETURNS TRIGGER AS $$
   BEGIN
     -- Call Edge Function via HTTP
     PERFORM net.http_post(
       url := 'https://YOUR_PROJECT.supabase.co/functions/v1/send-emergency-notification',
       headers := jsonb_build_object(
         'Authorization', 'Bearer ' || current_setting('request.jwt.claims')::json->>'sub'
       ),
       body := jsonb_build_object(
         'patient_id', NEW.patient_id,
         'alert_id', NEW.id,
         'location', ST_AsGeoJSON(NEW.location)::jsonb
       )
     );

     RETURN NEW;
   END;
   $$ LANGUAGE plpgsql SECURITY DEFINER;

   CREATE TRIGGER on_emergency_alert_created
     AFTER INSERT ON emergency_alerts
     FOR EACH ROW
     EXECUTE FUNCTION notify_emergency_contacts();
   ```

**Deliverables**:

- ✅ FCM fully integrated
- ✅ Tokens managed in database
- ✅ Edge Function deployed
- ✅ Real-time notifications working

**Testing**:

- [ ] Test foreground notifications
- [ ] Test background notifications
- [ ] Test notification tap navigation
- [ ] Test multiple devices
- [ ] Test emergency flow end-to-end

---

### 🔷 Phase 2.2: Enhancements & Polish (1-2 hari)

#### **Sprint 2.2.1: Location History** (0.5 hari)

**Tasks**:

1. ✅ **Location History Screen** (`lib/presentation/screens/family/map/location_history_screen.dart`)

   - List view dengan timeline
   - Date range filter (Today, Week, Month, Custom)
   - Location cards dengan map thumbnail
   - Tap to view on map

2. ✅ **History Provider**

   ```dart
   @riverpod
   Future<List<Location>> locationHistory(
     LocationHistoryRef ref,
     String patientId,
     DateTimeRange dateRange,
   ) async {
     return ref
       .watch(locationRepositoryProvider)
       .getLocationHistory(
         patientId: patientId,
         startDate: dateRange.start,
         endDate: dateRange.end,
       );
   }
   ```

3. ✅ **Map Integration**
   - Show historical route (polyline)
   - Animate playback (optional)
   - Export route as image/PDF

**Deliverables**:

- ✅ Location history accessible
- ✅ Filter working properly
- ✅ Map integration smooth

---

#### **Sprint 2.2.2: Notification Settings** (0.5 hari)

**Tasks**:

1. ✅ **Settings UI Enhancement** (Update existing `settings_screen.dart`)

   - Notification preferences section
   - Emergency alerts toggle
   - Activity reminders toggle
   - Notification sound selector
   - DND (Do Not Disturb) schedule

2. ✅ **Settings Provider Enhancement**
   - Persist notification preferences
   - Sync with local storage (shared_preferences)
   - Update FCM subscription topics

**Deliverables**:

- ✅ Settings UI complete
- ✅ Preferences persisted
- ✅ Toggles working

---

#### **Sprint 2.2.3: Battery Optimization** (0.5 hari)

**Tasks**:

1. ✅ **Adaptive Location Tracking**

   - Smart interval based on activity
   - Reduce frequency when stationary
   - Increase frequency when moving

2. ✅ **Battery Settings UI**

   - Tracking mode selector:
     - 🔋 High Accuracy (1min interval)
     - ⚡ Balanced (5min interval)
     - 🌿 Power Saving (15min interval)
   - Battery usage estimate
   - Background restriction warnings

3. ✅ **Battery Optimization Guide**
   - Help screen addition
   - Tips untuk battery life
   - Disable restrictions tutorial

**Deliverables**:

- ✅ Battery-friendly modes
- ✅ User control over tracking
- ✅ Clear documentation

---

### 🔷 Phase 2.3: Testing & Documentation (1 hari)

#### **Sprint 2.3.1: Integration Testing** (0.5 hari)

**Test Scenarios**:

1. **Location Tracking**:

   - [ ] Start tracking → Move device → Verify locations saved
   - [ ] Background mode → Lock screen → Verify still tracking
   - [ ] App killed → Reboot device → Verify auto-start
   - [ ] Permission denied → Show rationale → Request again

2. **Map View**:

   - [ ] Open map → Verify patient marker
   - [ ] Zoom in/out → Verify performance
   - [ ] Real-time update → Move patient → Verify marker moves
   - [ ] No location → Show empty state

3. **Emergency System**:

   - [ ] Press emergency button → Verify confirmation
   - [ ] Confirm → Verify alert created
   - [ ] Verify notification sent to contacts
   - [ ] Verify location captured

4. **Push Notifications**:
   - [ ] Foreground → Receive notification → Verify UI
   - [ ] Background → Receive notification → Verify notification
   - [ ] Terminated → Receive notification → Launch app
   - [ ] Tap notification → Navigate to alert

**Tools**:

- Patrol for E2E testing
- Firebase Test Lab for device testing
- Real devices for location testing (emulator tidak accurate)

---

#### **Sprint 2.3.2: Documentation Update** (0.5 hari)

**Documents to Create/Update**:

1. ✅ **PHASE2_IMPLEMENTATION.md**

   - Complete implementation log
   - Code snippets
   - Screenshots
   - Challenges & solutions

2. ✅ **LOCATION_TRACKING_GUIDE.md**

   - How location service works
   - Permissions explanation
   - Battery optimization tips
   - Troubleshooting common issues

3. ✅ **EMERGENCY_SYSTEM_GUIDE.md**

   - How emergency alerts work
   - Setting up contacts
   - Testing emergency flow
   - FCM setup guide

4. ✅ **USER_GUIDE_V2.md**

   - Updated user guide with Phase 2 features
   - Screenshots in Bahasa Indonesia
   - Step-by-step tutorials

5. ✅ **API_DOCUMENTATION.md**
   - Supabase tables & functions
   - Edge Functions documentation
   - RLS policies explanation

---

## 🗂️ FILE STRUCTURE - PHASE 2

### New Files to Create

```
project_aivia/
├── lib/
│   ├── data/
│   │   └── services/
│   │       ├── location_service.dart           # NEW - Background location tracking
│   │       └── fcm_service.dart                # NEW - Firebase Cloud Messaging
│   │
│   ├── presentation/
│   │   ├── screens/
│   │   │   └── family/
│   │   │       └── map/
│   │   │           ├── patient_map_screen.dart          # NEW - Real-time map
│   │   │           ├── location_history_screen.dart     # NEW - Historical locations
│   │   │           └── map_settings_screen.dart         # NEW - Map preferences
│   │   │
│   │   └── widgets/
│   │       ├── map/
│   │       │   ├── patient_marker.dart          # NEW - Custom map marker
│   │       │   ├── location_trail.dart          # NEW - Polyline trail
│   │       │   └── map_controls.dart            # NEW - Zoom/center controls
│   │       │
│   │       └── emergency/
│   │           ├── emergency_button.dart        # NEW - Panic button
│   │           ├── emergency_alert_card.dart    # NEW - Alert display
│   │           └── emergency_confirmation_dialog.dart # NEW - Confirm dialog
│   │
│   └── core/
│       └── utils/
│           ├── location_utils.dart              # NEW - Distance calculations, etc
│           └── permission_helper.dart           # NEW - Permission management
│
├── android/
│   └── app/
│       └── src/
│           └── main/
│               ├── AndroidManifest.xml          # UPDATE - Add permissions
│               ├── res/
│               │   └── values/
│               │       └── strings.xml          # UPDATE - Notification strings
│               └── kotlin/
│                   └── com/
│                       └── aivia/
│                           └── ForegroundService.kt  # NEW - Background service
│
├── supabase/
│   └── functions/
│       ├── send-emergency-notification/
│       │   └── index.ts                         # NEW - Emergency FCM handler
│       └── update-location-batch/
│           └── index.ts                         # NEW - Batch location updates
│
├── database/
│   ├── 006_emergency_notifications.sql          # NEW - Trigger for emergency
│   ├── 007_location_indexes.sql                 # NEW - Performance indexes
│   └── 008_fcm_tokens_cleanup.sql               # NEW - Token cleanup function
│
└── docs/
    ├── PHASE2_IMPLEMENTATION.md                 # NEW - Implementation log
    ├── LOCATION_TRACKING_GUIDE.md               # NEW - Location guide
    ├── EMERGENCY_SYSTEM_GUIDE.md                # NEW - Emergency guide
    ├── FCM_SETUP_GUIDE.md                       # NEW - Firebase setup
    └── USER_GUIDE_V2.md                         # NEW - Updated user guide
```

---

## 📦 DEPENDENCIES TO ADD

### Phase 2 Required Dependencies

```yaml
# pubspec.yaml

dependencies:
  # Existing...

  # Location Tracking
  geolocator: ^10.1.0 # GPS location
  permission_handler: ^11.0.1 # Runtime permissions

  # Maps
  flutter_map: ^6.0.0 # OpenStreetMap (recommended)
  latlong2: ^0.9.0 # Lat/Long calculations
  # OR
  # google_maps_flutter: ^2.5.0          # Google Maps (alternative)

  # Firebase
  firebase_core: ^2.24.0 # Firebase core
  firebase_messaging: ^14.7.6 # Push notifications (FCM)

  # Utilities
  cached_network_image: ^3.3.0 # Image caching
  path_provider: ^2.1.1 # File paths
  shared_preferences: ^2.2.2 # Local storage (already added?)

dev_dependencies:
  # Testing
  integration_test: # Built-in
  patrol: ^3.0.0 # E2E testing (already added?)
```

### Android Configuration

**android/app/build.gradle**:

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // FCM requires 21
        targetSdkVersion 34
    }
}

dependencies {
    implementation 'com.google.firebase:firebase-messaging:23.3.1'
}
```

**android/build.gradle**:

```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}
```

**android/app/build.gradle** (bottom):

```gradle
apply plugin: 'com.google.gms.google-services'
```

---

## ⚠️ POTENTIAL CHALLENGES & SOLUTIONS

### Challenge 1: Background Location Permission (Android 10+)

**Problem**: Android 10+ requires separate permission for background location

**Solution**:

1. Request FINE_LOCATION first
2. Show rationale for background usage
3. Request BACKGROUND_LOCATION separately
4. Handle "Allow all the time" vs "Allow only while using"
5. Educate user tentang pentingnya background tracking

**Implementation**:

```dart
// Step 1: Request foreground
await Permission.location.request();

// Step 2: Show dialog explaining why background needed
showDialog(...);

// Step 3: Request background
await Permission.locationAlways.request();

// Step 4: Handle denied
if (status.isDenied) {
  // Show guide to enable in Settings
  openAppSettings();
}
```

---

### Challenge 2: Battery Optimization Interference

**Problem**: Android manufacturers (Xiaomi, Huawei, Samsung) aggressively kill background apps

**Solution**:

1. Request "Battery Optimization Exemption"
2. Provide manufacturer-specific guides
3. Use Foreground Service dengan notification
4. Implement smart tracking (adaptive intervals)
5. Clear user communication

**Resources**:

- https://dontkillmyapp.com/
- Manufacturer-specific guides

---

### Challenge 3: FCM Reliability

**Problem**: Push notifications tidak selalu reliable (network issues, FCM delays)

**Solution**:

1. Implement retry mechanism
2. Use local notifications as fallback
3. Store message history in database
4. Show in-app notification badge
5. Poll for missed alerts on app open

---

### Challenge 4: Map Performance

**Problem**: Real-time map updates bisa lag dengan banyak markers

**Solution**:

1. Limit visible markers (clustering)
2. Use marker pooling (reuse objects)
3. Throttle location updates (1-2 sec interval)
4. Lazy load historical data
5. Simplify polylines (reduce points)

---

### Challenge 5: Location Accuracy

**Problem**: GPS tidak accurate indoor atau di dense urban areas

**Solution**:

1. Show accuracy indicator
2. Filter out low-accuracy points
3. Use location smoothing algorithms
4. Combine GPS + Network + Cell Tower data
5. Clear communication dengan user

---

## 📊 SUCCESS METRICS

### Technical Metrics

| Metric                        | Target         | Measurement               |
| ----------------------------- | -------------- | ------------------------- |
| **Location Accuracy**         | <50m (outdoor) | Geolocator accuracy value |
| **Location Update Frequency** | Every 1-5 min  | Timestamp difference      |
| **Battery Impact**            | <5% per hour   | Android battery stats     |
| **Map FPS**                   | >50 fps        | Flutter DevTools          |
| **Notification Delivery**     | >95% success   | FCM analytics             |
| **Emergency Response Time**   | <5 seconds     | Alert creation timestamp  |
| **App Crash Rate**            | <0.5%          | Firebase Crashlytics      |
| **ANR Rate**                  | <0.1%          | Google Play Console       |

### User Experience Metrics

| Metric                             | Target       | Measurement            |
| ---------------------------------- | ------------ | ---------------------- |
| **Permission Grant Rate**          | >80%         | Analytics              |
| **Emergency Button Accessibility** | <2 taps away | User testing           |
| **Map Load Time**                  | <2 seconds   | Performance monitoring |
| **Location History Load**          | <1 second    | Performance monitoring |
| **Notification Action Rate**       | >60%         | FCM analytics          |

---

## 🎯 DEFINITION OF DONE - PHASE 2

### Phase 2.1 (Core Features)

✅ **Location Tracking**:

- [ ] Background service running reliably
- [ ] Locations saved to database every 1-5min
- [ ] Permissions properly requested & explained
- [ ] Foreground service notification showing
- [ ] Battery optimization warnings handled
- [ ] No crashes on permission denial
- [ ] Works after app restart
- [ ] Works after device reboot

✅ **Map View**:

- [ ] Map displays patient location
- [ ] Real-time updates working (<5sec delay)
- [ ] Custom marker with patient avatar
- [ ] Zoom/pan gestures smooth (>50fps)
- [ ] Center on patient button works
- [ ] Empty state when no location
- [ ] Error state on network failure
- [ ] Loading state on initial load

✅ **Emergency System**:

- [ ] Emergency button always visible
- [ ] Long press confirmation working
- [ ] Alert created in database
- [ ] Current location captured
- [ ] User receives confirmation
- [ ] No false positives (accidental triggers)

✅ **Push Notifications**:

- [ ] FCM tokens saved to database
- [ ] Emergency contacts receive notification
- [ ] Notification appears in foreground
- [ ] Notification appears in background
- [ ] Notification appears when app killed
- [ ] Tapping notification opens app
- [ ] Notification content correct
- [ ] Multiple devices supported

### Phase 2.2 (Enhancements)

✅ **Location History**:

- [ ] History screen accessible
- [ ] Date filter working
- [ ] List performance good (>60fps)
- [ ] Tap to view on map works
- [ ] Export functionality (optional)

✅ **Settings**:

- [ ] Notification preferences working
- [ ] Battery mode selector working
- [ ] Preferences persisted
- [ ] Settings sync across devices

### Phase 2.3 (Polish)

✅ **Testing**:

- [ ] All integration tests passing
- [ ] E2E tests with Patrol passing
- [ ] Tested on 3+ real devices
- [ ] No memory leaks detected
- [ ] No ANR detected
- [ ] Battery impact acceptable

✅ **Documentation**:

- [ ] Implementation guide complete
- [ ] User guide updated
- [ ] API documentation complete
- [ ] Troubleshooting guide complete
- [ ] Code comments added

✅ **Code Quality**:

- [ ] Flutter analyze: 0 issues
- [ ] All TODOs resolved or documented
- [ ] Code reviewed
- [ ] No hardcoded values
- [ ] Proper error handling everywhere

---

## 📅 TIMELINE & MILESTONES

### Week 1 (Days 1-3): Phase 2.1 Core

| Day       | Focus            | Deliverable                  |
| --------- | ---------------- | ---------------------------- |
| **Day 1** | Location Service | Background tracking working  |
| **Day 2** | Map View         | Real-time map displaying     |
| **Day 3** | Emergency + FCM  | Panic button + notifications |

**Milestone 1**: ✅ Core features functional (testable)

### Week 1 (Days 4-5): Phase 2.2 Enhancement

| Day       | Focus              | Deliverable                    |
| --------- | ------------------ | ------------------------------ |
| **Day 4** | History + Settings | Location history + preferences |
| **Day 5** | Polish + Testing   | Bug fixes + integration tests  |

**Milestone 2**: ✅ All Phase 2 features complete

### Week 2 (Days 6-7): Phase 2.3 Testing & Docs

| Day       | Focus         | Deliverable                |
| --------- | ------------- | -------------------------- |
| **Day 6** | Testing       | E2E tests + device testing |
| **Day 7** | Documentation | Guides + API docs complete |

**Milestone 3**: ✅ Phase 2 production-ready

---

## 🚀 GETTING STARTED - IMMEDIATE NEXT STEPS

### Pre-Development Setup (30 min)

1. ✅ **Firebase Console Setup**

   - Create Firebase project: "AIVIA - Alzheimer Assistant"
   - Add Android app (package: `com.aivia.app`)
   - Download `google-services.json`
   - Enable Firebase Cloud Messaging
   - Generate SHA-1 & SHA-256 certificates

2. ✅ **Google Maps API (if using)**

   - Enable Maps SDK for Android
   - Get API key
   - Add billing account (free tier sufficient)

3. ✅ **Supabase Edge Functions Setup**

   - Install Supabase CLI: `npm install -g supabase`
   - Login: `supabase login`
   - Link project: `supabase link`

4. ✅ **Development Environment**
   - Ensure Android SDK updated
   - Test on real device (location services)
   - Setup Firebase Test Lab account

### Day 1 Start (Phase 2.1.1)

**Morning (3 hours)**:

1. Add dependencies to `pubspec.yaml`
2. Run `flutter pub get`
3. Download `google-services.json` → place in `android/app/`
4. Update `AndroidManifest.xml` with location permissions
5. Create `location_service.dart` skeleton
6. Test compilation: `flutter analyze`

**Afternoon (4 hours)**: 7. Implement `LocationService` class 8. Add permission request flow 9. Create foreground service notification 10. Test location tracking on device 11. Save locations to database

**End of Day**:

- ✅ Location tracking working
- ✅ Permissions handled
- ✅ Data flowing to database

---

## 🎓 LEARNING RESOURCES

### Flutter Location Tracking

- [Geolocator Package](https://pub.dev/packages/geolocator)
- [Background Location Best Practices](https://developer.android.com/training/location/background)
- [Flutter Background Services](https://medium.com/flutter-community/executing-dart-in-the-background-with-flutter-plugins-and-geofencing-2b3e40a1a124)

### Firebase Cloud Messaging

- [Firebase Messaging Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/client)
- [FCM HTTP v1 API](https://firebase.google.com/docs/cloud-messaging/send-message)
- [Handling FCM in Different States](https://firebase.flutter.dev/docs/messaging/usage/)

### Maps

- [Flutter Map Package](https://pub.dev/packages/flutter_map)
- [OpenStreetMap Tiles](https://wiki.openstreetmap.org/wiki/Tiles)
- [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)

### Supabase

- [Edge Functions Guide](https://supabase.com/docs/guides/functions)
- [Realtime Subscriptions](https://supabase.com/docs/guides/realtime)
- [Database Triggers](https://supabase.com/docs/guides/database/triggers)

---

## 📝 NOTES & REMINDERS

### Important Considerations

1. **Testing on Real Devices**: Emulator tidak accurate untuk GPS. Always test on real device.

2. **Battery Testing**: Monitor battery drain dengan Android Battery Historian.

3. **Permission UX**: Explain clearly WHY background location needed. Users suspicious of tracking.

4. **FCM Limits**: FCM has rate limits. Don't spam notifications.

5. **Database Costs**: Location tracking generates LOT of data. Monitor Supabase usage.

6. **Privacy**: Make clear how data is used & stored. Give user control.

7. **Offline Mode**: Handle network failures gracefully. Queue location updates.

8. **Error Logging**: Use Sentry/Firebase Crashlytics for production error tracking.

### Common Pitfalls to Avoid

❌ **Don't**: Track location more frequently than needed (battery killer)  
✅ **Do**: Use adaptive intervals (faster when moving, slower when stationary)

❌ **Don't**: Store raw coordinates without context  
✅ **Do**: Include accuracy, speed, heading, timestamp

❌ **Don't**: Hardcode FCM server key in app  
✅ **Do**: Use Edge Functions with service account

❌ **Don't**: Show map without loading states  
✅ **Do**: Show skeleton/shimmer while loading

❌ **Don't**: Ignore permission denial  
✅ **Do**: Provide clear rationale & guide to settings

---

## 🎯 CONCLUSION

Phase 2 akan membawa AIVIA dari MVP ke **production-ready app** dengan fitur keamanan inti:

- ✅ Real-time location tracking
- ✅ Emergency alert system
- ✅ Push notifications
- ✅ Map visualization

Foundation yang sudah dibangun di Phase 1 dan Pre-Phase 2 sangat solid. Dengan roadmap yang jelas ini, development Phase 2 bisa berjalan smooth dan terukur.

**Key to Success**:

1. 🔍 Test early, test often (especially on real devices)
2. 📝 Document as you go
3. 🎯 Focus on core features first (Phase 2.1)
4. 🔋 Monitor battery impact continuously
5. 👥 Get user feedback ASAP

---

**Status**: 📋 **READY TO START PHASE 2**  
**Next Action**: Setup Firebase Console & start Day 1 (Location Service)  
**Estimated Completion**: 7 days from start

🚀 **Let's build something amazing!**

---

_Document prepared by: AI Assistant_  
_Last Updated: 14 Oktober 2025_  
_Version: 1.0_

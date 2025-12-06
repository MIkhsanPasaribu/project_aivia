# Sprint B: Geofencing UI Implementation Plan

**Tanggal**: 06 Desember 2025  
**Status**: Sprint A Complete ✅ → Sprint B Ready to Start 🚀  
**Objective**: Implement complete Geofencing UI for Family/Wali users  
**Testing**: `flutter analyze` only

---

## 📋 Current Status

### ✅ Sprint A Complete (Steps 1-5)

1. ✅ **3 Data Models Created**

   - `geofence.dart` (328 lines) - Geofence model with PostGIS support
   - `geofence_event.dart` (197 lines) - Enter/Exit event tracking
   - `pending_notification.dart` (260 lines) - Notification queue

2. ✅ **GeofenceRepository Created** (273 lines)

   - CRUD operations (Create, Read, Update, Delete)
   - Real-time streams (watchGeofencesForPatient, watchGeofenceEvents)
   - Utility methods (isLocationInsideGeofence, getActiveGeofencesCount)

3. ✅ **FCM Integration Complete**

   - Login/Register/Splash screens initialize FCM
   - Notification tap handlers with navigation
   - Emergency button queues notifications

4. ✅ **Testing Complete**
   - `flutter analyze`: 0 errors, 0 warnings ✅

---

## 🎯 Sprint B: Geofencing UI (Steps 1-10)

### Architecture Overview

```
User Flow (Family/Wali):
1. Dashboard → Tap "Kelola Zona Geografis"
2. GeofenceListScreen → View all geofences, filters, search
3. Tap "+" FAB → GeofenceFormScreen (Create Mode)
4. Pick location on map → Set radius → Configure alerts → Save
5. Tap existing geofence → GeofenceDetailScreen (View/Edit Mode)
6. View map with geofence circle → See event history timeline
7. Background: GeofenceMonitoringService monitors patient location
8. Enter/Exit detected → Queue notification → FCM sends alert

Technical Stack:
- State: Riverpod (StateNotifier pattern)
- Maps: google_maps_flutter (already in pubspec.yaml)
- Navigation: Named routes with arguments
- Real-time: Supabase streams
- Background: GeofenceMonitoringService integrates with LocationService
```

---

## 📝 Step-by-Step Implementation

### **Step 1: Create GeofenceProvider** 🆕

**File**: `lib/presentation/providers/geofence_provider.dart`

**Purpose**: State management untuk geofences dengan Riverpod

**Features**:

- `GeofenceListNotifier extends StateNotifier<AsyncValue<List<Geofence>>>`
- Methods: `loadGeofences()`, `createGeofence()`, `updateGeofence()`, `deleteGeofence()`, `toggleStatus()`
- Auto-refresh after mutations
- Error handling dengan Result pattern

**Code Structure**:

```dart
@riverpod
class GeofenceListNotifier extends _$GeofenceListNotifier {
  @override
  Future<List<Geofence>> build(String patientId) async {
    return _loadGeofences();
  }

  Future<void> createGeofence({...}) async {
    state = const AsyncLoading();
    final result = await ref.read(geofenceRepositoryProvider).createGeofence(...);
    result.fold(
      onSuccess: (_) => ref.invalidateSelf(),
      onFailure: (e) => state = AsyncError(e, StackTrace.current),
    );
  }
}

// Stream provider untuk real-time updates
@riverpod
Stream<List<Geofence>> geofencesStream(GeofencesStreamRef ref, String patientId) {
  return ref.watch(geofenceRepositoryProvider).watchGeofencesForPatient(patientId);
}

// Count provider
@riverpod
Future<int> activeGeofencesCount(ActiveGeofencesCountRef ref, String patientId) async {
  final result = await ref.read(geofenceRepositoryProvider).getActiveGeofencesCount(patientId);
  return result.fold(onSuccess: (count) => count, onFailure: (_) => 0);
}
```

**Quality Checklist**:

- ✅ Riverpod code generation (@riverpod annotation)
- ✅ Dartdoc comments (Bahasa Indonesia)
- ✅ Error handling dengan AsyncValue
- ✅ Auto-refresh after mutations

**Time Estimate**: 1 hour

---

### **Step 2: Create GeofenceCard Widget** 🆕

**File**: `lib/presentation/widgets/geofence/geofence_card.dart`

**Purpose**: Reusable card widget untuk display geofence di list

**UI Components**:

```
┌─────────────────────────────────────┐
│ 🏠 Rumah                  [🟢 Aktif] │
│ Zona Aman • Radius 500m             │
│                                      │
│ Alert: ✅ Masuk  ✅ Keluar           │
│ Prioritas: ⭐⭐⭐⭐⭐ (5/10)          │
│                                      │
│ Dibuat: 5 Des 2025                   │
│                                      │
│ [Edit]  [Hapus]  [Toggle Status]    │
└─────────────────────────────────────┘
```

**Props**:

- `Geofence geofence` (required)
- `VoidCallback? onTap` (navigate to detail)
- `VoidCallback? onEdit`
- `VoidCallback? onDelete`
- `VoidCallback? onToggleStatus`

**Features**:

- Color-coded by fence_type (safe=green, danger=red, etc)
- Icon per fence_type (home, hospital, school, etc)
- Swipe-to-delete gesture (Dismissible)
- Status toggle switch

**Quality Checklist**:

- ✅ Material Design 3 (Card, Chip, Badge)
- ✅ Dark mode support
- ✅ Accessibility (Semantics)
- ✅ Responsive layout

**Time Estimate**: 45 minutes

---

### **Step 3: Create GeofenceListScreen** 🆕

**File**: `lib/presentation/screens/family/geofences/geofence_list_screen.dart`

**Purpose**: Main screen untuk family/wali manage geofences

**UI Layout**:

```
┌────────────────────────────────────┐
│ ← Zona Geografis          [🔍]     │
├────────────────────────────────────┤
│ [Semua] [Aman] [Bahaya] [Rumah]   │ ← Chip filters
├────────────────────────────────────┤
│ 🏠 Rumah             [🟢 Aktif]    │
│ Zona Aman • 500m                   │
│ ────────────────────────────────   │
│ 🏥 RS Siloam         [🟢 Aktif]    │
│ Zona Aman • 1000m                  │
│ ────────────────────────────────   │
│ ⚠️ Jalan Raya        [🔴 Bahaya]   │
│ Zona Berbahaya • 200m              │
├────────────────────────────────────┤
│                              [+]    │ ← FAB
└────────────────────────────────────┘
```

**Features**:

1. **AppBar**:

   - Title: "Zona Geografis"
   - Search icon → Show search bar
   - Back button

2. **Filter Chips** (Horizontal scroll):

   - Semua (default)
   - Aman (safe, home, hospital, school)
   - Bahaya (danger)
   - Aktif (is_active=true)
   - Nonaktif (is_active=false)

3. **List View**:

   - `ListView.builder` dengan GeofenceCard
   - Pull-to-refresh (RefreshIndicator)
   - Empty state: "Belum ada zona geografis"
   - Loading state: Shimmer skeleton

4. **FAB** (FloatingActionButton):

   - Icon: Icons.add
   - onPressed: Navigate to GeofenceFormScreen (create mode)

5. **Actions**:
   - Tap card → Navigate to GeofenceDetailScreen
   - Swipe delete → Confirmation dialog
   - Toggle switch → Update status

**State Management**:

```dart
final geofencesAsync = ref.watch(geofencesStreamProvider(patientId));

geofencesAsync.when(
  data: (geofences) {
    final filtered = _filterGeofences(geofences, selectedFilter);
    return ListView.builder(...);
  },
  loading: () => ShimmerLoading(),
  error: (e, st) => ErrorWidget(error: e),
);
```

**Quality Checklist**:

- ✅ Real-time updates (Stream)
- ✅ Search functionality
- ✅ Filters with state preservation
- ✅ Empty state handling
- ✅ Error handling
- ✅ Loading states (shimmer)

**Time Estimate**: 2 hours

---

### **Step 4: Create GeofenceFormScreen** 🆕

**Files**:

1. `lib/presentation/screens/family/geofences/geofence_form_screen.dart`
2. `lib/presentation/widgets/geofence/geofence_map_picker.dart` (custom widget)

**Purpose**: Form untuk create/edit geofence dengan map picker

**UI Layout**:

```
┌────────────────────────────────────┐
│ ← Tambah Zona Geografis      [✓]  │
├────────────────────────────────────┤
│                                    │
│        🗺️ MAP VIEW                │
│     ┌─────────────────┐            │
│     │  📍 Drag marker │            │
│     │  ⭕ Geofence    │            │
│     └─────────────────┘            │
│                                    │
├────────────────────────────────────┤
│ Nama Zona                          │
│ [Rumah_____________________]       │
│                                    │
│ Jenis Zona                         │
│ [Aman ▼] (Dropdown)                │
│                                    │
│ Radius (meter)                     │
│ [===========●===========] 500m     │
│                                    │
│ Alert saat masuk zona              │
│ [✓] Aktifkan notifikasi            │
│                                    │
│ Alert saat keluar zona             │
│ [✓] Aktifkan notifikasi            │
│                                    │
│ Prioritas                          │
│ [========●=============] 5/10      │
│                                    │
│ Deskripsi (Opsional)               │
│ [_________________________]        │
│                                    │
│ [Batal]          [Simpan]          │
└────────────────────────────────────┘
```

**Form Fields**:

1. **Map Picker** (GeofenceMapPicker widget):

   - google_maps_flutter (GoogleMap widget)
   - Draggable marker (center point)
   - Circle overlay (radius visualization)
   - Current location button
   - Zoom controls
   - Tap map → Update marker position

2. **Nama Zona** (TextField):

   - Required
   - Max 50 chars
   - Validator: tidak boleh kosong

3. **Jenis Zona** (DropdownButton):

   - Options: Aman, Bahaya, Rumah, Rumah Sakit, Sekolah, Custom
   - Maps to FenceType enum

4. **Radius** (Slider):

   - Min: 50m, Max: 5000m (5km)
   - Step: 10m
   - Display value: "500 meter"

5. **Alert On Enter** (SwitchListTile):

   - Default: true

6. **Alert On Exit** (SwitchListTile):

   - Default: true

7. **Priority** (Slider):

   - Min: 1, Max: 10
   - Display: Star rating visual

8. **Deskripsi** (TextField):
   - Optional
   - Multi-line (maxLines: 3)

**Validation**:

- At least one alert must be enabled (enter OR exit)
- Nama tidak boleh kosong
- Coordinates harus valid (dari map picker)

**Submit Logic**:

```dart
Future<void> _handleSubmit() async {
  if (!_formKey.currentState!.validate()) return;

  final provider = ref.read(geofenceListNotifierProvider(patientId).notifier);

  if (isEditMode) {
    await provider.updateGeofence(geofenceId, formData);
  } else {
    await provider.createGeofence(formData);
  }

  if (mounted) {
    Navigator.pop(context); // Back to list
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Zona berhasil disimpan')),
    );
  }
}
```

**Quality Checklist**:

- ✅ Form validation
- ✅ Map picker dengan UX baik
- ✅ Circle overlay dengan radius akurat
- ✅ Permission handling (location)
- ✅ Loading state saat submit
- ✅ Error handling

**Time Estimate**: 3 hours

---

### **Step 5: Create GeofenceDetailScreen** 🆕

**Files**:

1. `lib/presentation/screens/family/geofences/geofence_detail_screen.dart`
2. `lib/presentation/widgets/geofence/event_timeline_widget.dart`

**Purpose**: Detail screen dengan map view + event history timeline

**UI Layout**:

```
┌────────────────────────────────────┐
│ ← Rumah                    [Edit]  │
├────────────────────────────────────┤
│                                    │
│        🗺️ MAP VIEW                │
│     ┌─────────────────┐            │
│     │  ⭕ Geofence    │            │
│     │  📍 Patient loc │            │
│     │  ━━ Route      │            │
│     └─────────────────┘            │
│                                    │
├────────────────────────────────────┤
│ 📍 Informasi Zona                  │
│ ┌────────────────────────────────┐ │
│ │ Jenis: Zona Aman               │ │
│ │ Radius: 500 meter              │ │
│ │ Prioritas: ⭐⭐⭐⭐⭐ (5/10)     │ │
│ │ Alert: ✅ Masuk  ✅ Keluar     │ │
│ │ Status: 🟢 Aktif               │ │
│ │ Dibuat: 5 Des 2025             │ │
│ └────────────────────────────────┘ │
│                                    │
│ 📜 Riwayat Kejadian (10 terakhir)  │
│ ┌────────────────────────────────┐ │
│ │ 🟢 Masuk Zona                  │ │
│ │ 5 Des 2025, 14:30              │ │
│ │ Jarak: 25m dari pusat          │ │
│ └────────────────────────────────┘ │
│ ┌────────────────────────────────┐ │
│ │ 🔴 Keluar Zona                 │ │
│ │ 5 Des 2025, 12:15              │ │
│ │ Jarak: 520m dari pusat         │ │
│ └────────────────────────────────┘ │
│                                    │
│ [Toggle Status]  [Hapus Zona]      │
└────────────────────────────────────┘
```

**Sections**:

1. **AppBar**:

   - Title: Geofence name
   - Actions: Edit button (navigate to form edit mode)

2. **Map View** (Top section, 40% height):

   - GoogleMap with geofence circle
   - Patient's current location marker (real-time)
   - Center on geofence by default
   - Zoom to fit geofence + patient

3. **Info Card**:

   - Fence type dengan icon
   - Radius dalam meter
   - Priority dengan star rating
   - Alert configuration
   - Status (active/inactive)
   - Created date
   - Description (jika ada)

4. **Event Timeline** (EventTimelineWidget):

   - ListView of last 10 events
   - Enter events (green icon)
   - Exit events (red icon)
   - Timestamp
   - Distance from center
   - "Lihat Semua" button → Full history screen

5. **Action Buttons**:
   - Toggle Status: Switch geofence active/inactive
   - Hapus Zona: Delete dengan confirmation dialog

**Real-time Updates**:

```dart
// Watch geofence stream
final geofenceAsync = ref.watch(geofenceByIdStreamProvider(geofenceId));

// Watch events stream
final eventsAsync = ref.watch(geofenceEventsStreamProvider(geofenceId));

// Watch patient location
final locationAsync = ref.watch(patientLocationStreamProvider(patientId));
```

**Quality Checklist**:

- ✅ Real-time map updates (patient location)
- ✅ Event timeline dengan pagination
- ✅ Confirmation dialogs untuk delete
- ✅ Smooth animations
- ✅ Error handling

**Time Estimate**: 2.5 hours

---

### **Step 6: Create GeofenceMonitoringService** 🆕

**File**: `lib/data/services/geofence_monitoring_service.dart`

**Purpose**: Background service untuk monitor patient location vs geofences

**Architecture**:

```
LocationService (GPS updates every 15 sec)
     ↓
GeofenceMonitoringService (checks geofences)
     ↓
GeofenceRepository (create event)
     ↓
FCMRepository (queue notification)
```

**Key Methods**:

```dart
class GeofenceMonitoringService {
  Future<void> startMonitoring(String patientId) async {
    // 1. Load active geofences
    // 2. Listen to LocationService updates
    // 3. Check each location against geofences
    // 4. Detect enter/exit events
    // 5. Queue notifications
  }

  Future<void> _checkGeofences(Position position, List<Geofence> geofences) async {
    for (final geofence in geofences) {
      final isInside = await _isInsideGeofence(position, geofence);
      final wasInside = _previousStates[geofence.id] ?? false;

      if (isInside && !wasInside) {
        await _handleEnter(geofence, position);
      } else if (!isInside && wasInside) {
        await _handleExit(geofence, position);
      }

      _previousStates[geofence.id] = isInside;
    }
  }

  Future<void> _handleEnter(Geofence geofence, Position position) async {
    // 1. Create geofence_event (type: enter)
    // 2. Queue notification jika alert_on_enter=true
  }

  Future<void> _handleExit(Geofence geofence, Position position) async {
    // 1. Create geofence_event (type: exit)
    // 2. Queue notification jika alert_on_exit=true
  }
}
```

**State Persistence**:

- SharedPreferences untuk track last known state per geofence
- Prevent duplicate events (debouncing)

**Optimization**:

- Reuse LocationService updates (don't create new stream)
- Batch geofence checks (all in one location update)
- Debounce enter/exit (min 30 seconds between same event)

**Quality Checklist**:

- ✅ Battery-friendly (piggyback on existing location updates)
- ✅ Debouncing untuk prevent spam
- ✅ Error handling (network errors, etc)
- ✅ Background-safe (works when app in background)

**Time Estimate**: 2 hours

---

### **Step 7: Integrate Geofences in FamilyHomeScreen** 🆕

**File**: `lib/presentation/screens/family/family_home_screen.dart` (modify existing)

**Changes**:

1. **Add Menu Card**:

```dart
MenuCard(
  icon: Icons.location_on_outlined,
  title: 'Zona Geografis',
  subtitle: '$activeGeofencesCount zona aktif',
  onTap: () => Navigator.pushNamed(context, AppRoutes.familyGeofenceList),
),
```

2. **Add Dashboard Stats**:

```dart
StatsCard(
  icon: Icons.pin_drop,
  label: 'Zona Aktif',
  value: '$activeGeofencesCount',
  color: Colors.blue,
),
```

3. **Show Recent Geofence Events** (optional):

```dart
RecentEventsCard(
  title: 'Kejadian Zona Terakhir',
  events: recentGeofenceEvents,
),
```

**Quality Checklist**:

- ✅ UI konsisten dengan existing cards
- ✅ Real-time count update
- ✅ Navigation works

**Time Estimate**: 30 minutes

---

### **Step 8: Add Geofence Routes** 🆕

**File**: `lib/core/constants/app_routes.dart` (modify existing)

**Add Routes**:

```dart
// Geofence routes (family)
static const String familyGeofenceList = '/family/geofences';
static const String familyGeofenceForm = '/family/geofences/form';
static const String familyGeofenceDetail = '/family/geofences/detail';
```

**Register in MaterialApp**:

```dart
routes: {
  ...
  AppRoutes.familyGeofenceList: (context) => const GeofenceListScreen(),
  AppRoutes.familyGeofenceForm: (context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    return GeofenceFormScreen(
      patientId: args?['patient_id'],
      geofenceId: args?['geofence_id'], // null untuk create mode
    );
  },
  AppRoutes.familyGeofenceDetail: (context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return GeofenceDetailScreen(
      geofenceId: args['geofence_id'],
    );
  },
},
```

**Quality Checklist**:

- ✅ Named routes dengan type-safe arguments
- ✅ Consistent naming convention

**Time Estimate**: 15 minutes

---

### **Step 9: Integration Testing** 🧪

**Test Scenarios**:

1. **Create Geofence Flow**:

   - Navigate: Dashboard → Zona Geografis → [+]
   - Pick location on map
   - Fill form (all fields)
   - Submit → Should appear in list

2. **View Detail Flow**:

   - Tap geofence card
   - Should show map + info + events
   - Patient marker should update real-time

3. **Edit Geofence Flow**:

   - Detail screen → Edit button
   - Modify fields
   - Save → Should update in list

4. **Delete Geofence Flow**:

   - Swipe card / Detail screen → Delete
   - Confirmation dialog
   - Confirm → Should disappear from list

5. **Geofence Monitoring Flow**:

   - Patient moves near geofence
   - Should create enter event
   - Family should receive notification
   - Event should appear in timeline

6. **Real-time Updates**:
   - Open list screen on 2 devices
   - Create geofence on device 1
   - Should appear on device 2 automatically

**Quality Checklist**:

- ✅ All user flows work end-to-end
- ✅ No crashes or errors
- ✅ Real-time sync works
- ✅ Notifications delivered

**Time Estimate**: 1 hour

---

### **Step 10: Final Validation** ✅

**Command**: `flutter analyze`

**Expected**: 0 errors, 0 warnings

**Additional Checks**:

- ✅ No unused imports
- ✅ No unused variables
- ✅ All public APIs documented
- ✅ Null safety complete
- ✅ Bahasa Indonesia untuk UI strings

**Time Estimate**: 30 minutes

---

## 📊 Summary

### Total Time Estimate: **13.5 hours**

### Files to Create (14 new files):

1. `geofence_provider.dart` (provider)
2. `geofence_card.dart` (widget)
3. `geofence_list_screen.dart` (screen)
4. `geofence_form_screen.dart` (screen)
5. `geofence_map_picker.dart` (widget)
6. `geofence_detail_screen.dart` (screen)
7. `event_timeline_widget.dart` (widget)
8. `geofence_monitoring_service.dart` (service)

### Files to Modify (3 files):

1. `family_home_screen.dart` (add menu + stats)
2. `app_routes.dart` (add routes)
3. `main.dart` (register routes)

### Database Ready:

- ✅ Table `geofences` exists
- ✅ Table `geofence_events` exists
- ✅ PostGIS functions ready
- ✅ RLS policies configured

### Dependencies Already Installed:

- ✅ `google_maps_flutter` (maps)
- ✅ `geolocator` (location)
- ✅ `flutter_riverpod` (state)
- ✅ `supabase_flutter` (backend)

---

## 🎯 Next Steps

1. **Start dengan Step 1** (GeofenceProvider)
2. **Build UI incrementally** (Steps 2-5)
3. **Add monitoring service** (Step 6)
4. **Integrate with existing screens** (Step 7-8)
5. **Test thoroughly** (Step 9)
6. **Validate dengan flutter analyze** (Step 10)

---

## 🔥 Implementation Order (Optimal)

**Phase 1 - Foundation (Steps 1-2)**: Provider + Widget  
**Phase 2 - Screens (Steps 3-5)**: List → Form → Detail  
**Phase 3 - Monitoring (Step 6)**: Background service  
**Phase 4 - Integration (Steps 7-8)**: Dashboard + Routes  
**Phase 5 - Testing (Steps 9-10)**: E2E + Validation

---

## ✅ Definition of Done

Setiap step dianggap complete ketika:

- ✅ Code ditulis dengan best practices
- ✅ Dartdoc comments lengkap (Bahasa Indonesia)
- ✅ UI strings dalam Bahasa Indonesia
- ✅ Dark mode support
- ✅ Error handling complete
- ✅ Null safety enforced
- ✅ `flutter analyze` pass (0 errors, 0 warnings)

**Sprint B selesai ketika**:

- ✅ Family/Wali dapat create, view, edit, delete geofences
- ✅ Patient location monitored real-time
- ✅ Enter/Exit events detected dan logged
- ✅ Notifications sent saat enter/exit
- ✅ Event history visible dengan timeline
- ✅ All screens integrated dengan navigation
- ✅ `flutter analyze` clean

---

**Ready to start Sprint B!** 🚀

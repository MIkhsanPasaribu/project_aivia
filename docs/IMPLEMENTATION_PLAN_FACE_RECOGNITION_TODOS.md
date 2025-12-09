# 🚀 Implementation Plan: Face Recognition & TODO Resolution

**Dibuat**: 2025-01-08  
**Status**: Ready to Execute  
**Estimasi Total**: 4-6 jam

---

## 📊 **ANALISIS KOMPREHENSIF**

### **TODO Comments yang Ditemukan** (43 total)

#### **Kategori 1: CRITICAL - Face Recognition (13 TODOs)**

```
lib/data/services/face_recognition_service.dart:
├─ Line 15:  "Face embedding generation dengan TFLite GhostFaceNet (TODO: Phase 3B)"
├─ Line 22:  "TFLite interpreter will be added in Phase 3B"
├─ Line 50:  "TODO Phase 3B: Load TFLite model from assets"
├─ Line 223: "FACE EMBEDDING GENERATION (TODO: Phase 3B)"
├─ Line 228: "Status: STUB - Akan diimplementasi di Phase 3B"
├─ Line 264: "TODO Phase 3B: Implement TFLite inference"
├─ Line 265: "For now, return MOCK embedding (512 random values)"
├─ Line 267: "⚠️ MOCK: Generating random embedding"
├─ Line 268: "_generateMockEmbedding()"
├─ Line 278: "MOCK embedding generator (TEMPORARY - untuk testing)"
├─ Line 282: "_generateMockEmbedding()"
├─ Line 359: "TODO Phase 3B: _interpreter?.close()"
└─ Line 270: "return Success(mockEmbedding)"
```

#### **Kategori 2: HIGH Priority - Navigation & Features (8 TODOs)**

```
lib/data/services/notification_service.dart:
└─ Line 211: "TODO: Handle navigation berdasarkan notification type"

lib/data/services/fcm_service.dart:
├─ Line 428: "TODO: Implement navigation logic based on payload"
└─ Line 591: "TODO: Implement background processing logic"

lib/presentation/providers/face_recognition_provider.dart:
└─ Line 333: "TODO: get real similarity from DB"

lib/presentation/screens/patient/face_recognition/recognize_face_screen.dart:
└─ Line 200: "similarity: null, // TODO: Query from FaceRecognitionLog"

lib/presentation/screens/patient/face_recognition/recognition_result_screen.dart:
└─ Line 526: "TODO: Navigate to known persons list (family feature)"
```

#### **Kategori 3: MEDIUM Priority - Patient Selector (4 TODOs)**

```
lib/presentation/screens/family/patient_tracking/patient_map_tab_wrapper.dart:
└─ Line 38: "TODO: Implement patient selector"

lib/presentation/screens/family/known_persons/known_persons_tab_wrapper.dart:
└─ Line 38: "TODO: Implement patient selector"

lib/presentation/screens/family/activities/activities_tab_wrapper.dart:
└─ Line 41: "TODO: Implement patient selector"

lib/presentation/screens/family/patient_tracking/patient_map_screen.dart:
└─ Line 227: "TODO: Add caching in future optimization"
```

#### **Kategori 4: LOW Priority - Code Quality (18 TODOs)**

```
Type casting improvements (.toDouble() usage):
├─ lib/data/models/known_person.dart: Line 44
├─ lib/data/models/location.dart: Lines 28, 38
├─ lib/data/models/geofence_event.dart: Line 74
├─ lib/data/models/face_recognition_log.dart: Lines 39, 40, 66
└─ lib/presentation/screens/family/geofences/*.dart: Various lines
```

---

## 🎯 **IMPLEMENTATION STRATEGY**

### **Phase 1: TFLite GhostFaceNet Integration** ⭐ CRITICAL

**Priority**: P0 (Must Have)  
**Estimasi**: 3-4 jam  
**Impact**: Fitur face recognition menjadi 100% functional

#### **Tasks**:

1. ✅ Download GhostFaceNet model (~5MB)
2. ✅ Add model to `assets/ml_models/ghostfacenet.tflite`
3. ✅ Update `pubspec.yaml` untuk include asset
4. ✅ Implement TFLite loading di `FaceRecognitionService.initialize()`
5. ✅ Implement real inference di `generateEmbedding()`
6. ✅ Remove semua mock code
7. ✅ Add error handling untuk model loading
8. ✅ Add interpreter disposal di `dispose()`
9. ✅ Test dengan real photos

**Files to Modify**:

```
lib/data/services/face_recognition_service.dart (MAJOR REWRITE)
lib/main.dart (add initialization)
pubspec.yaml (add asset)
```

**Code Changes**:

```dart
// BEFORE (MOCK):
List<double> _generateMockEmbedding() {
  final random = Random();
  return List.generate(512, (_) => (random.nextDouble() * 2) - 1);
}

// AFTER (REAL):
Future<List<double>> generateEmbedding(File imageFile) async {
  // 1. Preprocess image
  final input = await _preprocessImageForInference(imageFile);

  // 2. Run TFLite inference
  final output = List.filled(512, 0.0).reshape([1, 512]);
  _interpreter!.run(input, output);

  // 3. L2 normalize
  return _l2Normalize(output[0]);
}
```

---

### **Phase 2: Navigation & Deep Linking** ⭐ HIGH

**Priority**: P1 (Should Have)  
**Estimasi**: 1-2 jam  
**Impact**: Better UX, notification click handling

#### **Tasks**:

1. ✅ Implement notification tap navigation di `NotificationService`
2. ✅ Implement FCM payload navigation di `FCMService`
3. ✅ Add route handling untuk:
   - Activity detail screen
   - Emergency alert screen
   - Face recognition result
   - Geofence alerts
4. ✅ Implement deep linking logic
5. ✅ Test notification navigation flow

**Files to Modify**:

```
lib/data/services/notification_service.dart
lib/data/services/fcm_service.dart
lib/core/constants/app_routes.dart (add new routes)
```

**Implementation**:

```dart
// NotificationService
void _handleNotificationTap(ReceivedAction receivedAction) {
  final payload = receivedAction.payload;

  switch (payload?['type']) {
    case 'activity_reminder':
      navigatorKey.currentState?.pushNamed(
        AppRoutes.activityDetail,
        arguments: payload['activity_id'],
      );
      break;
    case 'emergency_alert':
      navigatorKey.currentState?.pushNamed(
        AppRoutes.emergencyDetail,
        arguments: payload['alert_id'],
      );
      break;
    case 'geofence_event':
      navigatorKey.currentState?.pushNamed(
        AppRoutes.patientMap,
        arguments: payload['patient_id'],
      );
      break;
  }
}
```

---

### **Phase 3: Face Recognition Enhancements** ⭐ MEDIUM

**Priority**: P2 (Nice to Have)  
**Estimasi**: 1 jam  
**Impact**: Better analytics & user insights

#### **Tasks**:

1. ✅ Query real similarity dari `face_recognition_logs`
2. ✅ Display similarity score di UI result screen
3. ✅ Add navigation dari result ke known persons list
4. ✅ Add recognition statistics (count, last seen)
5. ✅ Improve error messaging

**Files to Modify**:

```
lib/presentation/providers/face_recognition_provider.dart
lib/presentation/screens/patient/face_recognition/recognition_result_screen.dart
lib/presentation/screens/patient/face_recognition/recognize_face_screen.dart
```

**Implementation**:

```dart
// FaceRecognitionProvider
Future<FaceRecognitionLog?> getLatestRecognitionLog(String patientId) async {
  final result = await _recognitionLogRepository.getLatestLog(patientId);
  return result is Success ? result.data : null;
}

// RecognitionResultScreen - show similarity
if (recognizedPerson != null && log != null) {
  Text('Kecocokan: ${(log.similarityScore * 100).toStringAsFixed(1)}%');
}
```

---

### **Phase 4: Patient Selector for Family** ⭐ MEDIUM

**Priority**: P2 (Nice to Have)  
**Estimasi**: 1-2 jam  
**Impact**: Multi-patient family support

#### **Tasks**:

1. ✅ Create `PatientSelectorWidget` reusable component
2. ✅ Implement patient switching logic
3. ✅ Persist selected patient di SharedPreferences
4. ✅ Update 3 wrapper screens untuk use selector
5. ✅ Add "Semua Pasien" option untuk family dengan multiple patients

**Files to Modify**:

```
lib/presentation/widgets/common/patient_selector_widget.dart (NEW)
lib/presentation/screens/family/patient_tracking/patient_map_tab_wrapper.dart
lib/presentation/screens/family/known_persons/known_persons_tab_wrapper.dart
lib/presentation/screens/family/activities/activities_tab_wrapper.dart
```

**Implementation**:

```dart
// PatientSelectorWidget
class PatientSelectorWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patients = ref.watch(linkedPatientsProvider);
    final selectedId = ref.watch(selectedPatientIdProvider);

    return DropdownButton<String>(
      value: selectedId,
      items: patients.map((p) => DropdownMenuItem(
        value: p.id,
        child: Text(p.fullName),
      )).toList(),
      onChanged: (id) {
        ref.read(selectedPatientIdProvider.notifier).state = id!;
      },
    );
  }
}
```

---

### **Phase 5: Code Quality & Type Safety** ⭐ LOW

**Priority**: P3 (Code Health)  
**Estimasi**: 30 min  
**Impact**: Safer code, fewer runtime errors

#### **Tasks**:

1. ✅ Fix all `.toDouble()` type casting dengan proper null safety
2. ✅ Add validation before casting
3. ✅ Use consistent patterns across models
4. ✅ Run `flutter analyze` dan fix warnings

**Files to Modify**:

```
lib/data/models/*.dart (semua model files)
```

**Pattern**:

```dart
// BEFORE:
final value = (json['field'] as num).toDouble();

// AFTER (safer):
final value = json['field'] != null
  ? (json['field'] as num).toDouble()
  : 0.0;

// OR with extension:
extension NumExtension on num? {
  double toDoubleOrZero() => this?.toDouble() ?? 0.0;
}

// Usage:
final value = (json['field'] as num?).toDoubleOrZero();
```

---

### **Phase 6: Performance Optimizations** ⭐ LOW

**Priority**: P4 (Future Enhancement)  
**Estimasi**: 1 jam  
**Impact**: Better performance for large datasets

#### **Tasks**:

1. ✅ Implement caching untuk patient map location queries
2. ✅ Add pagination untuk face recognition logs
3. ✅ Optimize vector similarity search queries
4. ✅ Add result memoization di providers

**Files to Modify**:

```
lib/presentation/screens/family/patient_tracking/patient_map_screen.dart
lib/data/repositories/known_person_repository.dart
lib/presentation/providers/face_recognition_provider.dart
```

---

## 📋 **DETAILED TODO CHECKLIST**

### **Sprint 1: Face Recognition Core (CRITICAL)** ⏰ 3-4 hours

- [ ] **Task 1.1**: Download GhostFaceNet Model

  - [ ] Research model sources (GitHub, TensorFlow Hub)
  - [ ] Download `.tflite` file (~5MB)
  - [ ] Verify file integrity (checksum)
  - [ ] Place in `assets/ml_models/ghostfacenet.tflite`

- [ ] **Task 1.2**: Update Project Configuration

  - [ ] Add asset path ke `pubspec.yaml`
  - [ ] Run `flutter pub get`
  - [ ] Verify asset bundled (`flutter assets`)

- [ ] **Task 1.3**: Implement TFLite Loading

  - [ ] Import `tflite_flutter` package
  - [ ] Add `Interpreter? _interpreter` field
  - [ ] Implement `initialize()` method:
    ```dart
    _interpreter = await Interpreter.fromAsset(
      'assets/ml_models/ghostfacenet.tflite',
      options: InterpreterOptions()..threads = 4,
    );
    ```
  - [ ] Add error handling untuk loading failures
  - [ ] Log input/output shapes untuk verification

- [ ] **Task 1.4**: Implement Image Preprocessing

  - [ ] Create `_preprocessImageForInference()` helper
  - [ ] Decode image dengan `image` package
  - [ ] Resize ke 112x112 (GhostFaceNet input)
  - [ ] Convert ke Float32List
  - [ ] Normalize pixels ke [0, 1]
  - [ ] Verify pixel order (RGB not BGR)

- [ ] **Task 1.5**: Implement Real Inference

  - [ ] Replace `_generateMockEmbedding()` call
  - [ ] Run inference: `_interpreter.run(input, output)`
  - [ ] Extract embedding dari output tensor
  - [ ] L2 normalize embedding
  - [ ] Verify embedding determinism (same photo = same embedding)

- [ ] **Task 1.6**: Remove Mock Code

  - [ ] Delete `_generateMockEmbedding()` method
  - [ ] Remove all "MOCK" debug prints
  - [ ] Remove "TODO Phase 3B" comments
  - [ ] Update method documentation

- [ ] **Task 1.7**: Update Disposal

  - [ ] Uncomment `_interpreter?.close()`
  - [ ] Add null check before closing
  - [ ] Verify no memory leaks

- [ ] **Task 1.8**: Update Main Initialization

  - [ ] Call `faceService.initialize()` di `main()`
  - [ ] Add error handling untuk init failures
  - [ ] Override provider dengan initialized service

- [ ] **Task 1.9**: Testing
  - [ ] Unit test: Model loading
  - [ ] Unit test: Embedding generation
  - [ ] Unit test: Embedding determinism
  - [ ] Manual test: Add known person
  - [ ] Manual test: Recognize face
  - [ ] Verify database has real embeddings (not all zeros)

---

### **Sprint 2: Navigation & UX (HIGH)** ⏰ 1-2 hours

- [ ] **Task 2.1**: Notification Navigation

  - [ ] Implement `_handleNotificationTap()` di NotificationService
  - [ ] Add route mapping untuk notification types:
    - [ ] `activity_reminder` → ActivityDetailScreen
    - [ ] `emergency_alert` → EmergencyAlertScreen
    - [ ] `geofence_event` → PatientMapScreen
  - [ ] Add payload validation
  - [ ] Test dengan local notifications

- [ ] **Task 2.2**: FCM Payload Navigation

  - [ ] Implement navigation logic di `FCMService._handleMessage()`
  - [ ] Parse RemoteMessage payload
  - [ ] Route based on notification type
  - [ ] Handle app states (foreground, background, terminated)
  - [ ] Test dengan FCM test messages

- [ ] **Task 2.3**: Deep Linking Setup

  - [ ] Add GlobalKey<NavigatorState> di main.dart
  - [ ] Configure routes di AppRouter
  - [ ] Add route guards (auth check)
  - [ ] Test navigation from notifications

- [ ] **Task 2.4**: Background Processing
  - [ ] Implement background message handler
  - [ ] Register with Firebase
  - [ ] Handle data-only messages
  - [ ] Test background sync

---

### **Sprint 3: Face Recognition UX (MEDIUM)** ⏰ 1 hour

- [ ] **Task 3.1**: Real Similarity Display

  - [ ] Query latest log dari `face_recognition_logs`
  - [ ] Display similarity score di result screen
  - [ ] Add visual indicator (progress bar / gauge)
  - [ ] Show confidence level (Tinggi/Sedang/Rendah)

- [ ] **Task 3.2**: Recognition Statistics

  - [ ] Display `recognition_count` di known person card
  - [ ] Display `last_seen_at` di result screen
  - [ ] Add "Terakhir dilihat: X hari yang lalu"
  - [ ] Update stats after successful recognition

- [ ] **Task 3.3**: Navigation Enhancements

  - [ ] Add "Lihat Semua Orang Dikenal" button di result
  - [ ] Navigate to KnownPersonsListScreen
  - [ ] Pass patient context
  - [ ] Highlight recognized person di list

- [ ] **Task 3.4**: Error Messaging
  - [ ] Improve "Wajah Tidak Dikenali" message
  - [ ] Add troubleshooting tips:
    - "Pastikan pencahayaan cukup"
    - "Hadapkan wajah ke depan kamera"
    - "Jarak ideal: 30-50cm"
  - [ ] Add retry guidance

---

### **Sprint 4: Patient Selector (MEDIUM)** ⏰ 1-2 hours

- [ ] **Task 4.1**: Create Reusable Widget

  - [ ] Create `PatientSelectorWidget`
  - [ ] Fetch linked patients dari PatientFamilyProvider
  - [ ] Build dropdown dengan patient names
  - [ ] Add avatar thumbnails
  - [ ] Implement selection handler

- [ ] **Task 4.2**: State Management

  - [ ] Create `selectedPatientIdProvider`
  - [ ] Persist to SharedPreferences
  - [ ] Load on app start
  - [ ] Handle multi-patient scenarios

- [ ] **Task 4.3**: Update Wrapper Screens

  - [ ] PatientMapTabWrapper: Add selector di AppBar
  - [ ] KnownPersonsTabWrapper: Add selector di AppBar
  - [ ] ActivitiesTabWrapper: Add selector di AppBar
  - [ ] Filter data based on selected patient

- [ ] **Task 4.4**: Multi-Patient Support
  - [ ] Add "Semua Pasien" option
  - [ ] Aggregate data from all patients
  - [ ] Update queries untuk support filtering
  - [ ] Test dengan 2+ patients

---

### **Sprint 5: Code Quality (LOW)** ⏰ 30 min

- [ ] **Task 5.1**: Type Casting Safety

  - [ ] Review all `.toDouble()` usages
  - [ ] Add null checks before casting
  - [ ] Use null-aware operators
  - [ ] Create extension methods untuk common patterns

- [ ] **Task 5.2**: Model Consistency

  - [ ] Standardize JSON parsing patterns
  - [ ] Add validation di fromJson constructors
  - [ ] Consistent error handling
  - [ ] Add factory constructors untuk common cases

- [ ] **Task 5.3**: Flutter Analyze
  - [ ] Run `flutter analyze`
  - [ ] Fix all warnings
  - [ ] Fix all hints
  - [ ] Fix all lints
  - [ ] Aim for 0 issues

---

### **Sprint 6: Performance (LOW)** ⏰ 1 hour

- [ ] **Task 6.1**: Location Caching

  - [ ] Implement cache untuk recent locations
  - [ ] Use LRU eviction strategy
  - [ ] Cache timeout: 30 seconds
  - [ ] Reduce database queries

- [ ] **Task 6.2**: Query Optimization

  - [ ] Add LIMIT clause ke expensive queries
  - [ ] Implement pagination untuk logs
  - [ ] Use database indexes effectively
  - [ ] Profile slow queries

- [ ] **Task 6.3**: Provider Memoization
  - [ ] Use `@riverpod` with autoDispose
  - [ ] Implement result caching
  - [ ] Add cache invalidation logic
  - [ ] Reduce unnecessary rebuilds

---

## 🎯 **EXECUTION ORDER** (Recommended)

### **Week 1: Core Functionality** ⭐ MUST DO

```
Day 1-2: Sprint 1 (Face Recognition TFLite) - 3-4 hours
Day 3:   Sprint 2 (Navigation) - 1-2 hours
Day 4:   Sprint 3 (Face Recognition UX) - 1 hour
```

### **Week 2: Enhancements** ⭐ SHOULD DO

```
Day 5-6: Sprint 4 (Patient Selector) - 1-2 hours
Day 7:   Sprint 5 (Code Quality) - 30 min
```

### **Week 3: Optimization** ⭐ NICE TO HAVE

```
Day 8: Sprint 6 (Performance) - 1 hour
Day 9: Final testing & polish
Day 10: Documentation update
```

---

## ✅ **SUCCESS CRITERIA**

### **Sprint 1 - Face Recognition**

- [x] TFLite model loads without errors
- [x] Real embeddings generated (not random)
- [x] Same photo = same embedding (deterministic)
- [x] Recognition accuracy > 85% for known persons
- [x] Unknown faces correctly rejected
- [x] No "MOCK" messages in logs
- [x] flutter analyze: 0 errors

### **Sprint 2 - Navigation**

- [x] Notification tap navigates correctly
- [x] FCM payload parsed and routed
- [x] Background messages handled
- [x] Deep links work from notifications

### **Sprint 3 - UX**

- [x] Similarity score displayed
- [x] Recognition stats updated
- [x] Navigation to known persons works
- [x] Error messages helpful

### **Sprint 4 - Patient Selector**

- [x] Dropdown shows all linked patients
- [x] Selection persisted across restarts
- [x] Data filtered correctly
- [x] Works with 1 or N patients

### **Sprint 5 - Code Quality**

- [x] All type casts safe
- [x] flutter analyze: 0 issues
- [x] Consistent code patterns
- [x] No TODO comments remaining

### **Sprint 6 - Performance**

- [x] Location queries < 100ms
- [x] Face recognition < 500ms end-to-end
- [x] No UI jank on scrolling
- [x] Memory usage stable

---

## 🔧 **TESTING STRATEGY**

### **Unit Tests**

```dart
test/services/face_recognition_service_test.dart
test/repositories/known_person_repository_test.dart
test/providers/face_recognition_provider_test.dart
```

### **Widget Tests**

```dart
test/screens/recognize_face_screen_test.dart
test/widgets/patient_selector_widget_test.dart
```

### **Integration Tests**

```dart
integration_test/face_recognition_flow_test.dart
integration_test/notification_navigation_test.dart
```

### **Manual Testing Checklist**

- [ ] Add known person with photo
- [ ] Recognize known person (should match)
- [ ] Try unknown face (should reject)
- [ ] Test notification tap navigation
- [ ] Test patient selector switching
- [ ] Test with poor lighting
- [ ] Test with multiple faces
- [ ] Test app restart (persistence)

---

## 📊 **PROGRESS TRACKING**

### **Completion Metrics**

| Sprint    | Tasks  | Estimated     | Status         | Actual |
| --------- | ------ | ------------- | -------------- | ------ |
| Sprint 1  | 9      | 3-4h          | 🔴 Not Started | -      |
| Sprint 2  | 4      | 1-2h          | 🔴 Not Started | -      |
| Sprint 3  | 4      | 1h            | 🔴 Not Started | -      |
| Sprint 4  | 4      | 1-2h          | 🔴 Not Started | -      |
| Sprint 5  | 3      | 30m           | 🔴 Not Started | -      |
| Sprint 6  | 3      | 1h            | 🔴 Not Started | -      |
| **TOTAL** | **27** | **7.5-10.5h** | **0%**         | **-**  |

### **Status Legend**

- 🔴 Not Started
- 🟡 In Progress
- 🟢 Completed
- ⚪ Blocked

---

## 🚨 **RISKS & MITIGATION**

| Risk                              | Probability | Impact   | Mitigation                               |
| --------------------------------- | ----------- | -------- | ---------------------------------------- |
| TFLite model not available        | Medium      | Critical | Use alternative (MobileFaceNet, FaceNet) |
| Model too slow (>500ms)           | Medium      | High     | Use quantized model (int8)               |
| Low recognition accuracy          | Low         | High     | Fine-tune threshold (0.80-0.90)          |
| Breaking changes in existing code | Low         | Medium   | Comprehensive testing before commit      |
| Memory leaks from interpreter     | Low         | Medium   | Proper disposal, profiling               |

---

## 📚 **RESOURCES**

### **Documentation**

- TFLite Flutter: https://pub.dev/packages/tflite_flutter
- GhostFaceNet Paper: https://arxiv.org/abs/1911.11907
- pgvector Guide: https://github.com/pgvector/pgvector

### **Code References**

- `TFLITE_IMPLEMENTATION_GUIDE.md` - Step-by-step TFLite setup
- `LAPORAN_PROGRESS_7_FACE_RECOGNITION_ANALYSIS.md` - Comprehensive analysis

### **Model Sources**

- GhostFaceNet: https://github.com/HuangJunJie2017/GhostFaceNets
- MobileFaceNet: https://github.com/sirius-ai/MobileFaceNet_TF
- FaceNet: https://github.com/davidsandberg/facenet

---

## 🎉 **READY TO START?**

**Recommendation**: Start dengan **Sprint 1 (Face Recognition)** karena ini adalah blocker untuk production release.

**Command to begin**:

```bash
# Navigate to project
cd c:\Users\mikhs\Documents\Projects\project_aivia

# Create feature branch
git checkout -b feature/face-recognition-tflite

# Start implementation!
```

---

**Prepared by**: GitHub Copilot  
**Last Updated**: 2025-01-08  
**Version**: 1.0.0

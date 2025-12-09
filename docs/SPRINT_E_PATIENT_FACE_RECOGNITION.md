# 🎯 SPRINT E: Patient Face Recognition UI - Rancangan Implementasi

**Tanggal**: 7 Desember 2025  
**Status**: 🚀 In Progress  
**Target**: Implementasi UI Face Recognition untuk Patient (Anak)

---

## 📋 Overview

Sprint E melanjutkan dari Sprint D (Family UI) dengan fokus pada implementasi UI untuk **patient (anak)** side. Patient akan dapat:

1. ✅ Membuka kamera untuk mengenali wajah
2. ✅ Melihat real-time face detection overlay
3. ✅ Capture foto dan dapatkan hasil recognition
4. ✅ Lihat informasi orang yang dikenali (nama, hubungan, bio)
5. ✅ Akses history recognition

---

## 🎯 Sprint Breakdown

### Sprint E.1: Analyze & Fix FaceRecognitionService ✅

**Status**: ✅ COMPLETED  
**Result**: `flutter analyze` → No issues found!

**Yang Sudah Ada**:

- ✅ Face detection dengan Google ML Kit (FREE, on-device)
- ✅ Image preprocessing untuk ML
- ✅ Mock embedding generation (temporary untuk testing UI)
- ✅ Face validation methods
- ✅ Crop & resize utilities

**Note**: Real TFLite GhostFaceNet model akan diintegrasikan di Phase 3B nanti. Untuk sekarang, mock embedding sudah cukup untuk testing UI flow.

---

### Sprint E.2: Create RecognizeFaceScreen (Patient)

**Durasi**: 3-4 jam  
**Lines of Code**: ~450 lines  
**Status**: 🔄 Next

#### File to Create:

**`lib/presentation/screens/patient/face_recognition/recognize_face_screen.dart`**

**Features**:

1. **Camera Preview dengan Overlay**

   - CameraController untuk akses kamera
   - Real-time face detection preview
   - Bounding box overlay di wajah yang terdeteksi
   - Auto-focus pada wajah

2. **UI Components**:

   - AppBar dengan back button
   - Camera preview full screen
   - Face detection overlay (custom painter)
   - Capture button (floating, bottom center)
   - Instructions text ("Arahkan kamera ke wajah")
   - Face count indicator ("1 wajah terdeteksi")

3. **State Management**:

   - Camera initialization state
   - Face detection state (real-time)
   - Capture loading state
   - Error handling state

4. **Flow**:
   ```
   1. Initialize camera (rear camera)
   2. Start real-time face detection on camera frames
   3. Show bounding box overlay untuk setiap wajah
   4. User tap "Kenali Wajah" button
   5. Capture frame → Generate embedding
   6. Query database untuk match
   7. Navigate to RecognitionResultScreen dengan result
   ```

**Key Components**:

```dart
class RecognizeFaceScreen extends ConsumerStatefulWidget {
  final String patientId;

  // State:
  // - CameraController _cameraController
  // - List<Face> _detectedFaces
  // - bool _isCameraInitialized
  // - bool _isProcessing

  // Methods:
  // - _initializeCamera()
  // - _startFaceDetection() // Real-time di background
  // - _onCapture() // Main action
  // - _processRecognition(File imageFile)
  // - _navigateToResult()

  // Widgets:
  // - _buildCameraPreview()
  // - _buildFaceOverlay() // CustomPaint
  // - _buildCaptureButton()
  // - _buildInstructions()
}
```

**Dependencies** (sudah ada di pubspec.yaml):

- `camera: ^0.11.0+2`
- `google_mlkit_face_detection: ^0.11.0`
- `flutter_riverpod: ^2.5.1`

---

### Sprint E.3: Create RecognitionResultScreen

**Durasi**: 2-3 jam  
**Lines of Code**: ~350 lines  
**Status**: ⏳ Pending

#### File to Create:

**`lib/presentation/screens/patient/face_recognition/recognition_result_screen.dart`**

**Features**:

1. **Display Hasil Recognition**

   - Photo yang di-capture (preview)
   - Recognized person info (jika match found)
   - "Not recognized" state (jika tidak ada match)

2. **Recognized State** (similarity > 0.85):

   ```
   ┌─────────────────────────────────┐
   │      [Captured Photo]            │
   │                                   │
   │  ✅ Wajah Dikenali!               │
   │                                   │
   │  [Person Photo from DB]          │
   │  👤 Nama: Ibu Sarah              │
   │  💝 Hubungan: Ibu                │
   │  📝 Bio: Ibu yang selalu...      │
   │                                   │
   │  📊 Similarity: 92%              │
   │  🕐 Dikenali pada: 14:30 WIB     │
   │                                   │
   │  [Kenali Lagi]  [Lihat Semua]   │
   └─────────────────────────────────┘
   ```

3. **Not Recognized State** (similarity < 0.85):

   ```
   ┌─────────────────────────────────┐
   │      [Captured Photo]            │
   │                                   │
   │  ❌ Wajah Tidak Dikenali          │
   │                                   │
   │  Maaf, wajah ini tidak ada       │
   │  di database orang dikenal.      │
   │                                   │
   │  💡 Minta keluarga untuk         │
   │     menambahkan orang ini        │
   │                                   │
   │  [Coba Lagi]  [Lihat Semua]     │
   └─────────────────────────────────┘
   ```

4. **Action Buttons**:
   - "Kenali Lagi" / "Coba Lagi" → Back to camera
   - "Lihat Semua Orang Dikenal" → Navigate to list (family feature, redirect to info)

**Key Components**:

```dart
class RecognitionResultScreen extends ConsumerWidget {
  final File capturedImage;
  final KnownPerson? recognizedPerson;
  final double? similarity;
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: 'Hasil Pengenalan'),
      body: _buildResultContent(),
    );
  }

  Widget _buildResultContent() {
    if (recognizedPerson != null) {
      return _buildRecognizedState();
    } else {
      return _buildNotRecognizedState();
    }
  }

  Widget _buildRecognizedState() {
    // Show person info with photo, name, relationship, bio
  }

  Widget _buildNotRecognizedState() {
    // Show "not found" message with suggestions
  }
}
```

---

### Sprint E.4: Integrate with PatientHomeScreen

**Durasi**: 30 menit  
**Lines of Code**: ~20 lines  
**Status**: ⏳ Pending

#### Changes Needed:

**File**: `lib/presentation/screens/patient/patient_home_screen.dart`

**Before**:

```dart
final List<Widget> _screens = [
  const ActivityListScreen(),
  const Center(
    child: Text('Kenali Wajah\n(Coming Soon)', textAlign: TextAlign.center),
  ),
  const ProfileScreen(),
];
```

**After**:

```dart
final List<Widget> _screens = [
  const ActivityListScreen(),
  RecognizeFaceScreen(patientId: userId), // ✅ NEW
  const ProfileScreen(),
];
```

**Dependencies to Import**:

```dart
import 'package:project_aivia/presentation/screens/patient/face_recognition/recognize_face_screen.dart';
```

---

### Sprint E.5: Add AppStrings & Test

**Durasi**: 30 menit  
**Lines of Code**: ~30 lines  
**Status**: ⏳ Pending

#### File: `lib/core/constants/app_strings.dart`

**Add New Strings**:

```dart
// Face Recognition - Patient
static const String recognizeFaceTitle = 'Kenali Wajah';
static const String recognizeFaceInstruction = 'Arahkan kamera ke wajah seseorang';
static const String faceDetected = 'wajah terdeteksi';
static const String noFaceDetected = 'Tidak ada wajah terdeteksi';
static const String captureButton = 'Kenali Wajah';
static const String processing = 'Memproses...';

// Recognition Result
static const String recognitionResultTitle = 'Hasil Pengenalan';
static const String faceRecognized = 'Wajah Dikenali!';
static const String faceNotRecognized = 'Wajah Tidak Dikenali';
static const String recognizedPerson = 'Ini adalah';
static const String similarity = 'Tingkat Kepercayaan';
static const String recognizedAt = 'Dikenali pada';
static const String tryAgain = 'Coba Lagi';
static const String recognizeAgain = 'Kenali Lagi';
static const String viewAllKnownPersons = 'Lihat Semua Orang Dikenal';
static const String notRecognizedMessage =
    'Maaf, wajah ini tidak ada dalam database orang dikenal.';
static const String notRecognizedSuggestion =
    'Minta keluarga untuk menambahkan orang ini ke dalam database.';

// Camera Errors
static const String cameraPermissionDenied =
    'Izin kamera ditolak. Aktifkan di pengaturan.';
static const String cameraInitError =
    'Gagal menginisialisasi kamera. Silakan coba lagi.';
static const String noCameraAvailable =
    'Tidak ada kamera tersedia di perangkat ini.';
```

**Testing**:

```bash
flutter analyze
# Target: 0 errors
```

---

## 📊 Architecture Diagram

### Patient Face Recognition Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     PATIENT USER (Anak)                      │
│                                                               │
│  1. Tap "Kenali Wajah" di bottom nav                        │
│     ↓                                                        │
│  2. RecognizeFaceScreen opens                               │
│     - Request camera permission                              │
│     - Initialize CameraController                            │
│     - Start real-time face detection                         │
│     ↓                                                        │
│  3. Camera preview dengan overlay                            │
│     - Show bounding box pada wajah terdeteksi               │
│     - Face count indicator                                   │
│     ↓                                                        │
│  4. User tap "Kenali Wajah" button                          │
│     ↓                                                        │
│  5. Capture frame & Process:                                │
│     - Take picture (CameraController.takePicture())         │
│     - FaceRecognitionService.generateEmbedding()            │
│     - KnownPersonRepository.findKnownPersonByEmbedding()    │
│     ↓                                                        │
│  6. Database Query (PostgreSQL + pgvector):                 │
│     SELECT * FROM known_persons                             │
│     WHERE owner_id = patient_id                             │
│     ORDER BY face_embedding <=> query_embedding             │
│     LIMIT 1;                                                 │
│     ↓                                                        │
│  7. Check similarity score:                                 │
│     IF similarity > 0.85:                                   │
│       ✅ RECOGNIZED                                          │
│       - Save to face_recognition_logs                       │
│       - Trigger update_known_person_last_seen()             │
│       - Show RecognitionResultScreen (success)              │
│     ELSE:                                                    │
│       ❌ NOT RECOGNIZED                                      │
│       - Save to logs (recognized_person_id = NULL)          │
│       - Show RecognitionResultScreen (not found)            │
│     ↓                                                        │
│  8. RecognitionResultScreen:                                │
│     - Display captured photo                                │
│     - Show person info OR not found message                 │
│     - Action buttons (try again, view all)                  │
└─────────────────────────────────────────────────────────────┘
```

### State Management Flow

```
RecognizeFaceScreen
    ↓
    ├─ Uses: CameraController (camera package)
    ├─ Uses: FaceDetector (ML Kit - on-device)
    ├─ Uses: faceRecognitionProvider (Riverpod)
    │   ↓
    │   └─ FaceRecognitionNotifier
    │       ├─ recognizeFace(File image, String patientId)
    │       │   ↓
    │       │   ├─ FaceRecognitionService.generateEmbedding()
    │       │   └─ KnownPersonRepository.findKnownPersonByEmbedding()
    │       │
    │       └─ logRecognition(...)
    │           └─ KnownPersonRepository.logRecognition()
    │
    └─ Navigate to RecognitionResultScreen
        ↓
        Display result based on KnownPerson? and similarity
```

---

## 🎨 UI/UX Design Principles

### 1. Accessibility untuk Pasien Alzheimer

**Font Sizes**:

- Title: 28sp (extra large)
- Instructions: 20sp (large)
- Body text: 18sp (readable)
- Button text: 18sp (clear)

**Colors**:

- Success (recognized): AppColors.success (hijau lembut)
- Error (not found): AppColors.warning (orange lembut, NOT red untuk tidak menakutkan)
- Primary actions: AppColors.primary (biru menenangkan)

**Touch Targets**:

- Capture button: 72x72dp (extra large, easy to tap)
- Action buttons: 56x56dp minimum
- Spacing: 24dp minimum antar elemen

**Feedback**:

- Haptic feedback saat capture
- Loading indicator saat processing
- Success/error animations (subtle, tidak overwhelming)

### 2. Camera UI Best Practices

**Camera Preview**:

- Full screen mode untuk fokus maksimal
- Auto-exposure & auto-focus enabled
- Real-time face detection overlay (non-intrusive)

**Capture Button**:

- Bottom center position (mudah dijangkau)
- Large circular button dengan icon
- Disabled state saat no face detected
- Loading state saat processing

**Face Overlay**:

- Green bounding box untuk detected face
- Smooth animations (60 FPS)
- Face count badge di corner

---

## 🔧 Technical Implementation Details

### Camera Setup

```dart
// Camera initialization dengan error handling
Future<void> _initializeCamera() async {
  try {
    // Request permission
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      _showError('Izin kamera diperlukan');
      return;
    }

    // Get available cameras
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      _showError('Tidak ada kamera tersedia');
      return;
    }

    // Use rear camera (index 0)
    _cameraController = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _cameraController!.initialize();

    // Start real-time detection
    _startFaceDetection();

    setState(() => _isCameraInitialized = true);
  } catch (e) {
    _showError('Gagal menginisialisasi kamera: $e');
  }
}
```

### Real-Time Face Detection

```dart
// Process camera frames untuk face detection
void _startFaceDetection() {
  _cameraController!.startImageStream((CameraImage image) async {
    if (_isDetecting) return; // Skip jika masih processing
    _isDetecting = true;

    try {
      final faces = await ref.read(faceRecognitionServiceProvider)
        .detectFacesInFrame(image);

      setState(() => _detectedFaces = faces);
    } catch (e) {
      debugPrint('Face detection error: $e');
    } finally {
      _isDetecting = false;
    }
  });
}
```

### Face Recognition Process

```dart
Future<void> _onCapture() async {
  if (_detectedFaces.isEmpty) {
    _showError('Tidak ada wajah terdeteksi');
    return;
  }

  setState(() => _isProcessing = true);

  try {
    // 1. Stop image stream
    await _cameraController!.stopImageStream();

    // 2. Capture photo
    final XFile photo = await _cameraController!.takePicture();
    final File imageFile = File(photo.path);

    // 3. Process recognition
    final result = await ref.read(faceRecognitionProvider.notifier)
      .recognizeFace(imageFile, widget.patientId);

    // 4. Navigate to result
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecognitionResultScreen(
            capturedImage: imageFile,
            recognizedPerson: result.person,
            similarity: result.similarity,
            patientId: widget.patientId,
          ),
        ),
      );
    }
  } catch (e) {
    _showError('Gagal memproses: $e');
  } finally {
    setState(() => _isProcessing = false);
    // Restart detection
    _startFaceDetection();
  }
}
```

---

## ✅ Acceptance Criteria

### Sprint E.2: RecognizeFaceScreen

- [x] Camera permission request flow
- [x] Camera preview full screen
- [x] Real-time face detection dengan overlay
- [x] Face count indicator
- [x] Capture button (enabled only when face detected)
- [x] Loading state during processing
- [x] Error handling (no camera, permission denied, etc.)
- [x] Navigate to result screen dengan data

### Sprint E.3: RecognitionResultScreen

- [x] Display captured photo
- [x] Recognized state: Show person info (photo, name, relationship, bio)
- [x] Not recognized state: Show helpful message
- [x] Similarity score display (untuk recognized)
- [x] Timestamp display
- [x] Action buttons (try again, view all)
- [x] Smooth animations

### Sprint E.4: Integration

- [x] PatientHomeScreen uses RecognizeFaceScreen
- [x] Bottom nav navigation works
- [x] User ID passed correctly
- [x] No breaking changes to existing screens

### Sprint E.5: Testing

- [x] `flutter analyze` → 0 errors
- [x] All AppStrings defined
- [x] Code quality: readable, commented, follows conventions
- [x] Error handling comprehensive

---

## 📝 Testing Checklist

### Manual Testing Flow

1. **Camera Access**:

   - [ ] First launch: Permission dialog appears
   - [ ] Permission granted: Camera preview shows
   - [ ] Permission denied: Error message + settings link

2. **Face Detection**:

   - [ ] Point camera at face: Green box appears
   - [ ] Multiple faces: Multiple boxes appear
   - [ ] No face: "Tidak ada wajah terdeteksi"
   - [ ] Face count updates real-time

3. **Capture & Recognition**:

   - [ ] Tap capture: Processing indicator shows
   - [ ] Known person: RecognitionResultScreen dengan info
   - [ ] Unknown person: "Not recognized" message
   - [ ] Error handling: Appropriate error messages

4. **Result Screen**:

   - [ ] Photo displays correctly
   - [ ] Person info readable (large fonts)
   - [ ] Similarity percentage shown
   - [ ] Buttons work (try again, view all)

5. **Navigation**:
   - [ ] Bottom nav to RecognizeFace works
   - [ ] Back from result returns to camera
   - [ ] Back from camera returns to home

### Edge Cases

- [ ] Camera already in use by another app
- [ ] Low light conditions
- [ ] Face partially visible
- [ ] Multiple faces in frame
- [ ] No internet (should still work - on-device ML)
- [ ] Database empty (no known persons)

---

## 🚀 Deployment Steps

1. **Create RecognizeFaceScreen**

   ```bash
   flutter analyze lib/presentation/screens/patient/face_recognition/recognize_face_screen.dart
   ```

2. **Create RecognitionResultScreen**

   ```bash
   flutter analyze lib/presentation/screens/patient/face_recognition/recognition_result_screen.dart
   ```

3. **Update PatientHomeScreen**

   ```bash
   flutter analyze lib/presentation/screens/patient/patient_home_screen.dart
   ```

4. **Update AppStrings**

   ```bash
   flutter analyze lib/core/constants/app_strings.dart
   ```

5. **Final Check**
   ```bash
   flutter analyze
   # Target: 0 errors
   ```

---

## 📈 Success Metrics

- ✅ `flutter analyze` → 0 errors
- ✅ Code coverage: 100% UI screens created
- ✅ User flow: Seamless dari tap nav → capture → result
- ✅ Performance: Camera FPS > 30, Face detection < 100ms per frame
- ✅ Accessibility: Font sizes, colors, touch targets compliant
- ✅ Error handling: All edge cases covered

---

## 🎯 Next Steps After Sprint E

### Phase 3B: TFLite Model Integration (Future)

Saat ini Sprint E menggunakan **mock embedding** dari FaceRecognitionService. Untuk production:

1. Download GhostFaceNet model (~5MB)
2. Add to `assets/ml_models/ghostfacenet.tflite`
3. Update `FaceRecognitionService.generateEmbedding()`:

   - Replace mock with real TFLite inference
   - Use `tflite_flutter` package
   - Generate real 512-dim embeddings

4. Test accuracy:
   - Add same person multiple times (different photos)
   - Verify similarity scores > 0.85
   - Test false positives/negatives

**Cost**: Still **$0** (on-device inference)

---

## 📚 References

- [Flutter Camera Plugin](https://pub.dev/packages/camera)
- [Google ML Kit Face Detection](https://pub.dev/packages/google_mlkit_face_detection)
- [TFLite Flutter](https://pub.dev/packages/tflite_flutter)
- [GhostFaceNet Paper](https://arxiv.org/abs/2102.04834)
- [pgvector Documentation](https://github.com/pgvector/pgvector)

---

**Last Updated**: 7 Desember 2025  
**Author**: Development Team  
**Status**: 🚀 Ready for Implementation

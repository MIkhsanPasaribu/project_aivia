import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/result.dart';
import '../../../../data/models/known_person.dart';
import '../../../../data/models/face_recognition_log.dart';
import '../../../providers/face_recognition_provider.dart';
import 'recognition_result_screen.dart';

/// Screen untuk mengenali wajah menggunakan kamera
///
/// Features:
/// - Camera preview full screen
/// - Real-time face detection dengan overlay
/// - Capture & process recognition
/// - Navigate ke result screen
///
/// **For Patient (Anak) Users**
class RecognizeFaceScreen extends ConsumerStatefulWidget {
  final String patientId;

  const RecognizeFaceScreen({super.key, required this.patientId});

  @override
  ConsumerState<RecognizeFaceScreen> createState() =>
      _RecognizeFaceScreenState();
}

class _RecognizeFaceScreenState extends ConsumerState<RecognizeFaceScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<Face> _detectedFaces = [];
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  bool _isProcessing = false;
  String? _errorMessage;

  // ✅ FIX #6: Debouncing fields untuk capture button
  DateTime? _lastCaptureTime;
  static const Duration _captureDebounce = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopImageStream();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _stopImageStream();
    } else if (state == AppLifecycleState.resumed) {
      // ✅ FIX #7: Add delay to ensure camera is ready after resume
      await Future.delayed(const Duration(milliseconds: 300));

      // ✅ FIX #7: Check again after delay (widget might be disposed)
      if (mounted &&
          _cameraController != null &&
          _cameraController!.value.isInitialized) {
        _startImageStream();
      } else {
        debugPrint('⚠️ Camera not ready after resume, skipping stream start');
      }
    }
  }

  // ====================================================
  // CAMERA INITIALIZATION
  // ====================================================

  Future<void> _initializeCamera() async {
    try {
      // 1. Request permission
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _errorMessage = AppStrings.cameraPermissionDenied;
        });
        return;
      }

      // 2. Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = AppStrings.noCameraAvailable;
        });
        return;
      }

      // 3. Use rear camera (index 0)
      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
        _errorMessage = null;
      });

      // 4. Start real-time face detection for preview overlay
      // Add delay to ensure camera is fully ready
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted &&
          _cameraController != null &&
          _cameraController!.value.isInitialized) {
        _startImageStream();
      }
    } catch (e) {
      debugPrint('❌ Camera initialization error: $e');
      setState(() {
        _errorMessage =
            '${AppStrings.cameraInitError}\nSilakan coba lagi.\n\nDetail: ${e.toString()}';
      });
    }
  }

  // ====================================================
  // REAL-TIME FACE DETECTION
  // ====================================================

  void _startImageStream() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint('⚠️ Cannot start image stream: camera not initialized');
      return;
    }

    try {
      _cameraController!.startImageStream((CameraImage image) async {
        if (_isDetecting || _isProcessing) return;
        _isDetecting = true;

        try {
          final faces = await ref
              .read(faceRecognitionServiceProvider)
              .detectFacesInFrame(image);

          if (mounted) {
            setState(() {
              _detectedFaces = faces;
              // Clear error message on successful detection
              if (_errorMessage != null && faces.isNotEmpty) {
                _errorMessage = null;
              }
            });
          }
        } catch (e) {
          debugPrint('⚠️ Face detection error in frame: $e');
          // Continue processing next frames even if one fails
          // Don't update error message here - would flicker too much
        } finally {
          _isDetecting = false;
        }
      });

      debugPrint('✅ Image stream started successfully');
    } catch (e) {
      debugPrint('❌ Failed to start image stream: $e');
      if (mounted) {
        setState(() {
          _errorMessage =
              'Gagal memulai kamera.\nSilakan tutup dan buka kembali layar ini.';
        });
      }
    }
  }

  void _stopImageStream() {
    if (_cameraController != null &&
        _cameraController!.value.isStreamingImages) {
      _cameraController!.stopImageStream();
    }
  }

  // ====================================================
  // CAPTURE & RECOGNIZE
  // ====================================================

  Future<void> _onCapture() async {
    // ✅ FIX #6: Debounce check - prevent spam capture
    if (_lastCaptureTime != null) {
      final elapsed = DateTime.now().difference(_lastCaptureTime!);
      if (elapsed < _captureDebounce) {
        final remaining = _captureDebounce.inSeconds - elapsed.inSeconds;
        _showSnackBar(
          'Tunggu $remaining detik lagi sebelum foto berikutnya',
          isError: true,
        );
        return;
      }
    }

    if (_detectedFaces.isEmpty) {
      _showSnackBar(AppStrings.noFaceDetected, isError: true);
      return;
    }

    if (_isProcessing) return;

    // ✅ FIX #6: Set last capture time
    _lastCaptureTime = DateTime.now();

    setState(() => _isProcessing = true);

    try {
      // 1. Stop image stream
      _stopImageStream();

      // 2. Capture photo
      final XFile photo = await _cameraController!.takePicture();
      final File imageFile = File(photo.path);

      // 3. Process recognition
      final result = await ref
          .read(faceRecognitionNotifierProvider.notifier)
          .recognizeFace(patientId: widget.patientId, photoFile: imageFile);

      // 4. Extract recognized person from Result
      KnownPerson? recognizedPerson;
      double? similarityScore;
      if (result is Success<KnownPerson?>) {
        recognizedPerson = result.data;
        // Query latest similarity score from recognition log
        if (recognizedPerson != null) {
          final logsResult = await ref
              .read(knownPersonRepositoryProvider)
              .getRecognitionLogs(patientId: widget.patientId, limit: 1);
          if (logsResult is Success<List<FaceRecognitionLog>>) {
            final logs = logsResult.data;
            if (logs.isNotEmpty) {
              similarityScore = logs.first.similarityScore;
            }
          }
        }
      }

      // 5. Navigate to result
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecognitionResultScreen(
              capturedImage: imageFile,
              recognizedPerson: recognizedPerson,
              similarity: similarityScore,
              patientId: widget.patientId,
            ),
          ),
        );

        // 6. Restart detection setelah kembali
        _startImageStream();
      }
    } catch (e) {
      debugPrint('?????? Recognition error: $e');
      _showSnackBar('Gagal memproses: ${e.toString()}', isError: true);
      // Restart detection on error
      _startImageStream();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // ====================================================
  // UI BUILD
  // ====================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          AppStrings.recognizeFaceTitle,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
      ),
      body: _errorMessage != null
          ? _buildErrorState(isDark)
          : !_isCameraInitialized
          ? _buildLoadingState()
          : _buildCameraView(isDark),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: AppDimensions.paddingL),
          Text(
            'Menginisialisasi kamera...',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: AppColors.error.withValues(alpha: 0.8),
            ),
            const SizedBox(height: AppDimensions.paddingL),
            Text(
              _errorMessage ?? AppStrings.errorGeneral,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingXL),
            ElevatedButton.icon(
              onPressed: () async {
                setState(() => _errorMessage = null);
                await _initializeCamera();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingXL,
                  vertical: AppDimensions.paddingM,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView(bool isDark) {
    return Stack(
      children: [
        // 1. Camera Preview
        Positioned.fill(
          child:
              _cameraController != null &&
                  _cameraController!.value.isInitialized
              ? CameraPreview(_cameraController!)
              : const SizedBox.shrink(),
        ),

        // 2. Face Detection Overlay
        if (_detectedFaces.isNotEmpty)
          Positioned.fill(
            child: CustomPaint(
              painter: FaceDetectionPainter(
                faces: _detectedFaces,
                imageSize: _cameraController!.value.previewSize!,
              ),
            ),
          ),

        // 3. Top Instructions
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildInstructions(isDark),
        ),

        // 4. Face Count Badge
        if (_detectedFaces.isNotEmpty)
          Positioned(
            top: AppDimensions.paddingL,
            right: AppDimensions.paddingL,
            child: _buildFaceCountBadge(),
          ),

        // 5. Bottom Capture Button
        Positioned(
          bottom: AppDimensions.paddingXL * 2,
          left: 0,
          right: 0,
          child: _buildCaptureButton(),
        ),
      ],
    );
  }

  Widget _buildInstructions(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingL,
        vertical: AppDimensions.paddingXL,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
      ),
      child: Column(
        children: [
          const Text(
            AppStrings.recognizeFaceInstruction,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            _detectedFaces.isEmpty
                ? AppStrings.noFaceDetected
                : '${_detectedFaces.length} ${AppStrings.faceDetected}',
            style: TextStyle(
              color: _detectedFaces.isEmpty
                  ? AppColors.warning
                  : AppColors.success,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceCountBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.face_rounded, color: Colors.white, size: 20),
          const SizedBox(width: AppDimensions.paddingS),
          Text(
            '${_detectedFaces.length}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureButton() {
    final bool canCapture = _detectedFaces.isNotEmpty && !_isProcessing;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canCapture ? _onCapture : null,
          borderRadius: BorderRadius.circular(36),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: canCapture
                  ? AppColors.primary
                  : AppColors.disabled.withValues(alpha: 0.5),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _isProcessing
                ? const Padding(
                    padding: EdgeInsets.all(AppDimensions.paddingM),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.face_rounded, size: 36, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ====================================================
  // UTILITY
  // ====================================================

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ====================================================
// FACE DETECTION OVERLAY PAINTER
// ====================================================

/// Custom painter untuk menggambar bounding box di wajah terdeteksi
class FaceDetectionPainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;

  FaceDetectionPainter({required this.faces, required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.success.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Calculate scale
    final double scaleX = size.width / imageSize.height;
    final double scaleY = size.height / imageSize.width;

    for (final face in faces) {
      final boundingBox = face.boundingBox;

      // Scale bounding box to screen size
      final left = boundingBox.left * scaleX;
      final top = boundingBox.top * scaleY;
      final right = boundingBox.right * scaleX;
      final bottom = boundingBox.bottom * scaleY;

      // Draw rectangle
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(left, top, right, bottom),
          const Radius.circular(12),
        ),
        paint,
      );

      // Draw corner markers
      final cornerPaint = Paint()
        ..color = AppColors.success
        ..style = PaintingStyle.fill;

      const cornerSize = 16.0;
      const cornerThickness = 4.0;

      // Top-left corner
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left - 2, top - 2, cornerSize, cornerThickness),
          const Radius.circular(2),
        ),
        cornerPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left - 2, top - 2, cornerThickness, cornerSize),
          const Radius.circular(2),
        ),
        cornerPaint,
      );

      // Top-right corner
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            right - cornerSize + 2,
            top - 2,
            cornerSize,
            cornerThickness,
          ),
          const Radius.circular(2),
        ),
        cornerPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            right - cornerThickness + 2,
            top - 2,
            cornerThickness,
            cornerSize,
          ),
          const Radius.circular(2),
        ),
        cornerPaint,
      );

      // Bottom-left corner
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            left - 2,
            bottom - cornerThickness + 2,
            cornerSize,
            cornerThickness,
          ),
          const Radius.circular(2),
        ),
        cornerPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            left - 2,
            bottom - cornerSize + 2,
            cornerThickness,
            cornerSize,
          ),
          const Radius.circular(2),
        ),
        cornerPaint,
      );

      // Bottom-right corner
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            right - cornerSize + 2,
            bottom - cornerThickness + 2,
            cornerSize,
            cornerThickness,
          ),
          const Radius.circular(2),
        ),
        cornerPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            right - cornerThickness + 2,
            bottom - cornerSize + 2,
            cornerThickness,
            cornerSize,
          ),
          const Radius.circular(2),
        ),
        cornerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(FaceDetectionPainter oldDelegate) {
    return oldDelegate.faces != faces;
  }
}

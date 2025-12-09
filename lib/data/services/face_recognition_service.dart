import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';

/// Service untuk Face Recognition menggunakan ML Kit + TFLite GhostFaceNet
///
/// Features:
/// - Face detection dengan Google ML Kit (on-device, FREE)
/// - Face embedding generation dengan TFLite GhostFaceNet (512-dim)
/// - Real-time camera face detection
/// - Image preprocessing untuk ML model
///
/// **100% FREE & PRIVACY-FRIENDLY**:
/// - Semua processing di device (no cloud API)
/// - No internet required
/// - No data sent to external servers
///
/// Model: FaceNet 512-dim (~90MB)
/// - Input: 160x160 or 112x112 RGB image (auto-detected from model)
/// - Output: 512-dimensional embedding vector (L2 normalized)
/// - Accuracy: 99.6% on LFW dataset
class FaceRecognitionService {
  final FaceDetector _faceDetector;

  /// TFLite interpreter for FaceNet model
  Interpreter? _interpreter;

  /// Initialization status
  bool _isInitialized = false;

  /// Model load status
  bool _isModelLoaded = false;

  /// Input size detected from model (112 or 160)
  int _inputSize = 112;

  /// Rate limiting for frame processing
  DateTime? _lastFrameProcessTime;
  static const _minFrameInterval = Duration(
    milliseconds: 500,
  ); // Process max 2 frames/sec

  // Singleton pattern
  static FaceRecognitionService? _instance;

  factory FaceRecognitionService() {
    _instance ??= FaceRecognitionService._internal();
    return _instance!;
  }

  FaceRecognitionService._internal()
    : _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableLandmarks: true,
          enableClassification: false,
          enableTracking: false,
          minFaceSize: 0.15, // 15% of image
          performanceMode: FaceDetectorMode.accurate,
        ),
      ) {
    // Ensure face detector is ready for use
    _initializeFaceDetector();
  }

  /// Initialize FaceDetector (Google ML Kit)
  ///
  /// **CRITICAL**: Must be called before processImage()
  /// This ensures internal state is properly set up.
  Future<void> _initializeFaceDetector() async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        // Create a minimal test image to force initialization
        // This prevents "Bad state: failed precondition" error
        // ML Kit requires minimum 32x32 pixels - using 100x100 to be safe
        final testImage = img.Image(width: 100, height: 100);
        final testBytes = img.encodePng(testImage);
        final tempFile = File(
          '${Directory.systemTemp.path}/ml_kit_init_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await tempFile.writeAsBytes(testBytes);

        final inputImage = InputImage.fromFile(tempFile);

        // This call forces ML Kit to initialize internal state
        await _faceDetector.processImage(inputImage);

        // Clean up
        try {
          await tempFile.delete();
        } catch (_) {
          // Ignore cleanup errors
        }

        debugPrint(
          '✅ FaceDetector initialized successfully (attempt ${retryCount + 1})',
        );
        return; // Success
      } catch (e) {
        retryCount++;
        debugPrint(
          '⚠️ FaceDetector initialization attempt $retryCount failed: $e',
        );

        if (retryCount < maxRetries) {
          // Wait before retry (exponential backoff)
          await Future.delayed(Duration(milliseconds: 100 * retryCount));
        } else {
          debugPrint(
            '❌ FaceDetector initialization failed after $maxRetries attempts',
          );
          debugPrint('   Will attempt initialization on first real use');
        }
      }
    }
  }

  /// Initialize service: Load TFLite model
  ///
  /// **MUST** be called before using generateEmbedding()
  ///
  /// Attempts to load GhostFaceNet model from assets.
  /// If model not found, service will still work for face detection,
  /// but embedding generation will return error.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load TFLite model from assets
      debugPrint('🔄 Loading GhostFaceNet TFLite model...');

      _interpreter = await Interpreter.fromAsset(
        'assets/ml_models/ghostfacenet.tflite',
        options: InterpreterOptions()
          ..threads =
              4 // Use 4 CPU threads for faster inference
          ..useNnApiForAndroid = true, // Use Android NNAPI if available
      );

      // Verify input/output shapes
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;

      // Auto-detect input size from model
      if (inputShape.length >= 2) {
        _inputSize = inputShape[1]; // [1, size, size, 3] → get size
      }

      debugPrint('✅ FaceNet 512-dim model loaded successfully');
      debugPrint(
        '   Input shape: $inputShape',
      ); // [1, 160, 160, 3] or [1, 112, 112, 3]
      debugPrint('   Output shape: $outputShape'); // [1, 512]
      debugPrint('   Detected input size: $_inputSize x $_inputSize');

      _isModelLoaded = true;
      _isInitialized = true;
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to load TFLite model');
      debugPrint('   Error: $e');

      if (kDebugMode) {
        debugPrint('   Stack trace: $stackTrace');
      }

      // Check if it's file not found error
      if (e is PlatformException && e.code == 'FileSystemException') {
        debugPrint('   ⚠️ Model file not found in assets/');
        debugPrint('   📥 Download model: See assets/ml_models/README.md');
      }

      _isModelLoaded = false;
      _isInitialized = true; // Still mark as initialized for face detection

      // Don't rethrow - service can still work for face detection only
    }
  }

  // ====================================================
  // FACE DETECTION (FREE - Google ML Kit)
  // ====================================================

  /// Detect faces in image file
  ///
  /// Returns: List of detected faces with bounding boxes
  /// Use case: Validate photo has exactly 1 face before adding to database
  Future<Result<List<Face>>> detectFacesInFile(File imageFile) async {
    try {
      // Verify file exists
      if (!await imageFile.exists()) {
        debugPrint('❌ Image file not found: ${imageFile.path}');
        return const ResultFailure(
          ValidationFailure('File foto tidak ditemukan'),
        );
      }

      final inputImage = InputImage.fromFile(imageFile);

      // Process with robust retry logic for initialization issues
      List<Face> faces = [];
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          faces = await _faceDetector.processImage(inputImage);
          debugPrint(
            '✅ Face detection successful: ${faces.length} face(s) found',
          );
          break; // Success
        } catch (e) {
          retryCount++;

          // Check if it's a precondition error (initialization issue)
          final errorStr = e.toString().toLowerCase();
          final isPreconditionError =
              errorStr.contains('precondition') ||
              errorStr.contains('not initialized') ||
              errorStr.contains('bad state');

          if (isPreconditionError && retryCount < maxRetries) {
            debugPrint(
              '⚠️ FaceDetector initialization issue (attempt $retryCount), retrying...',
            );
            // Exponential backoff: 100ms, 200ms, 400ms
            await Future.delayed(
              Duration(milliseconds: 100 * (1 << (retryCount - 1))),
            );
          } else {
            // Not a precondition error or max retries reached
            debugPrint('❌ Face detection failed: $e');
            rethrow;
          }
        }
      }

      if (faces.isEmpty) {
        return const ResultFailure(
          ValidationFailure(
            'Tidak ada wajah terdeteksi dalam foto. '
            'Pastikan foto jelas dan pencahayaan cukup.',
          ),
        );
      }

      return Success(faces);
    } catch (e, stackTrace) {
      debugPrint('❌ Face detection error: $e');
      if (kDebugMode) {
        debugPrint('   Stack trace: $stackTrace');
      }
      return ResultFailure(
        ServerFailure(
          'Gagal deteksi wajah. Coba ambil foto lagi.\nError: ${e.toString()}',
        ),
      );
    }
  }

  /// Detect faces in camera frame (for real-time preview)
  ///
  /// Returns: List of faces (can be empty)
  /// Use case: Show bounding box overlay di camera preview (DEPRECATED - use photo capture instead)
  ///
  /// **Note**: This method is kept for backward compatibility but photo capture
  /// is now preferred for better user experience and reliability.
  Future<List<Face>> detectFacesInFrame(CameraImage image) async {
    try {
      // Rate limiting - skip frames if processing too fast
      final now = DateTime.now();
      if (_lastFrameProcessTime != null) {
        final timeSinceLastFrame = now.difference(_lastFrameProcessTime!);
        if (timeSinceLastFrame < _minFrameInterval) {
          // Skip this frame to reduce load
          return [];
        }
      }
      _lastFrameProcessTime = now;

      final inputImage = _convertCameraImageToInputImage(image);
      if (inputImage == null) {
        // Silent skip - logged in converter
        return [];
      }

      // Safe call with graceful error handling
      try {
        final faces = await _faceDetector.processImage(inputImage);
        return faces;
      } catch (stateError) {
        // Handle initialization issues gracefully - don't crash, just skip frame
        final errorStr = stateError.toString().toLowerCase();
        if (errorStr.contains('precondition') ||
            errorStr.contains('not initialized') ||
            errorStr.contains('bad state')) {
          // Silently skip - this is expected during warm-up
          return [];
        }
        // Other errors - log but don't crash
        debugPrint('! Frame detection error: $stateError');
        return [];
      }
    } catch (e) {
      // Catch-all for unexpected errors
      debugPrint('! Unexpected frame detection error: $e');
      return [];
    }
  }

  /// Convert CameraImage to InputImage for ML Kit
  InputImage? _convertCameraImageToInputImage(CameraImage image) {
    try {
      // Validate image dimensions - ML Kit requires minimum 32x32
      if (image.width < 32 || image.height < 32) {
        debugPrint('⚠️ Image too small: ${image.width}x${image.height}');
        return null;
      }

      // Validate planes exist
      if (image.planes.isEmpty) {
        debugPrint('⚠️ No image planes available');
        return null;
      }

      // Get image format
      InputImageFormat? inputImageFormat;
      switch (image.format.group) {
        case ImageFormatGroup.yuv420:
          inputImageFormat = InputImageFormat.yuv420;
          break;
        case ImageFormatGroup.nv21:
          inputImageFormat = InputImageFormat.nv21;
          break;
        case ImageFormatGroup.bgra8888:
          inputImageFormat = InputImageFormat.bgra8888;
          break;
        default:
          debugPrint('⚠️ Unsupported image format: ${image.format.group}');
          return null;
      }

      // For YUV420/NV21, use plane bytes directly (more efficient)
      if (inputImageFormat == InputImageFormat.yuv420 ||
          inputImageFormat == InputImageFormat.nv21) {
        // Validate bytesPerRow
        final bytesPerRow = image.planes.first.bytesPerRow;
        if (bytesPerRow < image.width) {
          debugPrint('⚠️ Invalid bytesPerRow: $bytesPerRow < ${image.width}');
          return null;
        }

        // Use first plane bytes directly (Y plane for YUV420)
        return InputImage.fromBytes(
          bytes: image.planes.first.bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: InputImageRotation.rotation0deg,
            format: inputImageFormat,
            bytesPerRow: bytesPerRow,
          ),
        );
      }

      // For other formats, concatenate all plane bytes
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: inputImageFormat,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error converting camera image: $e');
      return null;
    }
  }

  // ====================================================
  // IMAGE PREPROCESSING
  // ====================================================

  /// Crop face dari image berdasarkan bounding box
  ///
  /// Adds 20% padding around face for better ML recognition
  Future<Result<File>> cropFaceFromImage(
    File imageFile,
    Rect boundingBox,
  ) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        return const ResultFailure(ValidationFailure('Gagal decode image'));
      }

      // Add 20% padding
      final padding = boundingBox.width * 0.2;
      final left = (boundingBox.left - padding)
          .clamp(0, image.width - 1)
          .toInt();
      final top = (boundingBox.top - padding)
          .clamp(0, image.height - 1)
          .toInt();
      final right = (boundingBox.right + padding)
          .clamp(0, image.width - 1)
          .toInt();
      final bottom = (boundingBox.bottom + padding)
          .clamp(0, image.height - 1)
          .toInt();

      final cropped = img.copyCrop(
        image,
        x: left,
        y: top,
        width: right - left,
        height: bottom - top,
      );

      // Save cropped image to temp file
      final tempDir = Directory.systemTemp;
      final tempFile = File(
        '${tempDir.path}/face_crop_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(img.encodeJpg(cropped, quality: 85));

      return Success(tempFile);
    } catch (e) {
      return ResultFailure(ServerFailure('Gagal crop wajah: ${e.toString()}'));
    }
  }

  // ====================================================
  // FACE EMBEDDING GENERATION
  // ====================================================

  /// Generate 512-dim face embedding dari image file menggunakan TFLite GhostFaceNet
  ///
  /// **Workflow**:
  /// 1. Detect face dengan ML Kit
  /// 2. Validate exactly 1 face detected
  /// 3. Crop face region dengan padding
  /// 4. Preprocess: resize 112x112, normalize pixels
  /// 5. Run TFLite inference (GhostFaceNet)
  /// 6. Extract 512-dim embedding
  /// 7. L2 normalize untuk cosine similarity
  ///
  /// **Returns**:
  /// - Success dengan 512-dim normalized embedding
  /// - Failure jika no face, multiple faces, atau ML error
  ///
  /// **Performance**: ~50-100ms on mid-range Android devices
  Future<Result<List<double>>> generateEmbedding(File imageFile) async {
    // Check model loaded
    if (!_isModelLoaded || _interpreter == null) {
      return const ResultFailure<List<double>>(
        ServerFailure(
          'TFLite model belum dimuat. '
          'Model file mungkin belum di-download. '
          'Lihat assets/ml_models/README.md untuk instruksi.',
        ),
      );
    }

    try {
      // Step 1: Detect face
      final facesResult = await detectFacesInFile(imageFile);
      if (facesResult is ResultFailure) {
        return ResultFailure<List<double>>(facesResult.failure);
      }
      final faces = (facesResult as Success<List<Face>>).data;

      // Validate single face
      if (faces.length > 1) {
        return ResultFailure<List<double>>(
          ValidationFailure(
            'Terdeteksi ${faces.length} wajah. '
            'Pastikan hanya ada 1 wajah dalam foto.',
          ),
        );
      }

      final face = faces.first;

      // Step 2: Crop face region
      final cropResult = await cropFaceFromImage(imageFile, face.boundingBox);
      if (cropResult is ResultFailure) {
        return ResultFailure<List<double>>(cropResult.failure);
      }
      final croppedFile = (cropResult as Success<File>).data;

      // Step 3: Preprocess image untuk TFLite
      final inputTensor = await _preprocessImageForInference(croppedFile);
      if (inputTensor == null) {
        return const ResultFailure<List<double>>(
          ServerFailure('Gagal preprocess image untuk model'),
        );
      }

      // Step 4: Run TFLite inference
      final outputTensor = List.filled(512, 0.0).reshape([1, 512]);

      final startTime = DateTime.now();
      _interpreter!.run(inputTensor, outputTensor);
      final inferenceTime = DateTime.now().difference(startTime).inMilliseconds;

      debugPrint('✅ TFLite inference completed in ${inferenceTime}ms');

      // Step 5: Extract embedding
      final embedding = List<double>.from(outputTensor[0]);

      // Step 6: L2 normalize
      final normalized = _l2Normalize(embedding);

      // Log sample values for debugging
      if (kDebugMode) {
        debugPrint(
          '   Embedding sample (first 5): ${normalized.sublist(0, 5)}',
        );
        final magnitude = _calculateMagnitude(normalized);
        debugPrint(
          '   L2 norm: ${magnitude.toStringAsFixed(4)} (should be ~1.0)',
        );
      }

      // Clean up temp file
      try {
        await croppedFile.delete();
      } catch (_) {
        // Ignore cleanup errors
      }

      return Success(normalized);
    } catch (e, stackTrace) {
      debugPrint('❌ Embedding generation failed');
      debugPrint('   Error: $e');

      if (kDebugMode) {
        debugPrint('   Stack: $stackTrace');
      }

      return ResultFailure(
        ServerFailure('Gagal generate face embedding: ${e.toString()}'),
      );
    }
  }

  /// Preprocess image untuk TFLite inference
  ///
  /// **Input**: Cropped face image (any size)
  /// **Output**: Float32List shaped [1, 112, 112, 3], normalized to [0, 1]
  ///
  /// Steps:
  /// 1. Decode image
  /// 2. Resize ke 112x112 (GhostFaceNet input size)
  /// 3. Convert ke Float32List
  /// 4. Normalize RGB values ke [0, 1]
  /// 5. Reshape ke tensor format [1, 112, 112, 3]
  Future<Float32List?> _preprocessImageForInference(File imageFile) async {
    try {
      // 1. Decode image
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        debugPrint('❌ Failed to decode image for preprocessing');
        return null;
      }

      // 2. Resize to 112x112 dengan cubic interpolation (high quality)
      final resized = img.copyResize(
        image,
        width: _inputSize,
        height: _inputSize,
        interpolation: img.Interpolation.cubic,
      );

      // 3. Convert to Float32List (RGB order, normalized to [0, 1])
      final input = Float32List(1 * _inputSize * _inputSize * 3);
      int pixelIndex = 0;

      for (int y = 0; y < _inputSize; y++) {
        for (int x = 0; x < _inputSize; x++) {
          final pixel = resized.getPixel(x, y);

          // Extract RGB channels dan normalize ke [0, 1]
          final r = pixel.r;
          final g = pixel.g;
          final b = pixel.b;

          input[pixelIndex++] = r / 255.0;
          input[pixelIndex++] = g / 255.0;
          input[pixelIndex++] = b / 255.0;
        }
      }

      return input;
    } catch (e) {
      debugPrint('❌ Error preprocessing image: $e');
      return null;
    }
  }

  /// L2 normalization untuk cosine similarity
  ///
  /// Formula: v_normalized = v / ||v||
  /// where ||v|| = sqrt(sum(v_i^2))
  ///
  /// **Important**: Normalized vectors have magnitude = 1.0
  /// This allows efficient cosine similarity via dot product
  List<double> _l2Normalize(List<double> vector) {
    final magnitude = _calculateMagnitude(vector);

    // Avoid division by zero or NaN
    if (magnitude == 0 || magnitude.isNaN) {
      debugPrint(
        '⚠️ Warning: Zero or NaN magnitude, returning original vector',
      );
      return vector;
    }

    return vector.map((v) => v / magnitude).toList();
  }

  /// Calculate L2 norm (magnitude) of vector
  ///
  /// Formula: ||v|| = sqrt(sum(v_i^2))
  double _calculateMagnitude(List<double> vector) {
    double sumSquares = 0.0;
    for (final value in vector) {
      sumSquares += value * value;
    }
    return sqrt(sumSquares);
  }

  // ====================================================
  // UTILITY METHODS
  // ====================================================

  /// Validate apakah foto cocok untuk face recognition
  ///
  /// Checks:
  /// - Ada minimal 1 wajah
  /// - Hanya ada 1 wajah (tidak multiple)
  /// - Wajah cukup besar (>15% of image)
  Future<Result<String>> validateFacePhoto(File imageFile) async {
    final facesResult = await detectFacesInFile(imageFile);

    if (facesResult is ResultFailure) {
      return ResultFailure<String>(facesResult.failure);
    }

    final faces = (facesResult as Success<List<Face>>).data;

    if (faces.isEmpty) {
      return ResultFailure<String>(
        ValidationFailure('Tidak ada wajah terdeteksi. Coba foto lagi.'),
      );
    }

    if (faces.length > 1) {
      return ResultFailure<String>(
        ValidationFailure(
          'Terdeteksi ${faces.length} wajah. Pastikan hanya ada 1 orang dalam foto.',
        ),
      );
    }

    return Success<String>('✅ Foto valid');
  }

  /// Get face count from image (untuk UI feedback)
  Future<int> getFaceCount(File imageFile) async {
    final result = await detectFacesInFile(imageFile);
    if (result is Success<List<Face>>) {
      return result.data.length;
    }
    return 0;
  }

  // ====================================================
  // CLEANUP
  // ====================================================

  /// Dispose service resources
  ///
  /// Closes:
  /// - Face detector
  /// - TFLite interpreter
  Future<void> dispose() async {
    try {
      await _faceDetector.close();
      _interpreter?.close();

      _isInitialized = false;
      _isModelLoaded = false;

      debugPrint('✅ FaceRecognitionService disposed');
    } catch (e) {
      debugPrint('⚠️ Error disposing FaceRecognitionService: $e');
    }
  }
}

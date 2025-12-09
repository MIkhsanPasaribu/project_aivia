import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';

/// Service untuk Face Recognition menggunakan ML Kit (FREE!)
///
/// Features:
/// - Face detection dengan Google ML Kit (on-device, FREE)
/// - Face embedding generation dengan TFLite GhostFaceNet (TODO: Phase 3B)
/// - Real-time camera face detection
/// - Image preprocessing untuk ML
///
/// **100% FREE**: Semua processing di device, tidak perlu API key/cloud ML
class FaceRecognitionService {
  final FaceDetector _faceDetector;
  // TFLite interpreter will be added in Phase 3B when model is downloaded
  // Interpreter? _interpreter;
  bool _isInitialized = false;

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
      );

  /// Initialize service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // TODO Phase 3B: Load TFLite model from assets
      // _interpreter = await Interpreter.fromAsset(
      //   'assets/ml_models/ghostfacenet.tflite',
      // );

      _isInitialized = true;
      debugPrint('✅ FaceRecognitionService initialized');
    } catch (e) {
      debugPrint('⚠️ FaceRecognitionService initialization failed: $e');
      // Don't rethrow - service can still work for face detection
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
      final inputImage = InputImage.fromFile(imageFile);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        return const ResultFailure(
          ValidationFailure('Tidak ada wajah terdeteksi dalam foto'),
        );
      }

      return Success(faces);
    } catch (e) {
      return ResultFailure(
        ServerFailure('Gagal deteksi wajah: ${e.toString()}'),
      );
    }
  }

  /// Detect faces in camera frame (for real-time preview)
  ///
  /// Returns: List of faces (can be empty)
  /// Use case: Show bounding box overlay di camera preview
  Future<List<Face>> detectFacesInFrame(CameraImage image) async {
    try {
      final inputImage = _convertCameraImageToInputImage(image);
      if (inputImage == null) return [];

      return await _faceDetector.processImage(inputImage);
    } catch (e) {
      debugPrint('⚠️ Frame detection error: $e');
      return [];
    }
  }

  /// Convert CameraImage to InputImage for ML Kit
  InputImage? _convertCameraImageToInputImage(CameraImage image) {
    try {
      // ML Kit requires specific format
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );

      const InputImageRotation imageRotation = InputImageRotation.rotation0deg;

      final InputImageFormat inputImageFormat =
          InputImageFormat.yuv420; // Android default

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: imageRotation,
          format: inputImageFormat,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('Error converting camera image: $e');
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

  /// Resize & normalize image untuk GhostFaceNet model (112x112)
  ///
  /// Returns: Float32List dengan nilai normalized [-1, 1]
  // ignore: unused_element
  Float32List _preprocessForModel(img.Image face) {
    // 1. Resize to 112x112 (GhostFaceNet input size)
    final resized = img.copyResize(face, width: 112, height: 112);

    // 2. Convert to Float32List & normalize [0, 255] → [-1, 1]
    final input = Float32List(1 * 112 * 112 * 3);
    int pixelIndex = 0;

    for (int y = 0; y < 112; y++) {
      for (int x = 0; x < 112; x++) {
        final pixel = resized.getPixel(x, y);

        // Normalize RGB channels to [-1, 1]
        input[pixelIndex++] = (pixel.r / 127.5) - 1.0;
        input[pixelIndex++] = (pixel.g / 127.5) - 1.0;
        input[pixelIndex++] = (pixel.b / 127.5) - 1.0;
      }
    }

    return input;
  }

  // ====================================================
  // FACE EMBEDDING GENERATION (TODO: Phase 3B)
  // ====================================================

  /// Generate 512-dim face embedding dari image file
  ///
  /// **Status**: STUB - Akan diimplementasi di Phase 3B saat model downloaded
  ///
  /// Flow:
  /// 1. Detect face
  /// 2. Crop face region
  /// 3. Preprocess (resize 112x112, normalize)
  /// 4. Run TFLite inference
  /// 5. Extract 512-dim embedding
  /// 6. L2 normalize untuk cosine similarity
  Future<Result<List<double>>> generateEmbedding(File imageFile) async {
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
            'Terdeteksi lebih dari 1 wajah. Pastikan hanya ada 1 wajah dalam foto.',
          ),
        );
      }

      final face = faces.first;

      // Step 2: Crop face (akan digunakan untuk TFLite input)
      final cropResult = await cropFaceFromImage(imageFile, face.boundingBox);
      if (cropResult is ResultFailure) {
        return ResultFailure<List<double>>(cropResult.failure);
      }
      // final croppedFile = (cropResult as Success<File>).data;

      // TODO Phase 3B: Implement TFLite inference
      // For now, return MOCK embedding (512 random values)
      // WARNING: This is TEMPORARY - will be replaced with real ML model
      debugPrint('⚠️ MOCK: Generating random embedding (no TFLite model yet)');
      final mockEmbedding = _generateMockEmbedding();

      return Success(mockEmbedding);
    } catch (e) {
      return ResultFailure(
        ServerFailure('Gagal generate embedding: ${e.toString()}'),
      );
    }
  }

  /// MOCK embedding generator (TEMPORARY - untuk testing)
  ///
  /// **WARNING**: Ini hanya untuk testing UI/flow
  /// Real embedding akan menggunakan TFLite GhostFaceNet model
  List<double> _generateMockEmbedding() {
    final random = Random();
    // Generate 512 random values antara -1 dan 1
    final mockValues = List.generate(512, (_) => (random.nextDouble() * 2) - 1);
    // L2 normalize
    return _l2Normalize(mockValues);
  }

  /// L2 normalization (penting untuk cosine similarity)
  ///
  /// Formula: v_normalized = v / ||v||
  /// where ||v|| = sqrt(sum(v_i^2))
  List<double> _l2Normalize(List<double> vector) {
    double sumSquares = 0.0;
    for (final val in vector) {
      sumSquares += val * val;
    }
    final norm = sqrt(sumSquares);

    // Avoid division by zero
    if (norm == 0) return vector;

    return vector.map((v) => v / norm).toList();
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
  Future<void> dispose() async {
    await _faceDetector.close();
    // TODO Phase 3B: _interpreter?.close();
    _isInitialized = false;
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_aivia/core/utils/result.dart';
import 'package:project_aivia/core/errors/failures.dart';

/// Service untuk handle image upload, crop, resize, dan delete
/// Digunakan untuk avatar profile dan future face recognition
class ImageUploadService {
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _bucketName = 'avatars';
  static const int _maxFileSizeBytes = 2 * 1024 * 1024; // 2MB
  static const int _targetImageSize = 512; // 512x512 untuk avatar

  /// Pick image dari gallery
  Future<Result<File>> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) {
        return const ResultFailure(
          ValidationFailure('Tidak ada gambar yang dipilih'),
        );
      }

      return Success(File(image.path));
    } catch (e) {
      return ResultFailure(
        ValidationFailure('Gagal memilih gambar: ${e.toString()}'),
      );
    }
  }

  /// Pick image dari camera
  Future<Result<File>> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) {
        return const ResultFailure(
          ValidationFailure('Tidak ada foto yang diambil'),
        );
      }

      return Success(File(image.path));
    } catch (e) {
      return ResultFailure(
        ValidationFailure('Gagal mengambil foto: ${e.toString()}'),
      );
    }
  }

  /// Crop image dengan aspect ratio 1:1 (untuk avatar)
  Future<Result<File>> cropImage(File imageFile) async {
    try {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Avatar',
            toolbarColor: const Color(0xFFA8DADC),
            toolbarWidgetColor: const Color(0xFF333333),
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Crop Avatar',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile == null) {
        return const ResultFailure(
          ValidationFailure('Crop dibatalkan'),
        );
      }

      return Success(File(croppedFile.path));
    } catch (e) {
      return ResultFailure(
        ValidationFailure('Gagal crop gambar: ${e.toString()}'),
      );
    }
  }

  /// Resize dan compress image untuk optimasi storage
  Future<Result<File>> resizeAndCompress(File imageFile) async {
    try {
      // Read image
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        return const ResultFailure(
          ValidationFailure('Gagal decode gambar'),
        );
      }

      // Resize to target size
      if (image.width > _targetImageSize || image.height > _targetImageSize) {
        image = img.copyResize(
          image,
          width: _targetImageSize,
          height: _targetImageSize,
          interpolation: img.Interpolation.linear,
        );
      }

      // Compress to JPEG
      final compressedBytes = img.encodeJpg(image, quality: 85);

      // Check file size
      if (compressedBytes.length > _maxFileSizeBytes) {
        return const ResultFailure(
          ValidationFailure('Ukuran file terlalu besar. Maksimal 2MB.'),
        );
      }

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('${tempDir.path}/temp_avatar_$timestamp.jpg');
      await tempFile.writeAsBytes(compressedBytes);

      return Success(tempFile);
    } catch (e) {
      return ResultFailure(
        ValidationFailure('Gagal resize gambar: ${e.toString()}'),
      );
    }
  }

  /// Upload image ke Supabase Storage
  /// Path: avatars/{userId}/avatar.jpg
  Future<Result<String>> uploadToStorage({
    required File imageFile,
    required String userId,
  }) async {
    try {
      final fileName = 'avatar.jpg';
      final path = '$userId/$fileName';

      // Upload with upsert (overwrite if exists)
      await _supabase.storage.from(_bucketName).upload(
            path,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage.from(_bucketName).getPublicUrl(path);

      return Success(publicUrl);
    } on StorageException catch (e) {
      return ResultFailure(
        ServerFailure('Gagal upload gambar: ${e.message}'),
      );
    } catch (e) {
      return ResultFailure(
        ServerFailure('Gagal upload gambar: ${e.toString()}'),
      );
    }
  }

  /// Delete image dari Supabase Storage
  Future<Result<void>> deleteFromStorage(String userId) async {
    try {
      final path = '$userId/avatar.jpg';

      await _supabase.storage.from(_bucketName).remove([path]);

      return const Success(null);
    } on StorageException catch (e) {
      // Not found is not an error
      if (e.message.contains('not found') || e.message.contains('does not exist')) {
        return const Success(null);
      }

      return ResultFailure(
        ServerFailure('Gagal hapus gambar: ${e.message}'),
      );
    } catch (e) {
      return ResultFailure(
        ServerFailure('Gagal hapus gambar: ${e.toString()}'),
      );
    }
  }

  /// Main method: Pick, crop, resize, dan upload dalam satu proses
  /// Digunakan untuk update avatar dari UI
  Future<Result<String>> pickCropAndUpload({
    required String userId,
    required ImageSource source,
  }) async {
    File? pickedFile;
    File? croppedFile;
    File? finalFile;

    try {
      // 1. Pick image
      final pickResult = source == ImageSource.gallery
          ? await pickImageFromGallery()
          : await pickImageFromCamera();

      if (pickResult is ResultFailure) {
        final failure = pickResult.failure;
        return ResultFailure(failure);
      }
      pickedFile = (pickResult as Success<File>).data;

      // 2. Crop image
      final cropResult = await cropImage(pickedFile);
      if (cropResult is ResultFailure) {
        final failure = cropResult.failure;
        return ResultFailure(failure);
      }
      croppedFile = (cropResult as Success<File>).data;

      // 3. Resize and compress
      final resizeResult = await resizeAndCompress(croppedFile);
      if (resizeResult is ResultFailure) {
        final failure = resizeResult.failure;
        return ResultFailure(failure);
      }
      finalFile = (resizeResult as Success<File>).data;

      // 4. Upload to Supabase Storage
      final uploadResult = await uploadToStorage(
        imageFile: finalFile,
        userId: userId,
      );

      return uploadResult;
    } catch (e) {
      return ResultFailure(
        ServerFailure('Gagal upload gambar: ${e.toString()}'),
      );
    } finally {
      // 5. Cleanup temp files
      try {
        if (pickedFile != null && await pickedFile.exists()) {
          await pickedFile.delete();
        }
        if (croppedFile != null && await croppedFile.exists()) {
          await croppedFile.delete();
        }
        if (finalFile != null && await finalFile.exists()) {
          await finalFile.delete();
        }
      } catch (e) {
        // Ignore cleanup errors
      }
    }
  }
}

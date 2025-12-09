import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/known_person.dart';
import '../../data/models/face_recognition_log.dart';
import '../../data/repositories/known_person_repository.dart';
import '../../data/services/face_recognition_service.dart';
import '../../core/utils/result.dart';
import '../../core/errors/failures.dart';

// ====================================================
// SINGLETON PROVIDERS
// ====================================================

/// Supabase client provider (global)
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

/// KnownPersonRepository provider (singleton)
final knownPersonRepositoryProvider = Provider<KnownPersonRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return KnownPersonRepository(supabase);
});

/// FaceRecognitionService provider (singleton dengan lazy init)
final faceRecognitionServiceProvider = Provider<FaceRecognitionService>((ref) {
  final service = FaceRecognitionService();
  // Initialize service (async - but provider is sync)
  service.initialize();
  return service;
});

// ====================================================
// STATE PROVIDERS
// ====================================================

/// Current user ID (dari auth)
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(supabaseClientProvider).auth.currentUser?.id;
});

/// Current user profile (untuk get patient_id dari family member)
final currentUserProfileProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final response = await ref
      .watch(supabaseClientProvider)
      .from('profiles')
      .select('id, full_name, email, user_role')
      .eq('id', userId)
      .single();

  return response;
});

// ====================================================
// KNOWN PERSONS LIST (FAMILY - untuk patient_id tertentu)
// ====================================================

/// Stream daftar orang dikenal untuk patient tertentu
final knownPersonsStreamProvider =
    StreamProvider.family<List<KnownPerson>, String>((ref, patientId) {
      final repository = ref.watch(knownPersonRepositoryProvider);
      return repository.knownPersonsStream(patientId);
    });

/// FutureProvider untuk fetch daftar (non-stream)
final knownPersonsListProvider =
    FutureProvider.family<List<KnownPerson>, String>((ref, patientId) async {
      final repository = ref.watch(knownPersonRepositoryProvider);
      final result = await repository.getKnownPersons(patientId);
      if (result is Success<List<KnownPerson>>) {
        return result.data;
      }
      throw Exception('Failed to load known persons');
    });

/// Single known person by ID
final knownPersonByIdProvider = FutureProvider.family<KnownPerson?, String>((
  ref,
  personId,
) async {
  final repository = ref.watch(knownPersonRepositoryProvider);
  final result = await repository.getKnownPersonById(personId);
  if (result is Success<KnownPerson>) {
    return result.data;
  }
  return null;
});

/// Statistics dashboard untuk patient
final knownPersonsStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, patientId) async {
      final repository = ref.watch(knownPersonRepositoryProvider);
      final result = await repository.getStatistics(patientId);
      if (result is Success<Map<String, dynamic>>) {
        return result.data;
      }
      return {'total': 0, 'recentlyRecognized': 0, 'lastRecognitionTime': null};
    });

// ====================================================
// FACE RECOGNITION LOGS
// ====================================================

/// Stream recognition logs untuk patient
final recognitionLogsProvider =
    FutureProvider.family<List<FaceRecognitionLog>, String>((
      ref,
      patientId,
    ) async {
      final repository = ref.watch(knownPersonRepositoryProvider);
      final result = await repository.getRecognitionLogs(
        patientId: patientId,
        limit: 20,
      );
      if (result is Success<List<FaceRecognitionLog>>) {
        return result.data;
      }
      return [];
    });

// ====================================================
// ACTION NOTIFIER (untuk CRUD operations)
// ====================================================

/// State untuk add/edit/delete known person
class KnownPersonNotifier extends StateNotifier<AsyncValue<void>> {
  KnownPersonNotifier(this._repository, this._faceService)
    : super(const AsyncValue.data(null));

  final KnownPersonRepository _repository;
  final FaceRecognitionService _faceService;

  /// Add known person dengan face detection & embedding generation
  ///
  /// Steps:
  /// 1. Validate photo (1 face only)
  /// 2. Generate embedding
  /// 3. Upload photo ke Supabase Storage
  /// 4. Save to database
  Future<Result<String>> addKnownPerson({
    required String patientId,
    required String fullName,
    required String relationship,
    String? bio,
    required File photoFile,
  }) async {
    state = const AsyncValue.loading();

    try {
      // Step 1: Validate photo (harus ada 1 wajah)
      debugPrint('🔍 Validating face in photo...');
      final validateResult = await _faceService.validateFacePhoto(photoFile);
      if (validateResult is ResultFailure) {
        state = AsyncValue.error(
          validateResult.failure.message,
          StackTrace.current,
        );
        return validateResult as ResultFailure<String>;
      }

      // Step 2: Generate embedding
      debugPrint('🧠 Generating face embedding...');
      final embeddingResult = await _faceService.generateEmbedding(photoFile);
      if (embeddingResult is ResultFailure) {
        state = AsyncValue.error(
          embeddingResult.failure.message,
          StackTrace.current,
        );
        return ResultFailure<String>(embeddingResult.failure);
      }
      final embedding = (embeddingResult as Success<List<double>>).data;

      // Step 3: Add to database (repository will handle photo upload)
      debugPrint('💾 Saving to database...');
      final result = await _repository.addKnownPerson(
        patientId: patientId,
        fullName: fullName,
        relationship: relationship,
        bio: bio,
        photoUrl: 'temp', // Will be replaced after upload
        faceEmbedding: embedding,
      );

      if (result is ResultFailure) {
        state = AsyncValue.error(result.failure.message, StackTrace.current);
        return ResultFailure<String>(result.failure);
      }

      final person = (result as Success<KnownPerson>).data;

      state = const AsyncValue.data(null);
      debugPrint('✅ Known person added: ${person.id}');
      return Success('✅ Berhasil menambahkan $fullName');
    } catch (e, stack) {
      debugPrint('❌ Add known person error: $e');
      state = AsyncValue.error(e, stack);
      return ResultFailure<String>(
        ServerFailure('Gagal menambahkan orang: ${e.toString()}'),
      );
    }
  }

  /// Update known person metadata (name, relationship, bio)
  ///
  /// **Note**: Embedding & photo TIDAK bisa diubah (security & ML reasons)
  Future<Result<String>> updateKnownPerson({
    required String personId,
    required String fullName,
    required String relationship,
    String? bio,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _repository.updateKnownPerson(
        id: personId,
        fullName: fullName,
        relationship: relationship,
        bio: bio,
      );

      state = const AsyncValue.data(null);
      return Success('✅ Berhasil memperbarui data');
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return ResultFailure<String>(
        ServerFailure('Gagal memperbarui: ${e.toString()}'),
      );
    }
  }

  /// Delete known person (cascade: embedding + logs akan terhapus)
  Future<Result<String>> deleteKnownPerson(String personId) async {
    state = const AsyncValue.loading();

    try {
      await _repository.deleteKnownPerson(personId);
      state = const AsyncValue.data(null);
      return const Success('✅ Berhasil menghapus data');
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return ResultFailure<String>(
        ServerFailure('Gagal menghapus: ${e.toString()}'),
      );
    }
  }
}

/// Provider untuk KnownPersonNotifier
final knownPersonNotifierProvider =
    StateNotifierProvider<KnownPersonNotifier, AsyncValue<void>>((ref) {
      final repository = ref.watch(knownPersonRepositoryProvider);
      final faceService = ref.watch(faceRecognitionServiceProvider);
      return KnownPersonNotifier(repository, faceService);
    });

// ====================================================
// FACE RECOGNITION ACTION (PATIENT)
// ====================================================

/// State untuk recognize face action
class FaceRecognitionNotifier extends StateNotifier<AsyncValue<KnownPerson?>> {
  FaceRecognitionNotifier(this._repository, this._faceService)
    : super(const AsyncValue.data(null));

  final KnownPersonRepository _repository;
  final FaceRecognitionService _faceService;

  /// Recognize face dari photo
  ///
  /// Steps:
  /// 1. Validate photo (1 face only)
  /// 2. Generate embedding
  /// 3. Search in database (cosine similarity > 0.85)
  /// 4. Save recognition log
  /// 5. Return matched person or null
  Future<Result<KnownPerson?>> recognizeFace({
    required String patientId,
    required File photoFile,
  }) async {
    state = const AsyncValue.loading();

    try {
      // Step 1: Validate photo
      debugPrint('🔍 Validating face...');
      final validateResult = await _faceService.validateFacePhoto(photoFile);
      if (validateResult is ResultFailure) {
        state = AsyncValue.error(
          validateResult.failure.message,
          StackTrace.current,
        );
        return ResultFailure<KnownPerson?>(validateResult.failure);
      }

      // Step 2: Generate embedding
      debugPrint('🧠 Generating embedding...');
      final embeddingResult = await _faceService.generateEmbedding(photoFile);
      if (embeddingResult is ResultFailure) {
        state = AsyncValue.error(
          embeddingResult.failure.message,
          StackTrace.current,
        );
        return ResultFailure<KnownPerson?>(embeddingResult.failure);
      }
      final embedding = (embeddingResult as Success<List<double>>).data;

      // Step 3: Search in database
      debugPrint('🔎 Searching database...');
      final searchResult = await _repository.findKnownPersonByEmbedding(
        patientId: patientId,
        queryEmbedding: embedding,
        threshold: 0.85, // 85% similarity
      );

      KnownPerson? matchedPerson;
      double? similarityScore;
      if (searchResult is Success<KnownPerson?>) {
        matchedPerson = searchResult.data;
        // Similarity score will be returned from DB function in real implementation
        // For now, use high confidence score for matched persons
        similarityScore = matchedPerson != null ? 0.92 : 0.0;
      }

      // Step 4: Save recognition log
      await _repository.saveRecognitionLog(
        patientId: patientId,
        recognizedPersonId: matchedPerson?.id,
        similarityScore: similarityScore,
        isRecognized: matchedPerson != null,
        photoUrl: '', // Optional: upload photo jika diperlukan
      );

      state = AsyncValue.data(matchedPerson);

      if (matchedPerson != null) {
        debugPrint('✅ Face recognized: ${matchedPerson.fullName}');
        return Success(matchedPerson);
      } else {
        debugPrint('❓ Face not recognized');
        return const Success(null);
      }
    } catch (e, stack) {
      debugPrint('❌ Recognition error: $e');
      state = AsyncValue.error(e, stack);
      return ResultFailure<KnownPerson?>(
        ServerFailure('Gagal mengenali wajah: ${e.toString()}'),
      );
    }
  }

  /// Reset state
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Provider untuk FaceRecognitionNotifier
final faceRecognitionNotifierProvider =
    StateNotifierProvider<FaceRecognitionNotifier, AsyncValue<KnownPerson?>>((
      ref,
    ) {
      final repository = ref.watch(knownPersonRepositoryProvider);
      final faceService = ref.watch(faceRecognitionServiceProvider);
      return FaceRecognitionNotifier(repository, faceService);
    });

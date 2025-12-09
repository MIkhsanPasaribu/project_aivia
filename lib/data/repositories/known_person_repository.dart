import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/known_person.dart';
import '../models/face_recognition_log.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';

/// Repository untuk operasi CRUD known_persons
///
/// Menangani:
/// - Get list known persons untuk patient tertentu
/// - Add known person dengan face embedding
/// - Update known person data
/// - Delete known person
/// - Find known person by face embedding (cosine similarity)
/// - Save recognition log
/// - Get recognition history
class KnownPersonRepository {
  final SupabaseClient _supabase;

  KnownPersonRepository(this._supabase);

  /// Get semua known persons untuk patient tertentu
  ///
  /// Returns: List KnownPerson yang dimiliki patient ini
  Future<Result<List<KnownPerson>>> getKnownPersons(String patientId) async {
    try {
      final response = await _supabase
          .from('known_persons')
          .select()
          .eq('owner_id', patientId)
          .order('created_at', ascending: false);

      final knownPersons = (response as List)
          .map((json) => KnownPerson.fromJson(json))
          .toList();

      return Success(knownPersons);
    } on PostgrestException catch (e) {
      return ResultFailure(
        ServerFailure('Gagal mengambil data orang dikenal: ${e.message}'),
      );
    } catch (e) {
      return ResultFailure(
        ServerFailure('Gagal mengambil data orang dikenal: ${e.toString()}'),
      );
    }
  }

  /// Get single known person by ID
  Future<Result<KnownPerson>> getKnownPersonById(String id) async {
    try {
      final response = await _supabase
          .from('known_persons')
          .select()
          .eq('id', id)
          .single();

      final knownPerson = KnownPerson.fromJson(response);
      return Success(knownPerson);
    } on PostgrestException catch (e) {
      return ResultFailure(ServerFailure('Gagal mengambil data: ${e.message}'));
    } catch (e) {
      return ResultFailure(
        ServerFailure('Gagal mengambil data: ${e.toString()}'),
      );
    }
  }

  /// Add known person baru dengan face embedding
  ///
  /// Parameters:
  /// - patientId: Owner dari known person ini
  /// - fullName: Nama lengkap orang yang dikenal
  /// - relationship: Hubungan (ibu, ayah, anak, teman, dll)
  /// - bio: Informasi tambahan
  /// - photoUrl: URL foto di Supabase Storage
  /// - faceEmbedding: 512-dimensional vector dari GhostFaceNet
  Future<Result<KnownPerson>> addKnownPerson({
    required String patientId,
    required String fullName,
    String? relationship,
    String? bio,
    required String photoUrl,
    required List<double> faceEmbedding,
  }) async {
    try {
      // Validate embedding dimension
      if (faceEmbedding.length != 512) {
        return const ResultFailure(
          ValidationFailure(
            'Face embedding harus 512 dimensi (GhostFaceNet format)',
          ),
        );
      }

      // Convert embedding to PostgreSQL vector format
      final embeddingString = '[${faceEmbedding.join(',')}]';

      final response = await _supabase
          .from('known_persons')
          .insert({
            'owner_id': patientId,
            'full_name': fullName,
            'relationship': relationship,
            'bio': bio,
            'photo_url': photoUrl,
            'face_embedding': embeddingString,
            'recognition_count': 0,
          })
          .select()
          .single();

      final knownPerson = KnownPerson.fromJson(response);
      return Success(knownPerson);
    } on PostgrestException catch (e) {
      return ResultFailure(
        ServerFailure('Gagal menambahkan orang dikenal: ${e.message}'),
      );
    } catch (e) {
      return ResultFailure(
        ServerFailure('Gagal menambahkan orang dikenal: ${e.toString()}'),
      );
    }
  }

  /// Update known person data (nama, relationship, bio)
  /// Note: Photo dan embedding tidak bisa diupdate, harus delete & add ulang
  Future<Result<KnownPerson>> updateKnownPerson({
    required String id,
    String? fullName,
    String? relationship,
    String? bio,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (fullName != null) updateData['full_name'] = fullName;
      if (relationship != null) updateData['relationship'] = relationship;
      if (bio != null) updateData['bio'] = bio;

      if (updateData.isEmpty) {
        return const ResultFailure(
          ValidationFailure('Tidak ada data yang diupdate'),
        );
      }

      final response = await _supabase
          .from('known_persons')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      final knownPerson = KnownPerson.fromJson(response);
      return Success(knownPerson);
    } on PostgrestException catch (e) {
      return ResultFailure(
        ServerFailure('Gagal mengupdate data: ${e.message}'),
      );
    } catch (e) {
      return ResultFailure(
        ServerFailure('Gagal mengupdate data: ${e.toString()}'),
      );
    }
  }

  /// Delete known person
  /// Akan cascade delete foto di storage (via trigger)
  Future<Result<void>> deleteKnownPerson(String id) async {
    try {
      await _supabase.from('known_persons').delete().eq('id', id);

      return const Success(null);
    } on PostgrestException catch (e) {
      return ResultFailure(ServerFailure('Gagal menghapus data: ${e.message}'));
    } catch (e) {
      return ResultFailure(
        ServerFailure('Gagal menghapus data: ${e.toString()}'),
      );
    }
  }

  /// Find known person by face embedding (cosine similarity)
  ///
  /// Menggunakan PostgreSQL function: find_known_person()
  /// yang memanfaatkan HNSW index untuk pencarian vector SUPER CEPAT
  ///
  /// Parameters:
  /// - patientId: Owner ID untuk filter known persons
  /// - queryEmbedding: 512-dim vector dari wajah yang ingin dikenali
  /// - threshold: Similarity threshold (default 0.85 = 85% match)
  ///
  /// Returns: KnownPerson jika ada match, null jika tidak ada
  Future<Result<KnownPerson?>> findKnownPersonByEmbedding({
    required String patientId,
    required List<double> queryEmbedding,
    double threshold = 0.85,
  }) async {
    try {
      // Validate embedding dimension
      if (queryEmbedding.length != 512) {
        return const ResultFailure(
          ValidationFailure('Query embedding harus 512 dimensi'),
        );
      }

      // Convert embedding to PostgreSQL vector format
      final embeddingString = '[${queryEmbedding.join(',')}]';

      // Call PostgreSQL function
      final response = await _supabase.rpc(
        'find_known_person',
        params: {
          'query_embedding': embeddingString,
          'patient_id': patientId,
          'similarity_threshold': threshold,
        },
      );

      // Function returns single row or null
      if (response == null || (response is List && response.isEmpty)) {
        return const Success(null); // No match found
      }

      // Extract result (function returns table with columns)
      final resultData = response is List ? response.first : response;

      // Map function result to KnownPerson
      final knownPerson = KnownPerson(
        id: resultData['id'] as String,
        ownerId: patientId,
        fullName: resultData['full_name'] as String,
        relationship: resultData['relationship'] as String?,
        bio: resultData['bio'] as String?,
        photoUrl: resultData['photo_url'] as String,
        faceEmbedding: null, // Function doesn't return embedding
        lastSeenAt: null, // Will be updated by trigger
        recognitionCount: 0, // Will be updated by trigger
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return Success(knownPerson);
    } on PostgrestException catch (e) {
      return ResultFailure(ServerFailure('Gagal mencari wajah: ${e.message}'));
    } catch (e) {
      return ResultFailure(
        ServerFailure('Gagal mencari wajah: ${e.toString()}'),
      );
    }
  }

  /// Save recognition log
  ///
  /// Log setiap kali patient mencoba recognize face
  /// Trigger database akan otomatis update last_seen_at dan recognition_count
  Future<Result<void>> saveRecognitionLog({
    required String patientId,
    String? recognizedPersonId,
    required double? similarityScore,
    required bool isRecognized,
    String? photoUrl,
    LatLng? location,
  }) async {
    try {
      await _supabase.from('face_recognition_logs').insert({
        'patient_id': patientId,
        'recognized_person_id': recognizedPersonId,
        'similarity_score': similarityScore,
        'is_recognized': isRecognized,
        'photo_url': photoUrl,
        'location': location != null
            ? 'POINT(${location.longitude} ${location.latitude})'
            : null,
      });

      return const Success(null);
    } on PostgrestException catch (e) {
      return ResultFailure(ServerFailure('Gagal menyimpan log: ${e.message}'));
    } catch (e) {
      return ResultFailure(
        ServerFailure('Gagal menyimpan log: ${e.toString()}'),
      );
    }
  }

  /// Get recognition history untuk patient
  ///
  /// Returns: List logs dengan data known person (jika dikenali)
  Future<Result<List<FaceRecognitionLog>>> getRecognitionLogs({
    required String patientId,
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('face_recognition_logs')
          .select()
          .eq('patient_id', patientId)
          .order('timestamp', ascending: false)
          .limit(limit);

      final logs = (response as List)
          .map((json) => FaceRecognitionLog.fromJson(json))
          .toList();

      return Success(logs);
    } on PostgrestException catch (e) {
      return ResultFailure(
        ServerFailure('Gagal mengambil history: ${e.message}'),
      );
    } catch (e) {
      return ResultFailure(
        ServerFailure('Gagal mengambil history: ${e.toString()}'),
      );
    }
  }

  /// Stream untuk real-time updates known persons
  Stream<List<KnownPerson>> knownPersonsStream(String patientId) {
    return _supabase
        .from('known_persons')
        .stream(primaryKey: ['id'])
        .eq('owner_id', patientId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => KnownPerson.fromJson(json)).toList());
  }

  /// Get statistics untuk dashboard
  Future<Result<Map<String, dynamic>>> getStatistics(String patientId) async {
    try {
      // Get total known persons
      final knownPersonsResponse = await _supabase
          .from('known_persons')
          .select()
          .eq('owner_id', patientId);
      final knownPersonsCount = (knownPersonsResponse as List).length;

      // Get total recognitions (successful)
      final recognitionsResponse = await _supabase
          .from('face_recognition_logs')
          .select()
          .eq('patient_id', patientId)
          .eq('is_recognized', true);
      final recognitionsCount = (recognitionsResponse as List).length;

      // Get recognition attempts (all)
      final attemptsResponse = await _supabase
          .from('face_recognition_logs')
          .select()
          .eq('patient_id', patientId);
      final attemptsCount = (attemptsResponse as List).length;

      // Calculate success rate
      final successRate = attemptsCount > 0
          ? (recognitionsCount / attemptsCount * 100).toStringAsFixed(1)
          : '0.0';

      return Success({
        'known_persons_count': knownPersonsCount,
        'recognitions_count': recognitionsCount,
        'attempts_count': attemptsCount,
        'success_rate': successRate,
      });
    } catch (e) {
      return ResultFailure(
        ServerFailure('Gagal mengambil statistik: ${e.toString()}'),
      );
    }
  }
}

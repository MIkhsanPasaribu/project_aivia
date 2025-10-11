import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/patient_family_link.dart';
import '../models/user_profile.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';

/// Repository untuk operasi patient-family links
///
/// Menangani:
/// - CRUD links antara pasien dan keluarga
/// - Query linked patients untuk family member
/// - Query family members untuk patient
/// - Update permissions (edit activities, view location)
class PatientFamilyRepository {
  final SupabaseClient _supabase;

  PatientFamilyRepository(this._supabase);

  /// Get semua pasien yang di-link ke family member ini
  ///
  /// Returns: List PatientFamilyLink dengan patientProfile sudah di-join
  Future<Result<List<PatientFamilyLink>>> getLinkedPatients(
    String familyMemberId,
  ) async {
    try {
      final response = await _supabase
          .from('patient_family_links')
          .select('''
            *,
            patient_profile:patient_id (
              id,
              full_name,
              email,
              user_role,
              avatar_url,
              phone_number,
              date_of_birth,
              address,
              created_at,
              updated_at
            )
          ''')
          .eq('family_member_id', familyMemberId)
          .order('created_at', ascending: false);

      final links = (response as List)
          .map(
            (json) => PatientFamilyLink.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      return Success(links);
    } on PostgrestException catch (e) {
      return ResultFailure(
        DatabaseFailure('Gagal mengambil daftar pasien: ${e.message}'),
      );
    } catch (e) {
      return ResultFailure(UnknownFailure('Error tidak diketahui: $e'));
    }
  }

  /// Get semua family members yang di-link ke pasien ini
  ///
  /// Returns: List PatientFamilyLink dengan familyMemberProfile sudah di-join
  Future<Result<List<PatientFamilyLink>>> getFamilyMembers(
    String patientId,
  ) async {
    try {
      final response = await _supabase
          .from('patient_family_links')
          .select('''
            *,
            family_member_profile:family_member_id (
              id,
              full_name,
              email,
              user_role,
              avatar_url,
              phone_number,
              date_of_birth,
              address,
              created_at,
              updated_at
            )
          ''')
          .eq('patient_id', patientId)
          .order('is_primary_caregiver', ascending: false);

      final links = (response as List)
          .map(
            (json) => PatientFamilyLink.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      return Success(links);
    } on PostgrestException catch (e) {
      return ResultFailure(
        DatabaseFailure('Gagal mengambil daftar keluarga: ${e.message}'),
      );
    } catch (e) {
      return ResultFailure(UnknownFailure('Error tidak diketahui: $e'));
    }
  }

  /// Get single link by ID dengan joined profiles
  Future<Result<PatientFamilyLink>> getLinkById(String linkId) async {
    try {
      final response = await _supabase
          .from('patient_family_links')
          .select('''
            *,
            patient_profile:patient_id (
              id,
              full_name,
              email,
              user_role,
              avatar_url,
              phone_number,
              date_of_birth,
              address,
              created_at,
              updated_at
            ),
            family_member_profile:family_member_id (
              id,
              full_name,
              email,
              user_role,
              avatar_url,
              phone_number,
              date_of_birth,
              address,
              created_at,
              updated_at
            )
          ''')
          .eq('id', linkId)
          .single();

      final link = PatientFamilyLink.fromJson(response);
      return Success(link);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return ResultFailure(DatabaseFailure('Link tidak ditemukan'));
      }
      return ResultFailure(
        DatabaseFailure('Gagal mengambil link: ${e.message}'),
      );
    } catch (e) {
      return ResultFailure(UnknownFailure('Error tidak diketahui: $e'));
    }
  }

  /// Create link baru antara pasien dan family member
  ///
  /// Validasi:
  /// - Patient harus ada dan role = 'patient'
  /// - Family member harus ada dan role = 'family'
  /// - Tidak boleh link ke diri sendiri (handled by DB constraint)
  /// - Tidak boleh duplicate link (handled by DB unique constraint)
  Future<Result<PatientFamilyLink>> createLink({
    required String patientId,
    required String familyMemberId,
    required String relationshipType,
    bool isPrimaryCaregiver = false,
    bool canEditActivities = true,
    bool canViewLocation = true,
  }) async {
    try {
      // Validasi: cek apakah patient ada dan role = 'patient'
      final patientResult = await _supabase
          .from('profiles')
          .select('user_role')
          .eq('id', patientId)
          .maybeSingle();

      if (patientResult == null) {
        return ResultFailure(ValidationFailure('Pasien tidak ditemukan'));
      }

      if (patientResult['user_role'] != 'patient') {
        return ResultFailure(ValidationFailure('User ini bukan pasien'));
      }

      // Validasi: cek apakah family member ada dan role = 'family'
      final familyResult = await _supabase
          .from('profiles')
          .select('user_role')
          .eq('id', familyMemberId)
          .maybeSingle();

      if (familyResult == null) {
        return ResultFailure(
          ValidationFailure('Anggota keluarga tidak ditemukan'),
        );
      }

      if (familyResult['user_role'] != 'family') {
        return ResultFailure(
          ValidationFailure('User ini bukan anggota keluarga'),
        );
      }

      // Create link
      final response = await _supabase
          .from('patient_family_links')
          .insert({
            'patient_id': patientId,
            'family_member_id': familyMemberId,
            'relationship_type': relationshipType,
            'is_primary_caregiver': isPrimaryCaregiver,
            'can_edit_activities': canEditActivities,
            'can_view_location': canViewLocation,
          })
          .select('''
            *,
            patient_profile:patient_id (
              id,
              full_name,
              email,
              user_role,
              avatar_url,
              phone_number,
              date_of_birth,
              address,
              created_at,
              updated_at
            ),
            family_member_profile:family_member_id (
              id,
              full_name,
              email,
              user_role,
              avatar_url,
              phone_number,
              date_of_birth,
              address,
              created_at,
              updated_at
            )
          ''')
          .single();

      final link = PatientFamilyLink.fromJson(response);
      return Success(link);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Unique constraint violation
        return ResultFailure(
          ValidationFailure('Link sudah ada antara pasien dan keluarga ini'),
        );
      }
      if (e.code == '23514') {
        // Check constraint violation (self-link)
        return ResultFailure(
          ValidationFailure('Tidak dapat membuat link ke diri sendiri'),
        );
      }
      return ResultFailure(DatabaseFailure('Gagal membuat link: ${e.message}'));
    } catch (e) {
      return ResultFailure(UnknownFailure('Error tidak diketahui: $e'));
    }
  }

  /// Update permissions dari existing link
  Future<Result<PatientFamilyLink>> updateLinkPermissions({
    required String linkId,
    bool? isPrimaryCaregiver,
    bool? canEditActivities,
    bool? canViewLocation,
  }) async {
    try {
      // Build update data (hanya yang non-null)
      final updateData = <String, dynamic>{};
      if (isPrimaryCaregiver != null) {
        updateData['is_primary_caregiver'] = isPrimaryCaregiver;
      }
      if (canEditActivities != null) {
        updateData['can_edit_activities'] = canEditActivities;
      }
      if (canViewLocation != null) {
        updateData['can_view_location'] = canViewLocation;
      }

      if (updateData.isEmpty) {
        return ResultFailure(ValidationFailure('Tidak ada data yang diupdate'));
      }

      final response = await _supabase
          .from('patient_family_links')
          .update(updateData)
          .eq('id', linkId)
          .select('''
            *,
            patient_profile:patient_id (
              id,
              full_name,
              email,
              user_role,
              avatar_url,
              phone_number,
              date_of_birth,
              address,
              created_at,
              updated_at
            ),
            family_member_profile:family_member_id (
              id,
              full_name,
              email,
              user_role,
              avatar_url,
              phone_number,
              date_of_birth,
              address,
              created_at,
              updated_at
            )
          ''')
          .single();

      final link = PatientFamilyLink.fromJson(response);
      return Success(link);
    } on PostgrestException catch (e) {
      return ResultFailure(
        DatabaseFailure('Gagal update permissions: ${e.message}'),
      );
    } catch (e) {
      return ResultFailure(UnknownFailure('Error tidak diketahui: $e'));
    }
  }

  /// Delete link (unlink patient dari family member)
  Future<Result<void>> deleteLink(String linkId) async {
    try {
      await _supabase.from('patient_family_links').delete().eq('id', linkId);

      return const Success(null);
    } on PostgrestException catch (e) {
      return ResultFailure(
        DatabaseFailure('Gagal menghapus link: ${e.message}'),
      );
    } catch (e) {
      return ResultFailure(UnknownFailure('Error tidak diketahui: $e'));
    }
  }

  /// Check apakah family member punya permission untuk edit activities patient
  Future<Result<bool>> canEditPatientActivities({
    required String patientId,
    required String familyMemberId,
  }) async {
    try {
      final response = await _supabase
          .from('patient_family_links')
          .select('can_edit_activities')
          .eq('patient_id', patientId)
          .eq('family_member_id', familyMemberId)
          .maybeSingle();

      if (response == null) {
        return const Success(false);
      }

      return Success(response['can_edit_activities'] as bool? ?? false);
    } on PostgrestException catch (e) {
      return ResultFailure(
        DatabaseFailure('Gagal cek permission: ${e.message}'),
      );
    } catch (e) {
      return ResultFailure(UnknownFailure('Error tidak diketahui: $e'));
    }
  }

  /// Check apakah family member punya permission untuk view location patient
  Future<Result<bool>> canViewPatientLocation({
    required String patientId,
    required String familyMemberId,
  }) async {
    try {
      final response = await _supabase
          .from('patient_family_links')
          .select('can_view_location')
          .eq('patient_id', patientId)
          .eq('family_member_id', familyMemberId)
          .maybeSingle();

      if (response == null) {
        return const Success(false);
      }

      return Success(response['can_view_location'] as bool? ?? false);
    } on PostgrestException catch (e) {
      return ResultFailure(
        DatabaseFailure('Gagal cek permission: ${e.message}'),
      );
    } catch (e) {
      return ResultFailure(UnknownFailure('Error tidak diketahui: $e'));
    }
  }

  /// Search patient by email (untuk link patient feature)
  ///
  /// Returns: UserProfile jika found dan role = 'patient'
  Future<Result<UserProfile>> searchPatientByEmail(String email) async {
    try {
      if (email.trim().isEmpty) {
        return ResultFailure(ValidationFailure('Email tidak boleh kosong'));
      }

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('email', email.trim().toLowerCase())
          .eq('user_role', 'patient')
          .maybeSingle();

      if (response == null) {
        return ResultFailure(
          ValidationFailure('Pasien dengan email ini tidak ditemukan'),
        );
      }

      final profile = UserProfile.fromJson(response);
      return Success(profile);
    } on PostgrestException catch (e) {
      return ResultFailure(
        DatabaseFailure('Gagal mencari pasien: ${e.message}'),
      );
    } catch (e) {
      return ResultFailure(UnknownFailure('Error tidak diketahui: $e'));
    }
  }
}

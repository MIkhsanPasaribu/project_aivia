import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/patient_family_link.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/patient_family_repository.dart';
import '../../core/utils/result.dart';
import '../../core/errors/failures.dart';

/// Provider untuk PatientFamilyRepository instance
final patientFamilyRepositoryProvider = Provider<PatientFamilyRepository>((
  ref,
) {
  return PatientFamilyRepository(Supabase.instance.client);
});

/// Provider untuk stream linked patients dari family member yang sedang login
///
/// Mengembalikan real-time list pasien yang di-link ke family member
final linkedPatientsStreamProvider = StreamProvider<List<PatientFamilyLink>>((
  ref,
) async* {
  final repository = ref.watch(patientFamilyRepositoryProvider);
  final currentUserId = Supabase.instance.client.auth.currentUser?.id;

  if (currentUserId == null) {
    yield [];
    return;
  }

  // Real-time stream dari Supabase
  final stream = Supabase.instance.client
      .from('patient_family_links')
      .stream(primaryKey: ['id'])
      .eq('family_member_id', currentUserId)
      .order('created_at', ascending: false);

  await for (final data in stream) {
    try {
      final links = data
          .map((json) => PatientFamilyLink.fromJson(json))
          .toList();

      // Fetch patient profiles untuk setiap link
      final linksWithProfiles = <PatientFamilyLink>[];
      for (final link in links) {
        final profileResult = await repository.getLinkById(link.id);
        profileResult.fold(
          onSuccess: (linkWithProfile) {
            linksWithProfiles.add(linkWithProfile);
          },
          onFailure: (_) {
            // Jika gagal fetch profile, tetap tambahkan link tanpa profile
            linksWithProfiles.add(link);
          },
        );
      }

      yield linksWithProfiles;
    } catch (e) {
      // Jika ada error, yield list kosong
      yield [];
    }
  }
});

/// Provider untuk PatientFamilyController
/// Menyediakan methods untuk manage patient-family relationships
final patientFamilyControllerProvider =
    StateNotifierProvider<PatientFamilyController, AsyncValue<void>>((ref) {
      return PatientFamilyController(
        ref.watch(patientFamilyRepositoryProvider),
      );
    });

/// Controller untuk manage operasi patient-family links
class PatientFamilyController extends StateNotifier<AsyncValue<void>> {
  final PatientFamilyRepository _repository;

  PatientFamilyController(this._repository)
    : super(const AsyncValue.data(null));

  /// Get semua linked patients untuk family member
  Future<Result<List<PatientFamilyLink>>> getLinkedPatients(
    String familyMemberId,
  ) async {
    return await _repository.getLinkedPatients(familyMemberId);
  }

  /// Get semua family members untuk patient
  Future<Result<List<PatientFamilyLink>>> getFamilyMembers(
    String patientId,
  ) async {
    return await _repository.getFamilyMembers(patientId);
  }

  /// Get single link dengan joined profiles
  Future<Result<PatientFamilyLink>> getLinkById(String linkId) async {
    return await _repository.getLinkById(linkId);
  }

  /// Create link antara patient dan family member
  ///
  /// Params:
  /// - patientEmail: Email patient yang akan di-link
  /// - relationshipType: Tipe hubungan (dari RelationshipTypes helper)
  /// - isPrimaryCaregiver: Apakah primary caregiver
  /// - canEditActivities: Permission edit activities
  /// - canViewLocation: Permission view location
  Future<Result<PatientFamilyLink>> createLink({
    required String patientEmail,
    required String relationshipType,
    bool isPrimaryCaregiver = false,
    bool canEditActivities = true,
    bool canViewLocation = true,
  }) async {
    state = const AsyncValue.loading();

    // 1. Cari patient berdasarkan email
    final searchResult = await _repository.searchPatientByEmail(patientEmail);

    return await searchResult.fold(
      onSuccess: (patient) async {
        // 2. Validasi role patient
        if (patient.userRole != UserRole.patient) {
          state = AsyncValue.error(
            'Email tersebut bukan akun pasien',
            StackTrace.current,
          );
          return ResultFailure(
            ValidationFailure('Email tersebut bukan akun pasien'),
          );
        }

        // 3. Get current user ID (family member)
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        if (currentUserId == null) {
          state = AsyncValue.error(
            'User tidak terautentikasi',
            StackTrace.current,
          );
          return ResultFailure(AuthFailure('User tidak terautentikasi'));
        }

        // 4. Create link
        final createResult = await _repository.createLink(
          patientId: patient.id,
          familyMemberId: currentUserId,
          relationshipType: relationshipType,
          isPrimaryCaregiver: isPrimaryCaregiver,
          canEditActivities: canEditActivities,
          canViewLocation: canViewLocation,
        );

        createResult.fold(
          onSuccess: (_) {
            state = const AsyncValue.data(null);
          },
          onFailure: (failure) {
            state = AsyncValue.error(failure.message, StackTrace.current);
          },
        );

        return createResult;
      },
      onFailure: (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return ResultFailure(failure);
      },
    );
  }

  /// Update permissions untuk link
  Future<Result<void>> updateLinkPermissions({
    required String linkId,
    bool? canEditActivities,
    bool? canViewLocation,
    bool? isPrimaryCaregiver,
  }) async {
    state = const AsyncValue.loading();

    final result = await _repository.updateLinkPermissions(
      linkId: linkId,
      canEditActivities: canEditActivities,
      canViewLocation: canViewLocation,
      isPrimaryCaregiver: isPrimaryCaregiver,
    );

    result.fold(
      onSuccess: (_) {
        state = const AsyncValue.data(null);
      },
      onFailure: (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
      },
    );

    return result;
  }

  /// Delete link (unlink patient dari family)
  Future<Result<void>> deleteLink(String linkId) async {
    state = const AsyncValue.loading();

    final result = await _repository.deleteLink(linkId);

    result.fold(
      onSuccess: (_) {
        state = const AsyncValue.data(null);
      },
      onFailure: (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
      },
    );

    return result;
  }

  /// Check apakah family member bisa edit activities patient
  Future<bool> canEditPatientActivities({
    required String patientId,
    required String familyMemberId,
  }) async {
    final result = await _repository.canEditPatientActivities(
      patientId: patientId,
      familyMemberId: familyMemberId,
    );

    return result.fold(
      onSuccess: (canEdit) => canEdit,
      onFailure: (_) => false,
    );
  }

  /// Check apakah family member bisa view location patient
  Future<bool> canViewPatientLocation({
    required String patientId,
    required String familyMemberId,
  }) async {
    final result = await _repository.canViewPatientLocation(
      patientId: patientId,
      familyMemberId: familyMemberId,
    );

    return result.fold(
      onSuccess: (canView) => canView,
      onFailure: (_) => false,
    );
  }

  /// Search patient by email (untuk form linking)
  Future<Result<UserProfile>> searchPatientByEmail(String email) async {
    return await _repository.searchPatientByEmail(email);
  }
}

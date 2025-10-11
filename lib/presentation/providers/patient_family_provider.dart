import 'package:flutter_riverpod/flutter_riverpod.dart';import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/patient_family_repository.dart';import '../../data/repositories/patient_family_repository.dart';

import '../../data/models/patient_family_link.dart';import '../../data/models/patient_family_link.dart';

import '../../core/errors/failures.dart';import '../../core/errors/failures.dart';

import '../../core/utils/result.dart';import '../../core/utils/result.dart';



/// Provider untuk PatientFamilyRepository instance/// Provider untuk PatientFamilyRepository instance

final patientFamilyRepositoryProvider = Provider<PatientFamilyRepository>((ref) {final patientFamilyRepositoryProvider = Provider<PatientFamilyRepository>((ref) {

  final supabase = Supabase.instance.client;  final supabase = Supabase.instance.client;

  return PatientFamilyRepository(supabase);  return PatientFamilyRepository(supabase);

});});



/// Stream provider untuk linked patients dari current user (family member)/// Stream provider untuk linked patients dari current user (family member)

/// /// 

/// Auto-updates ketika ada perubahan di database via Supabase Realtime/// Auto-updates ketika ada perubahan di database via Supabase Realtime

final linkedPatientsStreamProvider = StreamProvider<List<PatientFamilyLink>>((ref) {final linkedPatientsStreamProvider = StreamProvider<List<PatientFamilyLink>>((ref) {

  final supabase = Supabase.instance.client;  final supabase = Supabase.instance.client;

  final userId = supabase.auth.currentUser?.id;  final userId = supabase.auth.currentUser?.id;



  if (userId == null) {  if (userId == null) {

    return Stream.error(AuthFailure('User tidak terautentikasi'));    return Stream.error(AuthFailure('User tidak terautentikasi'));

  }  }



  return supabase  return supabase

      .from('patient_family_links')      .from('patient_family_links')

      .stream(primaryKey: ['id'])      .stream(primaryKey: ['id'])

      .eq('family_member_id', userId)      .eq('family_member_id', userId)

      .order('created_at', ascending: false)      .order('created_at', ascending: false)

      .map((maps) {      .map((maps) {

    return maps.map((json) {    return maps.map((json) {

      // Manual join dengan profiles untuk patient_profile      // Manual join dengan profiles untuk patient_profile

      // Note: Supabase stream tidak support nested select, jadi kita query manual      // Note: Supabase stream tidak support nested select, jadi kita query manual

      return PatientFamilyLink.fromJson(json);      return PatientFamilyLink.fromJson(json);

    }).toList();    }).toList();

  });  });

});});



/// Provider untuk get single link by ID/// Provider untuk get single link by ID

final linkByIdProvider = FutureProvider.family<PatientFamilyLink, String>((ref, linkId) async {final linkByIdProvider = FutureProvider.family<PatientFamilyLink, String>((ref, linkId) async {

  final repository = ref.watch(patientFamilyRepositoryProvider);  final repository = ref.watch(patientFamilyRepositoryProvider);

  final result = await repository.getLinkById(linkId);  final result = await repository.getLinkById(linkId);



  return result.fold(  return result.when(

    onSuccess: (link) => link,    success: (link) => link,

    onFailure: (failure) => throw failure.message,    failure: (failure) => throw failure.message,

  );  );

});});



/// Provider untuk check permissions/// Provider untuk check permissions

final canEditPatientActivitiesProvider = FutureProvider.family<bool, String>((ref, patientId) async {final canEditPatientActivitiesProvider = FutureProvider.family<bool, String>((ref, patientId) async {

  final repository = ref.watch(patientFamilyRepositoryProvider);  final repository = ref.watch(patientFamilyRepositoryProvider);

  final supabase = Supabase.instance.client;  final supabase = Supabase.instance.client;

  final familyMemberId = supabase.auth.currentUser?.id;  final familyMemberId = supabase.auth.currentUser?.id;



  if (familyMemberId == null) {  if (familyMemberId == null) {

    return false;    return false;

  }  }



  final result = await repository.canEditPatientActivities(  final result = await repository.canEditPatientActivities(

    patientId: patientId,    patientId: patientId,

    familyMemberId: familyMemberId,    familyMemberId: familyMemberId,

  );  );



  return result.fold(  return result.when(

    onSuccess: (canEdit) => canEdit,    success: (canEdit) => canEdit,

    onFailure: (_) => false,    failure: (_) => false,

  );  );

});});



/// Provider untuk check location permissions/// Provider untuk check location permissions

final canViewPatientLocationProvider = FutureProvider.family<bool, String>((ref, patientId) async {final canViewPatientLocationProvider = FutureProvider.family<bool, String>((ref, patientId) async {

  final repository = ref.watch(patientFamilyRepositoryProvider);  final repository = ref.watch(patientFamilyRepositoryProvider);

  final supabase = Supabase.instance.client;  final supabase = Supabase.instance.client;

  final familyMemberId = supabase.auth.currentUser?.id;  final familyMemberId = supabase.auth.currentUser?.id;



  if (familyMemberId == null) {  if (familyMemberId == null) {

    return false;    return false;

  }  }



  final result = await repository.canViewPatientLocation(  final result = await repository.canViewPatientLocation(

    patientId: patientId,    patientId: patientId,

    familyMemberId: familyMemberId,    familyMemberId: familyMemberId,

  );  );



  return result.fold(  return result.when(

    onSuccess: (canView) => canView,    success: (canView) => canView,

    onFailure: (_) => false,    failure: (_) => false,

  );  );

});});



/// StateNotifier controller untuk patient-family link operations/// StateNotifier controller untuk patient-family link operations

class PatientFamilyController extends StateNotifier<AsyncValue<List<PatientFamilyLink>>> {class PatientFamilyController extends StateNotifier<AsyncValue<List<PatientFamilyLink>>> {

  final PatientFamilyRepository _repository;  final PatientFamilyRepository _repository;

  final String _familyMemberId;  final String _familyMemberId;



  PatientFamilyController(this._repository, this._familyMemberId)  PatientFamilyController(this._repository, this._familyMemberId)

      : super(const AsyncValue.loading()) {      : super(const AsyncValue.loading()) {

    _loadLinkedPatients();    _loadLinkedPatients();

  }  }



  /// Load linked patients  /// Load linked patients

  Future<void> _loadLinkedPatients() async {  Future<void> _loadLinkedPatients() async {

    state = const AsyncValue.loading();    state = const AsyncValue.loading();



    final result = await _repository.getLinkedPatients(_familyMemberId);    final result = await _repository.getLinkedPatients(_familyMemberId);



    state = result.fold(    state = result.when(

      onSuccess: (links) => AsyncValue.data(links),      success: (links) => AsyncValue.data(links),

      onFailure: (failure) => AsyncValue.error(failure.message, StackTrace.current),      failure: (failure) => AsyncValue.error(failure.message, StackTrace.current),

    );    );

  }  }



  /// Refresh linked patients list  /// Refresh linked patients list

  Future<void> refreshLinkedPatients() async {  Future<void> refreshLinkedPatients() async {

    await _loadLinkedPatients();    await _loadLinkedPatients();

  }  }



  /// Create new patient-family link  /// Create new patient-family link

  Future<Result<PatientFamilyLink>> createLink({  Future<Result<PatientFamilyLink>> createLink({

    required String patientId,    required String patientId,

    required String relationshipType,    required String relationshipType,

    bool isPrimaryCaregiver = false,    bool isPrimaryCaregiver = false,

  }) async {  }) async {

    final result = await _repository.createLink(    final result = await _repository.createLink(

      patientId: patientId,      patientId: patientId,

      familyMemberId: _familyMemberId,      familyMemberId: _familyMemberId,

      relationshipType: relationshipType,      relationshipType: relationshipType,

      isPrimaryCaregiver: isPrimaryCaregiver,      isPrimaryCaregiver: isPrimaryCaregiver,

    );    );



    if (result.isSuccess) {    if (result is Success<PatientFamilyLink>) {

      // Reload list after successful creation      // Reload list after successful creation

      await _loadLinkedPatients();      await _loadLinkedPatients();

    }    }



    return result;    return result;

  }  }



  /// Update link permissions  /// Update link permissions

  Future<Result<PatientFamilyLink>> updateLinkPermissions({  Future<Result<PatientFamilyLink>> updateLinkPermissions({

    required String linkId,    required String linkId,

    bool? isPrimaryCaregiver,    bool? isPrimaryCaregiver,

    bool? canEditActivities,    bool? canEditActivities,

    bool? canViewLocation,    bool? canViewLocation,

  }) async {  }) async {

    final result = await _repository.updateLinkPermissions(    final result = await _repository.updateLinkPermissions(

      linkId: linkId,      linkId: linkId,

      isPrimaryCaregiver: isPrimaryCaregiver,      isPrimaryCaregiver: isPrimaryCaregiver,

      canEditActivities: canEditActivities,      canEditActivities: canEditActivities,

      canViewLocation: canViewLocation,      canViewLocation: canViewLocation,

    );    );



    if (result.isSuccess) {    if (result is Success<PatientFamilyLink>) {

      // Reload list after successful update      // Reload list after successful update

      await _loadLinkedPatients();      await _loadLinkedPatients();

    }    }



    return result;    return result;

  }  }



  /// Delete link (unlink patient)  /// Delete link (unlink patient)

  Future<Result<void>> deleteLink(String linkId) async {  Future<Result<void>> deleteLink(String linkId) async {

    final result = await _repository.deleteLink(linkId);    final result = await _repository.deleteLink(linkId);



    if (result.isSuccess) {    if (result is Success<void>) {

      // Reload list after successful deletion      // Reload list after successful deletion

      await _loadLinkedPatients();      await _loadLinkedPatients();

    }    }



    return result;    return result;

  }  }



  /// Search patient by email  /// Search patient by email

  Future<Result<dynamic>> searchPatientByEmail(String email) async {  Future<Result<dynamic>> searchPatientByEmail(String email) async {

    return await _repository.searchPatientByEmail(email);    return await _repository.searchPatientByEmail(email);

  }  }

}}



/// Provider untuk PatientFamilyController/// Provider untuk PatientFamilyController

final patientFamilyControllerProvider =final patientFamilyControllerProvider =

    StateNotifierProvider<PatientFamilyController, AsyncValue<List<PatientFamilyLink>>>((ref) {    StateNotifierProvider<PatientFamilyController, AsyncValue<List<PatientFamilyLink>>>((ref) {

  final repository = ref.watch(patientFamilyRepositoryProvider);  final repository = ref.watch(patientFamilyRepositoryProvider);

  final supabase = Supabase.instance.client;  final supabase = Supabase.instance.client;

  final userId = supabase.auth.currentUser?.id ?? '';  final userId = supabase.auth.currentUser?.id ?? '';



  return PatientFamilyController(repository, userId);  return PatientFamilyController(repository, userId);

});});


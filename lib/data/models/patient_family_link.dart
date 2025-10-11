import 'user_profile.dart';

/// Model untuk relasi antara pasien dan anggota keluarga/wali
///
/// Representasi dari tabel `patient_family_links` di database.
/// Digunakan untuk:
/// - Menghubungkan pasien dengan family member
/// - Mengatur permissions (edit activities, view location)
/// - Menentukan primary caregiver untuk notifikasi prioritas
class PatientFamilyLink {
  /// ID unik link (UUID)
  final String id;

  /// ID pasien yang dimonitor
  final String patientId;

  /// ID family member yang memonitor
  final String familyMemberId;

  /// Tipe hubungan: 'anak', 'orang tua', 'suami', 'istri', 'saudara', dll
  final String relationshipType;

  /// Apakah primary caregiver (mendapat notifikasi prioritas)
  final bool isPrimaryCaregiver;

  /// Permission untuk edit aktivitas pasien
  final bool canEditActivities;

  /// Permission untuk lihat lokasi real-time pasien
  final bool canViewLocation;

  /// Timestamp kapan link dibuat
  final DateTime createdAt;

  /// Optional: Data profil pasien (joined dari profiles table)
  final UserProfile? patientProfile;

  /// Optional: Data profil family member (joined dari profiles table)
  final UserProfile? familyMemberProfile;

  const PatientFamilyLink({
    required this.id,
    required this.patientId,
    required this.familyMemberId,
    required this.relationshipType,
    this.isPrimaryCaregiver = false,
    this.canEditActivities = true,
    this.canViewLocation = true,
    required this.createdAt,
    this.patientProfile,
    this.familyMemberProfile,
  });

  /// Create dari JSON (dari Supabase)
  factory PatientFamilyLink.fromJson(Map<String, dynamic> json) {
    return PatientFamilyLink(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      familyMemberId: json['family_member_id'] as String,
      relationshipType: json['relationship_type'] as String,
      isPrimaryCaregiver: json['is_primary_caregiver'] as bool? ?? false,
      canEditActivities: json['can_edit_activities'] as bool? ?? true,
      canViewLocation: json['can_view_location'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      patientProfile: json['patient_profile'] != null
          ? UserProfile.fromJson(
              json['patient_profile'] as Map<String, dynamic>,
            )
          : null,
      familyMemberProfile: json['family_member_profile'] != null
          ? UserProfile.fromJson(
              json['family_member_profile'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  /// Convert ke JSON (untuk Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'family_member_id': familyMemberId,
      'relationship_type': relationshipType,
      'is_primary_caregiver': isPrimaryCaregiver,
      'can_edit_activities': canEditActivities,
      'can_view_location': canViewLocation,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Copy dengan perubahan
  PatientFamilyLink copyWith({
    String? id,
    String? patientId,
    String? familyMemberId,
    String? relationshipType,
    bool? isPrimaryCaregiver,
    bool? canEditActivities,
    bool? canViewLocation,
    DateTime? createdAt,
    UserProfile? patientProfile,
    UserProfile? familyMemberProfile,
  }) {
    return PatientFamilyLink(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      familyMemberId: familyMemberId ?? this.familyMemberId,
      relationshipType: relationshipType ?? this.relationshipType,
      isPrimaryCaregiver: isPrimaryCaregiver ?? this.isPrimaryCaregiver,
      canEditActivities: canEditActivities ?? this.canEditActivities,
      canViewLocation: canViewLocation ?? this.canViewLocation,
      createdAt: createdAt ?? this.createdAt,
      patientProfile: patientProfile ?? this.patientProfile,
      familyMemberProfile: familyMemberProfile ?? this.familyMemberProfile,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PatientFamilyLink &&
        other.id == id &&
        other.patientId == patientId &&
        other.familyMemberId == familyMemberId &&
        other.relationshipType == relationshipType &&
        other.isPrimaryCaregiver == isPrimaryCaregiver &&
        other.canEditActivities == canEditActivities &&
        other.canViewLocation == canViewLocation &&
        other.createdAt == createdAt &&
        other.patientProfile == patientProfile &&
        other.familyMemberProfile == familyMemberProfile;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        patientId.hashCode ^
        familyMemberId.hashCode ^
        relationshipType.hashCode ^
        isPrimaryCaregiver.hashCode ^
        canEditActivities.hashCode ^
        canViewLocation.hashCode ^
        createdAt.hashCode ^
        patientProfile.hashCode ^
        familyMemberProfile.hashCode;
  }

  @override
  String toString() {
    return 'PatientFamilyLink(id: $id, patientId: $patientId, familyMemberId: $familyMemberId, '
        'relationshipType: $relationshipType, isPrimaryCaregiver: $isPrimaryCaregiver)';
  }
}

/// Helper class untuk relationship types yang umum
class RelationshipTypes {
  static const String child = 'anak';
  static const String parent = 'orang tua';
  static const String spouse = 'pasangan';
  static const String sibling = 'saudara';
  static const String grandparent = 'kakek/nenek';
  static const String grandchild = 'cucu';
  static const String other = 'lainnya';

  /// Daftar semua tipe relationship yang tersedia
  static const List<String> all = [
    child,
    parent,
    spouse,
    sibling,
    grandparent,
    grandchild,
    other,
  ];

  /// Get display label untuk relationship type
  static String getLabel(String type) {
    switch (type) {
      case child:
        return 'Anak';
      case parent:
        return 'Orang Tua';
      case spouse:
        return 'Pasangan';
      case sibling:
        return 'Saudara';
      case grandparent:
        return 'Kakek/Nenek';
      case grandchild:
        return 'Cucu';
      case other:
        return 'Lainnya';
      default:
        return type;
    }
  }
}

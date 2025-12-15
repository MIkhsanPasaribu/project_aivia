/// Model untuk orang yang dikenal (face recognition)
class KnownPerson {
  final String id;
  final String ownerId; // Patient ID yang memiliki database ini
  final String fullName;
  final String? relationship; // 'ibu', 'ayah', 'anak', 'teman', dll
  final String? bio; // Informasi tambahan untuk membantu mengingat
  final String photoUrl; // URL foto di Supabase Storage
  final List<double>? faceEmbedding; // 512-dim vector dari GhostFaceNet
  final DateTime? lastSeenAt; // Terakhir kali wajah dikenali
  final int recognitionCount; // Berapa kali wajah berhasil dikenali
  final DateTime createdAt;
  final DateTime updatedAt;

  final double? similarityScore; // Range [0, 1], null jika belum di-recognize

  const KnownPerson({
    required this.id,
    required this.ownerId,
    required this.fullName,
    this.relationship,
    this.bio,
    required this.photoUrl,
    this.faceEmbedding,
    this.lastSeenAt,
    this.recognitionCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.similarityScore, // ✅ FIX #4: Optional, only set during recognition
  });

  /// Create dari JSON (dari Supabase)
  factory KnownPerson.fromJson(Map<String, dynamic> json) {
    // Parse face_embedding dari PostgreSQL array/string format
    List<double>? embedding;
    if (json['face_embedding'] != null) {
      // PostgreSQL vector bisa return sebagai String "[0.1,0.2,...]" atau List
      final embeddingData = json['face_embedding'];
      if (embeddingData is String) {
        // Remove brackets dan parse
        final cleaned = embeddingData.replaceAll('[', '').replaceAll(']', '');
        embedding = cleaned
            .split(',')
            .map((e) => double.tryParse(e.trim()) ?? 0.0)
            .toList();
      } else if (embeddingData is List) {
        embedding = embeddingData
            .map((e) => (e as num?)?.toDouble() ?? 0.0)
            .toList();
      }
    }

    return KnownPerson(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      fullName: json['full_name'] as String,
      relationship: json['relationship'] as String?,
      bio: json['bio'] as String?,
      photoUrl: json['photo_url'] as String,
      faceEmbedding: embedding,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'] as String)
          : null,
      recognitionCount: json['recognition_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      similarityScore:
          json['similarity'] as double?,
    );
  }

  /// Convert ke JSON (untuk Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'full_name': fullName,
      'relationship': relationship,
      'bio': bio,
      'photo_url': photoUrl,
      // PostgreSQL vector format: "[0.1,0.2,0.3,...]"
      'face_embedding': faceEmbedding != null
          ? '[${faceEmbedding!.join(',')}]'
          : null,
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'recognition_count': recognitionCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with (untuk state management)
  KnownPerson copyWith({
    String? id,
    String? ownerId,
    String? fullName,
    String? relationship,
    String? bio,
    String? photoUrl,
    List<double>? faceEmbedding,
    DateTime? lastSeenAt,
    int? recognitionCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? similarityScore,
  }) {
    return KnownPerson(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      fullName: fullName ?? this.fullName,
      relationship: relationship ?? this.relationship,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      faceEmbedding: faceEmbedding ?? this.faceEmbedding,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      recognitionCount: recognitionCount ?? this.recognitionCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      similarityScore: similarityScore ?? this.similarityScore,
    );
  }

  /// Helper untuk display relationship
  String get displayRelationship {
    if (relationship == null || relationship!.isEmpty) {
      return 'Kenalan';
    }
    // Capitalize first letter
    return relationship![0].toUpperCase() + relationship!.substring(1);
  }

  /// Helper untuk last seen text
  String get lastSeenText {
    if (lastSeenAt == null) {
      return 'Belum pernah dilihat';
    }

    final now = DateTime.now();
    final difference = now.difference(lastSeenAt!);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks minggu yang lalu';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months bulan yang lalu';
    }
  }

  @override
  String toString() {
    return 'KnownPerson(id: $id, fullName: $fullName, relationship: $relationship, recognitionCount: $recognitionCount, similarityScore: $similarityScore)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is KnownPerson && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

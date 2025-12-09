import 'package:latlong2/latlong.dart';

/// Model untuk log face recognition
/// Setiap kali patient mencoba recognize face, akan dicatat di sini
class FaceRecognitionLog {
  final String id;
  final String patientId;
  final String? recognizedPersonId; // NULL jika wajah tidak dikenali
  final double?
  similarityScore; // Cosine similarity (0-1, higher = lebih mirip)
  final bool isRecognized; // TRUE jika score > threshold (0.85)
  final String? photoUrl; // URL foto yang di-capture saat recognition
  final LatLng? location; // Lokasi saat recognition dilakukan
  final DateTime timestamp;

  const FaceRecognitionLog({
    required this.id,
    required this.patientId,
    this.recognizedPersonId,
    this.similarityScore,
    required this.isRecognized,
    this.photoUrl,
    this.location,
    required this.timestamp,
  });

  /// Create dari JSON (dari Supabase)
  factory FaceRecognitionLog.fromJson(Map<String, dynamic> json) {
    // Parse location dari PostGIS POINT format
    LatLng? location;
    if (json['location'] != null) {
      try {
        // PostGIS format: "POINT(longitude latitude)" atau GeoJSON
        final locationData = json['location'];
        if (locationData is Map) {
          // GeoJSON format
          final coords = locationData['coordinates'] as List;
          location = LatLng(
            (coords[1] as num?)?.toDouble() ?? 0.0, // latitude
            (coords[0] as num?)?.toDouble() ?? 0.0, // longitude
          );
        } else if (locationData is String) {
          // POINT format
          final cleaned = locationData
              .replaceAll('POINT(', '')
              .replaceAll(')', '')
              .trim();
          final parts = cleaned.split(' ');
          if (parts.length == 2) {
            location = LatLng(
              double.parse(parts[1]), // latitude
              double.parse(parts[0]), // longitude
            );
          }
        }
      } catch (e) {
        // Ignore parsing errors
      }
    }

    return FaceRecognitionLog(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      recognizedPersonId: json['recognized_person_id'] as String?,
      similarityScore: json['similarity_score'] != null
          ? (json['similarity_score'] as num?)?.toDouble()
          : null,
      isRecognized: json['is_recognized'] as bool? ?? false,
      photoUrl: json['photo_url'] as String?,
      location: location,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convert ke JSON (untuk Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'recognized_person_id': recognizedPersonId,
      'similarity_score': similarityScore,
      'is_recognized': isRecognized,
      'photo_url': photoUrl,
      // PostGIS POINT format: "POINT(longitude latitude)"
      'location': location != null
          ? 'POINT(${location!.longitude} ${location!.latitude})'
          : null,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Helper untuk similarity percentage
  String get similarityPercentage {
    if (similarityScore == null) return '-';
    return '${(similarityScore! * 100).toStringAsFixed(1)}%';
  }

  /// Helper untuk status color
  String get statusText {
    return isRecognized ? 'Dikenali' : 'Tidak Dikenali';
  }

  @override
  String toString() {
    return 'FaceRecognitionLog(id: $id, isRecognized: $isRecognized, similarity: $similarityScore)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FaceRecognitionLog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

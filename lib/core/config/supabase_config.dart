import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Konfigurasi Supabase untuk aplikasi AIVIA
///
/// Kredensial dibaca dari file .env untuk keamanan.
/// Pastikan file .env sudah dibuat dari .env.example
class SupabaseConfig {
  SupabaseConfig._(); // Private constructor

  /// Supabase Project URL
  /// Dapatkan dari: Supabase Dashboard > Project Settings > API > Project URL
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception(
        'SUPABASE_URL tidak ditemukan di file .env. '
        'Pastikan file .env sudah dibuat dari .env.example',
      );
    }
    return url;
  }

  /// Supabase Anon Key (Public Key)
  /// Dapatkan dari: Supabase Dashboard > Project Settings > API > anon public
  /// Key ini aman untuk digunakan di client-side karena dilindungi Row Level Security (RLS)
  static String get supabaseAnonKey {
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception(
        'SUPABASE_ANON_KEY tidak ditemukan di file .env. '
        'Pastikan file .env sudah dibuat dari .env.example',
      );
    }
    return key;
  }

  /// Environment mode (development/production)
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';

  /// Check if running in production
  static bool get isProduction => environment == 'production';

  /// Check if running in development
  static bool get isDevelopment => environment == 'development';

  // Nama tabel database
  static const String tableProfiles = 'profiles';
  static const String tableActivities = 'activities';
  static const String tablePatientFamilyLinks = 'patient_family_links';
  static const String tableKnownPersons = 'known_persons';
  static const String tableLocations = 'locations';
  static const String tableEmergencyContacts = 'emergency_contacts';
  static const String tableEmergencyAlerts = 'emergency_alerts';
  static const String tableFcmTokens = 'fcm_tokens';

  // Nama bucket storage
  static const String bucketAvatars = 'avatars';
  static const String bucketKnownPersonsPhotos = 'known_persons_photos';
}

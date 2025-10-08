/// Konfigurasi Supabase untuk aplikasi AIVIA
class SupabaseConfig {
  SupabaseConfig._(); // Private constructor

  // TODO: Ganti dengan URL dan Key Supabase Anda
  // Untuk development, gunakan project Supabase development
  // Untuk production, gunakan project Supabase production
  
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

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

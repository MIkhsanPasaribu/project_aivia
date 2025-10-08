# Copilot Instructions - Aplikasi Asisten Alzheimer (AIVIA)

## Deskripsi Proyek

Aplikasi Android berbasis Flutter yang dirancang sebagai alat bantu khusus untuk anak-anak penderita penyakit Alzheimer. Aplikasi ini menyediakan fitur-fitur keamanan, pengingat aktivitas, pengenalan wajah, dan pelacakan lokasi untuk membantu pasien dan keluarga mereka.

---

## Arsitektur dan Teknologi

### Framework & Backend

- **Framework**: Flutter ^3.22.0
- **Backend**: Supabase (PostgreSQL)
- **Bahasa**: Dart
- **Platform Target**: Android (prioritas utama)

### Tumpukan Teknologi Utama

#### State Management

- `flutter_riverpod` ^2.5.1 - Manajemen state modern
- `riverpod_generator` ^2.4.0 - Code generation untuk provider
- `riverpod_annotation` - Anotasi untuk generator

#### Backend & Database

- `supabase_flutter` ^2.5.0 - Klien Supabase untuk Flutter
- PostgreSQL dengan Row Level Security (RLS)
- Supabase Auth untuk otentikasi
- Supabase Realtime untuk data real-time

#### Notifikasi & Background Services

- `awesome_notifications` ^0.9.3 - Notifikasi lokal dengan precise scheduling
- `flutter_background_geolocation` ^4.17.0 - Pelacakan lokasi latar belakang (PREMIUM)

#### Machine Learning (On-Device)

- `google_mlkit_face_detection` ^0.11.0 - Deteksi wajah
- `tflite_flutter` ^0.10.4 - Inferensi model TensorFlow Lite
- Model: GhostFaceNet untuk pengenalan wajah (embedding 512 dimensi)

#### Utilitas

- `camera` - Akses kamera
- `image_picker` - Galeri foto
- `permission_handler` - Manajemen izin runtime
- `geolocator` - Lokasi
- `flutter_map` atau `google_maps_flutter` - Tampilan peta

#### Testing

- `patrol` ^4.1.1 - E2E testing dengan native UI interaction
- `flutter_test` - Unit & widget testing
- `mockito` atau `mocktail` - Mocking untuk testing

---

## Struktur Folder Proyek

```
project_aivia/
├── lib/
│   ├── main.dart                          # Entry point aplikasi
│   │
│   ├── core/                              # Core functionality
│   │   ├── config/
│   │   │   ├── app_config.dart            # Konfigurasi aplikasi
│   │   │   ├── supabase_config.dart       # Konfigurasi Supabase
│   │   │   └── theme_config.dart          # Tema aplikasi
│   │   │
│   │   ├── constants/
│   │   │   ├── app_strings.dart           # String constants (ID)
│   │   │   ├── app_colors.dart            # Color constants
│   │   │   ├── app_dimensions.dart        # Spacing, sizes
│   │   │   └── app_routes.dart            # Route names
│   │   │
│   │   ├── errors/
│   │   │   ├── exceptions.dart            # Custom exceptions
│   │   │   └── failures.dart              # Failure classes
│   │   │
│   │   ├── utils/
│   │   │   ├── date_formatter.dart        # Format tanggal
│   │   │   ├── validators.dart            # Input validation
│   │   │   └── permission_helper.dart     # Helper izin
│   │   │
│   │   └── extensions/
│   │       ├── context_extension.dart     # BuildContext extensions
│   │       └── datetime_extension.dart    # DateTime extensions
│   │
│   ├── data/                              # Data layer
│   │   ├── models/
│   │   │   ├── user_profile.dart          # Model profil user
│   │   │   ├── activity.dart              # Model aktivitas
│   │   │   ├── known_person.dart          # Model orang dikenal
│   │   │   ├── location.dart              # Model lokasi
│   │   │   ├── emergency_contact.dart     # Model kontak darurat
│   │   │   └── patient_family_link.dart   # Model relasi pasien-keluarga
│   │   │
│   │   ├── repositories/
│   │   │   ├── auth_repository.dart       # Repository autentikasi
│   │   │   ├── activity_repository.dart   # Repository aktivitas
│   │   │   ├── location_repository.dart   # Repository lokasi
│   │   │   ├── person_repository.dart     # Repository orang dikenal
│   │   │   └── emergency_repository.dart  # Repository darurat
│   │   │
│   │   └── services/
│   │       ├── supabase_service.dart      # Service Supabase
│   │       ├── notification_service.dart  # Service notifikasi lokal
│   │       ├── location_service.dart      # Service pelacakan lokasi
│   │       └── face_recognition_service.dart # Service ML face recognition
│   │
│   ├── domain/                            # Business logic layer
│   │   ├── entities/                      # Entitas domain (jika diperlukan)
│   │   │
│   │   └── usecases/
│   │       ├── auth/
│   │       │   ├── login_usecase.dart
│   │       │   ├── register_usecase.dart
│   │       │   └── logout_usecase.dart
│   │       │
│   │       ├── activity/
│   │       │   ├── create_activity_usecase.dart
│   │       │   ├── update_activity_usecase.dart
│   │       │   ├── delete_activity_usecase.dart
│   │       │   └── get_activities_usecase.dart
│   │       │
│   │       └── emergency/
│   │           └── trigger_emergency_usecase.dart
│   │
│   ├── presentation/                      # Presentation layer
│   │   ├── providers/                     # Riverpod providers
│   │   │   ├── auth_provider.dart
│   │   │   ├── activity_provider.dart
│   │   │   ├── location_provider.dart
│   │   │   ├── person_provider.dart
│   │   │   └── emergency_provider.dart
│   │   │
│   │   ├── screens/
│   │   │   ├── splash/
│   │   │   │   └── splash_screen.dart
│   │   │   │
│   │   │   ├── auth/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── register_screen.dart
│   │   │   │
│   │   │   ├── patient/                   # UI untuk Pasien
│   │   │   │   ├── patient_home_screen.dart
│   │   │   │   ├── activity/
│   │   │   │   │   ├── activity_list_screen.dart
│   │   │   │   │   └── activity_detail_screen.dart
│   │   │   │   │
│   │   │   │   ├── face_recognition/
│   │   │   │   │   └── recognize_face_screen.dart
│   │   │   │   │
│   │   │   │   └── emergency/
│   │   │   │       └── emergency_button_widget.dart
│   │   │   │
│   │   │   ├── family/                    # UI untuk Keluarga/Wali
│   │   │   │   ├── family_home_screen.dart
│   │   │   │   ├── dashboard/
│   │   │   │   │   └── dashboard_screen.dart
│   │   │   │   │
│   │   │   │   ├── patient_tracking/
│   │   │   │   │   └── patient_map_screen.dart
│   │   │   │   │
│   │   │   │   ├── activity_management/
│   │   │   │   │   ├── manage_activities_screen.dart
│   │   │   │   │   ├── add_activity_screen.dart
│   │   │   │   │   └── edit_activity_screen.dart
│   │   │   │   │
│   │   │   │   └── known_persons/
│   │   │   │       ├── persons_list_screen.dart
│   │   │   │       ├── add_person_screen.dart
│   │   │   │       └── edit_person_screen.dart
│   │   │   │
│   │   │   └── admin/                     # UI untuk Admin (opsional)
│   │   │       └── admin_dashboard_screen.dart
│   │   │
│   │   ├── widgets/                       # Reusable widgets
│   │   │   ├── common/
│   │   │   │   ├── custom_button.dart
│   │   │   │   ├── custom_text_field.dart
│   │   │   │   ├── loading_indicator.dart
│   │   │   │   ├── error_widget.dart
│   │   │   │   └── bottom_nav_bar.dart
│   │   │   │
│   │   │   ├── activity/
│   │   │   │   ├── activity_card.dart
│   │   │   │   └── activity_form.dart
│   │   │   │
│   │   │   └── person/
│   │   │       └── person_card.dart
│   │   │
│   │   └── routes/
│   │       └── app_router.dart            # Routing (go_router recommended)
│   │
│   └── generated/                         # Generated files
│       └── *.g.dart                       # Riverpod & JSON serialization
│
├── assets/
│   ├── fonts/
│   │   ├── poppins_regular.ttf
│   │   ├── poppins_medium.ttf
│   │   ├── poppins_semibold.ttf
│   │   └── poppins_bold.ttf
│   │
│   ├── images/
│   │   ├── logo.png
│   │   ├── logo_noname.png
│   │   └── placeholder_avatar.png
│   │
│   └── ml_models/
│       └── ghostfacenet.tflite            # Model face recognition
│
├── test/
│   ├── unit/                              # Unit tests
│   ├── widget/                            # Widget tests
│   └── integration/                       # Integration tests (Patrol)
│
├── integration_test/                      # E2E tests dengan Patrol
│
├── android/                               # Android native config
├── ios/                                   # iOS native config (future)
│
├── supabase/                              # Supabase configuration
│   ├── migrations/                        # Database migrations
│   │   ├── 001_initial_schema.sql
│   │   ├── 002_add_rls_policies.sql
│   │   └── 003_create_functions.sql
│   │
│   ├── functions/                         # Edge Functions
│   │   └── send-emergency-notification/
│   │       └── index.ts
│   │
│   └── config.toml                        # Supabase config
│
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                         # CI workflow
│   │   ├── deploy_staging.yml             # Deploy ke staging
│   │   └── deploy_production.yml          # Deploy ke production
│   │
│   └── copilot-instructions.md            # File ini
│
├── docs/                                  # Dokumentasi proyek
│
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

## Skema Database (PostgreSQL/Supabase)

### Tabel Utama

#### 1. `profiles` (public.profiles)

Tabel profil pengguna dengan relasi 1:1 ke `auth.users`.

```sql
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  user_role TEXT NOT NULL CHECK (user_role IN ('patient', 'family', 'admin')),
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Family members can view linked patients
CREATE POLICY "Family can view linked patients"
  ON public.profiles FOR SELECT
  USING (
    id IN (
      SELECT patient_id FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  );
```

#### 2. `patient_family_links`

Tabel relasi many-to-many antara pasien dan keluarga.

```sql
CREATE TABLE public.patient_family_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  family_member_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  relationship_type TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(patient_id, family_member_id)
);

-- RLS Policies
ALTER TABLE public.patient_family_links ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own links"
  ON public.patient_family_links FOR SELECT
  USING (auth.uid() = patient_id OR auth.uid() = family_member_id);
```

#### 3. `activities`

Tabel jurnal aktivitas harian.

```sql
CREATE TABLE public.activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  activity_time TIMESTAMPTZ NOT NULL,
  reminder_sent BOOLEAN DEFAULT FALSE,
  is_completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  pickup_by_profile_id UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index untuk performa
CREATE INDEX idx_activities_patient_time ON public.activities(patient_id, activity_time);

-- RLS Policies
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;

-- Patients can view their own activities
CREATE POLICY "Patients view own activities"
  ON public.activities FOR SELECT
  USING (auth.uid() = patient_id);

-- Family members can manage linked patient's activities
CREATE POLICY "Family manage patient activities"
  ON public.activities FOR ALL
  USING (
    patient_id IN (
      SELECT patient_id FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  );
```

#### 4. `known_persons`

Tabel untuk fitur pengenalan wajah.

```sql
-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE public.known_persons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  relationship TEXT,
  bio TEXT,
  photo_url TEXT,
  face_embedding vector(512), -- GhostFaceNet embedding
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- HNSW index untuk pencarian vector cepat
CREATE INDEX ON public.known_persons
  USING hnsw (face_embedding vector_cosine_ops);

-- RLS Policies
ALTER TABLE public.known_persons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Owners can manage their known persons"
  ON public.known_persons FOR ALL
  USING (auth.uid() = owner_id);

-- Function untuk mencari wajah
CREATE OR REPLACE FUNCTION find_known_person(
  query_embedding vector(512),
  user_id UUID
)
RETURNS TABLE (
  id UUID,
  full_name TEXT,
  relationship TEXT,
  bio TEXT,
  photo_url TEXT,
  similarity FLOAT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    kp.id,
    kp.full_name,
    kp.relationship,
    kp.bio,
    kp.photo_url,
    1 - (kp.face_embedding <=> query_embedding) AS similarity
  FROM public.known_persons kp
  WHERE kp.owner_id = user_id
  ORDER BY kp.face_embedding <=> query_embedding
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### 5. `locations`

Tabel pelacakan lokasi historis.

```sql
-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE public.locations (
  id BIGSERIAL PRIMARY KEY,
  patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  coordinates GEOGRAPHY(POINT, 4326) NOT NULL,
  accuracy FLOAT,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Index untuk performa query geospasial
CREATE INDEX idx_locations_patient ON public.locations(patient_id);
CREATE INDEX idx_locations_coords ON public.locations USING GIST(coordinates);
CREATE INDEX idx_locations_time ON public.locations(timestamp);

-- RLS Policies
ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;

-- Patients can insert their own location
CREATE POLICY "Patients insert own location"
  ON public.locations FOR INSERT
  WITH CHECK (auth.uid() = patient_id);

-- Family members can view linked patient's location
CREATE POLICY "Family view patient location"
  ON public.locations FOR SELECT
  USING (
    patient_id IN (
      SELECT patient_id FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  );
```

#### 6. `emergency_contacts`

Tabel kontak darurat.

```sql
CREATE TABLE public.emergency_contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  contact_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  priority INTEGER DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(patient_id, contact_id)
);

-- RLS Policies
ALTER TABLE public.emergency_contacts ENABLE ROW LEVEL SECURITY;
```

#### 7. `emergency_alerts`

Tabel untuk log peringatan darurat.

```sql
CREATE TABLE public.emergency_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  location GEOGRAPHY(POINT, 4326),
  message TEXT,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'resolved')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

-- RLS Policies
ALTER TABLE public.emergency_alerts ENABLE ROW LEVEL SECURITY;
```

#### 8. `fcm_tokens`

Tabel untuk Firebase Cloud Messaging tokens.

```sql
CREATE TABLE public.fcm_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  device_info TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, token)
);

-- RLS Policies
ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;
```

### Triggers & Functions

#### Auto-create profile on user signup

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, user_role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
    COALESCE(NEW.raw_user_meta_data->>'user_role', 'patient')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
```

#### Update timestamp trigger

```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to tables
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_activities_updated_at
  BEFORE UPDATE ON public.activities
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_known_persons_updated_at
  BEFORE UPDATE ON public.known_persons
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

---

## Panduan Implementasi Fitur

### 1. Splash Screen & Onboarding

**Tujuan**: Tampilan awal aplikasi dengan logo dan loading state.

**Implementasi**:

- Cek status autentikasi menggunakan `Supabase.instance.client.auth.currentSession`
- Jika ada session → arahkan ke home sesuai role
- Jika tidak ada → arahkan ke halaman login
- Durasi splash: 2-3 detik

**Widget**: `SplashScreen` di `lib/presentation/screens/splash/`

### 2. Autentikasi (Login & Register)

**Tujuan**: Sistem autentikasi dengan validasi dan role-based access.

**Fitur**:

- **Register**: Email, password, nama lengkap, pilihan role (patient/family)
- **Login**: Email dan password
- **Validasi**: Email format, password min 8 karakter
- **Error Handling**: Tampilkan pesan error dalam bahasa Indonesia

**Implementasi**:

```dart
// Register
final response = await supabase.auth.signUp(
  email: email,
  password: password,
  data: {
    'full_name': fullName,
    'user_role': role,
  },
);

// Login
final response = await supabase.auth.signInWithPassword(
  email: email,
  password: password,
);

// Get user role
final profile = await supabase
  .from('profiles')
  .select('user_role')
  .eq('id', user.id)
  .single();
```

**UI Strings (Bahasa Indonesia)**:

- "Masuk ke Akun Anda"
- "Daftar Akun Baru"
- "Email"
- "Kata Sandi"
- "Nama Lengkap"
- "Peran: Pasien / Keluarga"
- "Masuk"
- "Daftar"
- "Belum punya akun? Daftar di sini"
- "Sudah punya akun? Masuk di sini"

### 3. Navigation (Bottom Navigation Bar)

**Tujuan**: Navigasi utama aplikasi berbeda untuk setiap role.

**Untuk Pasien**:

1. **Beranda** (Jurnal Aktivitas)
2. **Kenali Wajah** (Face Recognition)
3. **Profil**

**Untuk Keluarga**:

1. **Dashboard** (Overview)
2. **Lokasi Pasien** (Map)
3. **Kelola Aktivitas**
4. **Orang Dikenal**
5. **Profil**

**Implementasi**:

- Gunakan `IndexedStack` untuk maintain state
- Icon dengan label bahasa Indonesia
- Warna aktif/non-aktif sesuai tema

### 4. Jurnal Aktivitas (CRUD Utama)

**Tujuan**: Fitur inti untuk mengelola aktivitas harian pasien.

#### A. READ (Tampilkan Daftar)

**Provider (Riverpod)**:

```dart
@riverpod
Stream<List<Activity>> activitiesStream(
  ActivitiesStreamRef ref,
  String patientId,
) {
  return supabase
    .from('activities')
    .stream(primaryKey: ['id'])
    .eq('patient_id', patientId)
    .order('activity_time')
    .map((maps) => maps.map((m) => Activity.fromJson(m)).toList());
}
```

**UI**:

- ListView/GridView dengan kartu aktivitas
- Tampilkan: Judul, deskripsi, waktu, status (selesai/belum)
- Pull-to-refresh
- Filter: Hari ini / Minggu ini / Semua

#### B. CREATE (Tambah Aktivitas)

**Form Fields**:

- Judul aktivitas (TextField)
- Deskripsi (TextField multiline)
- Waktu & tanggal (DateTimePicker)
- Tombol: "Simpan" dan "Batal"

**Implementasi**:

```dart
Future<void> addActivity(Activity activity) async {
  await supabase.from('activities').insert(activity.toJson());

  // Schedule local notification
  await _scheduleNotification(activity);
}
```

#### C. UPDATE (Edit Aktivitas)

**UI**: Form yang sama dengan CREATE, pre-filled dengan data existing.

**Implementasi**:

```dart
Future<void> updateActivity(String id, Activity activity) async {
  await supabase
    .from('activities')
    .update(activity.toJson())
    .eq('id', id);

  // Reschedule notification
  await _updateNotification(activity);
}
```

#### D. DELETE (Hapus Aktivitas)

**UI**: Swipe-to-delete atau tombol hapus dengan konfirmasi dialog.

**Implementasi**:

```dart
Future<void> deleteActivity(String id) async {
  await supabase.from('activities').delete().eq('id', id);

  // Cancel notification
  await AwesomeNotifications().cancel(id.hashCode);
}
```

### 5. Notifikasi Lokal (Pengingat Aktivitas)

**Tujuan**: Mengingatkan pasien tentang aktivitas yang akan datang.

**Setup** (`notification_service.dart`):

```dart
class NotificationService {
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      'resource://drawable/ic_notification',
      [
        NotificationChannel(
          channelKey: 'activity_reminders',
          channelName: 'Pengingat Aktivitas',
          channelDescription: 'Notifikasi untuk aktivitas harian',
          defaultColor: Colors.blue,
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
      ],
    );
  }

  static Future<void> scheduleActivityReminder(Activity activity) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: activity.id.hashCode,
        channelKey: 'activity_reminders',
        title: 'Pengingat: ${activity.title}',
        body: activity.description ?? 'Saatnya untuk melakukan aktivitas ini',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar.fromDate(
        date: activity.activityTime.subtract(Duration(minutes: 15)),
        preciseAlarm: true, // Penting untuk Android 12+
      ),
    );
  }
}
```

**Permissions**: Request `SCHEDULE_EXACT_ALARM` untuk Android 13+.

### 6. Pelacakan Lokasi Background

**Tujuan**: Melacak lokasi pasien secara real-time di background.

**Setup** (`location_service.dart`):

```dart
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;

class LocationService {
  static Future<void> initialize() async {
    await bg.BackgroundGeolocation.ready(
      bg.Config(
        desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
        distanceFilter: 15.0,
        stopOnTerminate: false,
        startOnBoot: true,
        enableHeadless: true,
        foregroundService: true,
        notification: bg.Notification(
          title: "AIVIA Pelacakan Aktif",
          text: "Aplikasi melacak lokasi Anda untuk keamanan",
        ),
      ),
    );

    // Event listener
    bg.BackgroundGeolocation.onLocation(_onLocation);
  }

  static void _onLocation(bg.Location location) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await Supabase.instance.client.from('locations').insert({
      'patient_id': user.id,
      'coordinates': 'POINT(${location.coords.longitude} ${location.coords.latitude})',
      'accuracy': location.coords.accuracy,
    });
  }

  static Future<void> start() async {
    await bg.BackgroundGeolocation.start();
  }

  static Future<void> stop() async {
    await bg.BackgroundGeolocation.stop();
  }
}
```

**Permissions**:

- `ACCESS_FINE_LOCATION`
- `ACCESS_BACKGROUND_LOCATION` (Android 10+)
- Prompt user untuk "Allow all the time"

### 7. Tombol Darurat

**Tujuan**: Tombol panic yang mengirim alert ke kontak darurat.

**UI**:

- Floating Action Button berwarna merah
- Icon: `Icons.emergency` atau `Icons.warning`
- Posisi: Bottom-right, selalu visible
- Konfirmasi: Long press atau dialog konfirmasi

**Implementasi**:

```dart
Future<void> triggerEmergency() async {
  // Get current location
  final position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );

  final user = supabase.auth.currentUser!;

  // Insert emergency alert
  await supabase.from('emergency_alerts').insert({
    'patient_id': user.id,
    'location': 'POINT(${position.longitude} ${position.latitude})',
    'message': 'Peringatan Darurat!',
    'status': 'active',
  });

  // Webhook akan trigger Edge Function untuk kirim notifikasi push
}
```

**Edge Function** (Supabase):

```typescript
// supabase/functions/send-emergency-notification/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

serve(async (req) => {
  const { patient_id, location } = await req.json();

  // Get emergency contacts
  const { data: contacts } = await supabase
    .from("emergency_contacts")
    .select("contact_id, fcm_tokens(token)")
    .eq("patient_id", patient_id);

  // Send FCM notifications
  for (const contact of contacts) {
    await sendFCM(contact.token, {
      title: "PERINGATAN DARURAT!",
      body: `Pasien membutuhkan bantuan segera!`,
      data: { patient_id, location },
    });
  }

  return new Response(JSON.stringify({ success: true }));
});
```

### 8. Pengenalan Wajah (Face Recognition)

**Tujuan**: Membantu pasien mengenali wajah orang-orang terdekat.

#### A. Tambah Orang Dikenal (oleh Keluarga)

**Flow**:

1. Keluarga buka form "Tambah Orang Dikenal"
2. Input: Nama, hubungan, bio, foto (dari kamera/galeri)
3. Proses foto:
   - Deteksi wajah dengan `google_mlkit_face_detection`
   - Crop wajah
   - Generate embedding dengan TFLite (GhostFaceNet)
4. Upload foto ke Supabase Storage
5. Simpan data + embedding ke tabel `known_persons`

**Implementasi**:

```dart
class FaceRecognitionService {
  final _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  late Interpreter _interpreter;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/ml_models/ghostfacenet.tflite');
  }

  Future<List<double>> generateEmbedding(File imageFile) async {
    // 1. Detect face
    final inputImage = InputImage.fromFile(imageFile);
    final faces = await _faceDetector.processImage(inputImage);

    if (faces.isEmpty) throw Exception('Tidak ada wajah terdeteksi');

    // 2. Crop face
    final img.Image? image = img.decodeImage(imageFile.readAsBytesSync());
    final face = faces.first;
    final croppedFace = img.copyCrop(
      image!,
      face.boundingBox.left.toInt(),
      face.boundingBox.top.toInt(),
      face.boundingBox.width.toInt(),
      face.boundingBox.height.toInt(),
    );

    // 3. Preprocess
    final resized = img.copyResize(croppedFace, width: 112, height: 112);
    final input = _imageToByteListFloat32(resized);

    // 4. Run inference
    final output = List.filled(512, 0.0).reshape([1, 512]);
    _interpreter.run(input, output);

    return output[0];
  }
}
```

#### B. Kenali Wajah (oleh Pasien)

**Flow**:

1. Pasien buka kamera "Kenali Wajah"
2. Deteksi wajah di setiap frame
3. Generate embedding
4. Query database untuk cari kecocokan
5. Tampilkan info orang jika similarity > threshold (0.85)

**Implementasi**:

```dart
Future<KnownPerson?> recognizeFace(File imageFile) async {
  // Generate embedding
  final embedding = await generateEmbedding(imageFile);

  // Query Supabase
  final result = await supabase.rpc(
    'find_known_person',
    params: {
      'query_embedding': embedding,
      'user_id': supabase.auth.currentUser!.id,
    },
  ).single();

  if (result['similarity'] > 0.85) {
    return KnownPerson.fromJson(result);
  }

  return null;
}
```

**UI**:

- Camera preview dengan overlay
- Kotak deteksi wajah
- Jika dikenali: Tampilkan kartu dengan foto, nama, hubungan, bio
- Tombol "Tutup" atau "Cari Lagi"

---

## Desain UI/UX Guidelines

### Prinsip untuk Pasien (Cognitive Impairment)

1. **Kesederhanaan**:

   - Satu fokus per layar
   - Minimal 3-4 menu utama
   - Hindari dropdown/menu tersembunyi

2. **Tipografi**:

   - Font: Poppins (sudah tersedia)
   - Ukuran minimum: 18sp untuk body, 24sp untuk heading
   - Contrast ratio: minimum 7:1 (AAA level)

3. **Warna**:

   - Gunakan warna konsisten untuk aksi yang sama
   - Darurat: Merah (#D32F2F)
   - Sukses: Hijau (#388E3C)
   - Primary: Biru (#1976D2)
   - Hindari warna sebagai satu-satunya indikator

4. **Button & Touch Targets**:

   - Ukuran minimum: 48x48dp
   - Spacing antar elemen: minimum 16dp
   - Gunakan elevation/shadow untuk depth

5. **Feedback**:
   - Setiap aksi harus ada feedback visual
   - Loading indicator untuk proses async
   - Haptic feedback untuk tombol penting
   - Konfirmasi dialog untuk aksi destruktif

### Prinsip untuk Keluarga

1. **Information Density**:

   - Boleh lebih padat informasi
   - Dashboard dengan multiple widgets
   - Grafik/chart untuk tracking

2. **Efficiency**:
   - Quick actions
   - Batch operations
   - Search & filter

### Color Palette (Palette Warna Resmi Aplikasi)

Pallet warna aplikasi dirancang khusus untuk pengguna dengan gangguan kognitif, dengan fokus pada warna yang menenangkan dan kontras yang baik untuk keterbacaan.

| Jenis Warna    | Warna         | Hex Code  | Makna Psikologis                                   |
| -------------- | ------------- | --------- | -------------------------------------------------- |
| **Primary**    | Sky Blue      | `#A8DADC` | Warna lembut dan menenangkan, mengurangi kecemasan |
| **Secondary**  | Soft Green    | `#B7E4C7` | Menyimbolkan kehidupan dan keseimbangan            |
| **Accent**     | Warm Sand     | `#F6E7CB` | Hangat dan familiar, membantu rasa aman            |
| **Text**       | Charcoal Gray | `#333333` | Kontras cukup tinggi tapi tidak menyilaukan        |
| **Background** | Ivory White   | `#FFFDF5` | Cerah, lembut, dan tidak membuat mata lelah        |

**Implementasi di Flutter** (`lib/core/constants/app_colors.dart`):

```dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Sky Blue (Menenangkan)
  static const Color primary = Color(0xFFA8DADC);
  static const Color primaryLight = Color(0xFFD4F1F4);
  static const Color primaryDark = Color(0xFF7DBEC1);

  // Secondary Colors - Soft Green (Keseimbangan)
  static const Color secondary = Color(0xFFB7E4C7);
  static const Color secondaryLight = Color(0xFFDBF3E5);
  static const Color secondaryDark = Color(0xFF8FD4A5);

  // Accent Colors - Warm Sand (Hangat & Aman)
  static const Color accent = Color(0xFFF6E7CB);
  static const Color accentLight = Color(0xFFFFF5E1);
  static const Color accentDark = Color(0xFFE6D4A8);

  // Text Colors - Charcoal Gray (Kontras Tinggi)
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);

  // Background - Ivory White (Lembut)
  static const Color background = Color(0xFFFFFDF5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8F6ED);

  // Semantic Colors (Status & Feedback)
  static const Color success = Color(0xFF81C784); // Hijau lembut
  static const Color warning = Color(0xFFFFB74D); // Orange lembut
  static const Color error = Color(0xFFE57373); // Merah lembut
  static const Color info = Color(0xFF64B5F6); // Biru info lembut

  // Emergency - Lebih mencolok untuk perhatian
  static const Color emergency = Color(0xFFD32F2F);
  static const Color emergencyLight = Color(0xFFEF5350);

  // Utility
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x1A000000);
  static const Color disabled = Color(0xFFBDBDBD);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
```

**Catatan Penting**:

- Semua warna telah dioptimalkan untuk aksesibilitas (WCAG AA compliance)
- Contrast ratio minimum 4.5:1 untuk teks normal
- Contrast ratio minimum 7:1 untuk teks besar
- Hindari penggunaan warna sebagai satu-satunya cara menyampaikan informasi

---

## Testing Strategy

### 1. Unit Tests

- Repository methods
- Use cases
- Utility functions
- Validators

### 2. Widget Tests

- Individual widgets
- Forms dengan validasi
- List items
- State changes

### 3. Integration Tests dengan Patrol

**Test Scenarios**:

1. **Onboarding & Permissions**:

   - Install aplikasi
   - Grant location permission
   - Grant camera permission
   - Login flow

2. **Activity CRUD**:

   - Tambah aktivitas
   - Edit aktivitas
   - Hapus aktivitas
   - Verifikasi notifikasi scheduled

3. **Emergency Flow**:

   - Trigger emergency button
   - Verify data di database
   - Check notification received (mock)

4. **Background Location**:
   - Start tracking
   - Move to background
   - Verify location updates

**Example Test**:

```dart
void main() {
  patrolTest(
    'Login and add activity',
    ($) async {
      // Start app
      await $.pumpWidgetAndSettle(const MyApp());

      // Login
      await $(#emailField).enterText('test@example.com');
      await $(#passwordField).enterText('password123');
      await $(#loginButton).tap();

      // Navigate to add activity
      await $(#addActivityFab).tap();

      // Fill form
      await $(#activityTitleField).enterText('Makan Siang');
      await $(#activityDescField).enterText('Jangan lupa minum obat');
      await $(#saveButton).tap();

      // Verify
      expect($(text: 'Makan Siang'), findsOneWidget);
    },
  );
}
```

---

## CI/CD Pipeline

### GitHub Actions Workflows

#### 1. CI (Pull Request)

```yaml
name: CI
on: pull_request

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
```

#### 2. Deploy Staging (develop branch)

```yaml
name: Deploy Staging
on:
  push:
    branches: [develop]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2

      # Build
      - run: flutter build apk --debug

      # Deploy to Firebase App Distribution
      - uses: wzieba/Firebase-Distribution-Github-Action@v1
        with:
          appId: ${{ secrets.FIREBASE_APP_ID }}
          token: ${{ secrets.FIREBASE_TOKEN }}
          groups: testers
          file: build/app/outputs/flutter-apk/app-debug.apk
```

#### 3. Deploy Production (main branch)

```yaml
name: Deploy Production
on:
  push:
    tags:
      - "v*"

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2

      # Build release
      - run: flutter build appbundle --release

      # Upload to Play Store
      # (Requires setup dengan service account)
```

---

## Environment Configuration

### Supabase Configuration

**Development**:

```dart
const supabaseUrl = 'https://xxxxx.supabase.co';
const supabaseAnonKey = 'eyJxxxx...';
```

**Production**:

- Gunakan environment variables
- Separate Supabase projects untuk staging & production
- Secrets di GitHub Actions

### Environment Files

`.env.development`:

```
SUPABASE_URL=https://dev-xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJxxxx...
```

`.env.production`:

```
SUPABASE_URL=https://prod-xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJxxxx...
```

---

## Security Checklist

### Pre-Production

- [ ] Semua tabel memiliki RLS enabled
- [ ] Semua kebijakan RLS di-review dan tested
- [ ] SSL enforcement aktif di Supabase
- [ ] Network restrictions configured
- [ ] MFA enabled untuk Supabase org members
- [ ] Email confirmation required untuk signup
- [ ] Rate limiting pada auth endpoints
- [ ] Secrets tidak hardcoded di code
- [ ] ProGuard/R8 enabled untuk release build
- [ ] Certificate pinning (optional, advanced)

### Database

- [ ] Index pada foreign keys
- [ ] Index pada kolom yang sering di-query
- [ ] HNSW index pada face_embedding
- [ ] Backup policy configured
- [ ] Point-in-time recovery enabled

### Privacy & Compliance

- [ ] Privacy policy dibuat dan accessible
- [ ] User consent untuk location tracking
- [ ] User consent untuk camera/photos
- [ ] Data retention policy
- [ ] GDPR compliance (jika applicable)

---

## Performance Optimization

### Flutter App

1. **Lazy Loading**: Load data on-demand
2. **Pagination**: Limit query results
3. **Image Optimization**: Compress uploads, use cached_network_image
4. **Debouncing**: Search inputs, autocomplete
5. **Code Splitting**: Deferred loading untuk fitur yang jarang dipakai

### Database

1. **Indexes**: Pastikan query plans optimal
2. **Connection Pooling**: Gunakan pgBouncer di production
3. **Materialized Views**: Untuk data aggregation yang kompleks
4. **Partitioning**: locations table by time (jika data sangat besar)

### ML Model

1. **Quantization**: Gunakan model quantized (int8) untuk speed
2. **Caching**: Cache embeddings yang baru di-generate
3. **Batch Processing**: Process multiple faces di satu go

---

## Monitoring & Analytics

### Error Tracking

- Sentry atau Firebase Crashlytics
- Log semua exceptions
- Track user journey saat crash

### Performance Monitoring

- Firebase Performance Monitoring
- Track screen load times
- Track API latency

### Usage Analytics

- Firebase Analytics atau Mixpanel
- Track feature usage
- Track user retention
- Funnel analysis (signup → first activity)

---

## Deployment Checklist

### Pre-Launch

- [ ] Semua fitur CRUD tested
- [ ] Background location tested di multiple devices
- [ ] Notifikasi tested di Android 12+
- [ ] Face recognition accuracy validated
- [ ] Emergency flow tested end-to-end
- [ ] RLS policies validated
- [ ] Performance benchmarks met
- [ ] Security audit completed
- [ ] Privacy policy published
- [ ] App store assets ready (screenshots, description)

### Launch

- [ ] Deploy database migrations
- [ ] Deploy Edge Functions
- [ ] Build & sign release APK/AAB
- [ ] Upload to Play Store
- [ ] Submit for review
- [ ] Monitor crash reports
- [ ] Monitor server resources

### Post-Launch

- [ ] User feedback collection
- [ ] Bug triage & fixes
- [ ] Performance monitoring
- [ ] Feature usage analysis
- [ ] Plan for next iteration

---

## Panduan untuk Copilot

Saat membantu pengembangan aplikasi ini:

1. **Bahasa UI**: Selalu gunakan Bahasa Indonesia untuk semua string UI, label, pesan error, dan konten user-facing.

2. **Naming Convention**:

   - Dart: `camelCase` untuk variables/functions, `PascalCase` untuk classes
   - SQL: `snake_case` untuk tables/columns
   - Files: `snake_case.dart`

3. **State Management**: Prioritaskan Riverpod dengan code generation (@riverpod annotation).

4. **Data Flow**:

   - UI → Provider → Repository → Supabase
   - Stream data langsung dari Supabase ke UI via StreamProvider

5. **Error Handling**:

   - Gunakan `Result<T>` pattern atau `AsyncValue<T>` dari Riverpod
   - Tampilkan pesan error yang user-friendly dalam bahasa Indonesia
   - Log error untuk debugging

6. **Security-First**:

   - Selalu pertimbangkan RLS policies
   - Jangan bypass security di client side
   - Validasi input di client DAN server (RLS)

7. **Accessibility**:

   - Semantics untuk screen readers
   - High contrast colors
   - Large touch targets
   - Simple navigation untuk pasien

8. **Code Quality**:

   - Follow analysis_options.yaml
   - Write tests untuk business logic
   - Document complex algorithms
   - Keep functions small & focused

9. **Performance**:

   - Lazy load heavy resources (ML models)
   - Optimize images
   - Use const constructors
   - Avoid rebuilding entire trees

10. **Dependencies**:
    - Prefer official/well-maintained packages
    - Check license compatibility
    - Lock versions di pubspec.yaml

---

## Resources & Documentation

### Official Docs

- [Flutter Docs](https://docs.flutter.dev/)
- [Supabase Flutter](https://supabase.com/docs/reference/dart/introduction)
- [Riverpod](https://riverpod.dev/)
- [PostgreSQL](https://www.postgresql.org/docs/)

### Packages

- [awesome_notifications](https://pub.dev/packages/awesome_notifications)
- [flutter_background_geolocation](https://github.com/transistorsoft/flutter_background_geolocation)
- [google_mlkit_face_detection](https://pub.dev/packages/google_mlkit_face_detection)
- [tflite_flutter](https://pub.dev/packages/tflite_flutter)
- [patrol](https://patrol.leancode.co/)

### ML Models

- [GhostFaceNet](https://github.com/HuangJunJie2017/GhostFaceNets)
- [MobileFaceNet](https://github.com/sirius-ai/MobileFaceNet_TF)

### Design Guidelines

- [Material Design 3](https://m3.material.io/)
- [Accessibility Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)

---

## Glossary (Istilah Penting)

- **RLS**: Row Level Security - Keamanan tingkat baris di PostgreSQL
- **Embedding**: Representasi vektor numerik dari wajah untuk ML
- **Provider**: Objek Riverpod yang menyediakan state/data
- **FCM**: Firebase Cloud Messaging untuk push notifications
- **Edge Function**: Serverless function di Supabase (Deno runtime)
- **CRUD**: Create, Read, Update, Delete
- **E2E**: End-to-End testing
- **CI/CD**: Continuous Integration/Continuous Deployment

---

## Notes untuk Pengembangan Iteratif

### MVP (Minimum Viable Product) - Phase 1

- [x] Splash Screen
- [x] Login & Register
- [x] Bottom Navigation
- [x] Jurnal Aktivitas (CRUD)
- [x] Notifikasi Lokal
- [ ] Profil User

### Phase 2

- [ ] Pelacakan Lokasi Background
- [ ] Tombol Darurat
- [ ] Map View untuk Keluarga
- [ ] Emergency Notifications

### Phase 3

- [ ] Face Recognition (Add Known Persons)
- [ ] Face Recognition (Recognize)
- [ ] Database Optimization
- [ ] Advanced Analytics

### Phase 4

- [ ] Multi-language Support
- [ ] Dark Mode
- [ ] Offline Mode
- [ ] Data Export

---

**Last Updated**: 2025-10-08
**Version**: 1.0.0
**Maintainer**: Development Team

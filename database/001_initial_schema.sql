-- =====================================================
-- AIVIA Database Schema - Initial Setup
-- Version: 1.0.0
-- Date: 8 Oktober 2025
-- Description: Setup lengkap database untuk aplikasi AIVIA
-- =====================================================

-- =====================================================
-- STEP 1: Enable Required Extensions
-- =====================================================

-- UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Vector similarity search untuk face recognition
CREATE EXTENSION IF NOT EXISTS "vector";

-- Geospatial data untuk location tracking
CREATE EXTENSION IF NOT EXISTS "postgis";

-- =====================================================
-- STEP 2: Create Tables
-- =====================================================

-- -----------------------------------------------------
-- Table: profiles
-- Deskripsi: Profil user dengan relasi 1:1 ke auth.users
-- Relasi: 
--   - 1:1 dengan auth.users
--   - 1:N dengan activities (sebagai patient)
--   - M:N dengan profiles (via patient_family_links)
-- -----------------------------------------------------

CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  user_role TEXT NOT NULL CHECK (user_role IN ('patient', 'family', 'admin')),
  avatar_url TEXT,
  phone_number TEXT,
  date_of_birth DATE,
  address TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Indexes
  CONSTRAINT profiles_email_key UNIQUE (email)
);

-- Indexes untuk performa
CREATE INDEX IF NOT EXISTS idx_profiles_user_role ON public.profiles(user_role);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);

-- Comments
COMMENT ON TABLE public.profiles IS 'Tabel profil user dengan role-based access';
COMMENT ON COLUMN public.profiles.user_role IS 'Role user: patient, family, atau admin';

-- -----------------------------------------------------
-- Table: patient_family_links
-- Deskripsi: Relasi many-to-many antara pasien dan keluarga
-- Relasi:
--   - N:1 dengan profiles (patient_id)
--   - N:1 dengan profiles (family_member_id)
-- -----------------------------------------------------

CREATE TABLE IF NOT EXISTS public.patient_family_links (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  family_member_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  relationship_type TEXT NOT NULL, -- 'anak', 'suami', 'istri', 'saudara', 'orang tua', dll
  is_primary_caregiver BOOLEAN DEFAULT FALSE,
  can_edit_activities BOOLEAN DEFAULT TRUE,
  can_view_location BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT patient_family_links_unique_pair UNIQUE(patient_id, family_member_id),
  CONSTRAINT patient_family_links_no_self_link CHECK (patient_id != family_member_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_patient_family_links_patient ON public.patient_family_links(patient_id);
CREATE INDEX IF NOT EXISTS idx_patient_family_links_family ON public.patient_family_links(family_member_id);

COMMENT ON TABLE public.patient_family_links IS 'Relasi antara pasien dan anggota keluarga/wali';
COMMENT ON COLUMN public.patient_family_links.is_primary_caregiver IS 'Penanda primary caregiver yang mendapat notifikasi prioritas';

-- -----------------------------------------------------
-- Table: activities
-- Deskripsi: Jurnal aktivitas harian pasien
-- Relasi:
--   - N:1 dengan profiles (patient_id)
--   - N:1 dengan profiles (pickup_by_profile_id) - opsional
-- -----------------------------------------------------

CREATE TABLE IF NOT EXISTS public.activities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  activity_time TIMESTAMPTZ NOT NULL,
  reminder_minutes_before INTEGER DEFAULT 15, -- Reminder 15 menit sebelum aktivitas
  reminder_sent BOOLEAN DEFAULT FALSE,
  is_completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  notes TEXT, -- Catatan setelah aktivitas selesai
  pickup_by_profile_id UUID REFERENCES public.profiles(id), -- Siapa yang akan menjemput/menemani
  location_name TEXT, -- Nama lokasi aktivitas (opsional)
  created_by UUID REFERENCES public.profiles(id), -- Siapa yang membuat aktivitas (bisa family)
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT activities_time_check CHECK (activity_time > created_at)
);

-- Indexes untuk performa query
CREATE INDEX IF NOT EXISTS idx_activities_patient_id ON public.activities(patient_id);
CREATE INDEX IF NOT EXISTS idx_activities_patient_time ON public.activities(patient_id, activity_time);
CREATE INDEX IF NOT EXISTS idx_activities_time ON public.activities(activity_time);
CREATE INDEX IF NOT EXISTS idx_activities_completed ON public.activities(is_completed);
CREATE INDEX IF NOT EXISTS idx_activities_reminder ON public.activities(reminder_sent, activity_time) WHERE NOT is_completed;

COMMENT ON TABLE public.activities IS 'Jurnal aktivitas harian pasien';
COMMENT ON COLUMN public.activities.reminder_minutes_before IS 'Berapa menit sebelum aktivitas reminder dikirim';

-- -----------------------------------------------------
-- Table: known_persons
-- Deskripsi: Database orang-orang dikenal untuk face recognition
-- Relasi:
--   - N:1 dengan profiles (owner_id) - pasien yang punya database
-- -----------------------------------------------------

CREATE TABLE IF NOT EXISTS public.known_persons (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  relationship TEXT, -- 'ibu', 'ayah', 'anak', 'teman', dll
  bio TEXT, -- Informasi tambahan untuk membantu mengingat
  photo_url TEXT NOT NULL, -- URL foto di Supabase Storage
  face_embedding vector(512), -- GhostFaceNet embedding (512 dimensi)
  last_seen_at TIMESTAMPTZ, -- Terakhir kali wajah dikenali
  recognition_count INTEGER DEFAULT 0, -- Berapa kali wajah berhasil dikenali
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT known_persons_embedding_check CHECK (face_embedding IS NOT NULL)
);

-- HNSW index untuk pencarian vector similarity yang cepat
CREATE INDEX IF NOT EXISTS idx_known_persons_embedding ON public.known_persons 
  USING hnsw (face_embedding vector_cosine_ops);

-- Indexes lainnya
CREATE INDEX IF NOT EXISTS idx_known_persons_owner ON public.known_persons(owner_id);
CREATE INDEX IF NOT EXISTS idx_known_persons_last_seen ON public.known_persons(last_seen_at DESC);

COMMENT ON TABLE public.known_persons IS 'Database wajah orang-orang dikenal untuk face recognition';
COMMENT ON COLUMN public.known_persons.face_embedding IS 'Vector embedding 512 dimensi dari GhostFaceNet model';

-- -----------------------------------------------------
-- Table: locations
-- Deskripsi: Tracking lokasi historis pasien
-- Relasi:
--   - N:1 dengan profiles (patient_id)
-- -----------------------------------------------------

CREATE TABLE IF NOT EXISTS public.locations (
  id BIGSERIAL PRIMARY KEY,
  patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  coordinates GEOGRAPHY(POINT, 4326) NOT NULL, -- Longitude, Latitude
  accuracy FLOAT, -- Akurasi dalam meter
  altitude FLOAT, -- Ketinggian dalam meter (opsional)
  speed FLOAT, -- Kecepatan dalam m/s (opsional)
  heading FLOAT, -- Arah dalam derajat (0-360, opsional)
  battery_level INTEGER, -- Level baterai saat location captured (0-100)
  is_background BOOLEAN DEFAULT FALSE, -- Apakah captured di background
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  
  -- Indexes inline
  CONSTRAINT locations_accuracy_check CHECK (accuracy IS NULL OR accuracy >= 0),
  CONSTRAINT locations_battery_check CHECK (battery_level IS NULL OR (battery_level >= 0 AND battery_level <= 100))
);

-- Indexes untuk performa query geospasial dan time-based
CREATE INDEX IF NOT EXISTS idx_locations_patient_id ON public.locations(patient_id);
CREATE INDEX IF NOT EXISTS idx_locations_coords ON public.locations USING GIST(coordinates);
CREATE INDEX IF NOT EXISTS idx_locations_timestamp ON public.locations(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_locations_patient_time ON public.locations(patient_id, timestamp DESC);

-- Partitioning setup (opsional, untuk data yang sangat besar)
-- Uncomment jika data lokasi > 10 juta rows
-- CREATE INDEX IF NOT EXISTS idx_locations_timestamp_brin ON public.locations USING BRIN(timestamp);

COMMENT ON TABLE public.locations IS 'Tracking lokasi historis pasien dengan data geospasial';
COMMENT ON COLUMN public.locations.coordinates IS 'Koordinat geografis dalam format POINT(longitude, latitude)';

-- -----------------------------------------------------
-- Table: emergency_contacts
-- Deskripsi: Kontak darurat untuk setiap pasien
-- Relasi:
--   - N:1 dengan profiles (patient_id)
--   - N:1 dengan profiles (contact_id)
-- -----------------------------------------------------

CREATE TABLE IF NOT EXISTS public.emergency_contacts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  contact_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  priority INTEGER DEFAULT 1, -- 1 = highest priority, 2, 3, dst
  notification_enabled BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT emergency_contacts_unique_pair UNIQUE(patient_id, contact_id),
  CONSTRAINT emergency_contacts_no_self CHECK (patient_id != contact_id),
  CONSTRAINT emergency_contacts_priority_check CHECK (priority > 0)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_emergency_contacts_patient ON public.emergency_contacts(patient_id);
CREATE INDEX IF NOT EXISTS idx_emergency_contacts_priority ON public.emergency_contacts(patient_id, priority);

COMMENT ON TABLE public.emergency_contacts IS 'Kontak darurat untuk setiap pasien dengan prioritas';
COMMENT ON COLUMN public.emergency_contacts.priority IS 'Priority kontak, 1 = highest (akan dihubungi pertama)';

-- -----------------------------------------------------
-- Table: emergency_alerts
-- Deskripsi: Log peringatan darurat yang dipicu pasien
-- Relasi:
--   - N:1 dengan profiles (patient_id)
--   - N:1 dengan profiles (resolved_by) - opsional
-- -----------------------------------------------------

CREATE TABLE IF NOT EXISTS public.emergency_alerts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  location GEOGRAPHY(POINT, 4326), -- Lokasi saat emergency dipicu
  message TEXT DEFAULT 'Peringatan Darurat!',
  alert_type TEXT DEFAULT 'panic_button' CHECK (alert_type IN ('panic_button', 'fall_detection', 'geofence_exit', 'no_activity')),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'acknowledged', 'resolved', 'false_alarm')),
  severity TEXT DEFAULT 'high' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  notes TEXT, -- Catatan dari family saat resolve
  resolved_by UUID REFERENCES public.profiles(id), -- Family member yang me-resolve
  created_at TIMESTAMPTZ DEFAULT NOW(),
  acknowledged_at TIMESTAMPTZ, -- Kapan alert di-acknowledge oleh family
  resolved_at TIMESTAMPTZ,
  
  -- Constraints
  CONSTRAINT emergency_alerts_resolve_check CHECK (
    (status != 'resolved' AND resolved_at IS NULL) OR 
    (status = 'resolved' AND resolved_at IS NOT NULL)
  )
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_emergency_alerts_patient ON public.emergency_alerts(patient_id);
CREATE INDEX IF NOT EXISTS idx_emergency_alerts_status ON public.emergency_alerts(status);
CREATE INDEX IF NOT EXISTS idx_emergency_alerts_created ON public.emergency_alerts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_emergency_alerts_active ON public.emergency_alerts(patient_id, status) WHERE status = 'active';

COMMENT ON TABLE public.emergency_alerts IS 'Log semua emergency alerts dengan tracking status';
COMMENT ON COLUMN public.emergency_alerts.alert_type IS 'Tipe alert: panic_button, fall_detection, geofence_exit, no_activity';

-- -----------------------------------------------------
-- Table: fcm_tokens
-- Deskripsi: Firebase Cloud Messaging tokens untuk push notifications
-- Relasi:
--   - N:1 dengan profiles (user_id)
-- -----------------------------------------------------

CREATE TABLE IF NOT EXISTS public.fcm_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  device_info JSONB, -- {platform, model, os_version, app_version}
  is_active BOOLEAN DEFAULT TRUE,
  last_used_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT fcm_tokens_unique_token UNIQUE(token)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user ON public.fcm_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_active ON public.fcm_tokens(user_id, is_active) WHERE is_active = TRUE;

COMMENT ON TABLE public.fcm_tokens IS 'FCM tokens untuk push notifications ke devices';
COMMENT ON COLUMN public.fcm_tokens.is_active IS 'FALSE jika user logout atau uninstall app';

-- -----------------------------------------------------
-- Table: face_recognition_logs
-- Deskripsi: Log setiap kali face recognition dilakukan
-- Relasi:
--   - N:1 dengan profiles (patient_id)
--   - N:1 dengan known_persons (recognized_person_id) - opsional
-- -----------------------------------------------------

CREATE TABLE IF NOT EXISTS public.face_recognition_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  recognized_person_id UUID REFERENCES public.known_persons(id) ON DELETE SET NULL,
  similarity_score FLOAT, -- Cosine similarity score (0-1)
  is_recognized BOOLEAN DEFAULT FALSE, -- TRUE jika score > threshold (0.85)
  photo_url TEXT, -- URL foto yang di-capture untuk recognition
  location GEOGRAPHY(POINT, 4326), -- Lokasi saat recognition
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT face_recognition_logs_score_check CHECK (similarity_score IS NULL OR (similarity_score >= 0 AND similarity_score <= 1))
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_face_recognition_logs_patient ON public.face_recognition_logs(patient_id);
CREATE INDEX IF NOT EXISTS idx_face_recognition_logs_person ON public.face_recognition_logs(recognized_person_id);
CREATE INDEX IF NOT EXISTS idx_face_recognition_logs_timestamp ON public.face_recognition_logs(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_face_recognition_logs_recognized ON public.face_recognition_logs(patient_id, is_recognized);

COMMENT ON TABLE public.face_recognition_logs IS 'Log setiap kali face recognition dilakukan';
COMMENT ON COLUMN public.face_recognition_logs.similarity_score IS 'Cosine similarity antara embedding (0-1, higher = lebih mirip)';

-- -----------------------------------------------------
-- Table: notifications
-- Deskripsi: Log semua notifikasi yang dikirim
-- Relasi:
--   - N:1 dengan profiles (user_id)
-- -----------------------------------------------------

CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  notification_type TEXT NOT NULL CHECK (notification_type IN ('activity_reminder', 'emergency_alert', 'activity_created', 'face_recognized', 'location_update')),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB, -- Payload tambahan untuk navigation, dll
  is_read BOOLEAN DEFAULT FALSE,
  is_sent BOOLEAN DEFAULT FALSE, -- TRUE jika berhasil dikirim ke device
  sent_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Related entities (opsional, untuk tracking relasi)
  related_activity_id UUID REFERENCES public.activities(id) ON DELETE SET NULL,
  related_alert_id UUID REFERENCES public.emergency_alerts(id) ON DELETE SET NULL
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON public.notifications(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON public.notifications(created_at DESC);

COMMENT ON TABLE public.notifications IS 'Log semua notifikasi yang dikirim ke user';
COMMENT ON COLUMN public.notifications.data IS 'JSON payload untuk deep linking dan extra data';

-- =====================================================
-- STEP 3: Create Storage Buckets
-- =====================================================

-- Bucket untuk avatar photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Bucket untuk known persons photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('known_persons_photos', 'known_persons_photos', false)
ON CONFLICT (id) DO NOTHING;

-- Bucket untuk face recognition captures
INSERT INTO storage.buckets (id, name, public)
VALUES ('face_recognition_captures', 'face_recognition_captures', false)
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '✅ Schema creation completed successfully!';
  RAISE NOTICE 'Tables created: profiles, patient_family_links, activities, known_persons, locations, emergency_contacts, emergency_alerts, fcm_tokens, face_recognition_logs, notifications';
  RAISE NOTICE 'Storage buckets created: avatars, known_persons_photos, face_recognition_captures';
  RAISE NOTICE '📝 Next: Run 002_rls_policies.sql for Row Level Security';
END $$;

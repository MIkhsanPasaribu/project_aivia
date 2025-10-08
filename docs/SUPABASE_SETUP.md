# 📘 Panduan Setup Supabase untuk AIVIA

## 🎯 Overview

Aplikasi AIVIA menggunakan **Supabase** sebagai backend (Database, Authentication, Storage, Real-time).
Environment variables disimpan dengan aman menggunakan **flutter_dotenv** di file `.env`.

---

## 🚀 Langkah Setup

### 1. Buat Project Supabase

1. Buka [https://supabase.com](https://supabase.com)
2. Login atau Sign Up
3. Klik **"New Project"**
4. Isi form:
   - **Name**: `aivia-development` (atau nama lain)
   - **Database Password**: Simpan password ini dengan aman!
   - **Region**: Pilih yang terdekat (Singapore untuk Indonesia)
   - **Pricing Plan**: Free tier (sudah cukup untuk development)
5. Klik **"Create new project"**
6. Tunggu ~2 menit hingga project selesai dibuat

### 2. Dapatkan Kredensial Supabase

1. Buka project Supabase Anda
2. Klik **Settings** (ikon gear) di sidebar kiri
3. Klik **API** di menu Settings
4. Copy 2 nilai penting:
   - **Project URL**: `https://xxxxxxxxxxxxx.supabase.co`
   - **anon public**: Key panjang yang dimulai dengan `eyJ...`

### 3. Konfigurasi File `.env`

1. Buka file `.env` di root project
2. Ganti nilai placeholder dengan kredensial Anda:

```env
# Ganti dengan Project URL Anda
SUPABASE_URL=https://xxxxxxxxxxxxx.supabase.co

# Ganti dengan anon public key Anda
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlvdXItcHJvamVjdCIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNjk5OTk5OTk5LCJleHAiOjIwMTU1NzU5OTl9.your-signature

# Environment mode
ENVIRONMENT=development
```

3. **SIMPAN** file `.env`

### 4. Setup Database Schema

1. Di Supabase Dashboard, klik **SQL Editor** di sidebar kiri
2. Klik **"New query"**
3. Copy-paste SQL berikut untuk membuat tabel pertama kali:

```sql
-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgvector";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- =====================================================
-- TABLE: profiles
-- =====================================================
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  user_role TEXT NOT NULL CHECK (user_role IN ('patient', 'family', 'admin')),
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies untuk profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Family can view linked patients"
  ON public.profiles FOR SELECT
  USING (
    id IN (
      SELECT patient_id FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  );

-- Trigger untuk auto-create profile saat user signup
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

-- =====================================================
-- TABLE: patient_family_links
-- =====================================================
CREATE TABLE public.patient_family_links (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  family_member_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  relationship_type TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(patient_id, family_member_id)
);

ALTER TABLE public.patient_family_links ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own links"
  ON public.patient_family_links FOR SELECT
  USING (auth.uid() = patient_id OR auth.uid() = family_member_id);

-- =====================================================
-- TABLE: activities
-- =====================================================
CREATE TABLE public.activities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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

ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Patients view own activities"
  ON public.activities FOR SELECT
  USING (auth.uid() = patient_id);

CREATE POLICY "Patients insert own activities"
  ON public.activities FOR INSERT
  WITH CHECK (auth.uid() = patient_id);

CREATE POLICY "Family manage patient activities"
  ON public.activities FOR ALL
  USING (
    patient_id IN (
      SELECT patient_id FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  );

-- Trigger untuk update timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_activities_updated_at
  BEFORE UPDATE ON public.activities
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

4. Klik **"Run"** atau tekan `Ctrl+Enter`
5. Pastikan tidak ada error (akan muncul "Success. No rows returned")

### 5. Test Koneksi

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Jalankan aplikasi:
   ```bash
   flutter run
   ```

3. Jika berhasil, aplikasi akan:
   - Load file `.env`
   - Initialize Supabase
   - Tampilkan Splash Screen
   - Navigate ke Login Screen

---

## 🔒 Keamanan

### ✅ Yang AMAN untuk Commit ke Git:
- `.env.example` - Template tanpa kredensial
- `supabase_config.dart` - Code yang membaca dari .env
- `pubspec.yaml` - Dependencies

### ❌ Yang JANGAN COMMIT ke Git:
- `.env` - Berisi kredensial asli (sudah ada di `.gitignore`)
- `anon key` hardcoded di code
- Database passwords
- Service role keys

### 🛡️ Row Level Security (RLS)

Supabase menggunakan **RLS** untuk keamanan database:
- **Anon Key** aman digunakan di client karena RLS membatasi akses
- Setiap tabel memiliki policies yang mengatur siapa bisa akses data
- User hanya bisa melihat/edit data mereka sendiri
- Family hanya bisa melihat data pasien yang di-link

---

## 🗄️ Database Schema (Tabel Utama)

### 1. `profiles`
- **Fungsi**: Data profil user
- **Kolom**: id, full_name, email, user_role, avatar_url
- **Relasi**: 1:1 dengan auth.users

### 2. `patient_family_links`
- **Fungsi**: Relasi many-to-many antara pasien dan keluarga
- **Kolom**: patient_id, family_member_id, relationship_type

### 3. `activities`
- **Fungsi**: Jurnal aktivitas harian pasien
- **Kolom**: patient_id, title, description, activity_time, is_completed

---

## 🧪 Test Database

Setelah setup, test dengan:

1. **Register User Baru**:
   - Buka aplikasi → Register
   - Isi form dengan role "Pasien" atau "Keluarga"
   - Submit → Akan otomatis create record di tabel `profiles`

2. **Check di Supabase**:
   - Buka Supabase Dashboard
   - Klik **Table Editor**
   - Pilih tabel `profiles`
   - Lihat data user yang baru dibuat

3. **Test RLS**:
   - Login dengan user A
   - Coba akses data user B → Tidak bisa (protected by RLS)

---

## 📊 Monitoring

### Database Logs
- Dashboard > Logs > Database
- Lihat query yang dijalankan aplikasi

### API Logs
- Dashboard > Logs > API
- Lihat request/response dari aplikasi

### Auth Logs
- Dashboard > Authentication > Logs
- Lihat login/logout history

---

## 🔄 Update Schema

Jika perlu update schema (tambah tabel/kolom):

1. Buat file SQL baru di `supabase/migrations/`
2. Jalankan di SQL Editor
3. Test di development dulu
4. Apply ke production setelah tested

---

## 🚨 Troubleshooting

### Error: "SUPABASE_URL tidak ditemukan"
- Pastikan file `.env` ada di root project
- Pastikan `.env` di-load di `pubspec.yaml` (assets)
- Restart aplikasi setelah edit `.env`

### Error: "Invalid API key"
- Check anon key di `.env` matches dengan Supabase Dashboard
- Pastikan tidak ada spasi atau newline di key

### Error: "relation does not exist"
- Tabel belum dibuat → Jalankan SQL schema di SQL Editor
- Check nama tabel sesuai dengan yang di query

### Error: "permission denied for table"
- RLS policies belum configured
- Run SQL untuk create policies
- Check user sudah login (auth.uid() harus ada)

---

## 📞 Support

- **Supabase Docs**: https://supabase.com/docs
- **Supabase Discord**: https://discord.supabase.com
- **Flutter Supabase**: https://supabase.com/docs/guides/getting-started/quickstarts/flutter

---

**Created**: 8 Oktober 2025  
**Version**: 1.0.0  
**Status**: ✅ Ready untuk Development

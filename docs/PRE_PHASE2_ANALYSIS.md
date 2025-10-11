# 🔍 Analisis Pre-Phase 2 - AIVIA

**Date**: 8 Oktober 2025  
**Status**: 📊 Analisis & Perencanaan  
**Target**: Persiapan sebelum Phase 2 (Face Recognition & Location Tracking)

---

## 📋 Hasil Analisis Folder `lib/`

### ✅ Struktur yang Sudah Ada

```
lib/
├── main.dart ✅                          # Entry point dengan Supabase initialization
│
├── core/ ✅
│   ├── config/                          # Konfigurasi app
│   │   ├── supabase_config.dart ✅      # Supabase URL & keys
│   │   └── theme_config.dart ✅         # Material Design theme
│   │
│   ├── constants/ ✅
│   │   ├── app_colors.dart ✅           # Color palette (accessibility-focused)
│   │   ├── app_dimensions.dart ✅       # Spacing constants
│   │   ├── app_routes.dart ✅           # Route names
│   │   └── app_strings.dart ✅          # Indonesian UI strings
│   │
│   ├── errors/ ✅
│   │   ├── exceptions.dart ✅           # Custom exception classes
│   │   └── failures.dart ✅             # Failure/error handling
│   │
│   └── utils/ ✅
│       ├── date_formatter.dart ✅       # DateTime formatting
│       ├── logout_helper.dart ✅        # Optimized logout with timeout
│       ├── result.dart ✅               # Result<T> type for error handling
│       └── validators.dart ✅           # Form validation
│
├── data/ ✅
│   ├── models/ ✅
│   │   ├── activity.dart ✅             # Activity model dengan JSON
│   │   └── user_profile.dart ✅         # UserProfile model
│   │
│   └── repositories/ ✅
│       ├── activity_repository.dart ✅  # CRUD activities + realtime
│       └── auth_repository.dart ✅      # Auth dengan exponential backoff
│
└── presentation/ ✅
    ├── providers/ ✅
    │   ├── activity_provider.dart ✅    # Activity state management
    │   └── auth_provider.dart ✅        # Auth state management
    │
    ├── screens/ ✅
    │   ├── splash/
    │   │   └── splash_screen.dart ✅    # Splash dengan auto-navigation
    │   │
    │   ├── auth/
    │   │   ├── login_screen.dart ✅     # Login dengan validation
    │   │   └── register_screen.dart ✅  # Register dengan retry logic
    │   │
    │   ├── patient/
    │   │   ├── patient_home_screen.dart ✅   # Bottom nav (3 tabs)
    │   │   ├── profile_screen.dart ✅        # Profile dengan logout
    │   │   └── activity/
    │   │       ├── activity_list_screen.dart ✅  # List dengan CRUD
    │   │       └── activity_form_dialog.dart ✅  # Add/Edit form
    │   │
    │   └── family/
    │       └── family_home_screen.dart ✅    # Bottom nav (5 tabs placeholder)
    │
    └── widgets/
        └── common/
            └── shimmer_loading.dart ✅   # Shimmer skeleton loading
```

---

## 🔴 Yang MISSING & Harus Dikembangkan Sebelum Phase 2

### 1. ❌ **Profile Management Screen (CRITICAL)**

**Status**: ❌ BELUM ADA  
**Priority**: 🔥 **HIGHEST**  
**Alasan**: User tidak bisa edit profil mereka sendiri!

**Yang Harus Dibuat**:

```
lib/presentation/screens/patient/
└── edit_profile_screen.dart ❌  # Edit nama, foto, phone, dll

lib/presentation/screens/family/
└── edit_profile_screen.dart ❌  # Sama untuk family role
```

**Fitur yang Dibutuhkan**:

- ✏️ Edit full name
- 📞 Edit phone number
- 🎂 Edit date of birth
- 📍 Edit address
- 📷 Upload/update avatar
- 💾 Save changes ke Supabase
- ✅ Validation untuk semua field

**Database**: Sudah support (tabel `profiles` punya semua kolom)

---

### 2. ❌ **Family Dashboard Content (EMPTY)**

**Status**: ❌ Tab kosong placeholder  
**Priority**: 🔥 **HIGH**  
**File**: `family_home_screen.dart` (tab 0: Dashboard)

**Yang Harus Dibuat**:

```dart
// Current: Hanya placeholder Text widget
// Needed: Real dashboard dengan:

1. 📊 Statistics Cards
   - Total pasien yang di-manage
   - Aktivitas hari ini
   - Aktivitas pending
   - Aktivitas completed

2. 📝 Recent Activity Feed
   - 5 aktivitas terakhir dari semua pasien
   - Status: pending/completed/overdue
   - Timestamp

3. 🚨 Alerts Section
   - Aktivitas yang terlewat (overdue)
   - Pasien yang belum login hari ini
   - Notifications yang belum dibaca

4. ⚡ Quick Actions
   - Tambah aktivitas baru
   - Lihat semua pasien
   - Lihat notifikasi
```

**Database Support**:

- ✅ Sudah ada query untuk get all activities by family member
- ❌ Perlu tambah query untuk statistics aggregation

---

### 3. ❌ **Patient List Management (Family)**

**Status**: ❌ BELUM ADA  
**Priority**: 🔥 **HIGH**

**Yang Harus Dibuat**:

```
lib/presentation/screens/family/
├── patients_list_screen.dart ❌      # List semua pasien yang di-manage
├── patient_detail_screen.dart ❌     # Detail 1 pasien
└── link_patient_screen.dart ❌       # Add patient by email/code
```

**Fitur**:

- 👥 List semua pasien yang terhubung
- ➕ Link patient baru (via email/invite code)
- 🗑️ Unlink patient
- 📊 View patient statistics
- 🔍 Search patients

**Database**:

- ✅ Table `patient_family_links` sudah ada
- ❌ Perlu function untuk invite/link patient

---

### 4. ❌ **Activity Management (Family)**

**Status**: ⚠️ Partial - family belum bisa manage patient activities  
**Priority**: 🔥 **HIGH**

**Yang Harus Dibuat**:

```
lib/presentation/screens/family/
└── activity_management/
    ├── manage_activities_screen.dart ❌  # View all patient activities
    ├── add_activity_screen.dart ❌       # Create for specific patient
    └── edit_activity_screen.dart ❌      # Edit patient activity
```

**Fitur**:

- 📝 Create activity untuk pasien tertentu
- ✏️ Edit aktivitas pasien
- 🗑️ Delete aktivitas pasien
- 📊 Filter by patient
- 📅 Calendar view

**Repository**:

- ✅ `activity_repository.dart` sudah support
- ❌ Provider perlu update untuk handle family context

---

### 5. ❌ **Image Upload Service (CRITICAL untuk Profile)**

**Status**: ❌ BELUM ADA  
**Priority**: 🔥 **HIGHEST**

**Yang Harus Dibuat**:

```
lib/data/services/
└── image_upload_service.dart ❌

Features:
- 📷 Pick image dari camera/gallery
- ✂️ Crop & resize image
- ⬆️ Upload ke Supabase Storage
- 🗑️ Delete old image
- 🔄 Update profile.avatar_url
```

**Dependencies Needed**:

```yaml
dependencies:
  image_picker: ^1.0.4 # Pick from camera/gallery
  image_cropper: ^5.0.0 # Crop image
  image: ^4.1.3 # Resize/compress
```

**Supabase Storage**:

```sql
-- Bucket: avatars (public)
-- Path: {user_id}/avatar.jpg
-- Max size: 2MB
-- Allowed types: jpg, png, webp
```

---

### 6. ❌ **Settings Screen**

**Status**: ❌ BELUM ADA  
**Priority**: 🟡 **MEDIUM**

**Yang Harus Dibuat**:

```
lib/presentation/screens/common/
└── settings_screen.dart ❌

Features:
- 🔔 Notification settings
- 🌙 Dark mode toggle (future)
- 🌐 Language (future)
- 🔐 Change password
- 📧 Change email
- ℹ️ About app
- 📄 Privacy policy
- 🗑️ Delete account
```

---

### 7. ❌ **Notification Preferences**

**Status**: ❌ BELUM ADA  
**Priority**: 🟡 **MEDIUM**

**Yang Harus Dibuat**:

```
lib/data/models/
└── notification_settings.dart ❌

lib/presentation/screens/common/
└── notification_settings_screen.dart ❌

Features:
- ⏰ Reminder time (15 min, 30 min, 1 hour before)
- 🔇 Silent hours (e.g., 22:00 - 07:00)
- 📳 Vibration on/off
- 🔊 Notification sound selection
- 🎨 Notification style
```

**Database**:

```sql
-- Perlu tabel baru:
CREATE TABLE notification_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  reminder_minutes INTEGER DEFAULT 15,
  silent_start TIME,
  silent_end TIME,
  vibration_enabled BOOLEAN DEFAULT TRUE,
  sound_enabled BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

### 8. ❌ **Error Logging & Analytics**

**Status**: ❌ BELUM ADA  
**Priority**: 🟡 **MEDIUM**

**Yang Harus Dibuat**:

```
lib/core/services/
├── analytics_service.dart ❌     # Track user events
└── error_logger.dart ❌          # Log errors to backend
```

**Recommended Tools**:

- Firebase Analytics (free, comprehensive)
- Sentry (error tracking)
- Mixpanel (user behavior)

---

### 9. ❌ **Onboarding Screen**

**Status**: ❌ BELUM ADA  
**Priority**: 🟢 **LOW** (nice to have)

**Yang Harus Dibuat**:

```
lib/presentation/screens/onboarding/
└── onboarding_screen.dart ❌

Features:
- 📱 3-4 slide tutorial
- 🎯 Explain key features
- 🔐 First-time setup wizard
- ✅ Skip button
```

---

### 10. ❌ **Help & Support Screen**

**Status**: ❌ BELUM ADA  
**Priority**: 🟢 **LOW**

**Yang Harus Dibuat**:

```
lib/presentation/screens/common/
└── help_screen.dart ❌

Features:
- ❓ FAQ section
- 📧 Contact support
- 📚 User guide
- 🎥 Video tutorials (future)
```

---

## 📊 Database Analysis

### ✅ Tabel yang Sudah Ada

```sql
✅ profiles              # User profiles (patient, family, admin)
✅ patient_family_links  # Many-to-many patient ↔ family
✅ activities            # Activity journal
✅ known_persons         # Face recognition data (untuk Phase 2)
✅ locations             # Location tracking (untuk Phase 2)
✅ emergency_contacts    # Emergency contacts (untuk Phase 2)
✅ emergency_alerts      # Emergency logs (untuk Phase 2)
```

### ❌ Tabel yang Perlu Ditambahkan

```sql
❌ notification_settings   # User notification preferences
❌ app_settings           # User app preferences
❌ patient_invites        # Invite codes untuk link patient-family
❌ activity_reminders     # Scheduled reminders (tracking)
❌ audit_logs            # Activity logs untuk security
```

### ✅ RLS Policies Status

| Table                | RLS Enabled | Policies Complete | Notes                   |
| -------------------- | ----------- | ----------------- | ----------------------- |
| profiles             | ✅ Yes      | ✅ Yes            | Users can view own      |
| patient_family_links | ✅ Yes      | ✅ Yes            | Proper isolation        |
| activities           | ✅ Yes      | ✅ Yes            | Patient + family access |
| known_persons        | ✅ Yes      | ✅ Yes            | Owner only              |
| locations            | ✅ Yes      | ✅ Yes            | Patient + family        |
| emergency_contacts   | ✅ Yes      | ⚠️ Partial        | Need testing            |
| emergency_alerts     | ✅ Yes      | ⚠️ Partial        | Need testing            |

---

## 🎯 Rekomendasi: Apa yang Harus Dikerjakan Sebelum Phase 2

### 🔥 **MUST HAVE** (Blocking Phase 2)

1. **✅ Profile Edit Screen** → User harus bisa edit data mereka
2. **✅ Image Upload Service** → Untuk avatar (juga dipakai Phase 2 face recognition)
3. **✅ Family Dashboard** → Family harus bisa lihat overview pasien
4. **✅ Patient List Management** → Family harus bisa manage multiple patients
5. **✅ Activity Management (Family View)** → Family manage patient activities

**Estimasi Waktu**: 3-4 hari

---

### 🟡 **SHOULD HAVE** (Improve UX)

6. **✅ Notification Settings** → User kontrol reminder behavior
7. **✅ Settings Screen** → Change password, preferences, dll
8. **✅ Error Logging** → Track bugs di production

**Estimasi Waktu**: 2 hari

---

### 🟢 **NICE TO HAVE** (Can be done after Phase 2)

9. **✅ Onboarding Screen** → First-time user tutorial
10. **✅ Help & Support** → FAQ dan contact

**Estimasi Waktu**: 1-2 hari

---

## 📅 Roadmap yang Disarankan

### **Week 1: Core Functionality**

```
Day 1-2:
  ✅ Image Upload Service
  ✅ Profile Edit Screen (Patient & Family)
  ✅ Update avatar_url di database

Day 3-4:
  ✅ Family Dashboard (statistics, recent activities)
  ✅ Patient List Management
  ✅ Link patient by invite code

Day 5:
  ✅ Activity Management for Family
  ✅ Testing & bug fixes
```

### **Week 2: Polish & Settings**

```
Day 1-2:
  ✅ Settings Screen
  ✅ Notification Settings
  ✅ Change password functionality

Day 3:
  ✅ Error logging setup
  ✅ Analytics integration

Day 4-5:
  ✅ Comprehensive testing
  ✅ Documentation update
  ✅ Bug fixes
```

### **Week 3: Start Phase 2**

```
Day 1-5:
  🚀 Face Recognition Implementation
  🚀 Location Tracking Background Service
  🚀 Emergency Alert System
```

---

## 🧪 Testing Checklist Pre-Phase 2

### Patient Role Testing

```
✅ Login/logout
✅ View activities (real-time)
✅ Create activity
✅ Edit activity
✅ Delete activity
✅ Complete activity
✅ View profile
❌ Edit profile (BELUM ADA!)
❌ Upload avatar (BELUM ADA!)
✅ Receive notifications
```

### Family Role Testing

```
✅ Login/logout
❌ View dashboard (KOSONG!)
❌ View patient list (BELUM ADA!)
❌ Link new patient (BELUM ADA!)
❌ View patient activities (BELUM ADA!)
❌ Create activity for patient (BELUM ADA!)
❌ Edit patient activity (BELUM ADA!)
❌ Delete patient activity (BELUM ADA!)
✅ View own profile
❌ Edit profile (BELUM ADA!)
```

---

## 📝 Database Migrations yang Perlu Dibuat

### Migration 006: Notification Settings

```sql
-- database/006_notification_settings.sql
CREATE TABLE IF NOT EXISTS public.notification_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  reminder_minutes INTEGER DEFAULT 15 CHECK (reminder_minutes IN (5, 10, 15, 30, 60)),
  silent_start TIME,
  silent_end TIME,
  vibration_enabled BOOLEAN DEFAULT TRUE,
  sound_enabled BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE public.notification_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own notification settings"
  ON public.notification_settings FOR ALL
  USING (auth.uid() = user_id);
```

### Migration 007: Patient Invites

```sql
-- database/007_patient_invites.sql
CREATE TABLE IF NOT EXISTS public.patient_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invite_code TEXT UNIQUE NOT NULL,
  patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  family_member_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'expired')),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '7 days',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  accepted_at TIMESTAMPTZ
);

-- RLS policies
-- Function untuk generate invite code
CREATE OR REPLACE FUNCTION generate_invite_code()
RETURNS TEXT AS $$
BEGIN
  RETURN UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8));
END;
$$ LANGUAGE plpgsql;
```

---

## 🎯 Kesimpulan

### Status Saat Ini:

- ✅ **Phase 1 Core**: 100% Complete
- ⚠️ **Phase 1 Polish**: 40% Complete
- ❌ **Phase 2 Ready**: NO

### Yang Harus Dilakukan:

1. **Profile Management** (CRITICAL)
2. **Image Upload** (CRITICAL)
3. **Family Dashboard** (HIGH)
4. **Patient Management** (HIGH)
5. **Settings & Preferences** (MEDIUM)

### Rekomendasi:

**Jangan masuk Phase 2 dulu!** Selesaikan dulu 5 komponen di atas agar:

- ✅ User experience lebih baik
- ✅ Aplikasi lebih complete
- ✅ Foundation kuat untuk Phase 2
- ✅ Code reuse (image upload untuk avatar & face recognition)

---

**Next Step**: Mulai dari **Profile Edit Screen** + **Image Upload Service**

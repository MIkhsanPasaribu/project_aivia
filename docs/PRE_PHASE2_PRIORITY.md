# 🎯 Pre-Phase 2: Priority Tasks

**Tanggal**: 8 Oktober 2025  
**Status Phase 1**: ✅ 100% Complete  
**Siap Phase 2?**: ❌ NO - Masih ada gaps yang harus ditutup

---

## 📊 Quick Summary

### Yang Sudah Jalan ✅

- Login/Register dengan validation
- Activity CRUD lengkap (Create, Read, Update, Delete)
- Real-time sync activities
- Local notifications
- Profile view
- Logout optimized (<3s)
- Shimmer loading animations
- Bottom navigation untuk Patient & Family

### Yang MISSING ❌

- **Profile Edit** - User tidak bisa edit data mereka!
- **Image Upload** - Tidak ada upload avatar
- **Family Dashboard** - Tab masih kosong placeholder
- **Patient List** - Family tidak bisa manage multiple patients
- **Settings Screen** - Tidak ada pengaturan
- **Notification Preferences** - Tidak bisa customize reminder

---

## 🔥 CRITICAL (Harus Sebelum Phase 2)

### 1. **Profile Edit Screen** ⭐⭐⭐⭐⭐

**Waktu**: 1 hari  
**Files**:

```
lib/presentation/screens/common/
└── edit_profile_screen.dart ❌ BUAT BARU

lib/data/repositories/
└── profile_repository.dart ❌ BUAT BARU
```

**Fitur**:

- Edit nama, phone, tanggal lahir, alamat
- Upload foto profil
- Validation
- Save ke Supabase

**Kenapa Penting?**: User harus bisa update data mereka sendiri!

---

### 2. **Image Upload Service** ⭐⭐⭐⭐⭐

**Waktu**: 0.5 hari  
**Files**:

```
lib/data/services/
└── image_upload_service.dart ❌ BUAT BARU
```

**Dependencies**:

```yaml
image_picker: ^1.0.4
image_cropper: ^5.0.0
image: ^4.1.3
```

**Fitur**:

- Pick dari camera/gallery
- Crop & resize
- Upload ke Supabase Storage
- Update avatar_url di database

**Kenapa Penting?**:

- Dipakai untuk avatar (sekarang)
- Dipakai untuk face recognition (Phase 2)
- Foundation untuk upload fitur

---

### 3. **Family Dashboard** ⭐⭐⭐⭐

**Waktu**: 1 hari  
**Files**:

```
lib/presentation/screens/family/
├── dashboard_tab.dart ❌ BUAT BARU (pisahkan dari family_home_screen)
└── widgets/
    ├── statistics_card.dart ❌
    ├── recent_activity_widget.dart ❌
    └── alerts_widget.dart ❌
```

**Fitur**:

- Statistics cards (total patients, activities today, completed/pending)
- Recent activity feed (5 terakhir)
- Alerts (overdue activities)
- Quick actions (add activity, view patients)

**Kenapa Penting?**: Family role sekarang tidak berguna (tab kosong!)

---

### 4. **Patient List Management** ⭐⭐⭐⭐

**Waktu**: 1.5 hari  
**Files**:

```
lib/presentation/screens/family/patients/
├── patients_list_screen.dart ❌
├── patient_detail_screen.dart ❌
└── link_patient_dialog.dart ❌

lib/data/repositories/
└── patient_family_repository.dart ❌

lib/data/models/
└── patient_family_link.dart ❌
```

**Database Migration**:

```sql
-- database/006_patient_invites.sql
CREATE TABLE patient_invites (
  id UUID PRIMARY KEY,
  invite_code TEXT UNIQUE,
  patient_id UUID,
  family_member_id UUID,
  status TEXT,
  expires_at TIMESTAMPTZ
);
```

**Fitur**:

- List pasien yang terhubung
- Link pasien baru (via invite code)
- Unlink pasien
- View detail pasien (stats, recent activities)

**Kenapa Penting?**: Family harus bisa manage multiple patients!

---

### 5. **Activity Management for Family** ⭐⭐⭐

**Waktu**: 1 hari  
**Files**:

```
lib/presentation/screens/family/activities/
├── family_activities_screen.dart ❌
├── add_activity_for_patient_dialog.dart ❌
└── edit_patient_activity_dialog.dart ❌

lib/presentation/providers/
└── family_activity_provider.dart ❌ (extend activity_provider)
```

**Fitur**:

- View all activities dari semua pasien
- Create activity untuk pasien tertentu
- Edit/delete patient activities
- Filter by patient
- Calendar view

**Kenapa Penting?**: Fitur inti untuk family role!

---

## 🟡 IMPORTANT (Improve UX)

### 6. **Settings Screen** ⭐⭐⭐

**Waktu**: 0.5 hari  
**Files**:

```
lib/presentation/screens/common/
└── settings_screen.dart ❌
```

**Fitur**:

- Change password
- Notification preferences
- About app
- Privacy policy
- Logout

---

### 7. **Notification Settings** ⭐⭐⭐

**Waktu**: 1 hari  
**Files**:

```
lib/data/models/
└── notification_settings.dart ❌

lib/presentation/screens/common/
└── notification_settings_screen.dart ❌
```

**Database**:

```sql
-- database/007_notification_settings.sql
CREATE TABLE notification_settings (
  user_id UUID PRIMARY KEY,
  reminder_minutes INTEGER DEFAULT 15,
  silent_start TIME,
  silent_end TIME,
  vibration_enabled BOOLEAN DEFAULT TRUE
);
```

**Fitur**:

- Reminder time (5, 10, 15, 30, 60 menit before)
- Silent hours
- Vibration on/off
- Sound on/off

---

## 📅 Roadmap Disarankan

### **Minggu 1: Core Missing Features** (5 hari)

**Day 1: Image Upload & Profile Edit**

```
Morning:
  ✅ Setup image_picker, image_cropper dependencies
  ✅ Buat ImageUploadService
  ✅ Buat Supabase Storage bucket (avatars)
  ✅ Test upload/crop/delete

Afternoon:
  ✅ Buat EditProfileScreen
  ✅ Buat ProfileRepository
  ✅ Integrate ImageUploadService
  ✅ Form validation
  ✅ Test save profile + avatar
```

**Day 2: Family Dashboard**

```
Morning:
  ✅ Design dashboard layout
  ✅ Buat StatisticsCard widget
  ✅ Query statistics dari Supabase
  ✅ Implement StatisticsCard

Afternoon:
  ✅ Buat RecentActivityWidget
  ✅ Buat AlertsWidget
  ✅ Integrate semua di DashboardTab
  ✅ Test dengan data real
```

**Day 3: Patient List**

```
Morning:
  ✅ Database migration (patient_invites)
  ✅ Buat PatientFamilyLink model
  ✅ Buat PatientFamilyRepository

Afternoon:
  ✅ Buat PatientsListScreen
  ✅ Buat LinkPatientDialog
  ✅ Generate invite code function
  ✅ Test link/unlink patient
```

**Day 4: Activity Management (Family)**

```
Morning:
  ✅ Buat FamilyActivitiesScreen
  ✅ Extend ActivityProvider untuk family context
  ✅ Filter activities by patient

Afternoon:
  ✅ Buat AddActivityForPatientDialog
  ✅ Buat EditPatientActivityDialog
  ✅ Test CRUD dari family side
```

**Day 5: Settings & Polish**

```
Morning:
  ✅ Buat SettingsScreen
  ✅ Buat NotificationSettingsScreen
  ✅ Database migration (notification_settings)

Afternoon:
  ✅ Change password functionality
  ✅ Save notification preferences
  ✅ Comprehensive testing
  ✅ Bug fixes
```

---

### **Minggu 2: Testing & Refinement** (3 hari)

**Day 1-2: Comprehensive Testing**

```
✅ Test all patient role features
✅ Test all family role features
✅ Test profile edit & image upload
✅ Test patient linking
✅ Test activity management (both roles)
✅ Test notifications
✅ Test logout & session
✅ Edge cases & error scenarios
```

**Day 3: Documentation & Preparation**

```
✅ Update PHASE1_SUMMARY.md
✅ Create PHASE1.5_COMPLETION.md
✅ Update README.md
✅ Prepare Phase 2 plan
✅ Code review
✅ Performance check
```

---

### **Minggu 3: Phase 2 Start** 🚀

```
✅ Face Recognition implementation
✅ Location Tracking background service
✅ Emergency Alert system
```

---

## 🎯 Kesimpulan

### Kenapa Tidak Langsung Phase 2?

1. **User Experience Buruk**

   - User tidak bisa edit profil
   - Family role setengah jalan (tab kosong)
   - Tidak ada settings

2. **Foundation Tidak Lengkap**

   - Belum ada image upload (dipakai Phase 2!)
   - Belum ada patient management (critical!)
   - Activity management belum full

3. **Tech Debt**
   - Code quality akan turun
   - Susah maintain nanti
   - Harus refactor ulang

### Benefit Selesaikan Pre-Phase 2 Dulu:

✅ **User experience complete**  
✅ **Foundation kuat untuk Phase 2**  
✅ **Code reusable** (image upload untuk avatar & face recognition)  
✅ **Less tech debt**  
✅ **Easier testing**

---

## 📋 Action Items

**Start With** (Priority Order):

1. ✅ Image Upload Service
2. ✅ Profile Edit Screen
3. ✅ Family Dashboard
4. ✅ Patient List Management
5. ✅ Activity Management (Family)
6. ✅ Settings Screen
7. ✅ Notification Settings

**Total Estimasi**: 5-6 hari kerja penuh

**Next Step**: Mulai dari **Image Upload Service** karena ini foundation untuk banyak fitur lain!

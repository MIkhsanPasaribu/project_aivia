# Panduan Testing Aplikasi AIVIA v1.1

**Tanggal**: 8 Oktober 2025  
**Status**: Ready for Testing

---

## 🧪 Testing Checklist

### 1. Registrasi & Login

#### Test Case 1.1: Registrasi Pasien

**Steps**:

1. Buka aplikasi
2. Tap "Daftar di sini"
3. Isi form:
   - Email: test.patient@example.com
   - Nama Lengkap: Test Patient
   - Password: Password123
   - Role: **Pasien**
4. Tap "Daftar"

**Expected Result**:

- ✅ Loading indicator muncul
- ✅ Registrasi berhasil dalam 3-5 detik
- ✅ Redirect ke home screen pasien
- ✅ Bottom navigation dengan 3 tab

#### Test Case 1.2: Registrasi Keluarga

**Steps**:

1. Buka aplikasi
2. Tap "Daftar di sini"
3. Isi form:
   - Email: test.family@example.com
   - Nama Lengkap: Test Family
   - Password: Password123
   - Role: **Keluarga**
4. Tap "Daftar"

**Expected Result**:

- ✅ Loading indicator muncul
- ✅ Registrasi berhasil dalam 3-7 detik (dengan retry)
- ✅ Redirect ke home screen keluarga
- ✅ Bottom navigation dengan 5 tab

#### Test Case 1.3: Login

**Steps**:

1. Buka aplikasi
2. Sudah ada form login
3. Isi credentials dari test case 1.1 atau 1.2
4. Tap "Masuk"

**Expected Result**:

- ✅ Login berhasil < 2 detik
- ✅ Redirect ke home sesuai role

---

### 2. CRUD Aktivitas (Pasien)

#### Test Case 2.1: CREATE - Tambah Aktivitas

**Steps**:

1. Login sebagai pasien
2. Tab "Beranda" (sudah aktif)
3. Tap FAB (+) di kanan bawah
4. Isi form:
   - Judul: "Makan Siang"
   - Deskripsi: "Jangan lupa minum obat"
   - Tanggal: Hari ini
   - Waktu: 2 jam dari sekarang
5. Tap "Simpan"

**Expected Result**:

- ✅ Dialog tertutup
- ✅ Snackbar "Aktivitas berhasil dibuat"
- ✅ Activity muncul di list dengan animasi slide-in
- ✅ Tersimpan di database (cek refresh)

#### Test Case 2.2: READ - Lihat Daftar

**Steps**:

1. Pastikan sudah ada minimal 3 aktivitas
2. Scroll list aktivitas
3. Pull down untuk refresh

**Expected Result**:

- ✅ List tampil dengan group "Hari Ini" dan "Mendatang"
- ✅ Cards dengan animasi slide-in saat load
- ✅ Shimmer loading saat refresh
- ✅ Data terupdate setelah refresh

#### Test Case 2.3: READ - Detail Aktivitas

**Steps**:

1. Tap salah satu activity card
2. Bottom sheet detail muncul

**Expected Result**:

- ✅ Bottom sheet slide up dengan smooth
- ✅ Tampil full title, description, time
- ✅ Tombol "Edit" dan "Selesai" visible
- ✅ Swipe down untuk close

#### Test Case 2.4: UPDATE - Edit Aktivitas

**Steps**:

1. Tap activity card
2. Tap tombol "Edit" di detail
3. Ubah judul menjadi "Makan Siang Updated"
4. Ubah waktu menjadi 1 jam lebih lambat
5. Tap "Simpan"

**Expected Result**:

- ✅ Dialog tertutup
- ✅ Snackbar "Aktivitas berhasil diupdate"
- ✅ Perubahan langsung terlihat di list
- ✅ Data terupdate di database

#### Test Case 2.5: DELETE - Hapus Aktivitas

**Steps**:

1. Swipe activity card dari kanan ke kiri
2. Background merah dengan icon delete muncul
3. Swipe sampai habis
4. Dialog konfirmasi muncul
5. Tap "Hapus"

**Expected Result**:

- ✅ Dialog tertutup
- ✅ Card hilang dengan animasi
- ✅ Snackbar "Aktivitas berhasil dihapus"
- ✅ Data terhapus dari database

#### Test Case 2.6: COMPLETE - Tandai Selesai

**Steps**:

1. Tap activity card
2. Tap tombol "Selesai" (hijau)

**Expected Result**:

- ✅ Bottom sheet tertutup
- ✅ Snackbar "Aktivitas ditandai selesai"
- ✅ Card berubah dengan:
  - Icon check_circle
  - Text strikethrough
  - Chip "Selesai" warna hijau
- ✅ Status completed tersimpan

---

### 3. Profile & Logout

#### Test Case 3.1: View Profile

**Steps**:

1. Login sebagai pasien/keluarga
2. Tap tab "Profil" di bottom nav

**Expected Result**:

- ✅ Screen transitions dengan fade
- ✅ Avatar, nama, email tampil
- ✅ Badge role tampil
- ✅ Menu items lengkap

#### Test Case 3.2: Logout (Optimized)

**Steps**:

1. Di halaman profile
2. Tap tombol "Keluar" (merah)
3. Dialog konfirmasi muncul
4. Tap "Ya"

**Expected Result**:

- ✅ Loading overlay muncul dengan text
- ✅ Logout selesai dalam **< 3 detik**
- ✅ Redirect ke login screen
- ✅ Snackbar "Berhasil keluar"
- ✅ Session cleared

#### Test Case 3.3: Logout Timeout Test

**Steps**:

1. Matikan internet/WiFi
2. Coba logout seperti test 3.2

**Expected Result**:

- ✅ Loading muncul
- ✅ Timeout setelah 10 detik
- ✅ Force logout terjadi
- ✅ Redirect ke login
- ✅ Session cleared locally

---

### 4. UI/UX Animations

#### Test Case 4.1: Splash Screen Animation

**Steps**:

1. Kill app
2. Reopen app
3. Amati splash screen

**Expected Result**:

- ✅ Logo fade in + scale up
- ✅ App name fade in
- ✅ Tagline fade in
- ✅ Loading indicator fade in
- ✅ Total duration ~2.5 detik
- ✅ Smooth transition ke login

#### Test Case 4.2: Hero Animation Logo

**Steps**:

1. Amati splash screen
2. Tunggu redirect ke login/home

**Expected Result**:

- ✅ Logo melakukan hero transition
- ✅ Animasi smooth tanpa glitch
- ✅ Size adjustment smooth

#### Test Case 4.3: Activity Card Animation

**Steps**:

1. Login sebagai pasien
2. Amati saat activities load

**Expected Result**:

- ✅ Cards muncul dengan slide-in dari bawah
- ✅ Fade in effect
- ✅ Stagger animation (satu per satu)
- ✅ Delay 100ms antar card
- ✅ 60 FPS smooth

#### Test Case 4.4: Tab Transition Animation

**Steps**:

1. Di home screen
2. Tap tab berbeda di bottom nav
3. Amati transition

**Expected Result**:

- ✅ Fade out screen lama
- ✅ Fade in screen baru
- ✅ Duration 300ms
- ✅ Smooth tanpa lag

#### Test Case 4.5: Shimmer Loading

**Steps**:

1. Di activity list
2. Pull to refresh
3. Amati loading state

**Expected Result**:

- ✅ Shimmer effect pada skeleton cards
- ✅ Animated gradient berjalan
- ✅ Smooth animation loop
- ✅ Tidak freeze UI

---

### 5. Error Handling

#### Test Case 5.1: Email Sudah Terdaftar

**Steps**:

1. Coba registrasi dengan email yang sudah ada
2. Tap "Daftar"

**Expected Result**:

- ✅ Error message: "Email sudah terdaftar"
- ✅ Color merah
- ✅ User tetap di register screen

#### Test Case 5.2: Password Lemah

**Steps**:

1. Registrasi dengan password "123"
2. Tap "Daftar"

**Expected Result**:

- ✅ Error message: "Password terlalu lemah. Minimal 8 karakter"
- ✅ User tetap di register screen

#### Test Case 5.3: Login Credentials Salah

**Steps**:

1. Login dengan email/password salah
2. Tap "Masuk"

**Expected Result**:

- ✅ Error message: "Email atau password salah"
- ✅ User tetap di login screen

#### Test Case 5.4: Network Error

**Steps**:

1. Matikan internet
2. Coba login

**Expected Result**:

- ✅ Error message yang informatif
- ✅ Tidak crash
- ✅ User bisa retry

---

### 6. Performance Testing

#### Test Case 6.1: App Startup Time

**Steps**:

1. Force close app
2. Start timer
3. Open app
4. Stop timer saat splash selesai

**Target**: < 3 detik

#### Test Case 6.2: Login Time

**Steps**:

1. Di login screen
2. Start timer
3. Input credentials & tap "Masuk"
4. Stop timer saat home screen muncul

**Target**: < 2 detik

#### Test Case 6.3: Logout Time

**Steps**:

1. Di profile screen
2. Start timer
3. Tap "Keluar" > "Ya"
4. Stop timer saat kembali ke login

**Target**: < 3 detik (was 15-20s)

#### Test Case 6.4: Activity Creation Time

**Steps**:

1. Tap FAB
2. Start timer
3. Isi form & tap "Simpan"
4. Stop timer saat snackbar muncul

**Target**: < 1 detik

#### Test Case 6.5: Scroll Performance

**Steps**:

1. Buat 20+ activities
2. Scroll list dengan cepat

**Expected**: 60 FPS, no jank

---

### 7. Edge Cases

#### Test Case 7.1: Empty State

**Steps**:

1. Login sebagai pasien baru (no activities)

**Expected Result**:

- ✅ Icon besar calendar
- ✅ Text "Tidak ada aktivitas"
- ✅ FAB tetap visible

#### Test Case 7.2: Long Text Handling

**Steps**:

1. Buat activity dengan:
   - Judul: 100 karakter
   - Deskripsi: 500 karakter

**Expected Result**:

- ✅ Text truncated dengan ellipsis
- ✅ Tidak overflow
- ✅ Full text visible di detail

#### Test Case 7.3: Many Activities

**Steps**:

1. Buat 50+ activities

**Expected Result**:

- ✅ List scroll smooth
- ✅ No performance issue
- ✅ Pagination (future)

---

## 📊 Testing Results Template

```
Date: ___________
Tester: ___________
Device: ___________
Android Version: ___________

| Test Case | Status | Notes |
|-----------|--------|-------|
| 1.1 | ✅/❌ |       |
| 1.2 | ✅/❌ |       |
| 1.3 | ✅/❌ |       |
| ... | ... | ...   |
```

---

## 🐛 Bug Report Template

```markdown
**Bug ID**: BUG-XXX
**Priority**: High/Medium/Low
**Status**: Open/In Progress/Fixed

**Description**:
[Deskripsi bug]

**Steps to Reproduce**:

1. Step 1
2. Step 2
3. Step 3

**Expected Result**:
[Apa yang seharusnya terjadi]

**Actual Result**:
[Apa yang sebenarnya terjadi]

**Screenshots**:
[Jika ada]

**Device Info**:

- Device: [e.g., Samsung Galaxy S21]
- Android Version: [e.g., 13]
- App Version: [e.g., 1.1.0]

**Additional Info**:
[Info tambahan]
```

---

## 🚀 Pre-Production Checklist

- [ ] Semua test cases passed
- [ ] No critical bugs
- [ ] Performance targets met
- [ ] UI/UX approved
- [ ] Database backup ready
- [ ] Error logging configured
- [ ] Crash reporting setup
- [ ] User manual completed

---

**Happy Testing!** 🎉

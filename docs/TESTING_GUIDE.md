# 🧪 Phase 1 Testing Guide - AIVIA

**Version**: 1.0.0  
**Date**: 8 Oktober 2025  
**Status**: Ready for Testing

---

## 📋 Test Environment Setup

### Prerequisites

- [x] Flutter SDK 3.22.0+
- [x] Android device/emulator (API 21+)
- [x] Supabase project configured
- [x] Database migrations executed
- [x] Seed data loaded

### Test Accounts

```
Patient Accounts:
1. Email: budi@patient.com
   Password: password123
   Activities: 8-11 items (mixed today/upcoming)

2. Email: ani@patient.com
   Password: password123
   Activities: 6-8 items

Family Accounts:
1. Email: siti@family.com
   Password: password123
   Role: Family Member
```

---

## 🎯 Test Scenarios

### **Test Case 1: First Time Installation & Splash Screen**

**Objective**: Verify app installation and initial screen

**Steps**:

1. Install APK on device/emulator
2. Launch app
3. Observe splash screen

**Expected Results**:

- ✅ Splash screen appears with AIVIA logo
- ✅ Logo animates (fade in + scale)
- ✅ After 2.5 seconds, navigates to Login screen
- ✅ No crashes or errors

**Pass/Fail**: ☐

**Notes**: **********************\_**********************

---

### **Test Case 2: User Registration (Patient)**

**Objective**: Verify new patient registration flow

**Steps**:

1. On login screen, tap "Daftar di sini"
2. Fill form:
   - Nama Lengkap: Test Patient 1
   - Email: testpatient1@test.com
   - Kata Sandi: password123
   - Konfirmasi Kata Sandi: password123
   - Pilih Role: Pasien
3. Tap "Daftar"

**Expected Results**:

- ✅ Form validation works (email format, password match, required fields)
- ✅ Registration success
- ✅ Auto-login occurs
- ✅ Navigates to Patient Home Screen
- ✅ Success snackbar: "Selamat datang, Test Patient 1!"
- ✅ Bottom navigation shows: Beranda, Kenali Wajah, Profil

**Pass/Fail**: ☐

**Notes**: **********************\_**********************

---

### **Test Case 3: User Login**

**Objective**: Verify login with existing account

**Steps**:

1. On login screen, enter:
   - Email: budi@patient.com
   - Password: password123
2. Tap "Masuk"

**Expected Results**:

- ✅ Loading indicator shows briefly
- ✅ Login success
- ✅ Navigates to Patient Home Screen
- ✅ Success snackbar shows
- ✅ Activity list screen loads with activities

**Pass/Fail**: ☐

**Notes**: **********************\_**********************

---

### **Test Case 4: Login with Invalid Credentials**

**Objective**: Verify error handling for wrong credentials

**Steps**:

1. On login screen, enter:
   - Email: budi@patient.com
   - Password: wrongpassword
2. Tap "Masuk"

**Expected Results**:

- ✅ Error snackbar shows: "Email atau password salah"
- ✅ Red background on snackbar
- ✅ User remains on login screen
- ✅ No crash

**Pass/Fail**: ☐

**Notes**: **********************\_**********************

---

### **Test Case 5: View Activities (Non-Empty State)**

**Objective**: Verify activity list displays correctly

**Steps**:

1. Login as budi@patient.com
2. Should land on Activity List screen (Beranda tab)

**Expected Results**:

- ✅ Screen title: "Jurnal Aktivitas"
- ✅ Activities grouped by:
  - "Aktivitas Hari Ini" section
  - "Aktivitas Mendatang" section
- ✅ Each activity card shows:
  - Icon (clock or checkmark)
  - Title
  - Description (if any)
  - Time (relative format: "2 jam lagi", "besok")
  - Completion badge (if completed)
- ✅ Floating Action Button (+) visible at bottom-right

**Pass/Fail**: ☐

**Notes**: **********************\_**********************

---

### **Test Case 6: Add New Activity**

**Objective**: Verify activity creation

**Steps**:

1. From Activity List, tap FAB (+)
2. Dialog opens: "Tambah Aktivitas"
3. Fill form:
   - Judul: Makan Siang
   - Deskripsi: Jangan lupa minum obat
   - Tanggal: (select tomorrow)
   - Waktu: 12:00
4. Tap "Simpan"

**Expected Results**:

- ✅ Form validation works (title required, min 3 chars)
- ✅ Date picker shows in Indonesian
- ✅ Time picker works
- ✅ Dialog closes
- ✅ Success snackbar: "Aktivitas berhasil ditambahkan"
- ✅ New activity appears in list IMMEDIATELY (real-time)
- ✅ Activity appears in "Aktivitas Mendatang" section

**Pass/Fail**: ☐

**Notes**: **********************\_**********************

---

### **Test Case 7: View Activity Detail**

**Objective**: Verify bottom sheet detail view

**Steps**:

1. Tap on any activity card
2. Bottom sheet opens

**Expected Results**:

- ✅ Bottom sheet slides up from bottom
- ✅ Shows activity title (large, bold)
- ✅ Shows date/time (formatted: "Senin, 07 Oktober 2025, 14:00")
- ✅ Shows description (if any)
- ✅ Two buttons visible:
  - "Edit" (outlined button)
  - "Selesai" (filled button, green) OR "Selesai" (disabled if completed)

**Pass/Fail**: ☐

**Notes**: **********************\_**********************

---

### **Test Case 8: Edit Existing Activity**

**Objective**: Verify activity update

**Steps**:

1. Tap on activity card
2. In bottom sheet, tap "Edit"
3. Dialog opens: "Edit Aktivitas"
4. Modify title: "Makan Siang (Updated)"
5. Change time: 13:00
6. Tap "Simpan"

**Expected Results**:

- ✅ Form pre-filled with existing data
- ✅ Changes can be made
- ✅ Save success
- ✅ Snackbar: "Aktivitas berhasil diperbarui"
- ✅ Activity updates IMMEDIATELY in list (real-time)
- ✅ Updated data visible

**Pass/Fail**: ☐

**Notes**: **********************\_**********************

---

### **Test Case 9: Delete Activity (Swipe)**

**Objective**: Verify activity deletion

**Steps**:

1. On activity list, swipe LEFT on any activity card
2. Red background with trash icon appears
3. Release swipe
4. Confirmation dialog appears
5. Tap "Hapus"

**Expected Results**:

- ✅ Swipe gesture works smoothly
- ✅ Red delete background visible
- ✅ Confirmation dialog shows: "Apakah Anda yakin ingin menghapus..."
- ✅ After confirmation, activity disappears IMMEDIATELY
- ✅ Snackbar: "Aktivitas berhasil dihapus" (green)

**Pass/Fail**: ☐

**Notes**: **********************\_**********************

---

### **Test Case 10: Complete Activity**

**Objective**: Verify marking activity as complete

**Steps**:

1. Tap on incomplete activity card
2. In bottom sheet, tap "Selesai" button

**Expected Results**:

- ✅ Bottom sheet closes
- ✅ Snackbar: "Aktivitas ditandai selesai" (green)
- ✅ Activity card updates IMMEDIATELY:
  - Icon changes to green checkmark
  - Title has strikethrough
  - Green badge shows "Selesai"
  - Background tinted slightly green
- ✅ If tap same activity again, "Selesai" button is now disabled/grayed

**Pass/Fail**: ☐

**Notes**: **********************\_**********************

---

### **Test Case 11: Empty State**

**Objective**: Verify UI when no activities exist

**Steps**:

1. Login as newly registered user (testpatient1@test.com)
2. Navigate to Beranda tab

**Expected Results**:

- ✅ Large icon (event_note) in center
- ✅ Text: "Belum ada aktivitas"
- ✅ FAB still visible for adding first activity

**Pass/Fail**: ☐

**Notes**: **********************\_**********************

---

### **Test Case 12: Pull-to-Refresh**

**Objective**: Verify refresh functionality

**Steps**:

1. On activity list, pull down from top
2. Release

**Expected Results**:

- ✅ Loading indicator appears
- ✅ List refreshes
- ✅ (No visible change if data same, but no errors)

**Pass/Fail**: ☐

**Notes**: **********************\_**********************

---

### **Test Case 13: Real-time Sync (2 Devices)**

**Objective**: Verify Supabase real-time updates

**Prerequisites**: 2 devices/emulators

**Steps**:

1. Login to same account (budi@patient.com) on both devices
2. On Device 1: Add new activity "Test Sync"
3. Observe Device 2

**Expected Results**:

- ✅ Device 2 updates AUTOMATICALLY within 1-2 seconds
- ✅ New activity appears without manual refresh
- ✅ Test with Edit and Delete too → Both sync

**Pass/Fail**: ☐

**Notes**: **********************\_**********************

---

### **Test Case 14: Profile Screen - View**

**Objective**: Verify profile data display

**Steps**:

1. Login as budi@patient.com
2. Tap "Profil" tab in bottom navigation

**Expected Results**:

- ✅ Screen title: "Profil"
- ✅ Header section (blue background) shows:
  - Avatar (default icon or image)
  - Full name: "Budi Santoso"
  - Email: "budi@patient.com"
  - Role badge: "Pasien"
- ✅ Menu items visible:
  - Edit Profil
  - Notifikasi
  - Bantuan
  - Tentang Aplikasi
- ✅ Logout button (red) at bottom

**Pass/Fail**: ☐

**Notes**: **********************\_**********************

---

### **Test Case 15: Logout**

**Objective**: Verify logout functionality

**Steps**:

1. On profile screen, tap "Keluar" button
2. Confirmation dialog appears
3. Tap "Ya"

**Expected Results**:

- ✅ Confirmation dialog: "Apakah Anda yakin ingin keluar?"
- ✅ Loading indicator shows briefly
- ✅ Session cleared
- ✅ Navigates to Login screen
- ✅ Snackbar: "Anda telah keluar"
- ✅ Cannot go back to home (back button disabled)

**Pass/Fail**: ☐

**Notes**: **********************\_**********************

---

### **Test Case 16: About Dialog**

**Objective**: Verify about app information

**Steps**:

1. Profile screen → Tap "Tentang Aplikasi"

**Expected Results**:

- ✅ Dialog opens
- ✅ Shows AIVIA logo
- ✅ App name: "AIVIA"
- ✅ Tagline displayed
- ✅ Version: 0.1.0
- ✅ Description text
- ✅ "OK" button to close

**Pass/Fail**: ☐

**Notes**: **********************\_**********************

---

### **Test Case 17: Form Validation (Add Activity)**

**Objective**: Verify input validation

**Steps**:

1. Tap FAB to add activity
2. Test scenarios:
   - a) Leave title empty → Try save
   - b) Enter title with 2 chars "ab" → Try save
   - c) Enter valid title (3+ chars) → Save

**Expected Results**:

- ✅ Scenario a: Error "Judul aktivitas harus diisi"
- ✅ Scenario b: Error "Judul minimal 3 karakter"
- ✅ Scenario c: Saves successfully
- ✅ Description is optional (can be empty)

**Pass/Fail**: ☐

**Notes**: **********************\_**********************

---

### **Test Case 18: Date/Time Picker (Indonesian)**

**Objective**: Verify localization

**Steps**:

1. Add activity dialog
2. Tap date field
3. Tap time field

**Expected Results**:

- ✅ Date picker shows Indonesian day/month names
  - "Senin", "Selasa", etc.
  - "Januari", "Februari", etc.
- ✅ Time picker shows 24-hour or 12-hour based on system
- ✅ Cannot select past dates (firstDate = now)

**Pass/Fail**: ☐

**Notes**: **********************\_**********************

---

### **Test Case 19: Error State (No Internet)**

**Objective**: Verify offline error handling

**Steps**:

1. Turn off WiFi/data
2. Login screen → Try login
3. Activity list → Wait for timeout

**Expected Results**:

- ✅ Login fails with error message
- ✅ Activity list shows error state:
  - Red error icon
  - Error message
  - "Coba Lagi" button
- ✅ Tap retry → Tries to reload

**Pass/Fail**: ☐

**Notes**: **********************\_**********************

---

### **Test Case 20: Navigation Flow**

**Objective**: Verify app navigation

**Steps**:

1. Splash → Login → Patient Home
2. Tap each bottom nav tab:
   - Beranda → Activity List
   - Kenali Wajah → Placeholder
   - Profil → Profile Screen
3. Switch between tabs multiple times

**Expected Results**:

- ✅ All transitions smooth
- ✅ Tab state maintained (IndexedStack)
- ✅ Activity list doesn't reload when switching back
- ✅ Active tab highlighted correctly

**Pass/Fail**: ☐

**Notes**: **********************\_**********************

---

## 📊 Test Summary

### Test Results

| Test Case                | Status        | Notes |
| ------------------------ | ------------- | ----- |
| TC-01: Splash Screen     | ☐ Pass ☐ Fail |       |
| TC-02: Registration      | ☐ Pass ☐ Fail |       |
| TC-03: Login             | ☐ Pass ☐ Fail |       |
| TC-04: Invalid Login     | ☐ Pass ☐ Fail |       |
| TC-05: View Activities   | ☐ Pass ☐ Fail |       |
| TC-06: Add Activity      | ☐ Pass ☐ Fail |       |
| TC-07: View Detail       | ☐ Pass ☐ Fail |       |
| TC-08: Edit Activity     | ☐ Pass ☐ Fail |       |
| TC-09: Delete Activity   | ☐ Pass ☐ Fail |       |
| TC-10: Complete Activity | ☐ Pass ☐ Fail |       |
| TC-11: Empty State       | ☐ Pass ☐ Fail |       |
| TC-12: Pull-to-Refresh   | ☐ Pass ☐ Fail |       |
| TC-13: Real-time Sync    | ☐ Pass ☐ Fail |       |
| TC-14: Profile View      | ☐ Pass ☐ Fail |       |
| TC-15: Logout            | ☐ Pass ☐ Fail |       |
| TC-16: About Dialog      | ☐ Pass ☐ Fail |       |
| TC-17: Form Validation   | ☐ Pass ☐ Fail |       |
| TC-18: Date/Time Picker  | ☐ Pass ☐ Fail |       |
| TC-19: Error State       | ☐ Pass ☐ Fail |       |
| TC-20: Navigation        | ☐ Pass ☐ Fail |       |

**Total Pass**: **\_** / 20  
**Total Fail**: **\_** / 20  
**Pass Rate**: **\_**%

---

## 🐛 Bug Report Template

### Bug ID: BUG-001

**Title**: **********************\_**********************

**Severity**: ☐ Critical ☐ High ☐ Medium ☐ Low

**Steps to Reproduce**:

1. ***
2. ***
3. ***

**Expected Result**: ****\_\_\_****

**Actual Result**: ****\_\_\_****

**Screenshots/Logs**: ****\_\_\_****

**Device**: ****\_\_\_****

**Android Version**: ****\_\_\_****

---

## ✅ Sign-Off

**Tester Name**: **********\_\_\_**********  
**Date**: **********\_\_\_**********  
**Signature**: **********\_\_\_**********

**Status**:

- ☐ All tests passed - Ready for production
- ☐ Minor issues found - Can proceed with fixes
- ☐ Major issues found - Need immediate attention

**Comments**:

---

---

---

---

**End of Testing Guide**

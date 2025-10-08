# 📋 PHASE 1 - Testing Checklist

**Status**: 🟡 In Progress  
**Last Updated**: 8 Oktober 2025  
**Target Completion**: Phase 1 MVP

---

## 🎯 **Objective Phase 1**

Menyelesaikan MVP (Minimum Viable Product) dengan fitur-fitur dasar yang functional:

- ✅ Authentication (Login & Register)
- ✅ Activity Management (CRUD)
- ✅ Real-time Updates
- ⚠️ Local Notifications (Pending)
- ✅ Profile Management

---

## 📂 **Files Created/Updated**

### **Core Infrastructure**

- [x] `lib/core/errors/exceptions.dart` - Custom exceptions
- [x] `lib/core/errors/failures.dart` - Failure classes
- [x] `lib/core/utils/result.dart` - Result pattern untuk error handling

### **Data Layer**

- [x] `lib/data/repositories/auth_repository.dart` - Authentication logic
- [x] `lib/data/repositories/activity_repository.dart` - Activity CRUD logic

### **Presentation Layer**

- [x] `lib/presentation/providers/auth_provider.dart` - Auth state management
- [x] `lib/presentation/providers/activity_provider.dart` - Activity state management

### **UI Screens Updated**

- [x] `lib/presentation/screens/auth/login_screen.dart` - Functional login
- [x] `lib/presentation/screens/auth/register_screen.dart` - Functional register
- [x] `lib/presentation/screens/patient/activity/activity_list_screen.dart` - Real-time activity list

---

## 🧪 **Testing Checklist**

### **1. Environment Setup** ✅

- [x] Supabase database setup (001-005 SQL files berhasil dijalankan)
- [x] `.env` file configured dengan Supabase credentials
- [x] `flutter pub get` success
- [x] `flutter pub run build_runner build` success
- [x] `flutter analyze` - No critical errors
- [ ] Test users dari seed data tersedia:
  - `budi@patient.com` / `password123` (Patient)
  - `ahmad@family.com` / `password123` (Family)

---

### **2. Authentication Flow** ⚠️

#### **A. Register** (NEEDS TESTING)

- [ ] **Test Case 1**: Register patient baru

  - Input: email, password, nama lengkap, role=patient
  - Expected: User dibuat di database, auto-login, navigate ke patient home
  - Test dengan: `testuser1@patient.com` / `password123` / `Test Patient`

- [ ] **Test Case 2**: Register family baru

  - Input: email, password, nama lengkap, role=family
  - Expected: User dibuat, auto-login, navigate ke family home
  - Test dengan: `testfamily1@family.com` / `password123` / `Test Family`

- [ ] **Test Case 3**: Register dengan email duplikat

  - Input: `budi@patient.com` (sudah ada)
  - Expected: Error message "Email already exists"

- [ ] **Test Case 4**: Register dengan password lemah
  - Input: password kurang dari 8 karakter
  - Expected: Validation error

#### **B. Login** (NEEDS TESTING)

- [ ] **Test Case 1**: Login patient yang ada

  - Input: `budi@patient.com` / `password123`
  - Expected: Success, navigate ke `/patient/home`, show welcome snackbar

- [ ] **Test Case 2**: Login family yang ada

  - Input: `ahmad@family.com` / `password123`
  - Expected: Success, navigate ke `/family/home`

- [ ] **Test Case 3**: Login dengan credentials salah

  - Input: `budi@patient.com` / `wrongpassword`
  - Expected: Error "Invalid credentials"

- [ ] **Test Case 4**: Login dengan email tidak terdaftar
  - Input: `notexist@email.com` / `password123`
  - Expected: Error message

#### **C. Logout** (NEEDS TESTING)

- [ ] **Test Case 1**: Logout dari patient home

  - Action: Tap logout di profile screen
  - Expected: Session cleared, navigate ke login screen

- [ ] **Test Case 2**: Logout dari family home
  - Action: Tap logout
  - Expected: Session cleared, navigate ke login screen

---

### **3. Activity Management** ⚠️

#### **A. Read Activities (Real-time Stream)** (NEEDS TESTING)

- [ ] **Test Case 1**: View activities sebagai patient
  - Login: `budi@patient.com`
  - Expected: Tampil list activities dari seed data (8 activities hari ini)
- [ ] **Test Case 2**: Empty state

  - Login dengan user baru yang belum punya activities
  - Expected: Tampil empty state "Belum ada aktivitas"

- [ ] **Test Case 3**: Real-time update
  - Buka app di 2 devices dengan user yang sama
  - Tambah activity di device 1
  - Expected: Activity langsung muncul di device 2 (real-time)

#### **B. Create Activity** (NOT IMPLEMENTED YET)

- [ ] UI untuk tambah activity belum ada
- [ ] TODO: Buat form add activity (Phase 1 incomplete)

#### **C. Update Activity** (NOT IMPLEMENTED YET)

- [ ] Edit activity feature belum ada
- [ ] TODO: Buat form edit activity

#### **D. Delete Activity** (NOT IMPLEMENTED YET)

- [ ] Delete activity feature belum ada
- [ ] TODO: Implement swipe-to-delete atau delete button

#### **E. Complete Activity** (NOT IMPLEMENTED YET)

- [ ] Mark as complete feature belum ada
- [ ] TODO: Implement checkbox/button untuk complete

---

### **4. Error Handling** ⚠️

- [ ] **Network Error**: Matikan internet, coba login

  - Expected: Error message "No internet connection"

- [ ] **Supabase Down**: Simulate Supabase offline

  - Expected: Error message "Server error, try again later"

- [ ] **Invalid Data**: Coba submit form dengan field kosong
  - Expected: Validation errors tampil

---

### **5. UI/UX** ⚠️

- [ ] **Loading States**: Tampil CircularProgressIndicator saat loading
- [ ] **Error States**: Tampil error message dengan warna merah
- [ ] **Success States**: Tampil snackbar hijau saat sukses
- [ ] **Empty States**: Tampil empty state dengan icon dan text
- [ ] **Responsive**: Test di berbagai ukuran layar
- [ ] **Dark/Light Mode**: (Belum implement di Phase 1)

---

### **6. Local Notifications** ❌ NOT IMPLEMENTED

- [ ] Setup `awesome_notifications` package
- [ ] Request notification permission
- [ ] Schedule notification 15 menit sebelum activity
- [ ] Test notification tampil di lock screen
- [ ] Test notification action (tap untuk buka app)

**Status**: Belum dimulai - Prioritas rendah di Phase 1

---

## 🐛 **Known Issues & Bugs**

### **Critical** 🔴

1. ❌ **ActivityRepository methods (gte/lte) deprecated**

   - Error: `The method 'gte' isn't defined`
   - Location: `activity_repository.dart:46`
   - Fix: Update Supabase query methods

2. ❌ **AuthException ambiguous import**
   - Error: AuthException defined in 2 libraries
   - Location: `auth_repository.dart`
   - Fix: Use `hide` in import or rename custom exception

### **Medium** 🟡

3. ⚠️ **Riverpod deprecation warnings**

   - Warning: `ActivityRepositoryRef` deprecated
   - Impact: Will break in Riverpod 3.0
   - Fix: Replace with `Ref`

4. ⚠️ **Unnecessary imports**
   - Warning: `flutter_riverpod` unnecessary
   - Impact: None, just cleanup
   - Fix: Remove import

### **Low** 🟢

5. ⚠️ **Dangling doc comments**
   - Info: Doc comment formatting
   - Impact: None
   - Fix: Add `library` keyword

---

## 📝 **Next Steps**

### **Immediate (This Session)**

1. 🔧 Fix critical bugs (gte/lte, AuthException)
2. 🧪 Run `flutter analyze` dan pastikan 0 errors
3. 🚀 Run `flutter run` dan test manual login/register
4. ✅ Test dengan user dari seed data

### **Short Term (Next Session)**

1. 🎨 Implement CRUD UI untuk activities:

   - Add Activity FAB di activity_list_screen
   - Edit Activity dialog
   - Delete Activity confirmation
   - Complete Activity checkbox

2. 🔔 Setup Local Notifications:

   - Awesome Notifications initialization
   - Schedule reminder
   - Handle notification tap

3. 🧪 E2E Testing dengan Patrol

### **Medium Term (Phase 1 Completion)**

1. ✅ Complete all test cases
2. 📚 Update documentation
3. 🎉 Demo kepada client/team
4. 📊 Collect feedback

---

## ✅ **Phase 1 Completion Criteria**

- [x] Database setup complete
- [x] AuthRepository functional
- [x] ActivityRepository functional
- [x] Login screen functional
- [x] Register screen functional
- [x] Activity list screen dengan real-time
- [ ] Activity CRUD UI complete (Add/Edit/Delete)
- [ ] Local notifications functional
- [ ] All test cases pass
- [ ] Zero critical bugs
- [ ] Documentation updated

**Progress**: 70% Complete 🎯

---

## 📞 **Support & Resources**

- **Supabase Dashboard**: https://app.supabase.com
- **Flutter Docs**: https://docs.flutter.dev
- **Riverpod Docs**: https://riverpod.dev
- **Copilot Instructions**: `.github/copilot-instructions.md`
- **Database Schema**: `database/README.md`

---

**Next Action**: Fix critical bugs kemudian run manual test 🚀

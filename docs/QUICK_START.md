# 🚀 Quick Start Guide - AIVIA

**Quick setup guide untuk menjalankan aplikasi AIVIA Phase 1**

---

## ⚡ TL;DR (Super Quick Start)

```bash
# 1. Clone & setup
cd project_aivia
flutter pub get

# 2. Configure .env file (lihat di bawah)

# 3. Run migrations di Supabase Dashboard

# 4. Run app
flutter run
```

**Test Login**: `budi@patient.com` / `password123`

---

## 📋 Prerequisites

- Flutter SDK 3.22.0+
- Android Studio / VS Code
- Android device/emulator (API 21+)
- Supabase account

---

## 🔧 Step-by-Step Setup

### 1. Install Dependencies

```bash
cd project_aivia
flutter pub get
```

**Expected output**: All packages downloaded successfully

---

### 2. Configure Environment Variables

Create `.env` file in project root:

```env
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

**Where to find these**:

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Click "Settings" (gear icon) → "API"
4. Copy:
   - Project URL → `SUPABASE_URL`
   - Anon/Public key → `SUPABASE_ANON_KEY`

---

### 3. Setup Database

#### Option A: Supabase Dashboard (Recommended)

1. Go to Supabase Dashboard
2. Click "SQL Editor" (left sidebar)
3. Execute these files **in order**:

   **File 1: Initial Schema**

   ```sql
   -- Copy-paste contents of database/001_initial_schema.sql
   -- Click "Run" or Ctrl+Enter
   ```

   **File 2: RLS Policies**

   ```sql
   -- Copy-paste contents of database/002_rls_policies.sql
   -- Click "Run"
   ```

   **File 3: Triggers & Functions**

   ```sql
   -- Copy-paste contents of database/003_triggers_functions.sql
   -- Click "Run"
   ```

   **File 4: Realtime Config**

   ```sql
   -- Copy-paste contents of database/004_realtime_config.sql
   -- Click "Run"
   ```

   **File 5: Seed Data (Test Users)**

   ```sql
   -- Copy-paste contents of database/005_seed_data.sql
   -- Click "Run"
   ```

4. Verify:
   - Go to "Table Editor"
   - Should see tables: profiles, activities, etc.
   - Go to "Authentication" → "Users"
   - Should see 5 test users

---

### 4. Run Application

```bash
flutter run
```

**Or in Android Studio/VS Code**: Press F5 or click Run button

---

## 🧪 Test the App

### Quick Test Flow

1. **App opens** → Splash screen (2.5 sec)
2. **Login screen** appears
3. Enter credentials:
   - Email: `budi@patient.com`
   - Password: `password123`
4. **Tap "Masuk"**
5. **Patient Home** loads
6. **Activity List** shows 8-11 activities
7. **Test CRUD**:
   - Tap **+** button → Add activity
   - Tap card → View detail → Edit
   - Swipe left → Delete
   - Tap card → Complete button

---

## 👥 Test Accounts

### Patient Accounts (with data)

```
1. Email: budi@patient.com
   Password: password123
   Name: Budi Santoso
   Activities: 8-11 items

2. Email: ani@patient.com
   Password: password123
   Name: Ani Wijaya
   Activities: 6-8 items

3. Email: citra@patient.com
   Password: password123
   Name: Citra Lestari
   Activities: 5-7 items
```

### Family Accounts

```
1. Email: siti@family.com
   Password: password123
   Name: Siti Rahayu
   Role: Family

2. Email: dedi@family.com
   Password: password123
   Name: Dedi Kurniawan
   Role: Family
```

---

## ✅ Verification Checklist

After setup, verify these work:

- [ ] App launches without crash
- [ ] Login with test account works
- [ ] Activity list displays data
- [ ] Can add new activity
- [ ] Can edit activity
- [ ] Can delete activity
- [ ] Can mark as complete
- [ ] Real-time sync (open on 2 devices)
- [ ] Profile shows correct data
- [ ] Logout works

---

## 🐛 Troubleshooting

### Issue: "Supabase URL is not set"

**Solution**: Check `.env` file exists and has correct format

### Issue: "No activities showing"

**Solution**:

1. Check database migration (005_seed_data.sql) executed
2. Verify in Supabase Table Editor → activities table has data
3. Check user_id matches in activities.patient_id

### Issue: "Cannot login"

**Solution**:

1. Check Supabase project is active
2. Verify SUPABASE_ANON_KEY is correct
3. Check Authentication enabled in Supabase dashboard
4. Ensure seed data (005) executed to create users

### Issue: "Real-time not working"

**Solution**:

1. Execute 004_realtime_config.sql
2. In Supabase Dashboard → Database → Replication
3. Enable replication for 'activities' table

### Issue: "Flutter analyze errors"

**Solution**:

```bash
flutter clean
flutter pub get
flutter analyze
```

Should return: "No issues found!"

---

## 📱 Build APK (for Testing)

### Debug APK

```bash
flutter build apk --debug
```

**Output**: `build/app/outputs/flutter-apk/app-debug.apk`

### Release APK (for demo)

```bash
flutter build apk --release
```

**Output**: `build/app/outputs/flutter-apk/app-release.apk`

---

## 🎯 Features Implemented (Phase 1)

### ✅ Authentication

- User Registration (Patient/Family)
- Login with email/password
- Session management
- Logout

### ✅ Activity Management

- View activities (real-time stream)
- Add activity
- Edit activity
- Delete activity
- Mark as complete
- Group by Today/Upcoming

### ✅ Profile

- View profile data
- Display role badge
- About dialog
- Logout

### ✅ UI/UX

- Splash screen with animation
- Bottom navigation (Patient)
- Material Design 3
- Indonesian localization
- Error handling
- Loading states

---

## 📚 Additional Resources

- **Full Documentation**: See `PHASE1_COMPLETED.md`
- **Testing Guide**: See `TESTING_GUIDE.md`
- **Database Docs**: See `database/README.md`
- **Architecture**: See `.github/copilot-instructions.md`

---

## 🆘 Need Help?

### Common Commands

```bash
# Check Flutter installation
flutter doctor

# Clean build cache
flutter clean

# Update dependencies
flutter pub upgrade

# Run analyze
flutter analyze

# Run tests
flutter test

# Check connected devices
flutter devices
```

### Debug Mode

```bash
# Run with verbose logging
flutter run -v

# Hot reload: Press 'r' in terminal
# Hot restart: Press 'R' in terminal
# Quit: Press 'q'
```

---

## ✨ You're Ready!

If all steps completed successfully, you should now have:

- ✅ App running on device/emulator
- ✅ Database with test data
- ✅ Ability to login and test CRUD operations
- ✅ Real-time sync working

**Happy Testing! 🎉**

---

**Last Updated**: 8 Oktober 2025  
**Version**: 1.0.0

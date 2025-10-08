# 🚨 COMPLETE FIX: Step-by-Step Instructions

**Problem You're Experiencing**:

- ❌ Email DISABLED → Error 400: "Email signups are disabled"
- ❌ Email ENABLED → Error 422: "Database error querying schema"

**Root Cause**: Database RLS policies have infinite recursion bug!

**Solution**: Fix database FIRST, then enable email

---

## ✅ STEP-BY-STEP FIX (DO IN ORDER!)

### 🔴 STEP 1: Fix Database Policies (CRITICAL!)

**Why First?**: Kalau database tidak diperbaiki dulu, enable email akan tetap error!

#### 1.1 Login to Supabase

1. Go to: https://supabase.com/dashboard
2. Login with your account
3. Select your AIVIA project

#### 1.2 Open SQL Editor

1. Click **SQL Editor** in left sidebar
2. Click **+ New query** button at top

#### 1.3 Copy Fixed SQL

1. Open file on your computer:

   ```
   C:\Users\mikhs\OneDrive\Documents\Semester 5\Praktikum Pemograman Bergerak\project_aivia\database\002_rls_policies_FIXED.sql
   ```

2. Select ALL content (Ctrl+A)
3. Copy (Ctrl+C)

#### 1.4 Paste and Run

1. In Supabase SQL Editor, paste the SQL (Ctrl+V)
2. Click **RUN** button (bottom right)
   - Or press **F5** keyboard shortcut

#### 1.5 Verify Success

You should see output like:

```
✅ DROP POLICY (multiple times) - cleaning old policies
✅ ALTER TABLE ENABLE ROW LEVEL SECURITY (10 tables)
✅ CREATE POLICY (multiple new policies)
Success! No errors.
```

**If you see errors**: Copy the error message and send to me!

---

### 🟡 STEP 2: Configure Email Settings

**IMPORTANT**: Do this AFTER Step 1 is successful!

#### 2.1 Enable Email Provider

1. In Supabase Dashboard, click **Authentication** (left sidebar)
2. Click **Providers** tab
3. Find **Email** in the list
4. Make sure these settings:

   ```
   ✅ Enable email provider: ON
   ✅ Enable signup: ON
   ❌ Confirm email: OFF  ← IMPORTANT!
   ❌ Secure email change: OFF
   ```

5. Click **Save** button

#### 2.2 Verify Auth Settings

1. Still in **Authentication** section
2. Click **Settings** tab
3. Check:
   ```
   Site URL: http://localhost
   Redirect URLs: http://localhost
   ```

---

### 🟢 STEP 3: Test Registration

#### 3.1 Run Flutter App

```bash
flutter run
```

#### 3.2 Try Register

1. Open app on your device
2. Tap **"Daftar di sini"**
3. Fill form:
   ```
   Nama Lengkap: Test User 4
   Email: testuser4@gmail.com
   Kata Sandi: password123
   Konfirmasi Sandi: password123
   Peran: Pasien
   ```
4. Tap **"Daftar"** button

#### 3.3 Expected Result

✅ **SUCCESS**:

- Loading dialog appears
- "Registrasi berhasil!" message
- Navigate to Patient Home screen
- Bottom navigation visible (3 tabs)

❌ **If Error**:

- Take screenshot of error
- Check Supabase logs (Dashboard → Logs → Error Logs)
- Send me the error message

---

### 🟢 STEP 4: Test Login

#### 4.1 Use Existing Test Account

1. If registration success, logout first
2. On Login screen, enter:
   ```
   Email: budi@patient.com
   Password: password123
   ```
3. Tap **"Masuk"**

#### 4.2 Expected Result

✅ **SUCCESS**:

- Loading indicator
- Login successful
- Navigate to Patient Home
- Profile loads correctly

---

## 🔍 Troubleshooting

### Issue 1: SQL Errors When Running Fix

**Error Message**: "policy already exists" or "relation does not exist"

**Solution**:

```sql
-- Run this first to clean everything
DROP POLICY IF EXISTS "users_view_own_profile" ON public.profiles CASCADE;
DROP POLICY IF EXISTS "users_insert_own_profile" ON public.profiles CASCADE;
-- ... etc for all policies

-- Then run the full 002_rls_policies_FIXED.sql again
```

---

### Issue 2: Still Getting "Database error querying schema"

**Possible Causes**:

1. SQL fix not applied successfully
2. Old policies still active
3. Tables not created

**Solution**:

#### Check if policies exist:

```sql
-- Run in SQL Editor
SELECT tablename, policyname
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'profiles'
ORDER BY policyname;
```

**Expected Output**:

```
profiles | authenticated_users_view_profiles
profiles | users_insert_own_profile
profiles | users_update_own_profile
profiles | users_view_own_profile
```

#### Check if trigger exists:

```sql
-- Run in SQL Editor
SELECT trigger_name, event_manipulation, event_object_table
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';
```

**Expected Output**:

```
on_auth_user_created | INSERT | users
```

#### If trigger missing, create it:

```sql
-- Run in SQL Editor
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

---

### Issue 3: "Email signups are disabled" (After Enable)

**Solution**: Wait 1-2 minutes for Supabase settings to propagate, then try again.

---

### Issue 4: Registration Success but Profile Not Created

**Check in SQL Editor**:

```sql
-- See all users
SELECT id, email, created_at FROM auth.users ORDER BY created_at DESC LIMIT 5;

-- See all profiles
SELECT id, email, full_name, user_role FROM public.profiles ORDER BY created_at DESC LIMIT 5;
```

**If user exists but profile doesn't**:

```sql
-- Manually create profile for that user
INSERT INTO public.profiles (id, email, full_name, user_role)
SELECT id, email, raw_user_meta_data->>'full_name', raw_user_meta_data->>'user_role'
FROM auth.users
WHERE email = 'your-email@gmail.com';
```

---

## 📊 Verification Checklist

After completing all steps:

- [ ] Step 1: SQL fix applied successfully (no errors)
- [ ] Step 1: Verified policies exist (query shows 4 policies for profiles)
- [ ] Step 1: Verified trigger exists (on_auth_user_created)
- [ ] Step 2: Email provider enabled in dashboard
- [ ] Step 2: Email confirmation DISABLED
- [ ] Step 3: Registration SUCCESS (testuser4@gmail.com)
- [ ] Step 3: Navigate to Patient Home after register
- [ ] Step 4: Login SUCCESS (budi@patient.com)
- [ ] Step 4: Profile screen loads correctly

---

## 🎯 Success Criteria

When everything is fixed:

✅ **Registration**:

- No "Email signups are disabled" error
- No "Database error querying schema" error
- No "Infinite recursion" error
- Profile created automatically
- Navigate to Patient Home

✅ **Login**:

- No authentication errors
- No database errors
- Profile loads correctly
- Navigate to Patient Home

✅ **Profile Screen**:

- Shows user name from database
- Shows email
- Shows role badge
- Logout works

---

## 🚀 After Success

Once registration and login work:

### Test Activity CRUD:

1. Create activity: "Minum Obat" tomorrow 08:00
2. Edit activity
3. Mark as complete
4. Delete activity

### All should work without errors!

---

## 📞 If Still Having Issues

Send me:

1. **Screenshot of error** (full screen)
2. **Supabase logs**:
   - Dashboard → Logs → Error Logs
   - Copy last 5 error entries
3. **SQL verification results**:
   ```sql
   SELECT tablename, policyname FROM pg_policies WHERE tablename = 'profiles';
   SELECT * FROM information_schema.triggers WHERE trigger_name = 'on_auth_user_created';
   ```

---

## 💡 Why This Happens

### The Problem Chain:

1. **Original RLS Policies**: Had circular dependencies

   ```
   profiles → patient_family_links → profiles (LOOP!)
   ```

2. **Missing INSERT Policy**: Trigger couldn't create profile

   ```sql
   -- This was MISSING!
   CREATE POLICY "users_insert_own_profile" ON profiles FOR INSERT ...
   ```

3. **Result**: Both registration AND login failed
   - Registration: Can't insert into profiles
   - Login: Infinite loop when querying profiles

### The Solution:

1. **DROP all old policies**: Clean slate
2. **CREATE simplified policies**: No circular dependencies
3. **ADD INSERT policy**: Allow trigger to work
4. **Use direct checks**: `auth.uid() = id` instead of complex queries

---

**CRITICAL**: You MUST do Step 1 (Fix Database) before enabling email!

**Estimated Time**: 5-10 minutes total

---

**Good luck! Ikuti step-by-step dan pasti berhasil! 🎯**

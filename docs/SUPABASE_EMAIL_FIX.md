# 🔧 Supabase Configuration Fix - Email Rate Limit

**Problem**: Register gagal dengan error "over_email_send_rate_limit" (429)  
**Solution**: Disable email confirmation untuk development/testing

---

## 🚨 Problem Description

Error yang muncul:

```
AuthApiException(message: For security purposes, you can only request this after 46 seconds., statusCode: 429, code: over_email_send_rate_limit)
```

**Penyebab**:

- Supabase mengirim email konfirmasi setiap kali ada registrasi baru
- Ada rate limit untuk keamanan (max 1 email per ~1 menit)
- Ketika testing berulang kali, rate limit tercapai

---

## ✅ Solution 1: Disable Email Confirmation (Recommended for Development)

### Step 1: Login ke Supabase Dashboard

1. Buka [Supabase Dashboard](https://supabase.com/dashboard)
2. Pilih project Anda
3. Klik **Authentication** di sidebar kiri
4. Klik **Providers**

### Step 2: Configure Email Provider

1. Cari **Email** di list providers
2. Klik untuk expand/edit
3. **DISABLE** option berikut:
   - ❌ **"Enable email confirmations"** → Turn OFF
   - ❌ **"Secure email change"** → Turn OFF (optional)
4. Click **Save**

### Step 3: Verify Settings

Settings yang benar untuk development:

```
Email Provider Settings:
✅ Enable email provider: ON
❌ Enable email confirmations: OFF  ← IMPORTANT!
❌ Secure email change: OFF
✅ Enable signup: ON
```

---

## ✅ Solution 2: Update Application Code (Already Done)

File sudah diupdate dengan improvements:

### 1. `auth_repository.dart`

**Changes**:

```dart
// Added emailRedirectTo: null to disable confirmation
final response = await _supabase.auth.signUp(
  email: email,
  password: password,
  data: {...},
  emailRedirectTo: null, // ← Disable email confirmation
);

// Added retry mechanism for profile creation
int retries = 3;
while (retries > 0 && profile == null) {
  // Try fetch profile with retries
}

// Better error handling for rate limit
if (e.message.contains('429') ||
    e.message.contains('rate') ||
    e.message.contains('email_send_rate_limit')) {
  return const ResultFailure(
    AuthFailure(
      'Terlalu banyak permintaan. Silakan tunggu beberapa saat.',
      code: 'rate_limit',
    ),
  );
}
```

### 2. `register_screen.dart`

**Changes**:

```dart
// Added loading dialog to prevent multiple submissions
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => LoadingDialog(),
);

// Navigate directly without auto-login (already logged in after signUp)
Navigator.of(context).pushReplacementNamed(route);

// Show rate limit dialog with helpful info
void _showRateLimitDialog() {
  // Shows test account credentials
  // Suggests waiting 5-10 minutes
}
```

---

## 🧪 Testing After Fix

### Test Register Flow

1. **Open app**
2. **Tap "Daftar di sini"**
3. **Fill form**:
   ```
   Nama: Test User 1
   Email: testuser1@test.com
   Password: password123
   Konfirmasi: password123
   Role: Pasien
   ```
4. **Tap "Daftar"**
5. **Expected**:
   - ✅ Loading dialog appears
   - ✅ Registration success
   - ✅ Navigate to Patient Home immediately
   - ✅ No email confirmation needed

### If Still Getting Rate Limit

**Option A**: Wait 5-10 minutes before trying again

**Option B**: Use existing test accounts:

```
Email: budi@patient.com
Password: password123
```

**Option C**: Use Supabase SQL Editor to create user directly:

```sql
-- Create auth user (skip email)
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_user_meta_data,
  created_at,
  updated_at
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'newuser@test.com',
  crypt('password123', gen_salt('bf')),
  NOW(), -- Automatically confirmed
  '{"full_name": "New Test User", "user_role": "patient"}'::jsonb,
  NOW(),
  NOW()
);

-- Profile will be auto-created by trigger
```

---

## 🔒 For Production

### Re-enable Email Confirmation

Before going to production, you should re-enable email confirmation:

1. **Supabase Dashboard** → **Authentication** → **Providers** → **Email**
2. **Enable**:
   - ✅ Enable email confirmations
   - ✅ Secure email change
3. **Configure**:
   - Set up custom email templates
   - Configure SMTP settings (optional, for custom domain)
   - Set confirmation URL redirect

### Update Code for Production

```dart
// In auth_repository.dart, change:
final response = await _supabase.auth.signUp(
  email: email,
  password: password,
  data: {...},
  emailRedirectTo: 'your-app://confirm-email', // Production redirect
);
```

---

## 📱 Alternative: Email Whitelist

Jika ingin tetap enable email confirmation tapi bypass untuk testing:

1. **Supabase Dashboard** → **Authentication** → **Email Rate Limits**
2. Add test emails ke whitelist
3. Configure rate limit settings

**Note**: Feature ini mungkin perlu upgrade ke paid plan.

---

## ✅ Verification Checklist

After applying fix:

- [ ] Email confirmation disabled di Supabase Dashboard
- [ ] Code updated (`auth_repository.dart` & `register_screen.dart`)
- [ ] Run `flutter clean && flutter pub get`
- [ ] Test registration dengan email baru
- [ ] Verify langsung masuk tanpa konfirmasi email
- [ ] Test login dengan akun yang baru dibuat

---

## 🐛 Troubleshooting

### Still Getting Rate Limit?

1. **Clear Supabase cache**:

   ```bash
   flutter clean
   rm -rf .dart_tool
   flutter pub get
   ```

2. **Check Auth settings saved**:

   - Dashboard → Authentication → Providers
   - Verify "Enable email confirmations" is OFF

3. **Try different email**:
   - Use completely new email address
   - Or use test accounts provided

### Profile Not Created?

Check trigger in database:

```sql
-- Verify trigger exists
SELECT * FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';

-- Manually create profile if needed
INSERT INTO public.profiles (id, email, full_name, user_role)
SELECT id, email, raw_user_meta_data->>'full_name', raw_user_meta_data->>'user_role'
FROM auth.users
WHERE email = 'yournewemail@test.com';
```

---

## 📚 References

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Email Rate Limiting](https://supabase.com/docs/guides/auth/rate-limits)
- [Disable Email Confirmation](https://supabase.com/docs/guides/auth/auth-email)

---

**Status**: ✅ Fixed  
**Last Updated**: 8 Oktober 2025  
**Next Step**: Test registration on device

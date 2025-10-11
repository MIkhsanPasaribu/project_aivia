# 🗄️ Supabase Storage Setup - Avatars Bucket

**Date**: 8 Oktober 2025  
**Purpose**: Setup storage bucket untuk avatar images

---

## 📋 Setup Instructions

### 1. Create Avatars Bucket

1. **Login ke Supabase Dashboard**

   - URL: https://supabase.com/dashboard
   - Pilih project AIVIA

2. **Navigate to Storage**

   - Di sidebar kiri, klik **Storage**
   - Klik tombol **New Bucket**

3. **Configure Bucket**

   ```
   Bucket name: avatars
   Public bucket: ✅ YES (checked)
   File size limit: 2MB
   Allowed MIME types: image/jpeg, image/png, image/webp
   ```

4. **Create Bucket**
   - Klik **Create bucket**

---

### 2. Setup Storage Policies (RLS)

Setelah bucket dibuat, setup policies untuk security:

#### Policy 1: Allow Authenticated Users to Upload Their Own Avatar

```sql
-- Policy name: Users can upload own avatar
-- Table: storage.objects
-- Operation: INSERT

CREATE POLICY "Users can upload own avatar"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars' AND
  (storage.foldername(name))[1] = auth.uid()::text
);
```

#### Policy 2: Allow Users to Update Their Own Avatar

```sql
-- Policy name: Users can update own avatar
-- Table: storage.objects
-- Operation: UPDATE

CREATE POLICY "Users can update own avatar"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars' AND
  (storage.foldername(name))[1] = auth.uid()::text
);
```

#### Policy 3: Allow Users to Delete Their Own Avatar

```sql
-- Policy name: Users can delete own avatar
-- Table: storage.objects
-- Operation: DELETE

CREATE POLICY "Users can delete own avatar"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars' AND
  (storage.foldername(name))[1] = auth.uid()::text
);
```

#### Policy 4: Anyone Can View Public Avatars

```sql
-- Policy name: Anyone can view avatars
-- Table: storage.objects
-- Operation: SELECT

CREATE POLICY "Anyone can view avatars"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'avatars');
```

---

### 3. Verify Bucket Configuration

Di Supabase Dashboard → Storage → avatars:

**Settings**:

- ✅ Public: YES
- ✅ File size limit: 2097152 bytes (2MB)
- ✅ Allowed MIME types: image/jpeg, image/png, image/webp

**Policies** (4 policies total):

- ✅ Users can upload own avatar (INSERT)
- ✅ Users can update own avatar (UPDATE)
- ✅ Users can delete own avatar (DELETE)
- ✅ Anyone can view avatars (SELECT)

---

### 4. Test Upload (Optional)

Test upload via SQL Editor:

```sql
-- Get bucket info
SELECT * FROM storage.buckets WHERE name = 'avatars';

-- Check policies
SELECT * FROM storage.policies WHERE bucket_id = 'avatars';

-- Test file structure
-- Expected path: avatars/{user_id}/avatar.jpg
```

---

### 5. Flutter Integration

File path structure:

```
avatars/
├── {user_id_1}/
│   └── avatar.jpg
├── {user_id_2}/
│   └── avatar.jpg
└── {user_id_3}/
    └── avatar.jpg
```

Public URL format:

```
https://{project_ref}.supabase.co/storage/v1/object/public/avatars/{user_id}/avatar.jpg
```

---

## 🔐 Security Features

### Implemented:

- ✅ **Row Level Security (RLS)**: Users can only upload/update/delete their own avatar
- ✅ **Public Read**: Anyone can view avatars (for profile display)
- ✅ **File Size Limit**: Maximum 2MB per image
- ✅ **MIME Type Validation**: Only jpg, png, webp allowed
- ✅ **Path-based Security**: Users must use their UUID in path

### Path Structure:

- Correct: `avatars/{user_uuid}/avatar.jpg` ✅
- Incorrect: `avatars/random_name.jpg` ❌ (blocked by policy)
- Incorrect: `avatars/{other_user_uuid}/avatar.jpg` ❌ (blocked by policy)

---

## 🧪 Testing Checklist

After setup, verify:

- [ ] Bucket `avatars` exists
- [ ] Bucket is public
- [ ] File size limit is 2MB
- [ ] 4 RLS policies are active
- [ ] Test upload via Flutter app
- [ ] Verify public URL works
- [ ] Test update (replace existing)
- [ ] Test delete
- [ ] Verify other users can't access your upload

---

## 📝 Notes

- **Auto-replace**: Upload dengan `upsert: true` akan replace file existing
- **Caching**: Default cache control 3600s (1 hour)
- **Path Convention**: Always use `{user_id}/avatar.jpg` format
- **Cleanup**: Old avatars otomatis ter-replace saat upload baru
- **Future Use**: Struktur ini juga akan dipakai untuk face recognition images di Phase 2

---

## 🚀 Next Steps

After bucket setup:

1. ✅ Test ImageUploadService dengan real upload
2. ✅ Buat ProfileRepository yang uses ImageUploadService
3. ✅ Integrate ke EditProfileScreen

---

**Status**: ⏳ **MANUAL SETUP REQUIRED**  
**Estimated Time**: 10 minutes  
**Priority**: 🔥 **CRITICAL** (Blocking profile edit feature)

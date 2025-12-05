# Edge Function Deployment - Quick Start Guide

**Target**: Deploy `send-emergency-fcm` Edge Function + Cron Job  
**Time**: 15-20 menit  
**Cost**: $0 (100% FREE)  
**Date**: 12 November 2025

---

## 📋 Prerequisites Checklist

Sebelum mulai, pastikan sudah ada:

- [x] Firebase project **aivia-aaeca** sudah dibuat
- [x] Supabase project sudah setup
- [x] Edge Function file sudah dibuat: `supabase/functions/send-emergency-fcm/index.ts`
- [ ] Supabase CLI installed
- [ ] Firebase service account JSON
- [ ] Supabase project credentials

---

## 🚀 Deployment Steps (5 Langkah)

### Step 1: Install Supabase CLI

```powershell
# Install via NPM
npm install -g supabase

# Verify installation
supabase --version
# Expected: v1.127.0 or later
```

---

### Step 2: Login & Link Supabase Project

```powershell
# 1. Login via browser (satu kali saja)
supabase login

# 2. Navigate to project
cd "C:\Users\mikhs\OneDrive\Documents\Semester 5\Praktikum Pemograman Bergerak\project_aivia"

# 3. Link to remote project
supabase link

# Akan muncul list projects, pilih project AIVIA
# Atau jika tau project reference:
supabase link --project-ref YOUR_PROJECT_REF

# Find PROJECT_REF dari URL Dashboard:
# https://supabase.com/dashboard/project/[PROJECT_REF]
```

✅ **Verify**: Run `supabase projects list` dan lihat project AIVIA ada checkmark

---

### Step 3: Setup Firebase Service Account

#### 3a. Download Service Account JSON

1. Buka [Firebase Console](https://console.firebase.google.com/)
2. Pilih project **aivia-aaeca**
3. Click ⚙️ **Project Settings** → **Service Accounts** tab
4. Click **Generate new private key** → Confirm
5. File downloaded: `aivia-aaeca-firebase-adminsdk-xxxxx.json`

#### 3b. Secure the File

```powershell
# Create secure folder (gitignored)
New-Item -Path ".\.credentials" -ItemType Directory -Force

# Move file ke folder secure
Move-Item -Path "Downloads\aivia-aaeca-firebase-adminsdk-*.json" `
          -Destination ".\.credentials\firebase-service-account.json"

# Verify file exists
Test-Path ".\.credentials\firebase-service-account.json"
# Expected: True
```

#### 3c. Add to .gitignore

```powershell
# Add to gitignore
Add-Content -Path ".gitignore" -Value "`n# Firebase credentials`n.credentials/"
```

---

### Step 4: Set Supabase Secrets (3 Secrets)

```powershell
# Secret 1: Firebase Service Account (from file)
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(Get-Content -Path '.\.credentials\firebase-service-account.json' -Raw)"

# Secret 2: Supabase URL (from dashboard)
# Go to: Dashboard → Project Settings → API → Project URL
supabase secrets set SUPABASE_URL="https://YOUR_PROJECT_REF.supabase.co"

# Secret 3: Supabase Service Role Key (from dashboard)
# Go to: Dashboard → Project Settings → API → service_role (secret)
supabase secrets set SUPABASE_SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Verify all secrets set
supabase secrets list
```

✅ **Expected output**:

```
NAME                          DIGEST
FIREBASE_SERVICE_ACCOUNT      abc123...
SUPABASE_URL                  def456...
SUPABASE_SERVICE_ROLE_KEY     ghi789...
```

---

### Step 5: Deploy Edge Function

```powershell
# Deploy function to Supabase
supabase functions deploy send-emergency-fcm

# Verify deployment
supabase functions list
```

✅ **Expected output**:

```
NAME                 STATUS    VERSION   UPDATED
send-emergency-fcm   ACTIVE    1         2025-11-12
```

---

## ⏰ Setup Cron Job (2 Cara)

### Cara 1: Via Supabase SQL Editor (RECOMMENDED)

1. Buka Supabase Dashboard → **SQL Editor**
2. Click **New Query**
3. Copy-paste script ini:

```sql
-- Enable pg_cron
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Set service role key (REPLACE dengan key dari Dashboard)
ALTER DATABASE postgres SET app.settings.service_role_key = 'YOUR_SERVICE_ROLE_KEY';

-- Schedule cron job (every 30 seconds)
SELECT cron.schedule(
  'send-emergency-notifications',
  '*/1 * * * *',  -- Every 1 minute (safer than 30s for free tier)
  $$
  SELECT
    net.http_post(
      url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-emergency-fcm',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
      ),
      body := '{}'::jsonb
    ) AS request_id;
  $$
);

-- Verify job created
SELECT * FROM cron.job;
```

4. **IMPORTANT**: Replace 2 values:

   - `YOUR_SERVICE_ROLE_KEY` → service role key dari Dashboard
   - `YOUR_PROJECT_REF` → project reference dari URL

5. Click **Run** (F5)

✅ **Expected**: "Successfully run. 1 rows returned" dan lihat job di result

---

### Cara 2: Via Migration File (ALTERNATIVE)

```powershell
# Edit file untuk set project reference
code "database\013_edge_function_cron.sql"

# Update line ~75: project_ref := 'YOUR_PROJECT_REF';
# Save file

# Run migration via Supabase dashboard:
# 1. Buka SQL Editor
# 2. Paste seluruh isi file 013_edge_function_cron.sql
# 3. Click Run
```

---

## ✅ Verification (5 Checks)

### Check 1: Edge Function Deployed

```powershell
supabase functions list
# Expected: send-emergency-fcm = ACTIVE
```

### Check 2: Secrets Set

```powershell
supabase secrets list
# Expected: 3 secrets listed
```

### Check 3: Cron Job Active

```sql
-- Run in Supabase SQL Editor
SELECT jobname, schedule, active
FROM cron.job
WHERE jobname = 'send-emergency-notifications';

-- Expected: 1 row, active = true
```

### Check 4: Manual Function Test

```powershell
# Get anon key from Dashboard → Project Settings → API
$anonKey = "YOUR_ANON_KEY"
$projectRef = "YOUR_PROJECT_REF"

$headers = @{
    "Authorization" = "Bearer $anonKey"
    "Content-Type" = "application/json"
}

$response = Invoke-RestMethod `
    -Uri "https://$projectRef.supabase.co/functions/v1/send-emergency-fcm" `
    -Method Post `
    -Headers $headers `
    -Body '{}'

$response | ConvertTo-Json
```

✅ **Expected response**:

```json
{
  "timestamp": "2025-11-12T...",
  "total_processed": 0,
  "successful": 0,
  "failed": 0
}
```

### Check 5: Cron Job History

```sql
-- Run in SQL Editor
SELECT
  start_time,
  end_time,
  status,
  return_message
FROM cron.job_run_details
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'send-emergency-notifications')
ORDER BY start_time DESC
LIMIT 5;

-- Expected: See recent runs (within last 5 minutes)
```

---

## 🔍 Monitoring Commands

### View Function Logs (Real-time)

```powershell
# Stream logs
supabase functions logs send-emergency-fcm --tail

# Filter errors only
supabase functions logs send-emergency-fcm --tail | Select-String "ERROR"
```

### Check Notification Status (SQL)

```sql
-- Count pending vs sent (last hour)
SELECT
  status,
  COUNT(*) as total
FROM pending_notifications
WHERE created_at > NOW() - INTERVAL '1 hour'
GROUP BY status;
```

### Check Cron Health (SQL)

```sql
-- Last 10 cron runs
SELECT
  start_time,
  status,
  return_message
FROM cron.job_run_details
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'send-emergency-notifications')
ORDER BY start_time DESC
LIMIT 10;

-- Success rate (last 24h)
SELECT
  status,
  COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () as percentage
FROM cron.job_run_details
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'send-emergency-notifications')
  AND start_time > NOW() - INTERVAL '24 hours'
GROUP BY status;
```

---

## 🐛 Troubleshooting

### Problem: Function deployment failed

**Error**: `unauthorized` atau `project not linked`

**Solution**:

```powershell
supabase login
supabase link
supabase functions deploy send-emergency-fcm
```

---

### Problem: Secrets not working

**Error**: `Could not load the default credentials`

**Solution**:

```powershell
# Re-set secrets
supabase secrets unset FIREBASE_SERVICE_ACCOUNT
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(Get-Content -Path '.\.credentials\firebase-service-account.json' -Raw)"

# Redeploy function
supabase functions deploy send-emergency-fcm
```

---

### Problem: Cron job not running

**Check 1**: Job exists?

```sql
SELECT * FROM cron.job WHERE jobname = 'send-emergency-notifications';
-- Expected: 1 row
```

**Check 2**: Job active?

```sql
UPDATE cron.job
SET active = true
WHERE jobname = 'send-emergency-notifications';
```

**Check 3**: Service role key set?

```sql
SHOW app.settings.service_role_key;
-- Should show your key
```

**Solution**: Recreate job

```sql
SELECT cron.unschedule('send-emergency-notifications');
-- Then run Step 5 Cara 1 again
```

---

### Problem: No notifications sent

**Check**: Pending notifications exist?

```sql
SELECT * FROM pending_notifications WHERE status = 'pending' LIMIT 5;
```

**Check**: FCM tokens exist?

```sql
SELECT * FROM fcm_tokens WHERE is_active = true LIMIT 5;
```

**Check**: Function logs

```powershell
supabase functions logs send-emergency-fcm --tail
```

---

## 📊 Usage Monitoring

### Free Tier Limits

- **Edge Functions**: 500K invocations/month ✅
- **Cron with 1 min interval**: ~43K invocations/month ✅
- **Well within limits** 🎉

### Adjust Schedule if Needed

```sql
-- Change to 5 minutes (more conservative)
SELECT cron.alter_job(
  job_id := (SELECT jobid FROM cron.job WHERE jobname = 'send-emergency-notifications'),
  schedule := '*/5 * * * *'
);
```

---

## ✅ Deployment Checklist

Before marking complete:

- [ ] Supabase CLI installed & logged in
- [ ] Project linked
- [ ] Firebase service account secured
- [ ] 3 secrets configured
- [ ] Edge Function deployed (ACTIVE status)
- [ ] Cron job created (active = true)
- [ ] Manual test passed (200 response)
- [ ] Cron history shows runs
- [ ] Function logs accessible
- [ ] No errors in logs

---

## 📝 Next Steps

After deployment complete:

1. ✅ Deploy remaining database migrations (007-011)
2. ✅ Test end-to-end emergency flow
3. ✅ Run flutter analyze
4. ✅ Create completion report

---

## 🎯 Quick Command Reference

```powershell
# Deploy function
supabase functions deploy send-emergency-fcm

# View logs
supabase functions logs send-emergency-fcm --tail

# List secrets
supabase secrets list

# Check cron (SQL)
SELECT * FROM cron.job;
SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 10;
```

---

**Status**: 🚀 Ready to Deploy  
**Time Required**: 15-20 minutes  
**Cost**: $0/month (FREE tier)

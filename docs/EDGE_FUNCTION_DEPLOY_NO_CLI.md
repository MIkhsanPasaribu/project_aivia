# Edge Function Deployment - Tanpa CLI (Dashboard Only)

**Alternative Method**: Deploy Edge Function **tanpa install Supabase CLI**  
**Time**: 10-15 menit  
**Cost**: $0 (100% FREE)  
**Date**: 19 November 2025

---

## 🎯 Why This Method?

Supabase CLI install sering bermasalah di Windows. Method ini menggunakan **Supabase Dashboard UI** saja - lebih mudah dan tidak perlu install tools tambahan!

---

## 📋 Prerequisites

- [x] Firebase project **aivia-aaeca** sudah dibuat
- [x] Supabase project sudah setup
- [x] Edge Function code sudah ada: `supabase/functions/send-emergency-fcm/index.ts`
- [x] Browser (Chrome/Edge/Firefox)
- [x] Akses ke Firebase Console
- [x] Akses ke Supabase Dashboard

---

## 🚀 Deployment Steps (4 Langkah Utama)

### Step 1: Setup Firebase Service Account (5 min)

#### 1a. Download Service Account JSON

1. Buka [Firebase Console](https://console.firebase.google.com/)
2. Pilih project **aivia-aaeca**
3. Click ⚙️ **Project Settings** → tab **Service Accounts**
4. Click **Generate new private key**
5. Click **Generate key** (confirm)
6. File downloaded: `aivia-aaeca-firebase-adminsdk-xxxxx.json`

#### 1b. Secure the File

```powershell
# Navigate to project
cd "C:\Users\mikhs\OneDrive\Documents\Semester 5\Praktikum Pemograman Bergerak\project_aivia"

# Create secure folder
New-Item -Path ".\.credentials" -ItemType Directory -Force

# Move downloaded file (adjust filename jika berbeda)
Move-Item -Path "$env:USERPROFILE\Downloads\aivia-aaeca-firebase-adminsdk-*.json" `
          -Destination ".\.credentials\firebase-service-account.json"

# Verify
Test-Path ".\.credentials\firebase-service-account.json"
# Expected: True
```

#### 1c. Add to .gitignore

```powershell
# Prevent committing credentials to git
Add-Content -Path ".gitignore" -Value "`n# Firebase credentials`n.credentials/"

# Verify
Get-Content ".gitignore" | Select-String ".credentials"
```

#### 1d. Copy JSON Content

```powershell
# Open file dan copy ENTIRE content (semua text dalam file)
notepad ".\.credentials\firebase-service-account.json"

# ATAU copy via PowerShell
Get-Content ".\.credentials\firebase-service-account.json" -Raw | Set-Clipboard
Write-Host "✅ JSON content copied to clipboard!" -ForegroundColor Green
```

**⚠️ PENTING**: Content JSON akan di-paste ke Supabase Dashboard nanti

---

### Step 2: Configure Supabase Secrets via Dashboard (5 min)

#### 2a. Open Supabase Dashboard

1. Buka [Supabase Dashboard](https://supabase.com/dashboard)
2. Login dengan akun Anda
3. Pilih project **AIVIA**

#### 2b. Navigate to Edge Functions Settings

1. Sidebar → **Edge Functions**
2. Click tab **Settings** (or **Secrets**)

#### 2c. Add Secret: FIREBASE_SERVICE_ACCOUNT

1. Click **Add new secret** atau **New secret**
2. **Name**: `FIREBASE_SERVICE_ACCOUNT`
3. **Value**: Paste JSON content dari Step 1d (entire JSON)
4. Click **Save** atau **Add**

#### 2d. Add Secret: SERVICE_ROLE_KEY

1. Go to: Dashboard → **Project Settings** → **API**
2. Find **service_role** key (section: **Project API keys**)
3. Click **👁️ Reveal** → Copy key
4. Back to Edge Functions → Secrets
5. Add new secret:
   - **Name**: `SERVICE_ROLE_KEY` ⚠️ **PENTING: Jangan pakai prefix SUPABASE\_**
   - **Value**: Paste service role key
6. Click **Save**

✅ **Verify**: You should see **2 secrets** listed:

- FIREBASE_SERVICE_ACCOUNT
- SERVICE_ROLE_KEY

**📝 Note**: `SUPABASE_URL` sudah **otomatis tersedia** sebagai built-in environment variable dari Supabase, tidak perlu ditambahkan manual!

---

### Step 3: Deploy Edge Function via Dashboard (3 min)

#### 3a. Prepare Function Code

```powershell
# Navigate to function directory
cd "C:\Users\mikhs\OneDrive\Documents\Semester 5\Praktikum Pemograman Bergerak\project_aivia\supabase\functions\send-emergency-fcm"

# Verify file exists
Test-Path "index.ts"
# Expected: True

# Open file
code "index.ts"
# ATAU
notepad "index.ts"
```

#### 3b. Copy Function Code

1. Select **ALL** content in `index.ts` (Ctrl+A)
2. Copy (Ctrl+C)

#### 3c. Create Function in Dashboard

1. Go to: Supabase Dashboard → **Edge Functions**
2. Click **Create a new function** atau **+ New function**
3. **Function name**: `send-emergency-fcm`
4. **Editor**: Paste code dari clipboard (Ctrl+V)
5. Click **Save** atau **Deploy**

⏳ **Wait**: Deployment takes ~30-60 seconds

✅ **Success**: Function shows status **"Deployed"** atau **"Active"**

---

### Step 4: Setup Cron Job via SQL Editor (5 min)

#### 4a. Get Your Project Reference

1. Look at browser URL: `https://supabase.com/dashboard/project/[PROJECT_REF]`
2. Copy the `PROJECT_REF` part (e.g., `abcdefghijklmnop`)

#### 4b. Get Service Role Key (Again)

1. Dashboard → **Project Settings** → **API**
2. Copy **service_role** key

#### 4c. Open SQL Editor

1. Sidebar → **SQL Editor**
2. Click **New query**

#### 4d. Run Cron Setup SQL

Copy-paste script ini ke SQL Editor:

```sql
-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Set service role key (REPLACE dengan key Anda)
ALTER DATABASE postgres SET app.settings.service_role_key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR2cmttcHRtZWh1dnJkZ3lreXRjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTg5NTk3MiwiZXhwIjoyMDc1NDcxOTcyfQ.OVQjH0dhyvQkoNQmOG9pDT2rMWaCnYR6iATgiCim3B8';

-- Schedule cron job (every 1 minute)
SELECT cron.schedule(
  'send-emergency-notifications',
  '*/1 * * * *',  -- Every 1 minute
  $$
  SELECT
    net.http_post(
      url := 'https://tvrkmptmehuvrdgykytc.supabase.co/functions/v1/send-emergency-fcm',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
      ),
      body := '{}'::jsonb,
      timeout_milliseconds := 30000
    ) AS request_id;
  $$
);

-- Verify job created
SELECT jobname, schedule, active FROM cron.job;
```

**⚠️ IMPORTANT**: Replace 2 values:z

1. Line 6: `YOUR_SERVICE_ROLE_KEY_HERE` → service role key Anda
2. Line 14: `YOUR_PROJECT_REF_HERE` → project ref dari Step 4a

#### 4e. Execute Query

1. Click **Run** atau press **F5**
2. Wait for execution (~5 seconds)

✅ **Expected output**:

- "Successfully run"
- Result table shows 1 row with job name `send-emergency-notifications`

---

## ✅ Verification (4 Checks)

### Check 1: Edge Function Status

1. Dashboard → **Edge Functions**
2. Find `send-emergency-fcm`
3. Status should be: **Deployed** atau **Active** ✅

### Check 2: Secrets Configured

1. Edge Functions → **Secrets** tab
2. Should see 3 secrets listed ✅

### Check 3: Cron Job Active

Run in SQL Editor:

```sql
SELECT jobname, schedule, active
FROM cron.job
WHERE jobname = 'send-emergency-notifications';
```

Expected: 1 row, `active = true` ✅

### Check 4: Cron Job Running

Wait 2-3 minutes, then run:

```sql
SELECT
  start_time,
  end_time,
  status,
  return_message
FROM cron.job_run_details
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'send-emergency-notifications')
ORDER BY start_time DESC
LIMIT 5;
```

Expected: See recent runs (status should be `succeeded` or similar) ✅

---

## 🐛 Troubleshooting

### Problem: Cannot create function in dashboard

**Solution**:

- Check if you're on correct project
- Verify you have Owner/Admin permissions
- Try refreshing page

---

### Problem: Secrets not saving

**Solution**:

- Verify JSON is valid (use [JSONLint](https://jsonlint.com/))
- Check for trailing spaces/newlines
- Try copy-paste again

---

### Problem: Cron job fails

**Check 1**: Service role key correct?

```sql
SHOW app.settings.service_role_key;
-- Should show your key (not empty)
```

**Check 2**: Project ref correct in URL?

```sql
-- Verify URL accessible
SELECT net.http_get(
  'https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-emergency-fcm'
);
```

**Solution**: Re-run SQL with correct values

---

### Problem: No notifications sent

**Check**: Pending notifications exist?

```sql
SELECT * FROM pending_notifications
WHERE status = 'pending'
LIMIT 5;
```

If empty → Create test notification:

```sql
INSERT INTO pending_notifications (
  recipient_user_id,
  notification_type,
  title,
  body,
  data,
  scheduled_at
) VALUES (
  (SELECT id FROM profiles LIMIT 1),  -- Use any user ID
  'test',
  'Test Notification',
  'Testing Edge Function',
  '{}'::jsonb,
  NOW()
);
```

Wait 1 minute, then check:

```sql
SELECT * FROM pending_notifications
WHERE notification_type = 'test'
ORDER BY created_at DESC LIMIT 1;
-- status should change to 'sent'
```

---

## 📊 Monitoring via Dashboard

### View Function Logs

1. Dashboard → **Edge Functions**
2. Click `send-emergency-fcm`
3. Tab **Logs**
4. Filter: Last 1 hour, All levels

You'll see:

- Function invocations
- Successful sends
- Errors (if any)

### View Cron Job History

Run in SQL Editor:

```sql
-- Last 10 runs
SELECT
  start_time,
  end_time,
  status,
  return_message
FROM cron.job_run_details
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'send-emergency-notifications')
ORDER BY start_time DESC
LIMIT 10;

-- Success rate (last 24h)
SELECT
  status,
  COUNT(*) as total,
  COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () as percentage
FROM cron.job_run_details
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'send-emergency-notifications')
  AND start_time > NOW() - INTERVAL '24 hours'
GROUP BY status;
```

---

## ✅ Deployment Checklist

- [ ] Firebase service account JSON downloaded & secured
- [ ] JSON added to .gitignore
- [ ] 3 Supabase secrets configured
- [ ] Edge Function deployed (status: Active)
- [ ] Cron job created (active = true)
- [ ] Cron job history shows runs
- [ ] Function logs accessible
- [ ] Test notification sent & received

---

## 🎯 Next Steps

After deployment complete:

1. ✅ Deploy database migrations (007-011)
   - Follow: `docs/DATABASE_MIGRATIONS_DEPLOY.md`
2. ✅ Test emergency flow end-to-end
   - Trigger emergency button in app
   - Verify notification received
3. ✅ Monitor for 24 hours
   - Check cron job success rate
   - Review function logs
   - Verify no errors

---

## 💡 Tips

### Adjust Cron Schedule

If needed, change interval:

```sql
-- Change to every 5 minutes (more conservative)
SELECT cron.alter_job(
  job_id := (SELECT jobid FROM cron.job WHERE jobname = 'send-emergency-notifications'),
  schedule := '*/5 * * * *'
);

-- Verify change
SELECT schedule FROM cron.job WHERE jobname = 'send-emergency-notifications';
```

### Temporarily Disable Cron

```sql
-- Disable
UPDATE cron.job
SET active = false
WHERE jobname = 'send-emergency-notifications';

-- Re-enable
UPDATE cron.job
SET active = true
WHERE jobname = 'send-emergency-notifications';
```

---

## 📚 Additional Resources

- [Supabase Edge Functions Docs](https://supabase.com/docs/guides/functions)
- [Firebase Admin SDK Docs](https://firebase.google.com/docs/admin/setup)
- [pg_cron Documentation](https://github.com/citusdata/pg_cron)

---

## ✨ Advantages of This Method

✅ **No CLI installation hassle**  
✅ **Visual interface (easier to understand)**  
✅ **Works on any OS (Windows/Mac/Linux)**  
✅ **No permission issues**  
✅ **Easier troubleshooting (logs in dashboard)**

---

**Status**: 🚀 Ready to Deploy (No CLI Required)  
**Time**: 10-15 minutes  
**Cost**: $0/month (FREE tier)  
**Difficulty**: ⭐⭐ Easy

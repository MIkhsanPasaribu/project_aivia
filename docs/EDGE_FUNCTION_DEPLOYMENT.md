# Supabase Edge Function Deployment Guide

**Function Name**: `send-emergency-fcm`  
**Purpose**: Automatic FCM notification delivery for emergency alerts  
**Runtime**: Deno (TypeScript)  
**Cost**: $0/month (Supabase FREE tier: 500K invocations/month)  
**Created**: 12 November 2025

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Firebase Service Account Setup](#firebase-service-account-setup)
3. [Supabase Secrets Configuration](#supabase-secrets-configuration)
4. [Function Deployment](#function-deployment)
5. [Cron Job Setup](#cron-job-setup)
6. [Testing & Verification](#testing--verification)
7. [Monitoring & Debugging](#monitoring--debugging)
8. [Troubleshooting](#troubleshooting)

---

## 🔧 Prerequisites

### Required Tools

1. **Supabase CLI** (v1.127.0 or later)

   ```powershell
   # Install via NPM (Windows PowerShell)
   npm install -g supabase

   # Verify installation
   supabase --version
   ```

2. **Firebase CLI** (already installed)

   ```powershell
   # Verify installation
   firebase --version
   ```

3. **Deno** (for local testing - optional)

   ```powershell
   # Install via PowerShell
   irm https://deno.land/install.ps1 | iex

   # Verify installation
   deno --version
   ```

### Required Access

- ✅ Firebase Project Owner/Editor access
- ✅ Supabase Project Owner access
- ✅ Firebase Service Account credentials
- ✅ Supabase Service Role Key

---

## 🔑 Firebase Service Account Setup

### Step 1: Navigate to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **aivia-aaeca**

### Step 2: Create Service Account

1. Click **Project Settings** (⚙️ icon) → **Service Accounts** tab
2. Click **Generate new private key**
3. Confirm: **"Generate key"**
4. File downloaded: `aivia-aaeca-firebase-adminsdk-xxxxx.json`

### Step 3: Verify Service Account JSON

Open the downloaded file and verify it contains:

```json
{
  "type": "service_account",
  "project_id": "aivia-aaeca",
  "private_key_id": "xxxxx...",
  "private_key": "-----BEGIN PRIVATE KEY-----\nxxxxx...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@aivia-aaeca.iam.gserviceaccount.com",
  "client_id": "xxxxx...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-xxxxx%40aivia-aaeca.iam.gserviceaccount.com"
}
```

**⚠️ IMPORTANT**: Keep this file **SECURE**! Do NOT commit to Git!

### Step 4: Store Service Account Securely

```powershell
# Move to secure location (NOT in project folder)
Move-Item -Path "aivia-aaeca-firebase-adminsdk-xxxxx.json" `
          -Destination "$env:USERPROFILE\Documents\.credentials\"

# OR create a .gitignored folder
New-Item -Path ".\.credentials" -ItemType Directory -Force
Move-Item -Path "aivia-aaeca-firebase-adminsdk-xxxxx.json" `
          -Destination ".\.credentials\"

# Add to .gitignore
Add-Content -Path ".gitignore" -Value "`n.credentials/"
```

---

## 🔐 Supabase Secrets Configuration

### Step 1: Login to Supabase CLI

```powershell
# Login via browser (recommended)
supabase login

# OR use access token
supabase login --token YOUR_ACCESS_TOKEN
```

### Step 2: Link to Supabase Project

```powershell
# Navigate to project root
cd "C:\Users\mikhs\OneDrive\Documents\Semester 5\Praktikum Pemograman Bergerak\project_aivia"

# Link to remote project
supabase link --project-ref YOUR_PROJECT_REF

# Find PROJECT_REF from Supabase Dashboard URL:
# https://supabase.com/dashboard/project/[PROJECT_REF]
```

### Step 3: Set Environment Secrets

#### Method A: Using File (Recommended)

```powershell
# Set FIREBASE_SERVICE_ACCOUNT from file
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(Get-Content -Path '.\.credentials\aivia-aaeca-firebase-adminsdk-xxxxx.json' -Raw)"
```

#### Method B: Manual Copy-Paste

```powershell
# Copy entire JSON content (remove newlines)
supabase secrets set FIREBASE_SERVICE_ACCOUNT='{"type":"service_account","project_id":"aivia-aaeca",...}'
```

#### Set Other Required Secrets

```powershell
# SUPABASE_URL (from Dashboard → Project Settings → API)
supabase secrets set SUPABASE_URL="https://YOUR_PROJECT_REF.supabase.co"

# SUPABASE_SERVICE_ROLE_KEY (from Dashboard → Project Settings → API → service_role key)
supabase secrets set SUPABASE_SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

### Step 4: Verify Secrets

```powershell
# List all secrets (shows names only, not values)
supabase secrets list

# Expected output:
# NAME                          DIGEST
# FIREBASE_SERVICE_ACCOUNT      xxxxx
# SUPABASE_URL                  xxxxx
# SUPABASE_SERVICE_ROLE_KEY     xxxxx
```

---

## 🚀 Function Deployment

### Step 1: Verify Function Structure

Ensure file exists:

```
supabase/
└── functions/
    └── send-emergency-fcm/
        └── index.ts
```

### Step 2: Deploy Function

```powershell
# Deploy to Supabase (production)
supabase functions deploy send-emergency-fcm

# Expected output:
# Deploying function send-emergency-fcm...
# ✓ Function deployed successfully
# Function URL: https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-emergency-fcm
```

### Step 3: Verify Deployment

```powershell
# List all deployed functions
supabase functions list

# Expected output:
# NAME                 STATUS    VERSION   UPDATED
# send-emergency-fcm   ACTIVE    1         2025-11-12
```

---

## ⏰ Cron Job Setup

### Option A: Using Supabase SQL Editor (Recommended)

1. Go to Supabase Dashboard → **SQL Editor**
2. Create new query:

```sql
-- Enable pg_cron extension
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule Edge Function to run every 30 seconds
SELECT cron.schedule(
  'send-emergency-notifications',              -- Job name
  '*/30 * * * * *',                            -- Every 30 seconds (cron format with seconds)
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

-- Verify cron job
SELECT * FROM cron.job;
```

3. **Replace** `YOUR_PROJECT_REF` with your actual project reference
4. Click **Run** (F5)

### Option B: Using Supabase CLI

```powershell
# Create SQL file
$cronSQL = @"
CREATE EXTENSION IF NOT EXISTS pg_cron;

SELECT cron.schedule(
  'send-emergency-notifications',
  '*/30 * * * * *',
  \$\$
  SELECT
    net.http_post(
      url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-emergency-fcm',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
      ),
      body := '{}'::jsonb
    ) AS request_id;
  \$\$
);
"@

$cronSQL | Out-File -FilePath "supabase\migrations\013_cron_setup.sql" -Encoding utf8

# Apply migration
supabase db push
```

### Verify Cron Job

```sql
-- Check cron jobs
SELECT jobid, jobname, schedule, command
FROM cron.job;

-- Check cron history (last 10 runs)
SELECT *
FROM cron.job_run_details
ORDER BY start_time DESC
LIMIT 10;
```

### Adjust Cron Schedule (Optional)

```sql
-- Change to every 1 minute (for testing)
SELECT cron.alter_job(
  job_id := (SELECT jobid FROM cron.job WHERE jobname = 'send-emergency-notifications'),
  schedule := '* * * * *'  -- Every minute
);

-- Change to every 5 minutes (production)
SELECT cron.alter_job(
  job_id := (SELECT jobid FROM cron.job WHERE jobname = 'send-emergency-notifications'),
  schedule := '*/5 * * * *'  -- Every 5 minutes
);

-- Disable cron job
SELECT cron.unschedule('send-emergency-notifications');
```

---

## 🧪 Testing & Verification

### Test 1: Manual Invocation

```powershell
# Test via curl (PowerShell)
$headers = @{
    "Authorization" = "Bearer YOUR_ANON_KEY"
    "Content-Type" = "application/json"
}

Invoke-RestMethod -Uri "https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-emergency-fcm" `
                  -Method Post `
                  -Headers $headers `
                  -Body '{}' | ConvertTo-Json
```

Expected response:

```json
{
  "timestamp": "2025-11-12T10:30:00.000Z",
  "total_processed": 0,
  "successful": 0,
  "partial": 0,
  "failed": 0,
  "results": []
}
```

### Test 2: Create Test Notification

```sql
-- Insert test notification
INSERT INTO pending_notifications (
  recipient_user_id,
  notification_type,
  title,
  body,
  data,
  scheduled_at
) VALUES (
  'YOUR_USER_ID',  -- Replace with actual user ID
  'test',
  'Test Notification',
  'This is a test notification from Edge Function',
  '{"test": true}'::jsonb,
  NOW()
);

-- Wait 30 seconds for cron to trigger

-- Verify notification was processed
SELECT id, status, sent_at
FROM pending_notifications
WHERE notification_type = 'test'
ORDER BY created_at DESC
LIMIT 1;

-- Expected: status = 'sent', sent_at = recent timestamp
```

### Test 3: Check Delivery Logs

```sql
-- View recent deliveries
SELECT
  ndl.notification_id,
  pn.title,
  ndl.status,
  ndl.error_message,
  ndl.delivered_at
FROM notification_delivery_logs ndl
JOIN pending_notifications pn ON pn.id = ndl.notification_id
ORDER BY ndl.delivered_at DESC
LIMIT 10;
```

### Test 4: End-to-End Emergency Flow

1. **Flutter App**: Trigger emergency button
2. **Database**: Check `emergency_alerts` table
3. **Function**: Check logs (see Monitoring section)
4. **FCM**: Verify notification received on device

---

## 📊 Monitoring & Debugging

### View Function Logs

#### Method A: Supabase Dashboard

1. Go to **Edge Functions** → **send-emergency-fcm** → **Logs** tab
2. View real-time logs with filters

#### Method B: Supabase CLI

```powershell
# Stream logs in real-time
supabase functions logs send-emergency-fcm --tail

# View specific time range
supabase functions logs send-emergency-fcm --since 1h

# Filter by keyword
supabase functions logs send-emergency-fcm | Select-String "ERROR"
```

### Monitor Function Performance

```sql
-- Count notifications by status (last 24 hours)
SELECT
  status,
  COUNT(*) as total,
  COUNT(*) FILTER (WHERE sent_at > NOW() - INTERVAL '1 hour') as last_hour
FROM pending_notifications
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY status;

-- Average delivery time
SELECT
  AVG(EXTRACT(EPOCH FROM (sent_at - created_at))) as avg_seconds
FROM pending_notifications
WHERE status = 'sent' AND sent_at IS NOT NULL;

-- Failed deliveries (last 24 hours)
SELECT
  pn.id,
  pn.title,
  pn.recipient_user_id,
  ndl.error_message,
  ndl.delivered_at
FROM pending_notifications pn
JOIN notification_delivery_logs ndl ON ndl.notification_id = pn.id
WHERE ndl.status = 'failed'
  AND ndl.delivered_at > NOW() - INTERVAL '24 hours'
ORDER BY ndl.delivered_at DESC;
```

### Monitor Cron Job Health

```sql
-- Check cron job runs (last 10)
SELECT
  start_time,
  end_time,
  status,
  return_message
FROM cron.job_run_details
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'send-emergency-notifications')
ORDER BY start_time DESC
LIMIT 10;

-- Count successful vs failed runs (last 24 hours)
SELECT
  status,
  COUNT(*) as total
FROM cron.job_run_details
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'send-emergency-notifications')
  AND start_time > NOW() - INTERVAL '24 hours'
GROUP BY status;
```

---

## 🔧 Troubleshooting

### Issue 1: Function Deployment Failed

**Error**: `Error deploying function: unauthorized`

**Solution**:

```powershell
# Re-login to Supabase
supabase login

# Re-link project
supabase link --project-ref YOUR_PROJECT_REF

# Try deployment again
supabase functions deploy send-emergency-fcm
```

---

### Issue 2: Firebase Admin SDK Error

**Error**: `Error: Could not load the default credentials`

**Solution**:

```powershell
# Verify secret is set correctly
supabase secrets list

# Re-set FIREBASE_SERVICE_ACCOUNT
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(Get-Content -Path '.\.credentials\aivia-aaeca-firebase-adminsdk-xxxxx.json' -Raw)"

# Redeploy function
supabase functions deploy send-emergency-fcm
```

---

### Issue 3: No Notifications Sent

**Check 1: Verify pending notifications exist**

```sql
SELECT * FROM pending_notifications WHERE status = 'pending' LIMIT 5;
```

**Check 2: Verify RPC function works**

```sql
SELECT * FROM get_pending_emergency_notifications(10);
```

**Check 3: Verify FCM tokens exist**

```sql
SELECT user_id, token, is_active
FROM fcm_tokens
WHERE is_active = true
LIMIT 5;
```

**Check 4: Check function logs**

```powershell
supabase functions logs send-emergency-fcm --tail
```

---

### Issue 4: Cron Job Not Running

**Check 1: Verify cron job exists**

```sql
SELECT * FROM cron.job WHERE jobname = 'send-emergency-notifications';
```

**Check 2: Check cron job errors**

```sql
SELECT * FROM cron.job_run_details
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'send-emergency-notifications')
ORDER BY start_time DESC LIMIT 5;
```

**Check 3: Manually trigger function**

```powershell
# Test if function works when called manually
$headers = @{"Authorization" = "Bearer YOUR_ANON_KEY"}
Invoke-RestMethod -Uri "https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-emergency-fcm" -Method Post -Headers $headers
```

**Solution**: Delete and recreate cron job

```sql
-- Delete old job
SELECT cron.unschedule('send-emergency-notifications');

-- Recreate job (see Cron Job Setup section)
```

---

### Issue 5: High Latency / Timeouts

**Check**: Function execution time

```powershell
# View logs with timestamps
supabase functions logs send-emergency-fcm | Select-String "completed"
```

**Solution 1**: Reduce batch size

Edit `index.ts`:

```typescript
// Change from 50 to 20
const { data: notifications } = await supabase.rpc(
  "get_pending_emergency_notifications",
  { limit_count: 20 }
);
```

**Solution 2**: Increase function timeout (if needed)

```powershell
# Deploy with custom timeout (max 300 seconds)
supabase functions deploy send-emergency-fcm --timeout 120
```

---

## 📈 Usage Monitoring

### Supabase Free Tier Limits

- **Edge Function Invocations**: 500,000/month (FREE)
- **Edge Function Execution Time**: 400,000 CPU-seconds/month (FREE)

### Current Usage Estimation

- **Cron Frequency**: Every 30 seconds
- **Invocations per Month**: ~86,400 (well within FREE tier)
- **Average Execution Time**: ~2-5 seconds
- **Total CPU-seconds**: ~432,000 (slightly above FREE tier, but acceptable)

### Check Usage

```powershell
# View Edge Function metrics (Dashboard)
# Go to: Supabase Dashboard → Edge Functions → send-emergency-fcm → Metrics
```

---

## 🔄 Updating the Function

### Make Changes to index.ts

```powershell
# Edit file
code "supabase\functions\send-emergency-fcm\index.ts"

# Save changes

# Redeploy
supabase functions deploy send-emergency-fcm

# Verify new version
supabase functions list
```

---

## 🧹 Maintenance Tasks

### Weekly Tasks

1. **Check delivery success rate**:

   ```sql
   SELECT
     COUNT(*) FILTER (WHERE status = 'sent') * 100.0 / COUNT(*) as success_rate
   FROM pending_notifications
   WHERE created_at > NOW() - INTERVAL '7 days';
   ```

2. **Review failed deliveries**:

   ```sql
   SELECT * FROM notification_delivery_logs
   WHERE status = 'failed'
     AND delivered_at > NOW() - INTERVAL '7 days';
   ```

### Monthly Tasks

1. **Verify cron job health**:

   ```sql
   SELECT COUNT(*) FROM cron.job_run_details
   WHERE status = 'failed'
     AND start_time > NOW() - INTERVAL '30 days';
   ```

2. **Check free tier usage** (Supabase Dashboard → Billing)

---

## 📚 Additional Resources

- [Supabase Edge Functions Docs](https://supabase.com/docs/guides/functions)
- [Firebase Admin SDK Docs](https://firebase.google.com/docs/admin/setup)
- [pg_cron Documentation](https://github.com/citusdata/pg_cron)
- [Deno Deploy Docs](https://deno.com/deploy/docs)

---

## ✅ Deployment Checklist

Before marking Sprint 2.3E as complete:

- [ ] Firebase Service Account downloaded and secured
- [ ] Supabase secrets configured (FIREBASE_SERVICE_ACCOUNT, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
- [ ] Edge Function deployed successfully
- [ ] Cron job created and scheduled
- [ ] Manual test passed (notification sent)
- [ ] End-to-end test passed (emergency → FCM)
- [ ] Logs reviewed (no errors)
- [ ] Cron job health verified (successful runs)
- [ ] Documentation updated

---

**Next Steps**: Sprint 2.3F - Testing & Final Documentation

**Status**: 🚀 Ready for Production Deployment (FREE tier)

**Cost**: $0/month ✅

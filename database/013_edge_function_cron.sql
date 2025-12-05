-- =============================================================================
-- Migration 013: Edge Function Cron Job Setup
-- =============================================================================
-- Purpose: Schedule automatic FCM notification delivery via Edge Function
-- Created: 2025-11-12
-- Dependencies: Edge Function 'send-emergency-fcm' must be deployed first
-- FREE Service: pg_cron (built-in on Supabase)
-- =============================================================================

-- Description:
-- This migration sets up pg_cron to automatically call the Supabase Edge
-- Function 'send-emergency-fcm' every 30 seconds. The Edge Function processes
-- pending emergency notifications and sends them via Firebase Cloud Messaging.
--
-- Flow:
-- 1. pg_cron runs every 30 seconds
-- 2. Calls Edge Function via HTTP POST
-- 3. Edge Function processes pending_notifications table
-- 4. Sends FCM messages to recipients
-- 5. Logs delivery status to notification_delivery_logs
--
-- Benefits:
-- - Near real-time notification delivery (<30 seconds latency)
-- - Automatic retry for failed deliveries
-- - 100% FREE (pg_cron + Edge Functions free tier)
-- - No external cron service needed

-- =============================================================================
-- 1. ENABLE REQUIRED EXTENSIONS
-- =============================================================================

-- Enable pg_cron (available on Supabase FREE tier)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Enable pg_net for HTTP calls (available on Supabase)
CREATE EXTENSION IF NOT EXISTS pg_net;

-- =============================================================================
-- 2. CREATE HELPER FUNCTION: Get Supabase Service Role Key
-- =============================================================================

-- Function to retrieve service role key from vault
-- This is safer than hardcoding the key in SQL
CREATE OR REPLACE FUNCTION get_service_role_key()
RETURNS TEXT AS $$
BEGIN
  -- On Supabase, service role key is available via app settings
  -- This function should return the actual key value
  -- For security, the key should be stored in Supabase Vault
  
  -- IMPORTANT: Replace this with actual implementation
  -- Option 1: Use Supabase Vault (recommended)
  -- RETURN vault.get_secret('service_role_key');
  
  -- Option 2: Use PostgreSQL setting (set via dashboard)
  RETURN current_setting('app.settings.service_role_key', true);
  
  -- Option 3: Hardcode (NOT RECOMMENDED - use for testing only)
  -- RETURN 'your_service_role_key_here';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- 3. GET SUPABASE PROJECT URL
-- =============================================================================

-- Function to get current Supabase project URL
-- This dynamically constructs the Edge Function URL
CREATE OR REPLACE FUNCTION get_supabase_project_url()
RETURNS TEXT AS $$
DECLARE
  project_ref TEXT;
BEGIN
  -- Extract project reference from database connection
  -- Supabase format: postgres://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres
  
  -- Get current database host
  SELECT split_part(split_part(current_setting('listen_addresses'), '.', 2), '.', 1)
  INTO project_ref;
  
  -- If above doesn't work, use environment variable or hardcode
  IF project_ref IS NULL OR project_ref = '' THEN
    -- IMPORTANT: Replace with your actual project reference
    -- Find it from: https://supabase.com/dashboard/project/[PROJECT_REF]
    project_ref := 'YOUR_PROJECT_REF';
  END IF;
  
  RETURN 'https://' || project_ref || '.supabase.co';
END;
$$ LANGUAGE plpgsql STABLE;

-- =============================================================================
-- 4. CREATE CRON JOB: Send Emergency Notifications
-- =============================================================================

-- Remove existing job if it exists (for re-running this migration)
DO $$
BEGIN
  PERFORM cron.unschedule('send-emergency-notifications');
EXCEPTION
  WHEN OTHERS THEN NULL; -- Ignore error if job doesn't exist
END $$;

-- Schedule Edge Function to run every 30 seconds
SELECT cron.schedule(
  'send-emergency-notifications',              -- Job name
  '*/30 * * * * *',                            -- Every 30 seconds (with seconds support)
  $$
  SELECT
    net.http_post(
      url := get_supabase_project_url() || '/functions/v1/send-emergency-fcm',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || get_service_role_key()
      ),
      body := '{}'::jsonb,
      timeout_milliseconds := 30000  -- 30 second timeout
    ) AS request_id;
  $$
);

-- =============================================================================
-- 5. VERIFY CRON JOB CREATED
-- =============================================================================

-- Check if cron job exists
DO $$
DECLARE
  job_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO job_count
  FROM cron.job
  WHERE jobname = 'send-emergency-notifications';
  
  IF job_count > 0 THEN
    RAISE NOTICE '✅ Cron job "send-emergency-notifications" created successfully';
    RAISE NOTICE 'Schedule: Every 30 seconds';
    RAISE NOTICE 'Target: Edge Function send-emergency-fcm';
  ELSE
    RAISE EXCEPTION '❌ Failed to create cron job';
  END IF;
END $$;

-- =============================================================================
-- 6. DISPLAY CRON JOB DETAILS
-- =============================================================================

-- Show created job
SELECT
  jobid,
  jobname,
  schedule,
  active,
  command
FROM cron.job
WHERE jobname = 'send-emergency-notifications';

-- =============================================================================
-- 7. USEFUL QUERIES FOR MONITORING
-- =============================================================================

-- Check last 10 cron job runs
COMMENT ON EXTENSION pg_cron IS 'Monitoring queries:

-- View last 10 cron runs:
SELECT
  start_time,
  end_time,
  status,
  return_message
FROM cron.job_run_details
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = ''send-emergency-notifications'')
ORDER BY start_time DESC
LIMIT 10;

-- Count successful vs failed runs (last hour):
SELECT
  status,
  COUNT(*) as total
FROM cron.job_run_details
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = ''send-emergency-notifications'')
  AND start_time > NOW() - INTERVAL ''1 hour''
GROUP BY status;

-- Check if cron is running:
SELECT
  jobname,
  schedule,
  active,
  CASE WHEN active THEN ''✅ ACTIVE'' ELSE ''❌ INACTIVE'' END as status
FROM cron.job
WHERE jobname = ''send-emergency-notifications'';
';

-- =============================================================================
-- 8. IMPORTANT NOTES
-- =============================================================================

/*
BEFORE RUNNING THIS MIGRATION:

1. ✅ Edge Function 'send-emergency-fcm' must be deployed
   Run: supabase functions deploy send-emergency-fcm

2. ✅ Supabase secrets must be configured:
   - FIREBASE_SERVICE_ACCOUNT (Firebase service account JSON)
   - SUPABASE_URL (your project URL)
   - SUPABASE_SERVICE_ROLE_KEY (from dashboard)

3. ✅ Replace 'YOUR_PROJECT_REF' in get_supabase_project_url() function
   with your actual Supabase project reference

4. ✅ Configure service_role_key setting:
   - Go to Supabase Dashboard → Project Settings → API
   - Copy "service_role" secret (NOT anon key)
   - Set via SQL:
     ALTER DATABASE postgres SET app.settings.service_role_key = 'your_key_here';

AFTER RUNNING THIS MIGRATION:

1. Verify cron job is running:
   SELECT * FROM cron.job WHERE jobname = 'send-emergency-notifications';

2. Check cron execution history:
   SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 5;

3. Monitor Edge Function logs:
   - Via Supabase Dashboard → Edge Functions → send-emergency-fcm → Logs
   - Via CLI: supabase functions logs send-emergency-fcm --tail

4. Test end-to-end flow:
   - Create emergency alert in app
   - Wait 30 seconds
   - Check notification delivery logs

TROUBLESHOOTING:

If cron job fails:
- Check Edge Function is deployed: supabase functions list
- Verify secrets are set: supabase secrets list
- Check service_role_key setting: SHOW app.settings.service_role_key;
- View error logs: SELECT * FROM cron.job_run_details WHERE status = 'failed';

To adjust schedule:
-- Every 1 minute (testing):
SELECT cron.alter_job(
  job_id := (SELECT jobid FROM cron.job WHERE jobname = 'send-emergency-notifications'),
  schedule := '* * * * *'
);

-- Every 5 minutes (production):
SELECT cron.alter_job(
  job_id := (SELECT jobid FROM cron.job WHERE jobname = 'send-emergency-notifications'),
  schedule := '*/5 * * * *'
);

To disable:
SELECT cron.unschedule('send-emergency-notifications');
*/

-- =============================================================================
-- MIGRATION COMPLETE
-- =============================================================================

RAISE NOTICE '
================================================================================
Migration 013: Edge Function Cron Job Setup - COMPLETE
================================================================================

✅ pg_cron extension enabled
✅ pg_net extension enabled
✅ Helper functions created
✅ Cron job scheduled (every 30 seconds)

Next Steps:
1. Verify Edge Function deployed: supabase functions list
2. Set service_role_key: ALTER DATABASE postgres SET app.settings.service_role_key = ''your_key'';
3. Update PROJECT_REF in get_supabase_project_url() function
4. Test notification flow end-to-end
5. Monitor cron job health: SELECT * FROM cron.job_run_details;

Cost: $0.00 (100%% FREE)
================================================================================
';

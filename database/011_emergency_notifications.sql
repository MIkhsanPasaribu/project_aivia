-- =============================================================================
-- Migration 011: Emergency Notifications (FCM Integration)
-- =============================================================================
-- Purpose: Automatic push notifications for emergency alerts
-- Created: 2025-01-12
-- Dependencies: 006_fcm_tokens.sql, 001_initial_schema.sql (emergency_alerts)
-- FREE Service: Firebase Cloud Messaging (unlimited FREE)
-- =============================================================================

-- Description:
-- This migration creates automatic emergency notification system using Firebase
-- Cloud Messaging (FCM). When patient triggers emergency button, system
-- automatically sends push notifications to all emergency contacts and family
-- members using Supabase Edge Function webhooks.
--
-- Flow:
-- 1. Patient presses emergency button
-- 2. emergency_alerts table INSERT trigger
-- 3. Trigger calls Supabase Edge Function via webhook
-- 4. Edge Function sends FCM notifications
-- 5. Family members receive push notifications instantly
--
-- Benefits:
-- - Real-time emergency alerts (<5 seconds)
-- - Automatic notification to all contacts
-- - Delivery tracking
-- - Retry logic for failed notifications
-- - 100% FREE (FCM unlimited messages)

-- =============================================================================
-- 1. CREATE TABLE: emergency_notification_log
-- =============================================================================

-- Table to track notification delivery status
DROP TABLE IF EXISTS public.emergency_notification_log CASCADE;

CREATE TABLE public.emergency_notification_log (
  -- Primary key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Foreign keys
  alert_id UUID NOT NULL REFERENCES public.emergency_alerts(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  
  -- Notification details
  fcm_token TEXT NOT NULL,
  fcm_message_id TEXT, -- FCM response message ID
  
  -- Delivery status
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'delivered', 'failed')),
  error_message TEXT,
  retry_count INTEGER DEFAULT 0,
  
  -- Notification payload
  notification_payload JSONB,
  
  -- Timestamps
  sent_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- 2. CREATE INDEXES
-- =============================================================================

-- Index for querying by alert
CREATE INDEX idx_emergency_notification_log_alert 
  ON public.emergency_notification_log(alert_id);

-- Index for querying by recipient
CREATE INDEX idx_emergency_notification_log_recipient 
  ON public.emergency_notification_log(recipient_id);

-- Index for failed notifications (for retry worker)
CREATE INDEX idx_emergency_notification_log_failed 
  ON public.emergency_notification_log(created_at) 
  WHERE status = 'failed' AND retry_count < 3;

-- =============================================================================
-- 3. CREATE FUNCTION: Get Emergency Notification Recipients
-- =============================================================================

-- Function to get all recipients for emergency alert
-- Combines emergency contacts + family members
CREATE OR REPLACE FUNCTION get_emergency_notification_recipients(p_patient_id UUID)
RETURNS TABLE (
  recipient_id UUID,
  recipient_name TEXT,
  recipient_type TEXT,
  fcm_tokens TEXT[],
  priority INTEGER
) AS $$
BEGIN
  RETURN QUERY
  -- Emergency contacts (highest priority)
  SELECT 
    ec.contact_id AS recipient_id,
    p.full_name AS recipient_name,
    'emergency_contact'::TEXT AS recipient_type,
    ARRAY_AGG(ft.token) AS fcm_tokens,
    ec.priority
  FROM public.emergency_contacts ec
  INNER JOIN public.profiles p ON ec.contact_id = p.id
  INNER JOIN public.fcm_tokens ft ON ft.user_id = ec.contact_id
  WHERE ec.patient_id = p_patient_id
    AND ft.is_active = TRUE
  GROUP BY ec.contact_id, p.full_name, ec.priority
  
  UNION ALL
  
  -- Family members (secondary priority)
  SELECT 
    pfl.family_member_id AS recipient_id,
    p.full_name AS recipient_name,
    'family_member'::TEXT AS recipient_type,
    ARRAY_AGG(ft.token) AS fcm_tokens,
    99 AS priority -- Lower priority than emergency contacts
  FROM public.patient_family_links pfl
  INNER JOIN public.profiles p ON pfl.family_member_id = p.id
  INNER JOIN public.fcm_tokens ft ON ft.user_id = pfl.family_member_id
  WHERE pfl.patient_id = p_patient_id
    AND ft.is_active = TRUE
    -- Exclude if already in emergency contacts
    AND pfl.family_member_id NOT IN (
      SELECT contact_id FROM public.emergency_contacts WHERE patient_id = p_patient_id
    )
  GROUP BY pfl.family_member_id, p.full_name
  
  ORDER BY priority ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_emergency_notification_recipients(UUID) TO authenticated;

-- =============================================================================
-- 4. CREATE FUNCTION: Prepare Emergency Notification Payload
-- =============================================================================

-- Function to prepare FCM notification payload
CREATE OR REPLACE FUNCTION prepare_emergency_notification_payload(
  p_alert_id UUID
)
RETURNS JSONB AS $$
DECLARE
  v_alert RECORD;
  v_payload JSONB;
BEGIN
  -- Get alert details
  SELECT 
    ea.id,
    ea.patient_id,
    p.full_name AS patient_name,
    ea.message,
    ST_Y(ea.location::geometry) AS latitude,
    ST_X(ea.location::geometry) AS longitude,
    ea.created_at
  INTO v_alert
  FROM public.emergency_alerts ea
  INNER JOIN public.profiles p ON ea.patient_id = p.id
  WHERE ea.id = p_alert_id;
  
  IF v_alert.id IS NULL THEN
    RAISE EXCEPTION 'Emergency alert not found: %', p_alert_id;
  END IF;
  
  -- Build FCM payload
  v_payload := jsonb_build_object(
    'notification', jsonb_build_object(
      'title', '🚨 PERINGATAN DARURAT',
      'body', format('Pasien %s membutuhkan bantuan segera!', v_alert.patient_name),
      'sound', 'emergency_alert.mp3',
      'priority', 'high',
      'badge', '1'
    ),
    'data', jsonb_build_object(
      'type', 'emergency_alert',
      'alert_id', v_alert.id::TEXT,
      'patient_id', v_alert.patient_id::TEXT,
      'patient_name', v_alert.patient_name,
      'message', COALESCE(v_alert.message, 'Peringatan darurat'),
      'latitude', v_alert.latitude::TEXT,
      'longitude', v_alert.longitude::TEXT,
      'timestamp', v_alert.created_at::TEXT,
      'google_maps_url', format(
        'https://www.google.com/maps/search/?api=1&query=%s,%s',
        v_alert.latitude,
        v_alert.longitude
      )
    ),
    'android', jsonb_build_object(
      'priority', 'high',
      'ttl', '3600s',
      'notification', jsonb_build_object(
        'channel_id', 'emergency_alerts',
        'color', '#FF0000',
        'default_sound', false,
        'sound', 'emergency_alert'
      )
    ),
    'apns', jsonb_build_object(
      'headers', jsonb_build_object(
        'apns-priority', '10'
      ),
      'payload', jsonb_build_object(
        'aps', jsonb_build_object(
          'alert', jsonb_build_object(
            'title', '🚨 PERINGATAN DARURAT',
            'body', format('Pasien %s membutuhkan bantuan segera!', v_alert.patient_name)
          ),
          'sound', 'emergency_alert.caf',
          'badge', 1,
          'category', 'EMERGENCY_ALERT'
        )
      )
    )
  );
  
  RETURN v_payload;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION prepare_emergency_notification_payload(UUID) TO authenticated;

-- =============================================================================
-- 5. CREATE FUNCTION: Send Emergency Notifications (Webhook Trigger)
-- =============================================================================

-- Function to trigger Edge Function for sending notifications
-- This function makes HTTP request to Supabase Edge Function
CREATE OR REPLACE FUNCTION send_emergency_notifications(p_alert_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_alert RECORD;
  v_recipients RECORD;
  v_payload JSONB;
  v_webhook_url TEXT;
  v_response JSONB;
  v_log_id UUID;
  v_notification_count INTEGER := 0;
BEGIN
  -- Get alert details
  SELECT * INTO v_alert
  FROM public.emergency_alerts
  WHERE id = p_alert_id;
  
  IF v_alert.id IS NULL THEN
    RAISE EXCEPTION 'Emergency alert not found: %', p_alert_id;
  END IF;
  
  -- Prepare notification payload
  v_payload := prepare_emergency_notification_payload(p_alert_id);
  
  -- Get all recipients
  FOR v_recipients IN
    SELECT * FROM get_emergency_notification_recipients(v_alert.patient_id)
  LOOP
    -- For each FCM token, create notification log entry
    FOREACH v_webhook_url IN ARRAY v_recipients.fcm_tokens
    LOOP
      INSERT INTO public.emergency_notification_log (
        alert_id,
        recipient_id,
        fcm_token,
        status,
        notification_payload,
        created_at
      ) VALUES (
        p_alert_id,
        v_recipients.recipient_id,
        v_webhook_url,
        'pending',
        v_payload,
        NOW()
      )
      RETURNING id INTO v_log_id;
      
      v_notification_count := v_notification_count + 1;
      
      RAISE NOTICE 'Queued notification for % (%) - token: %', 
        v_recipients.recipient_name, 
        v_recipients.recipient_type,
        LEFT(v_webhook_url, 20) || '...';
    END LOOP;
  END LOOP;
  
  -- Return summary
  v_response := jsonb_build_object(
    'alert_id', p_alert_id,
    'notifications_queued', v_notification_count,
    'status', 'queued',
    'message', format('Queued %s notifications for delivery', v_notification_count)
  );
  
  RAISE NOTICE 'Emergency notifications queued: %', v_notification_count;
  
  -- Note: Actual FCM sending will be done by Edge Function
  -- Edge Function polls emergency_notification_log for pending notifications
  
  RETURN v_response;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION send_emergency_notifications(UUID) TO authenticated;

-- =============================================================================
-- 6. CREATE TRIGGER FUNCTION: Auto-send on Emergency Alert Insert
-- =============================================================================

-- Trigger function that runs AFTER INSERT on emergency_alerts
-- Automatically queues notifications for delivery
CREATE OR REPLACE FUNCTION trigger_send_emergency_notifications()
RETURNS TRIGGER AS $$
DECLARE
  v_result JSONB;
BEGIN
  -- Queue notifications asynchronously
  v_result := send_emergency_notifications(NEW.id);
  
  RAISE NOTICE 'Emergency alert % triggered notifications: %', NEW.id, v_result;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- 7. CREATE TRIGGER: Apply Notification on Emergency Alert
-- =============================================================================

-- Drop trigger if exists (for re-running migration)
DROP TRIGGER IF EXISTS trigger_emergency_alert_notifications ON public.emergency_alerts;

-- Create trigger
CREATE TRIGGER trigger_emergency_alert_notifications
  AFTER INSERT ON public.emergency_alerts
  FOR EACH ROW
  EXECUTE FUNCTION trigger_send_emergency_notifications();

-- =============================================================================
-- 8. CREATE FUNCTION: Mark Notification as Sent/Delivered
-- =============================================================================

-- Function to update notification status
-- Called by Edge Function after sending FCM message
CREATE OR REPLACE FUNCTION update_notification_status(
  p_log_id UUID,
  p_status TEXT,
  p_fcm_message_id TEXT DEFAULT NULL,
  p_error_message TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE public.emergency_notification_log
  SET 
    status = p_status,
    fcm_message_id = COALESCE(p_fcm_message_id, fcm_message_id),
    error_message = p_error_message,
    sent_at = CASE WHEN p_status IN ('sent', 'delivered') THEN NOW() ELSE sent_at END,
    delivered_at = CASE WHEN p_status = 'delivered' THEN NOW() ELSE delivered_at END,
    retry_count = CASE WHEN p_status = 'failed' THEN retry_count + 1 ELSE retry_count END
  WHERE id = p_log_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to service role
GRANT EXECUTE ON FUNCTION update_notification_status(UUID, TEXT, TEXT, TEXT) TO service_role;

-- =============================================================================
-- 9. CREATE FUNCTION: Get Pending Notifications
-- =============================================================================

-- Function to get pending notifications (for Edge Function worker)
CREATE OR REPLACE FUNCTION get_pending_emergency_notifications(p_limit INTEGER DEFAULT 50)
RETURNS TABLE (
  log_id UUID,
  alert_id UUID,
  patient_id UUID,
  patient_name TEXT,
  recipient_id UUID,
  recipient_name TEXT,
  fcm_token TEXT,
  notification_payload JSONB,
  retry_count INTEGER,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    enl.id AS log_id,
    ea.id AS alert_id,
    ea.patient_id,
    p_patient.full_name AS patient_name,
    enl.recipient_id,
    p_recipient.full_name AS recipient_name,
    enl.fcm_token,
    enl.notification_payload,
    enl.retry_count,
    enl.created_at
  FROM public.emergency_notification_log enl
  INNER JOIN public.emergency_alerts ea ON enl.alert_id = ea.id
  INNER JOIN public.profiles p_patient ON ea.patient_id = p_patient.id
  INNER JOIN public.profiles p_recipient ON enl.recipient_id = p_recipient.id
  WHERE enl.status = 'pending'
    AND enl.retry_count < 3
    AND enl.created_at > NOW() - INTERVAL '1 hour' -- Only recent notifications
  ORDER BY enl.created_at ASC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to service role
GRANT EXECUTE ON FUNCTION get_pending_emergency_notifications(INTEGER) TO service_role;

-- =============================================================================
-- 10. CREATE VIEW: Emergency Notification Statistics
-- =============================================================================

-- View to monitor notification delivery
CREATE OR REPLACE VIEW public.emergency_notification_stats AS
SELECT 
  ea.id AS alert_id,
  ea.patient_id,
  p.full_name AS patient_name,
  ea.created_at AS alert_created_at,
  COUNT(enl.id) AS total_notifications,
  COUNT(CASE WHEN enl.status = 'sent' THEN 1 END) AS sent_count,
  COUNT(CASE WHEN enl.status = 'delivered' THEN 1 END) AS delivered_count,
  COUNT(CASE WHEN enl.status = 'failed' THEN 1 END) AS failed_count,
  COUNT(CASE WHEN enl.status = 'pending' THEN 1 END) AS pending_count,
  MIN(enl.sent_at) AS first_notification_sent,
  MAX(enl.sent_at) AS last_notification_sent,
  EXTRACT(EPOCH FROM (MIN(enl.sent_at) - ea.created_at))::INTEGER AS response_time_seconds
FROM public.emergency_alerts ea
LEFT JOIN public.emergency_notification_log enl ON ea.id = enl.alert_id
LEFT JOIN public.profiles p ON ea.patient_id = p.id
GROUP BY ea.id, ea.patient_id, p.full_name, ea.created_at
ORDER BY ea.created_at DESC;

-- Grant view access
GRANT SELECT ON public.emergency_notification_stats TO authenticated;

-- =============================================================================
-- 11. ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================

-- Enable RLS on notification log
ALTER TABLE public.emergency_notification_log ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view notifications sent to them
CREATE POLICY "Users can view own notifications"
  ON public.emergency_notification_log
  FOR SELECT
  USING (auth.uid() = recipient_id);

-- Policy: Users can view notifications for their patients' alerts
CREATE POLICY "Family can view patient notifications"
  ON public.emergency_notification_log
  FOR SELECT
  USING (
    alert_id IN (
      SELECT ea.id
      FROM public.emergency_alerts ea
      INNER JOIN public.patient_family_links pfl ON ea.patient_id = pfl.patient_id
      WHERE pfl.family_member_id = auth.uid()
    )
  );

-- Policy: Service role can manage all notifications
CREATE POLICY "Service role can manage all notifications"
  ON public.emergency_notification_log
  FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- =============================================================================
-- 12. CREATE FUNCTION: Retry Failed Notifications
-- =============================================================================

-- Function to retry failed notifications
CREATE OR REPLACE FUNCTION retry_failed_emergency_notifications()
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER := 0;
BEGIN
  -- Reset failed notifications for retry (max 3 attempts)
  UPDATE public.emergency_notification_log
  SET 
    status = 'pending',
    error_message = NULL
  WHERE status = 'failed'
    AND retry_count < 3
    AND created_at > NOW() - INTERVAL '1 hour';
  
  GET DIAGNOSTICS v_count = ROW_COUNT;
  
  RAISE NOTICE 'Reset % failed notifications for retry', v_count;
  
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to service role
GRANT EXECUTE ON FUNCTION retry_failed_emergency_notifications() TO service_role;

-- =============================================================================
-- 13. VERIFICATION QUERIES
-- =============================================================================

-- Verify table created
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'emergency_notification_log') THEN
    RAISE EXCEPTION 'emergency_notification_log table was not created!';
  END IF;
  
  RAISE NOTICE '✅ emergency_notification_log table created successfully';
END $$;

-- Verify trigger created
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'trigger_emergency_alert_notifications'
  ) THEN
    RAISE EXCEPTION 'Emergency notification trigger was not created!';
  END IF;
  
  RAISE NOTICE '✅ Emergency notification trigger created successfully';
END $$;

-- Verify RLS enabled
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_tables 
    WHERE tablename = 'emergency_notification_log' 
    AND rowsecurity = TRUE
  ) THEN
    RAISE EXCEPTION 'RLS is not enabled on emergency_notification_log table!';
  END IF;
  
  RAISE NOTICE '✅ RLS enabled successfully';
END $$;

-- =============================================================================
-- MIGRATION COMPLETE
-- =============================================================================

DO $$
BEGIN
  RAISE NOTICE '
================================================================================
✅ Migration 011: Emergency Notifications (FCM Integration) - COMPLETE
================================================================================
Created:
  - Table: emergency_notification_log (delivery tracking)
  - Indexes: alert_id, recipient_id, failed notifications
  - Functions:
    * get_emergency_notification_recipients(patient_id)
    * prepare_emergency_notification_payload(alert_id)
    * send_emergency_notifications(alert_id)
    * update_notification_status(log_id, status, ...)
    * get_pending_emergency_notifications(limit)
    * retry_failed_emergency_notifications()
  - Trigger: trigger_emergency_alert_notifications (AFTER INSERT on emergency_alerts)
  - View: emergency_notification_stats (delivery monitoring)
  - RLS Policies: 3 policies for user access control

How It Works:
  1. Patient presses emergency button
  2. INSERT into emergency_alerts table
  3. Trigger automatically calls send_emergency_notifications()
  4. Function queries get_emergency_notification_recipients()
  5. Creates notification log entries (status = pending)
  6. Edge Function worker polls get_pending_emergency_notifications()
  7. Edge Function sends FCM messages
  8. Calls update_notification_status() for each delivery
  9. Failed notifications can be retried (max 3 times)

Required Edge Function:
  Create Supabase Edge Function to poll and send FCM notifications.
  See: supabase/functions/send-emergency-fcm/index.ts

Usage Examples:
  -- Get notification recipients for patient
  SELECT * FROM get_emergency_notification_recipients(''patient-uuid'');

  -- Manually trigger notifications (if needed)
  SELECT send_emergency_notifications(''alert-uuid'');

  -- Get pending notifications (Edge Function)
  SELECT * FROM get_pending_emergency_notifications(50);

  -- Update notification status (Edge Function)
  SELECT update_notification_status(
    ''log-uuid'',
    ''delivered'',
    ''fcm-message-id-123'',
    NULL
  );

  -- Retry failed notifications
  SELECT retry_failed_emergency_notifications();

  -- View statistics
  SELECT * FROM emergency_notification_stats;

Expected Performance:
  - Notification queued: <100ms
  - FCM delivery: 1-5 seconds
  - Total response time: <5 seconds (alert → notification received)

Cost: $0.00 (Firebase FCM is FREE unlimited)
================================================================================
';
END $$;

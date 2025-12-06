-- =============================================================================
-- Migration 014: Pending Notifications Queue Table
-- =============================================================================
-- Purpose: Queue notifications untuk processing oleh Edge Function
-- Created: 2025-12-06
-- Dependencies: 006_fcm_tokens.sql, 001_initial_schema.sql
-- FREE Service: Supabase PostgreSQL (built-in)
-- =============================================================================

-- Description:
-- Table ini adalah queue untuk semua notifications yang perlu dikirim via FCM.
-- Edge Function (send-emergency-fcm) akan query table ini setiap 1 menit via cron,
-- lalu send notifications ke recipients dan update status.
--
-- Flow:
-- 1. Trigger/Application insert notification ke pending_notifications
-- 2. Cron job triggers Edge Function setiap 1 menit
-- 3. Edge Function query pending notifications (status = 'pending')
-- 4. Send via FCM to recipient FCM tokens
-- 5. Update status to 'sent', 'failed', or 'partial'
-- 6. Log delivery details to notification_delivery_logs
--
-- Notification Types:
-- - emergency: Darurat (emergency button pressed)
-- - geofence: Geofence enter/exit alerts
-- - activity: Activity reminders
-- - reminder: General reminders
-- - system: System messages

-- =============================================================================
-- 1. CREATE TABLE: pending_notifications
-- =============================================================================

-- Drop table if exists (untuk development/testing)
DROP TABLE IF EXISTS public.pending_notifications CASCADE;

-- Create pending notifications queue table
CREATE TABLE public.pending_notifications (
  -- Primary key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Recipient (foreign key)
  recipient_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  
  -- Notification type & content
  notification_type TEXT NOT NULL CHECK (
    notification_type IN ('emergency', 'geofence', 'activity', 'reminder', 'system')
  ),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  
  -- Additional data (JSON payload untuk custom fields)
  data JSONB DEFAULT '{}'::jsonb,
  -- Example data structures:
  -- Emergency: {"alert_id": "uuid", "patient_id": "uuid", "latitude": 0.0, "longitude": 0.0}
  -- Geofence: {"geofence_id": "uuid", "event_type": "enter", "geofence_name": "Rumah"}
  -- Activity: {"activity_id": "uuid", "activity_time": "2025-12-06T10:00:00Z"}
  
  -- Processing status
  status TEXT NOT NULL DEFAULT 'pending' CHECK (
    status IN ('pending', 'sent', 'failed', 'partial')
  ),
  -- pending: Belum diprocess
  -- sent: Berhasil terkirim ke semua tokens
  -- failed: Gagal terkirim ke semua tokens
  -- partial: Berhasil ke beberapa tokens, gagal ke beberapa
  
  -- Scheduling
  scheduled_at TIMESTAMPTZ DEFAULT NOW(), -- Kapan notif harus dikirim
  sent_at TIMESTAMPTZ, -- Kapan notif actually terkirim
  
  -- Priority (optional, untuk future use)
  priority INTEGER DEFAULT 5 CHECK (priority >= 1 AND priority <= 10),
  -- 1 = highest priority, 10 = lowest
  
  -- Retry tracking (optional)
  retry_count INTEGER DEFAULT 0,
  max_retries INTEGER DEFAULT 3,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- 2. CREATE INDEXES
-- =============================================================================

-- Index untuk query pending notifications (Edge Function use case)
-- Note: Tidak pakai NOW() di predicate karena not immutable
CREATE INDEX idx_pending_notifications_status_scheduled 
  ON public.pending_notifications(status, scheduled_at)
  WHERE status = 'pending';

-- Index untuk query by recipient
CREATE INDEX idx_pending_notifications_recipient 
  ON public.pending_notifications(recipient_user_id);

-- Index untuk query by type
CREATE INDEX idx_pending_notifications_type 
  ON public.pending_notifications(notification_type);

-- Index untuk cleanup old notifications
CREATE INDEX idx_pending_notifications_created 
  ON public.pending_notifications(created_at);

-- =============================================================================
-- 3. CREATE TABLE: notification_delivery_logs
-- =============================================================================

-- Table untuk track delivery status per FCM token
DROP TABLE IF EXISTS public.notification_delivery_logs CASCADE;

CREATE TABLE public.notification_delivery_logs (
  -- Primary key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Foreign keys
  notification_id UUID NOT NULL REFERENCES public.pending_notifications(id) ON DELETE CASCADE,
  recipient_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  
  -- FCM details
  fcm_token TEXT NOT NULL,
  fcm_message_id TEXT, -- FCM response message ID (jika sukses)
  
  -- Delivery status
  status TEXT NOT NULL CHECK (status IN ('sent', 'failed')),
  error_message TEXT, -- Error message jika failed
  
  -- Timestamps
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- 4. CREATE INDEXES untuk delivery logs
-- =============================================================================

-- Index untuk query logs by notification
CREATE INDEX idx_notification_delivery_logs_notification 
  ON public.notification_delivery_logs(notification_id);

-- Index untuk query logs by recipient
CREATE INDEX idx_notification_delivery_logs_recipient 
  ON public.notification_delivery_logs(recipient_user_id);

-- Index untuk query failed deliveries
CREATE INDEX idx_notification_delivery_logs_failed 
  ON public.notification_delivery_logs(sent_at) 
  WHERE status = 'failed';

-- =============================================================================
-- 5. CREATE FUNCTION: Get Pending Notifications (untuk Edge Function)
-- =============================================================================

-- Drop existing function if exists (handle signature changes)
DROP FUNCTION IF EXISTS get_pending_emergency_notifications(INTEGER);

-- Function yang dipanggil Edge Function untuk get batch of pending notifications
CREATE OR REPLACE FUNCTION get_pending_emergency_notifications(
  batch_size INTEGER DEFAULT 50
)
RETURNS TABLE (
  id UUID,
  recipient_user_id UUID,
  notification_type TEXT,
  title TEXT,
  body TEXT,
  data JSONB,
  scheduled_at TIMESTAMPTZ,
  priority INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    pn.id,
    pn.recipient_user_id,
    pn.notification_type,
    pn.title,
    pn.body,
    pn.data,
    pn.scheduled_at,
    pn.priority
  FROM public.pending_notifications pn
  WHERE pn.status = 'pending'
    AND pn.scheduled_at <= NOW()
    AND pn.retry_count < pn.max_retries
  ORDER BY pn.priority ASC, pn.scheduled_at ASC
  LIMIT batch_size;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute ke service role (Edge Function menggunakan service role key)
GRANT EXECUTE ON FUNCTION get_pending_emergency_notifications(INTEGER) TO service_role;
GRANT EXECUTE ON FUNCTION get_pending_emergency_notifications(INTEGER) TO authenticated;

-- =============================================================================
-- 6. CREATE FUNCTION: Update Notification Status
-- =============================================================================

-- Function untuk update status notification setelah Edge Function proses
CREATE OR REPLACE FUNCTION update_pending_notification_status(
  p_notification_id UUID,
  p_status TEXT,
  p_sent_at TIMESTAMPTZ DEFAULT NOW()
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE public.pending_notifications
  SET 
    status = p_status,
    sent_at = p_sent_at,
    updated_at = NOW()
  WHERE id = p_notification_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute
GRANT EXECUTE ON FUNCTION update_pending_notification_status(UUID, TEXT, TIMESTAMPTZ) TO service_role;
GRANT EXECUTE ON FUNCTION update_pending_notification_status(UUID, TEXT, TIMESTAMPTZ) TO authenticated;

-- =============================================================================
-- 7. CREATE TRIGGER: Auto-update updated_at
-- =============================================================================

-- Trigger function untuk auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION trigger_update_pending_notification_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger
CREATE TRIGGER update_pending_notifications_updated_at
  BEFORE UPDATE ON public.pending_notifications
  FOR EACH ROW
  EXECUTE FUNCTION trigger_update_pending_notification_timestamp();

-- =============================================================================
-- 8. ENABLE ROW LEVEL SECURITY (RLS)
-- =============================================================================

-- Enable RLS
ALTER TABLE public.pending_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_delivery_logs ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- 9. CREATE RLS POLICIES
-- =============================================================================

-- Policy 1: Users can view their own pending notifications
CREATE POLICY "Users can view own pending notifications"
  ON public.pending_notifications
  FOR SELECT
  USING (auth.uid() = recipient_user_id);

-- Policy 2: Service role can manage all notifications (for Edge Function)
CREATE POLICY "Service role can manage all notifications"
  ON public.pending_notifications
  FOR ALL
  USING (auth.jwt()->>'role' = 'service_role');

-- Policy 3: Family members can create notifications for linked patients
CREATE POLICY "Family can create notifications for patients"
  ON public.pending_notifications
  FOR INSERT
  WITH CHECK (
    recipient_user_id IN (
      SELECT patient_id 
      FROM public.patient_family_links 
      WHERE family_member_id = auth.uid()
    )
  );

-- Policy 4: Users can view their own delivery logs
CREATE POLICY "Users can view own delivery logs"
  ON public.notification_delivery_logs
  FOR SELECT
  USING (auth.uid() = recipient_user_id);

-- Policy 5: Service role can manage all delivery logs
CREATE POLICY "Service role can manage all delivery logs"
  ON public.notification_delivery_logs
  FOR ALL
  USING (auth.jwt()->>'role' = 'service_role');

-- =============================================================================
-- 10. CREATE HELPER FUNCTION: Queue Notification
-- =============================================================================

-- Helper function untuk queue notification dari aplikasi/trigger
CREATE OR REPLACE FUNCTION queue_notification(
  p_recipient_user_id UUID,
  p_notification_type TEXT,
  p_title TEXT,
  p_body TEXT,
  p_data JSONB DEFAULT '{}'::jsonb,
  p_scheduled_at TIMESTAMPTZ DEFAULT NOW(),
  p_priority INTEGER DEFAULT 5
)
RETURNS UUID AS $$
DECLARE
  v_notification_id UUID;
BEGIN
  INSERT INTO public.pending_notifications (
    recipient_user_id,
    notification_type,
    title,
    body,
    data,
    scheduled_at,
    priority,
    status
  ) VALUES (
    p_recipient_user_id,
    p_notification_type,
    p_title,
    p_body,
    p_data,
    p_scheduled_at,
    p_priority,
    'pending'
  )
  RETURNING id INTO v_notification_id;
  
  RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute
GRANT EXECUTE ON FUNCTION queue_notification(UUID, TEXT, TEXT, TEXT, JSONB, TIMESTAMPTZ, INTEGER) TO authenticated;

-- =============================================================================
-- 11. CREATE CLEANUP FUNCTION: Delete Old Notifications
-- =============================================================================

-- Function untuk cleanup notifikasi lama (>30 hari)
-- Bisa dijadwalkan via pg_cron juga
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS INTEGER AS $$
DECLARE
  v_deleted_count INTEGER;
BEGIN
  -- Delete notifications older than 30 days
  WITH deleted AS (
    DELETE FROM public.pending_notifications
    WHERE created_at < NOW() - INTERVAL '30 days'
      AND status IN ('sent', 'failed')
    RETURNING id
  )
  SELECT COUNT(*) INTO v_deleted_count FROM deleted;
  
  RAISE NOTICE 'Cleaned up % old notifications', v_deleted_count;
  
  RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute ke service role only
GRANT EXECUTE ON FUNCTION cleanup_old_notifications() TO service_role;

-- =============================================================================
-- 12. CREATE VIEW: Notification Statistics
-- =============================================================================

-- View untuk monitoring notification metrics
CREATE OR REPLACE VIEW notification_statistics AS
SELECT 
  notification_type,
  status,
  COUNT(*) AS total_count,
  COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '24 hours') AS last_24h_count,
  COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '1 hour') AS last_1h_count,
  AVG(EXTRACT(EPOCH FROM (sent_at - created_at))) AS avg_processing_time_seconds
FROM public.pending_notifications
GROUP BY notification_type, status;

-- Grant select
GRANT SELECT ON notification_statistics TO authenticated;

-- =============================================================================
-- MIGRATION VERIFICATION QUERIES
-- =============================================================================

-- Verify table created
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'pending_notifications'
  ) THEN
    RAISE NOTICE '✅ Table pending_notifications created successfully';
  ELSE
    RAISE EXCEPTION '❌ Table pending_notifications NOT created';
  END IF;
  
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'notification_delivery_logs'
  ) THEN
    RAISE NOTICE '✅ Table notification_delivery_logs created successfully';
  ELSE
    RAISE EXCEPTION '❌ Table notification_delivery_logs NOT created';
  END IF;
END $$;

-- Test function call (should return 0 rows initially)
SELECT COUNT(*) as pending_count 
FROM get_pending_emergency_notifications(10);

-- Show notification statistics (should be empty initially)
SELECT * FROM notification_statistics;

-- =============================================================================
-- SAMPLE DATA (Optional - for testing)
-- =============================================================================

-- Uncomment below untuk insert test notification
/*
INSERT INTO public.pending_notifications (
  recipient_user_id,
  notification_type,
  title,
  body,
  data,
  priority
) VALUES (
  (SELECT id FROM public.profiles WHERE user_role = 'family' LIMIT 1),
  'system',
  'Test Notification',
  'Ini adalah test notification dari database migration',
  '{"test": true, "migration": "014"}'::jsonb,
  5
);
*/

-- =============================================================================
-- COMPLETION SUMMARY
-- =============================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Migration 014: Pending Notifications';
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ Table: pending_notifications';
  RAISE NOTICE '✅ Table: notification_delivery_logs';
  RAISE NOTICE '✅ Indexes: 8 indexes created';
  RAISE NOTICE '✅ Functions: 5 functions created';
  RAISE NOTICE '✅ Triggers: 1 trigger created';
  RAISE NOTICE '✅ RLS Policies: 5 policies created';
  RAISE NOTICE '✅ View: notification_statistics';
  RAISE NOTICE '';
  RAISE NOTICE '🔔 Edge Function can now query pending notifications!';
  RAISE NOTICE '📊 Use view "notification_statistics" untuk monitoring';
  RAISE NOTICE '';
  RAISE NOTICE 'Next Step: Verify cron job picks up notifications';
  RAISE NOTICE '========================================';
END $$;

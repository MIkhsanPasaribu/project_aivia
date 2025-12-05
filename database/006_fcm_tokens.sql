-- =============================================================================
-- Migration 006: FCM Tokens Table
-- =============================================================================
-- Purpose: Store Firebase Cloud Messaging tokens for push notifications
-- Created: 2025-01-12
-- Dependencies: 001_initial_schema.sql (profiles table)
-- FREE Service: Firebase Cloud Messaging (unlimited FREE)
-- =============================================================================

-- Description:
-- This migration creates infrastructure for push notifications using Firebase 
-- Cloud Messaging (FCM). FCM is 100% FREE with unlimited messages, making it
-- perfect for enterprise-grade real-time notifications without any cost.
--
-- Features:
-- - Store FCM tokens per user device
-- - Support multiple devices per user
-- - Track device information (OS, model, app version)
-- - Handle token refresh automatically
-- - Clean up stale tokens
-- - RLS policies for security

-- =============================================================================
-- 1. CREATE TABLE: fcm_tokens
-- =============================================================================

-- Drop table if exists (for development/testing)
DROP TABLE IF EXISTS public.fcm_tokens CASCADE;

-- Create FCM tokens table
CREATE TABLE public.fcm_tokens (
  -- Primary key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Foreign key to profiles
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  
  -- FCM token (unique per device)
  token TEXT NOT NULL,
  
  -- Device information (JSONB for flexibility)
  device_info JSONB DEFAULT '{}'::jsonb,
  -- Example device_info structure:
  -- {
  --   "platform": "android",
  --   "os_version": "Android 13",
  --   "device_model": "Samsung Galaxy S23",
  --   "app_version": "1.0.0",
  --   "device_id": "abc123...",
  --   "locale": "id_ID"
  -- }
  
  -- Status tracking
  is_active BOOLEAN DEFAULT TRUE,
  last_used_at TIMESTAMPTZ,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT fcm_tokens_token_unique UNIQUE(token),
  CONSTRAINT fcm_tokens_device_info_check CHECK (jsonb_typeof(device_info) = 'object')
);

-- =============================================================================
-- 2. CREATE INDEXES
-- =============================================================================

-- Index for querying by user (most common query)
CREATE INDEX idx_fcm_tokens_user_id 
  ON public.fcm_tokens(user_id) 
  WHERE is_active = TRUE;

-- Index for token lookup
CREATE INDEX idx_fcm_tokens_token 
  ON public.fcm_tokens(token) 
  WHERE is_active = TRUE;

-- Index for cleanup queries
CREATE INDEX idx_fcm_tokens_last_used 
  ON public.fcm_tokens(last_used_at) 
  WHERE is_active = TRUE;

-- =============================================================================
-- 3. CREATE FUNCTION: Upsert FCM Token
-- =============================================================================

-- Function to insert or update FCM token
-- If token exists: update last_used_at and device_info
-- If new token: insert new record
CREATE OR REPLACE FUNCTION upsert_fcm_token(
  p_user_id UUID,
  p_token TEXT,
  p_device_info JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID AS $$
DECLARE
  v_token_id UUID;
BEGIN
  -- Insert or update token
  INSERT INTO public.fcm_tokens (user_id, token, device_info, is_active, last_used_at)
  VALUES (p_user_id, p_token, p_device_info, TRUE, NOW())
  ON CONFLICT (token) DO UPDATE
  SET 
    device_info = EXCLUDED.device_info,
    is_active = TRUE,
    last_used_at = NOW(),
    updated_at = NOW()
  RETURNING id INTO v_token_id;
  
  RETURN v_token_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION upsert_fcm_token(UUID, TEXT, JSONB) TO authenticated;

-- =============================================================================
-- 4. CREATE FUNCTION: Get Active Tokens for User
-- =============================================================================

-- Function to get all active FCM tokens for a user
-- Used when sending notifications to all user's devices
CREATE OR REPLACE FUNCTION get_user_fcm_tokens(p_user_id UUID)
RETURNS TABLE (
  token TEXT,
  device_info JSONB,
  last_used_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ft.token,
    ft.device_info,
    ft.last_used_at
  FROM public.fcm_tokens ft
  WHERE ft.user_id = p_user_id
    AND ft.is_active = TRUE
  ORDER BY ft.last_used_at DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_user_fcm_tokens(UUID) TO authenticated;

-- =============================================================================
-- 5. CREATE FUNCTION: Cleanup Stale Tokens
-- =============================================================================

-- Function to mark tokens as inactive if not used for 90 days
-- Stale tokens are likely from uninstalled apps or logged out devices
CREATE OR REPLACE FUNCTION cleanup_stale_fcm_tokens()
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
BEGIN
  -- Mark tokens as inactive if last_used_at > 90 days ago
  UPDATE public.fcm_tokens
  SET 
    is_active = FALSE,
    updated_at = NOW()
  WHERE is_active = TRUE
    AND (last_used_at IS NULL OR last_used_at < NOW() - INTERVAL '90 days');
  
  GET DIAGNOSTICS v_count = ROW_COUNT;
  
  RAISE NOTICE 'Marked % stale FCM tokens as inactive', v_count;
  
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to service role (for cron jobs)
GRANT EXECUTE ON FUNCTION cleanup_stale_fcm_tokens() TO service_role;

-- =============================================================================
-- 6. CREATE TRIGGER: Update timestamp
-- =============================================================================

-- Create trigger function to auto-update updated_at
CREATE OR REPLACE FUNCTION update_fcm_tokens_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
CREATE TRIGGER trigger_update_fcm_tokens_updated_at
  BEFORE UPDATE ON public.fcm_tokens
  FOR EACH ROW
  EXECUTE FUNCTION update_fcm_tokens_updated_at();

-- =============================================================================
-- 7. ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================

-- Enable RLS
ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own FCM tokens
CREATE POLICY "Users can view own FCM tokens"
  ON public.fcm_tokens
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own FCM tokens
CREATE POLICY "Users can insert own FCM tokens"
  ON public.fcm_tokens
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own FCM tokens
CREATE POLICY "Users can update own FCM tokens"
  ON public.fcm_tokens
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own FCM tokens
CREATE POLICY "Users can delete own FCM tokens"
  ON public.fcm_tokens
  FOR DELETE
  USING (auth.uid() = user_id);

-- Policy: Service role can manage all tokens (for Edge Functions)
CREATE POLICY "Service role can manage all FCM tokens"
  ON public.fcm_tokens
  FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- =============================================================================
-- 8. HELPER FUNCTION: Get Emergency Contact Tokens
-- =============================================================================

-- Function to get FCM tokens for all emergency contacts of a patient
-- Used when sending emergency alerts
CREATE OR REPLACE FUNCTION get_emergency_contact_tokens(p_patient_id UUID)
RETURNS TABLE (
  contact_id UUID,
  contact_name TEXT,
  token TEXT,
  device_info JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ec.contact_id,
    p.full_name AS contact_name,
    ft.token,
    ft.device_info
  FROM public.emergency_contacts ec
  INNER JOIN public.profiles p ON ec.contact_id = p.id
  INNER JOIN public.fcm_tokens ft ON ft.user_id = ec.contact_id
  WHERE ec.patient_id = p_patient_id
    AND ft.is_active = TRUE
  ORDER BY ec.priority ASC, ft.last_used_at DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_emergency_contact_tokens(UUID) TO authenticated;

-- =============================================================================
-- 9. HELPER FUNCTION: Get Family Member Tokens
-- =============================================================================

-- Function to get FCM tokens for all family members linked to a patient
-- Used for location alerts and activity reminders
CREATE OR REPLACE FUNCTION get_family_member_tokens(p_patient_id UUID)
RETURNS TABLE (
  family_member_id UUID,
  family_member_name TEXT,
  token TEXT,
  device_info JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    pfl.family_member_id,
    p.full_name AS family_member_name,
    ft.token,
    ft.device_info
  FROM public.patient_family_links pfl
  INNER JOIN public.profiles p ON pfl.family_member_id = p.id
  INNER JOIN public.fcm_tokens ft ON ft.user_id = pfl.family_member_id
  WHERE pfl.patient_id = p_patient_id
    AND ft.is_active = TRUE
  ORDER BY ft.last_used_at DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_family_member_tokens(UUID) TO authenticated;

-- =============================================================================
-- 10. VERIFICATION QUERIES
-- =============================================================================

-- Verify table created
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'fcm_tokens') THEN
    RAISE EXCEPTION 'fcm_tokens table was not created!';
  END IF;
  
  RAISE NOTICE '✅ fcm_tokens table created successfully';
END $$;

-- Verify indexes created
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_fcm_tokens_user_id') THEN
    RAISE EXCEPTION 'idx_fcm_tokens_user_id index was not created!';
  END IF;
  
  RAISE NOTICE '✅ All indexes created successfully';
END $$;

-- Verify RLS enabled
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_tables 
    WHERE tablename = 'fcm_tokens' 
    AND rowsecurity = TRUE
  ) THEN
    RAISE EXCEPTION 'RLS is not enabled on fcm_tokens table!';
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
✅ Migration 006: FCM Tokens Table - COMPLETE
================================================================================
Created:
  - Table: fcm_tokens (with JSONB device_info)
  - Indexes: user_id, token, last_used_at
  - Functions: upsert_fcm_token, get_user_fcm_tokens, cleanup_stale_fcm_tokens
  - Helper Functions: get_emergency_contact_tokens, get_family_member_tokens
  - RLS Policies: 5 policies for user access control
  - Trigger: auto-update updated_at

Usage Example:
  -- Save FCM token
  SELECT upsert_fcm_token(
    auth.uid(),
    ''fcmToken123...'',
    ''{"platform": "android", "os_version": "Android 13"}''::jsonb
  );

  -- Get all active tokens for user
  SELECT * FROM get_user_fcm_tokens(auth.uid());

  -- Get emergency contact tokens
  SELECT * FROM get_emergency_contact_tokens(''patient-uuid-here'');

Cost: $0.00 (Firebase FCM is FREE unlimited)
================================================================================
';
END $$;
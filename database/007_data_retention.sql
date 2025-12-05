-- =============================================================================
-- Migration 007: Data Retention & Cleanup
-- =============================================================================
-- Purpose: Automatic cleanup of old location data to prevent database bloat
-- Created: 2025-01-12
-- Dependencies: 001_initial_schema.sql (locations table)
-- FREE Service: pg_cron (built-in PostgreSQL extension)
-- =============================================================================

-- Description:
-- This migration implements enterprise-grade data retention policies using
-- PostgreSQL's pg_cron extension (100% FREE). It automatically archives and
-- deletes old location data to prevent database bloat while maintaining
-- recent data for operational needs.
--
-- Retention Policy:
-- - Keep last 90 days of location data (hot storage)
-- - Delete data older than 90 days (or archive to cold storage)
-- - Run cleanup daily at 2 AM UTC
-- - Preserve emergency-related locations indefinitely
--
-- Benefits:
-- - Prevents database bloat (millions of GPS points)
-- - Maintains fast query performance
-- - Reduces storage costs
-- - Complies with data retention policies

-- =============================================================================
-- 1. ENABLE pg_cron EXTENSION
-- =============================================================================

-- Check if pg_cron is available
DO $$
BEGIN
  -- pg_cron is available on Supabase FREE tier
  -- Enable extension
  CREATE EXTENSION IF NOT EXISTS pg_cron;
  
  RAISE NOTICE '✅ pg_cron extension enabled';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE '⚠️  pg_cron extension not available. This is OK for local development.';
    RAISE NOTICE 'On Supabase, pg_cron is available by default.';
END $$;

-- =============================================================================
-- 2. CREATE TABLE: location_archives (Optional - Cold Storage)
-- =============================================================================

-- Table to store archived locations (older than 90 days)
-- This is optional - you can also just DELETE old data
DROP TABLE IF EXISTS public.location_archives CASCADE;

CREATE TABLE public.location_archives (
  -- Same schema as locations table
  id BIGINT PRIMARY KEY,
  patient_id UUID NOT NULL,
  coordinates GEOGRAPHY(POINT, 4326) NOT NULL,
  accuracy REAL,
  altitude REAL,
  speed REAL,
  heading REAL,
  timestamp TIMESTAMPTZ NOT NULL,
  
  -- Archive metadata
  archived_at TIMESTAMPTZ DEFAULT NOW(),
  archive_reason TEXT DEFAULT 'retention_policy'
);

-- Index for archived data queries
CREATE INDEX idx_location_archives_patient 
  ON public.location_archives(patient_id);

CREATE INDEX idx_location_archives_timestamp 
  ON public.location_archives(timestamp DESC);

-- RLS policies for archives
ALTER TABLE public.location_archives ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Family can view archived patient locations"
  ON public.location_archives
  FOR SELECT
  USING (
    patient_id IN (
      SELECT patient_id 
      FROM public.patient_family_links 
      WHERE family_member_id = auth.uid()
    )
  );

-- =============================================================================
-- 3. CREATE FUNCTION: Cleanup Old Locations
-- =============================================================================

-- Main cleanup function
-- Deletes (or archives) locations older than retention_days
CREATE OR REPLACE FUNCTION cleanup_old_locations(
  retention_days INTEGER DEFAULT 90,
  archive_before_delete BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
  archived_count INTEGER,
  deleted_count INTEGER,
  freed_space_mb NUMERIC
) AS $$
DECLARE
  v_archived_count INTEGER := 0;
  v_deleted_count INTEGER := 0;
  v_table_size_before BIGINT;
  v_table_size_after BIGINT;
  v_freed_space_mb NUMERIC;
  v_cutoff_date TIMESTAMPTZ;
BEGIN
  -- Calculate cutoff date
  v_cutoff_date := NOW() - (retention_days || ' days')::INTERVAL;
  
  RAISE NOTICE 'Starting cleanup: deleting locations older than %', v_cutoff_date;
  
  -- Get table size before cleanup
  SELECT pg_total_relation_size('public.locations') INTO v_table_size_before;
  
  -- STEP 1: Archive old locations (if requested)
  IF archive_before_delete THEN
    RAISE NOTICE 'Archiving locations older than % days...', retention_days;
    
    INSERT INTO public.location_archives (
      id, patient_id, coordinates, accuracy, altitude, 
      speed, heading, timestamp, archived_at, archive_reason
    )
    SELECT 
      l.id, l.patient_id, l.coordinates, l.accuracy, l.altitude,
      l.speed, l.heading, l.timestamp, NOW(), 
      'retention_policy_' || retention_days || '_days'
    FROM public.locations l
    WHERE l.timestamp < v_cutoff_date
      -- Don't archive emergency-related locations
      AND NOT EXISTS (
        SELECT 1 FROM public.emergency_alerts ea
        WHERE ea.patient_id = l.patient_id
          AND ea.created_at BETWEEN l.timestamp - INTERVAL '1 hour' 
                                AND l.timestamp + INTERVAL '1 hour'
      );
    
    GET DIAGNOSTICS v_archived_count = ROW_COUNT;
    RAISE NOTICE 'Archived % locations', v_archived_count;
  END IF;
  
  -- STEP 2: Delete old locations
  RAISE NOTICE 'Deleting locations older than % days...', retention_days;
  
  DELETE FROM public.locations l
  WHERE l.timestamp < v_cutoff_date
    -- Don't delete emergency-related locations
    AND NOT EXISTS (
      SELECT 1 FROM public.emergency_alerts ea
      WHERE ea.patient_id = l.patient_id
        AND ea.created_at BETWEEN l.timestamp - INTERVAL '1 hour' 
                              AND l.timestamp + INTERVAL '1 hour'
    );
  
  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  RAISE NOTICE 'Deleted % locations', v_deleted_count;
  
  -- STEP 3: Vacuum table to reclaim space
  EXECUTE 'VACUUM ANALYZE public.locations';
  
  -- Get table size after cleanup
  SELECT pg_total_relation_size('public.locations') INTO v_table_size_after;
  
  -- Calculate freed space in MB
  v_freed_space_mb := ROUND((v_table_size_before - v_table_size_after)::NUMERIC / 1024 / 1024, 2);
  
  RAISE NOTICE 'Freed % MB of space', v_freed_space_mb;
  
  -- Return summary
  RETURN QUERY SELECT v_archived_count, v_deleted_count, v_freed_space_mb;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to service role
GRANT EXECUTE ON FUNCTION cleanup_old_locations(INTEGER, BOOLEAN) TO service_role;

-- =============================================================================
-- 4. CREATE FUNCTION: Get Cleanup Statistics
-- =============================================================================

-- Function to check what will be deleted before running cleanup
CREATE OR REPLACE FUNCTION get_cleanup_statistics(retention_days INTEGER DEFAULT 90)
RETURNS TABLE (
  locations_to_delete BIGINT,
  oldest_location TIMESTAMPTZ,
  newest_location TIMESTAMPTZ,
  estimated_space_mb NUMERIC,
  emergency_protected BIGINT
) AS $$
DECLARE
  v_cutoff_date TIMESTAMPTZ;
BEGIN
  v_cutoff_date := NOW() - (retention_days || ' days')::INTERVAL;
  
  RETURN QUERY
  SELECT 
    COUNT(*) AS locations_to_delete,
    MIN(l.timestamp) AS oldest_location,
    MAX(l.timestamp) AS newest_location,
    ROUND((COUNT(*) * 100)::NUMERIC / 1024, 2) AS estimated_space_mb, -- ~100 bytes per row
    (
      SELECT COUNT(*) FROM public.locations l2
      WHERE l2.timestamp < v_cutoff_date
        AND EXISTS (
          SELECT 1 FROM public.emergency_alerts ea
          WHERE ea.patient_id = l2.patient_id
            AND ea.created_at BETWEEN l2.timestamp - INTERVAL '1 hour' 
                                  AND l2.timestamp + INTERVAL '1 hour'
        )
    ) AS emergency_protected
  FROM public.locations l
  WHERE l.timestamp < v_cutoff_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_cleanup_statistics(INTEGER) TO authenticated;

-- =============================================================================
-- 5. CREATE FUNCTION: Cleanup Old Archives
-- =============================================================================

-- Function to delete archives older than 1 year (365 days)
-- Archives are already in cold storage, so safe to delete
CREATE OR REPLACE FUNCTION cleanup_old_archives(archive_retention_days INTEGER DEFAULT 365)
RETURNS INTEGER AS $$
DECLARE
  v_deleted_count INTEGER;
  v_cutoff_date TIMESTAMPTZ;
BEGIN
  v_cutoff_date := NOW() - (archive_retention_days || ' days')::INTERVAL;
  
  RAISE NOTICE 'Deleting archived locations older than %', v_cutoff_date;
  
  DELETE FROM public.location_archives
  WHERE archived_at < v_cutoff_date;
  
  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  
  RAISE NOTICE 'Deleted % archived locations', v_deleted_count;
  
  EXECUTE 'VACUUM ANALYZE public.location_archives';
  
  RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to service role
GRANT EXECUTE ON FUNCTION cleanup_old_archives(INTEGER) TO service_role;

-- =============================================================================
-- 6. SCHEDULE CRON JOBS (Supabase Production Only)
-- =============================================================================

-- Schedule daily cleanup at 2 AM UTC
-- This will only work on Supabase (not local development)
DO $$
BEGIN
  -- Check if pg_cron is available
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    
    -- Remove existing jobs if they exist (for re-running migration)
    -- Check first to avoid error if job doesn't exist
    IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'cleanup-old-locations') THEN
      PERFORM cron.unschedule('cleanup-old-locations');
    END IF;
    
    IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'cleanup-old-archives') THEN
      PERFORM cron.unschedule('cleanup-old-archives');
    END IF;
    
    -- Schedule main cleanup job (daily at 2 AM UTC)
    PERFORM cron.schedule(
      'cleanup-old-locations',                    -- Job name
      '0 2 * * *',                                -- Cron schedule (2 AM daily)
      'SELECT cleanup_old_locations(90, false)'   -- Delete after 90 days
    );
    
    -- Schedule archive cleanup job (monthly on 1st at 3 AM UTC)
    PERFORM cron.schedule(
      'cleanup-old-archives',                     -- Job name
      '0 3 1 * *',                                -- Cron schedule (1st of month)
      'SELECT cleanup_old_archives(365)'          -- Delete archives > 1 year
    );
    
    RAISE NOTICE '✅ Cron jobs scheduled successfully';
    RAISE NOTICE '   - cleanup-old-locations: Daily at 2 AM UTC';
    RAISE NOTICE '   - cleanup-old-archives: Monthly on 1st at 3 AM UTC';
    
  ELSE
    RAISE NOTICE '⚠️  pg_cron not available - cron jobs not scheduled';
    RAISE NOTICE 'For production on Supabase, pg_cron is automatically available';
  END IF;
END $$;

-- =============================================================================
-- 7. CREATE VIEW: Cleanup Statistics Dashboard
-- =============================================================================

-- View to monitor data retention status
CREATE OR REPLACE VIEW public.location_retention_stats AS
SELECT 
  -- Total locations
  (SELECT COUNT(*) FROM public.locations) AS total_locations,
  
  -- Locations by age bucket
  (SELECT COUNT(*) FROM public.locations WHERE timestamp > NOW() - INTERVAL '7 days') AS last_7_days,
  (SELECT COUNT(*) FROM public.locations WHERE timestamp > NOW() - INTERVAL '30 days') AS last_30_days,
  (SELECT COUNT(*) FROM public.locations WHERE timestamp > NOW() - INTERVAL '90 days') AS last_90_days,
  (SELECT COUNT(*) FROM public.locations WHERE timestamp <= NOW() - INTERVAL '90 days') AS older_than_90_days,
  
  -- Table sizes
  pg_size_pretty(pg_total_relation_size('public.locations')) AS locations_table_size,
  pg_size_pretty(pg_total_relation_size('public.location_archives')) AS archives_table_size,
  
  -- Archive stats
  (SELECT COUNT(*) FROM public.location_archives) AS total_archived,
  (SELECT MIN(archived_at) FROM public.location_archives) AS oldest_archive,
  (SELECT MAX(archived_at) FROM public.location_archives) AS newest_archive,
  
  -- Next scheduled cleanup (if pg_cron available)
  (
    SELECT MAX(c.schedule)
    FROM cron.job c
    WHERE c.jobname = 'cleanup-old-locations'
  ) AS next_cleanup_schedule;

-- Grant view access
GRANT SELECT ON public.location_retention_stats TO authenticated;

-- =============================================================================
-- 8. HELPER FUNCTION: Manual Cleanup Test (Safe)
-- =============================================================================

-- Function to preview cleanup without actually deleting
-- Useful for testing and validation
CREATE OR REPLACE FUNCTION preview_cleanup(retention_days INTEGER DEFAULT 90)
RETURNS TABLE (
  will_be_deleted BIGINT,
  will_be_kept BIGINT,
  oldest_to_delete TIMESTAMPTZ,
  newest_to_delete TIMESTAMPTZ,
  oldest_to_keep TIMESTAMPTZ,
  space_to_free_mb NUMERIC
) AS $$
DECLARE
  v_cutoff_date TIMESTAMPTZ;
BEGIN
  v_cutoff_date := NOW() - (retention_days || ' days')::INTERVAL;
  
  RETURN QUERY
  SELECT 
    (SELECT COUNT(*) FROM public.locations WHERE timestamp < v_cutoff_date) AS will_be_deleted,
    (SELECT COUNT(*) FROM public.locations WHERE timestamp >= v_cutoff_date) AS will_be_kept,
    (SELECT MIN(timestamp) FROM public.locations WHERE timestamp < v_cutoff_date) AS oldest_to_delete,
    (SELECT MAX(timestamp) FROM public.locations WHERE timestamp < v_cutoff_date) AS newest_to_delete,
    (SELECT MIN(timestamp) FROM public.locations WHERE timestamp >= v_cutoff_date) AS oldest_to_keep,
    ROUND((
      SELECT COUNT(*)::NUMERIC * 100 / 1024
      FROM public.locations 
      WHERE timestamp < v_cutoff_date
    ), 2) AS space_to_free_mb;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION preview_cleanup(INTEGER) TO authenticated;

-- =============================================================================
-- 9. VERIFICATION QUERIES
-- =============================================================================

-- Verify archive table created
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'location_archives') THEN
    RAISE EXCEPTION 'location_archives table was not created!';
  END IF;
  
  RAISE NOTICE '✅ location_archives table created successfully';
END $$;

-- Verify functions created
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'cleanup_old_locations') THEN
    RAISE EXCEPTION 'cleanup_old_locations function was not created!';
  END IF;
  
  RAISE NOTICE '✅ All cleanup functions created successfully';
END $$;

-- Verify view created
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'location_retention_stats') THEN
    RAISE EXCEPTION 'location_retention_stats view was not created!';
  END IF;
  
  RAISE NOTICE '✅ Retention stats view created successfully';
END $$;

-- Check if cron jobs are scheduled (production only)
DO $$
DECLARE
  v_job_count INTEGER;
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    SELECT COUNT(*) INTO v_job_count
    FROM cron.job
    WHERE jobname IN ('cleanup-old-locations', 'cleanup-old-archives');
    
    IF v_job_count = 2 THEN
      RAISE NOTICE '✅ Cron jobs scheduled successfully';
    ELSE
      RAISE WARNING 'Only % of 2 expected cron jobs were scheduled', v_job_count;
    END IF;
  ELSE
    RAISE NOTICE 'ℹ️  pg_cron not available (OK for local dev)';
  END IF;
END $$;

-- =============================================================================
-- MIGRATION COMPLETE
-- =============================================================================

DO $$
BEGIN
  RAISE NOTICE '
================================================================================
✅ Migration 007: Data Retention & Cleanup - COMPLETE
================================================================================
Created:
  - Table: location_archives (cold storage)
  - Functions: 
    * cleanup_old_locations(retention_days, archive_before_delete)
    * get_cleanup_statistics(retention_days)
    * cleanup_old_archives(archive_retention_days)
    * preview_cleanup(retention_days)
  - View: location_retention_stats (monitoring dashboard)
  - Cron Jobs (if pg_cron available):
    * cleanup-old-locations: Daily at 2 AM UTC
    * cleanup-old-archives: Monthly on 1st at 3 AM UTC

Retention Policy:
  - Hot Storage: 90 days (operational data)
  - Archive Storage: 365 days (historical data)
  - Emergency locations: Protected indefinitely

Usage Examples:
  -- Preview what will be deleted
  SELECT * FROM preview_cleanup(90);

  -- Check retention statistics
  SELECT * FROM location_retention_stats;

  -- Get cleanup stats before running
  SELECT * FROM get_cleanup_statistics(90);

  -- Manual cleanup (if needed)
  SELECT * FROM cleanup_old_locations(90, false);

  -- List scheduled cron jobs
  SELECT * FROM cron.job;

Cost: $0.00 (pg_cron is FREE on Supabase)
================================================================================
';
END $$;

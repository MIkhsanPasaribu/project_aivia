-- =============================================================================
-- Master Migration Script: Run All Phase 2 Migrations
-- =============================================================================
-- Purpose: Execute all Phase 2 database migrations in correct order
-- Created: 2025-01-12
-- Phase: Sprint 2.3B - Database Enhancements (100% FREE)
-- =============================================================================

-- IMPORTANT NOTES:
-- 1. Backup your database before running this script
-- 2. Run this in Supabase SQL Editor with "Run" button
-- 3. Check for errors after each migration
-- 4. All migrations use FREE PostgreSQL/PostGIS features
-- 5. Total execution time: ~30-60 seconds

-- =============================================================================
-- PRE-FLIGHT CHECKS
-- =============================================================================

-- Check if PostGIS is enabled (required for location features)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'postgis') THEN
    RAISE EXCEPTION '❌ PostGIS extension is not enabled! Enable it first:
      CREATE EXTENSION postgis;';
  END IF;
  
  RAISE NOTICE '✅ PostGIS extension is enabled';
END $$;

-- Check if profiles table exists (dependency)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles') THEN
    RAISE EXCEPTION '❌ profiles table does not exist! Run 001_initial_schema.sql first.';
  END IF;
  
  RAISE NOTICE '✅ profiles table exists';
END $$;

-- Check if locations table exists (dependency)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'locations') THEN
    RAISE EXCEPTION '❌ locations table does not exist! Run 001_initial_schema.sql first.';
  END IF;
  
  RAISE NOTICE '✅ locations table exists';
END $$;

-- Check if emergency_alerts table exists (dependency)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'emergency_alerts') THEN
    RAISE EXCEPTION '❌ emergency_alerts table does not exist! Run 001_initial_schema.sql first.';
  END IF;
  
  RAISE NOTICE '✅ emergency_alerts table exists';
END $$;

DO $$
BEGIN
  RAISE NOTICE '
================================================================================
Starting Phase 2 Database Migrations
================================================================================
Total Migrations: 6
  - 006_fcm_tokens.sql
  - 007_data_retention.sql
  - 008_location_clustering.sql
  - 009_geofences.sql
  - 010_geofence_events.sql
  - 011_emergency_notifications.sql

Estimated Time: 30-60 seconds
Cost: $0.00 (100%% FREE features)
================================================================================
';
END $$;

-- =============================================================================
-- MIGRATION 006: FCM Tokens Table
-- =============================================================================

RAISE NOTICE '
--------------------------------------------------------------------------------
[1/6] Running Migration 006: FCM Tokens Table
--------------------------------------------------------------------------------
';

\i 006_fcm_tokens.sql

RAISE NOTICE '✅ Migration 006 complete - FCM Tokens Table created';

-- =============================================================================
-- MIGRATION 007: Data Retention & Cleanup
-- =============================================================================

RAISE NOTICE '
--------------------------------------------------------------------------------
[2/6] Running Migration 007: Data Retention & Cleanup
--------------------------------------------------------------------------------
';

\i 007_data_retention.sql

RAISE NOTICE '✅ Migration 007 complete - Data Retention configured';

-- =============================================================================
-- MIGRATION 008: Location Clustering & Noise Reduction
-- =============================================================================

RAISE NOTICE '
--------------------------------------------------------------------------------
[3/6] Running Migration 008: Location Clustering
--------------------------------------------------------------------------------
';

\i 008_location_clustering.sql

RAISE NOTICE '✅ Migration 008 complete - Location Clustering active';

-- =============================================================================
-- MIGRATION 009: Geofences (Safe Zones & Danger Zones)
-- =============================================================================

RAISE NOTICE '
--------------------------------------------------------------------------------
[4/6] Running Migration 009: Geofences
--------------------------------------------------------------------------------
';

\i 009_geofences.sql

RAISE NOTICE '✅ Migration 009 complete - Geofences table created';

-- =============================================================================
-- MIGRATION 010: Geofence Events (Enter/Exit Detection)
-- =============================================================================

RAISE NOTICE '
--------------------------------------------------------------------------------
[5/6] Running Migration 010: Geofence Events
--------------------------------------------------------------------------------
';

\i 010_geofence_events.sql

RAISE NOTICE '✅ Migration 010 complete - Geofence Events detection active';

-- =============================================================================
-- MIGRATION 011: Emergency Notifications (FCM Integration)
-- =============================================================================

RAISE NOTICE '
--------------------------------------------------------------------------------
[6/6] Running Migration 011: Emergency Notifications
--------------------------------------------------------------------------------
';

\i 011_emergency_notifications.sql

RAISE NOTICE '✅ Migration 011 complete - Emergency Notifications configured';

-- =============================================================================
-- POST-MIGRATION VERIFICATION
-- =============================================================================

RAISE NOTICE '
================================================================================
Running Post-Migration Verification
================================================================================
';

-- Verify all tables created
DO $$
DECLARE
  v_tables TEXT[] := ARRAY[
    'fcm_tokens',
    'location_archives',
    'geofences',
    'geofence_events',
    'emergency_notification_log'
  ];
  v_table TEXT;
  v_missing INTEGER := 0;
BEGIN
  FOREACH v_table IN ARRAY v_tables
  LOOP
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = v_table) THEN
      RAISE WARNING '❌ Table missing: %', v_table;
      v_missing := v_missing + 1;
    ELSE
      RAISE NOTICE '✅ Table exists: %', v_table;
    END IF;
  END LOOP;
  
  IF v_missing > 0 THEN
    RAISE EXCEPTION '❌ % table(s) are missing! Check migration logs.', v_missing;
  END IF;
  
  RAISE NOTICE '✅ All tables created successfully';
END $$;

-- Verify all triggers created
DO $$
DECLARE
  v_triggers TEXT[] := ARRAY[
    'trigger_update_fcm_tokens_updated_at',
    'trigger_cluster_locations_on_insert',
    'trigger_update_geofences_updated_at',
    'trigger_check_geofences_after_insert',
    'trigger_emergency_alert_notifications'
  ];
  v_trigger TEXT;
  v_missing INTEGER := 0;
BEGIN
  FOREACH v_trigger IN ARRAY v_triggers
  LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = v_trigger) THEN
      RAISE WARNING '❌ Trigger missing: %', v_trigger;
      v_missing := v_missing + 1;
    ELSE
      RAISE NOTICE '✅ Trigger exists: %', v_trigger;
    END IF;
  END LOOP;
  
  IF v_missing > 0 THEN
    RAISE EXCEPTION '❌ % trigger(s) are missing! Check migration logs.', v_missing;
  END IF;
  
  RAISE NOTICE '✅ All triggers created successfully';
END $$;

-- Verify key functions created
DO $$
DECLARE
  v_functions TEXT[] := ARRAY[
    'upsert_fcm_token',
    'cleanup_old_locations',
    'should_cluster_location',
    'get_patient_geofences',
    'detect_geofence_events',
    'send_emergency_notifications'
  ];
  v_function TEXT;
  v_missing INTEGER := 0;
BEGIN
  FOREACH v_function IN ARRAY v_functions
  LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = v_function) THEN
      RAISE WARNING '❌ Function missing: %', v_function;
      v_missing := v_missing + 1;
    ELSE
      RAISE NOTICE '✅ Function exists: %', v_function;
    END IF;
  END LOOP;
  
  IF v_missing > 0 THEN
    RAISE EXCEPTION '❌ % function(s) are missing! Check migration logs.', v_missing;
  END IF;
  
  RAISE NOTICE '✅ All key functions created successfully';
END $$;

-- Check pg_cron jobs (production only)
DO $$
DECLARE
  v_job_count INTEGER;
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    SELECT COUNT(*) INTO v_job_count
    FROM cron.job
    WHERE jobname IN ('cleanup-old-locations', 'cleanup-old-archives');
    
    IF v_job_count > 0 THEN
      RAISE NOTICE '✅ pg_cron jobs scheduled: %', v_job_count;
      
      -- List scheduled jobs
      FOR v_job_count IN
        SELECT jobid, schedule, command
        FROM cron.job
        WHERE jobname IN ('cleanup-old-locations', 'cleanup-old-archives')
      LOOP
        RAISE NOTICE '  Job ID %, Schedule: %, Command: %', 
          v_job_count.jobid, v_job_count.schedule, v_job_count.command;
      END LOOP;
    ELSE
      RAISE NOTICE 'ℹ️  No pg_cron jobs scheduled (OK for local dev)';
    END IF;
  ELSE
    RAISE NOTICE 'ℹ️  pg_cron extension not available (OK for local dev)';
  END IF;
END $$;

-- =============================================================================
-- GENERATE STATISTICS
-- =============================================================================

RAISE NOTICE '
================================================================================
Migration Statistics
================================================================================
';

-- Count objects created
DO $$
DECLARE
  v_table_count INTEGER;
  v_function_count INTEGER;
  v_trigger_count INTEGER;
  v_view_count INTEGER;
  v_index_count INTEGER;
BEGIN
  -- Count new tables
  SELECT COUNT(*) INTO v_table_count
  FROM information_schema.tables
  WHERE table_name IN (
    'fcm_tokens', 'location_archives', 'geofences', 
    'geofence_events', 'emergency_notification_log'
  );
  
  -- Count new functions
  SELECT COUNT(*) INTO v_function_count
  FROM pg_proc
  WHERE proname IN (
    'upsert_fcm_token', 'get_user_fcm_tokens', 'cleanup_old_locations',
    'get_cleanup_statistics', 'should_cluster_location', 'update_clustered_location',
    'get_patient_geofences', 'check_location_geofences', 'get_patient_current_geofence_state',
    'detect_geofence_events', 'send_emergency_notifications', 'update_notification_status'
  );
  
  -- Count new triggers
  SELECT COUNT(*) INTO v_trigger_count
  FROM pg_trigger
  WHERE tgname IN (
    'trigger_update_fcm_tokens_updated_at', 'trigger_cluster_locations_on_insert',
    'trigger_update_geofences_updated_at', 'trigger_check_geofences_after_insert',
    'trigger_emergency_alert_notifications'
  );
  
  -- Count new views
  SELECT COUNT(*) INTO v_view_count
  FROM pg_views
  WHERE viewname IN (
    'location_retention_stats', 'location_clustering_stats', 'geofence_stats',
    'geofence_event_stats', 'recent_geofence_activity', 'emergency_notification_stats'
  );
  
  -- Count new indexes (approximation)
  SELECT COUNT(*) INTO v_index_count
  FROM pg_indexes
  WHERE tablename IN (
    'fcm_tokens', 'location_archives', 'geofences', 
    'geofence_events', 'emergency_notification_log'
  );
  
  RAISE NOTICE 'Objects Created:';
  RAISE NOTICE '  - Tables: %', v_table_count;
  RAISE NOTICE '  - Functions: %', v_function_count;
  RAISE NOTICE '  - Triggers: %', v_trigger_count;
  RAISE NOTICE '  - Views: %', v_view_count;
  RAISE NOTICE '  - Indexes: %', v_index_count;
  RAISE NOTICE '  - Total: %', v_table_count + v_function_count + v_trigger_count + v_view_count + v_index_count;
END $$;

-- =============================================================================
-- MIGRATION COMPLETE
-- =============================================================================

DO $$
BEGIN
  RAISE NOTICE '
================================================================================
✅ ALL PHASE 2 MIGRATIONS COMPLETE!
================================================================================

Successfully Applied:
  ✅ Migration 006: FCM Tokens Table
  ✅ Migration 007: Data Retention & Cleanup
  ✅ Migration 008: Location Clustering & Noise Reduction
  ✅ Migration 009: Geofences (Safe Zones & Danger Zones)
  ✅ Migration 010: Geofence Events (Enter/Exit Detection)
  ✅ Migration 011: Emergency Notifications (FCM Integration)

New Features Enabled:
  📱 Firebase Cloud Messaging (FCM) integration
  🗑️  Automatic data retention (90-day cleanup)
  🎯 GPS noise reduction (40-60% space saving)
  📍 Geofencing (safe zones & danger zones)
  🚨 Automatic geofence event detection
  🔔 Emergency push notifications

Next Steps:
  1. Create Firebase project (console.firebase.google.com)
  2. Enable FCM, Crashlytics, Analytics, Performance
  3. Download google-services.json
  4. Run: flutterfire configure
  5. Implement FCMService in Flutter
  6. Create Supabase Edge Function for FCM delivery
  7. Test emergency notifications end-to-end

Cost: $0.00 (100% FREE features)

Documentation:
  - See PHASE2_SPRINT_2.3A_COMPLETE.md for implementation details
  - See PHASE2_ENTERPRISE_FREE_IMPLEMENTATION_PLAN.md for full roadmap

================================================================================
';
END $$;

-- Optional: Run verification queries
-- Uncomment to see sample data from new views

-- SELECT * FROM location_retention_stats;
-- SELECT * FROM location_clustering_stats;
-- SELECT * FROM geofence_stats;
-- SELECT * FROM geofence_event_stats;
-- SELECT * FROM recent_geofence_activity LIMIT 10;
-- SELECT * FROM emergency_notification_stats LIMIT 10;

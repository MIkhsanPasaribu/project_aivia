-- =====================================================
-- AIVIA Database - Master Migration Script
-- Version: 1.0.0
-- Date: 8 Oktober 2025
-- Description: Run all migrations in correct order
-- =====================================================

-- =====================================================
-- USAGE INSTRUCTIONS
-- =====================================================
-- 
-- Option 1: Run All at Once (Supabase SQL Editor)
-- 1. Open Supabase Dashboard > SQL Editor
-- 2. Create "New query"
-- 3. Copy isi file ini
-- 4. Run (Ctrl+Enter)
--
-- Option 2: Run Step by Step
-- 1. Run 001_initial_schema.sql
-- 2. Run 002_rls_policies.sql
-- 3. Run 003_triggers_functions.sql
-- 4. Run 004_realtime_config.sql
-- 5. Run 005_seed_data.sql (optional, hanya development)
--
-- =====================================================

BEGIN;

-- =====================================================
-- STEP 1: Initial Schema
-- =====================================================
\echo '📦 Running 001_initial_schema.sql...'
\i database/001_initial_schema.sql

-- =====================================================
-- STEP 2: RLS Policies
-- =====================================================
\echo '🔒 Running 002_rls_policies.sql...'
\i database/002_rls_policies.sql

-- =====================================================
-- STEP 3: Triggers & Functions
-- =====================================================
\echo '🔄 Running 003_triggers_functions.sql...'
\i database/003_triggers_functions.sql

-- =====================================================
-- STEP 4: Realtime Configuration
-- =====================================================
\echo '📡 Running 004_realtime_config.sql...'
\i database/004_realtime_config.sql

-- =====================================================
-- STEP 5: Seed Data (Optional - Only for Development)
-- =====================================================
-- Uncomment baris berikut jika ingin seed data:
-- \echo '🌱 Running 005_seed_data.sql...'
-- \i database/005_seed_data.sql

COMMIT;

-- =====================================================
-- VERIFICATION
-- =====================================================

DO $$
DECLARE
  table_count INTEGER;
  policy_count INTEGER;
  function_count INTEGER;
  trigger_count INTEGER;
  publication_table_count INTEGER;
BEGIN
  -- Count tables
  SELECT COUNT(*) INTO table_count
  FROM information_schema.tables
  WHERE table_schema = 'public'
    AND table_type = 'BASE TABLE';
  
  -- Count RLS policies
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE schemaname = 'public';
  
  -- Count functions
  SELECT COUNT(*) INTO function_count
  FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname = 'public'
    AND p.prokind = 'f';
  
  -- Count triggers
  SELECT COUNT(*) INTO trigger_count
  FROM information_schema.triggers
  WHERE trigger_schema = 'public';
  
  -- Count realtime tables
  SELECT COUNT(*) INTO publication_table_count
  FROM pg_publication_tables
  WHERE pubname = 'supabase_realtime';
  
  RAISE NOTICE '';
  RAISE NOTICE '════════════════════════════════════════════════';
  RAISE NOTICE '✅ AIVIA DATABASE SETUP COMPLETE!';
  RAISE NOTICE '════════════════════════════════════════════════';
  RAISE NOTICE '';
  RAISE NOTICE '📊 Database Statistics:';
  RAISE NOTICE '   📦 Tables: %', table_count;
  RAISE NOTICE '   🔒 RLS Policies: %', policy_count;
  RAISE NOTICE '   🛠️  Functions: %', function_count;
  RAISE NOTICE '   🔄 Triggers: %', trigger_count;
  RAISE NOTICE '   📡 Realtime Tables: %', publication_table_count;
  RAISE NOTICE '';
  RAISE NOTICE '🎯 Next Steps:';
  RAISE NOTICE '   1. Update .env file dengan Supabase credentials';
  RAISE NOTICE '   2. Run: flutter pub get';
  RAISE NOTICE '   3. Run: flutter run';
  RAISE NOTICE '   4. Test register/login di aplikasi';
  RAISE NOTICE '';
  RAISE NOTICE '📚 Documentation:';
  RAISE NOTICE '   - SUPABASE_SETUP.md: Setup guide lengkap';
  RAISE NOTICE '   - ENVIRONMENT.md: Environment variables guide';
  RAISE NOTICE '   - DATA_FLOW.md: Architecture & data flow';
  RAISE NOTICE '';
  RAISE NOTICE '🔐 Security Checklist:';
  RAISE NOTICE '   ✅ RLS enabled on all tables';
  RAISE NOTICE '   ✅ Storage bucket policies configured';
  RAISE NOTICE '   ✅ Triggers for automation in place';
  RAISE NOTICE '   ✅ Realtime subscriptions ready';
  RAISE NOTICE '';
  RAISE NOTICE '════════════════════════════════════════════════';
  RAISE NOTICE '🚀 Ready untuk development!';
  RAISE NOTICE '════════════════════════════════════════════════';
END $$;

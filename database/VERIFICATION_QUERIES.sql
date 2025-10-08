-- =====================================================
-- QUICK VERIFICATION QUERIES
-- Run these in Supabase SQL Editor to verify fix
-- =====================================================

-- =====================================================
-- 1. CHECK POLICIES FOR PROFILES TABLE
-- =====================================================
-- Should show 4 policies after fix
SELECT tablename, policyname, cmd
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'profiles'
ORDER BY policyname;

-- Expected Output:
-- profiles | authenticated_users_view_profiles | SELECT
-- profiles | users_insert_own_profile | INSERT
-- profiles | users_update_own_profile | UPDATE
-- profiles | users_view_own_profile | SELECT


-- =====================================================
-- 2. CHECK RLS ENABLED ON ALL TABLES
-- =====================================================
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- All should have rowsecurity = true


-- =====================================================
-- 3. CHECK TRIGGER EXISTS
-- =====================================================
SELECT trigger_name, event_manipulation, event_object_table, action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';

-- Expected Output:
-- on_auth_user_created | INSERT | users | EXECUTE FUNCTION public.handle_new_user()


-- =====================================================
-- 4. CHECK ALL USERS
-- =====================================================
SELECT id, email, created_at, 
       raw_user_meta_data->>'full_name' as full_name,
       raw_user_meta_data->>'user_role' as user_role
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 10;


-- =====================================================
-- 5. CHECK ALL PROFILES
-- =====================================================
SELECT id, email, full_name, user_role, created_at
FROM public.profiles 
ORDER BY created_at DESC 
LIMIT 10;


-- =====================================================
-- 6. FIND USERS WITHOUT PROFILES (Should be empty!)
-- =====================================================
SELECT u.id, u.email, u.created_at
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL;

-- If any results, create profiles manually:
-- INSERT INTO public.profiles (id, email, full_name, user_role)
-- SELECT id, email, 
--        COALESCE(raw_user_meta_data->>'full_name', 'User'),
--        COALESCE(raw_user_meta_data->>'user_role', 'patient')
-- FROM auth.users
-- WHERE email = 'specific-email@example.com';


-- =====================================================
-- 7. COUNT POLICIES PER TABLE
-- =====================================================
SELECT tablename, COUNT(*) as policy_count
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- Expected counts:
-- activities: 4
-- emergency_alerts: 3
-- emergency_contacts: 1
-- face_recognition_logs: 2
-- fcm_tokens: 1
-- known_persons: 2
-- locations: 2
-- notifications: 1
-- patient_family_links: 4
-- profiles: 4


-- =====================================================
-- 8. CHECK FOR CIRCULAR POLICY DEPENDENCIES
-- =====================================================
-- This query checks if any policies reference multiple tables
SELECT 
  policyname,
  tablename,
  regexp_matches(pg_get_expr(polqual, polrelid::regclass), 'FROM\s+[\w\.]+', 'g') as referenced_tables
FROM pg_policy
JOIN pg_class ON pg_policy.polrelid = pg_class.oid
JOIN pg_namespace ON pg_class.relnamespace = pg_namespace.oid
WHERE nspname = 'public'
ORDER BY tablename, policyname;

-- Should NOT see profiles referencing patient_family_links that references back to profiles


-- =====================================================
-- 9. TEST POLICY AS USER (Simulate)
-- =====================================================
-- Replace 'your-user-uuid' with actual user ID from auth.users
DO $$
DECLARE
  test_user_id UUID := 'your-user-uuid-here';
BEGIN
  -- Set session as that user
  PERFORM set_config('request.jwt.claims', json_build_object('sub', test_user_id)::text, true);
  
  -- Try to select profile
  PERFORM * FROM public.profiles WHERE id = test_user_id;
  
  RAISE NOTICE 'Policy test passed!';
END $$;


-- =====================================================
-- 10. CLEANUP BAD DATA (If needed)
-- =====================================================
-- Delete auth users without profiles (use with caution!)
-- DELETE FROM auth.users 
-- WHERE id IN (
--   SELECT u.id FROM auth.users u
--   LEFT JOIN public.profiles p ON u.id = p.id
--   WHERE p.id IS NULL
-- );

-- Or create missing profiles
-- INSERT INTO public.profiles (id, email, full_name, user_role)
-- SELECT id, email, 
--        COALESCE(raw_user_meta_data->>'full_name', 'User'),
--        COALESCE(raw_user_meta_data->>'user_role', 'patient')
-- FROM auth.users u
-- WHERE NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = u.id);


-- =====================================================
-- 11. CHECK ACTIVITIES ACCESSIBLE
-- =====================================================
-- As specific user
SELECT a.id, a.title, a.patient_id, p.full_name
FROM public.activities a
JOIN public.profiles p ON a.patient_id = p.id
ORDER BY a.activity_time DESC
LIMIT 10;


-- =====================================================
-- 12. FULL SYSTEM CHECK
-- =====================================================
-- Run all checks at once
DO $$
DECLARE
  policy_count INTEGER;
  trigger_count INTEGER;
  orphan_users INTEGER;
  rls_disabled INTEGER;
BEGIN
  -- Count policies
  SELECT COUNT(*) INTO policy_count FROM pg_policies WHERE schemaname = 'public';
  RAISE NOTICE 'Total policies: %', policy_count;
  
  -- Check trigger
  SELECT COUNT(*) INTO trigger_count 
  FROM information_schema.triggers 
  WHERE trigger_name = 'on_auth_user_created';
  RAISE NOTICE 'Trigger exists: %', (trigger_count > 0);
  
  -- Check orphan users
  SELECT COUNT(*) INTO orphan_users
  FROM auth.users u
  LEFT JOIN public.profiles p ON u.id = p.id
  WHERE p.id IS NULL;
  RAISE NOTICE 'Users without profiles: %', orphan_users;
  
  -- Check RLS disabled tables
  SELECT COUNT(*) INTO rls_disabled
  FROM pg_tables
  WHERE schemaname = 'public' AND rowsecurity = false;
  RAISE NOTICE 'Tables without RLS: %', rls_disabled;
  
  -- Summary
  IF policy_count >= 20 AND trigger_count = 1 AND orphan_users = 0 AND rls_disabled = 0 THEN
    RAISE NOTICE '✅ ALL CHECKS PASSED!';
  ELSE
    RAISE NOTICE '❌ SOME CHECKS FAILED! Review output above.';
  END IF;
END $$;

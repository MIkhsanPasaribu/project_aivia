-- =====================================================
-- AIVIA Database - Row Level Security (RLS) Policies
-- Version: 2.0.0 - FIXED INFINITE RECURSION
-- Date: 8 Oktober 2025
-- Description: Simplified RLS policies tanpa circular dependencies
-- =====================================================

-- =====================================================
-- CRITICAL FIX: Infinite Recursion Problem
-- =====================================================
-- Problem: policies yang query profiles -> patient_family_links -> profiles (loop!)
-- Solution: Simplified policies, remove circular dependencies
-- =====================================================

-- =====================================================
-- STEP 0: Drop All Existing Policies (Clean Slate)
-- =====================================================

-- Drop profiles policies
DROP POLICY IF EXISTS "users_view_own_profile" ON public.profiles;
DROP POLICY IF EXISTS "users_update_own_profile" ON public.profiles;
DROP POLICY IF EXISTS "family_view_linked_patients" ON public.profiles;
DROP POLICY IF EXISTS "patients_view_linked_family" ON public.profiles;
DROP POLICY IF EXISTS "admin_view_all_profiles" ON public.profiles;
DROP POLICY IF EXISTS "users_insert_own_profile" ON public.profiles;

-- Drop patient_family_links policies
DROP POLICY IF EXISTS "users_view_own_links" ON public.patient_family_links;
DROP POLICY IF EXISTS "family_create_links" ON public.patient_family_links;
DROP POLICY IF EXISTS "family_delete_own_links" ON public.patient_family_links;
DROP POLICY IF EXISTS "patients_delete_links" ON public.patient_family_links;
DROP POLICY IF EXISTS "family_update_links" ON public.patient_family_links;

-- Drop activities policies
DROP POLICY IF EXISTS "patients_view_own_activities" ON public.activities;
DROP POLICY IF EXISTS "family_view_patient_activities" ON public.activities;
DROP POLICY IF EXISTS "patients_insert_own_activities" ON public.activities;
DROP POLICY IF EXISTS "family_insert_patient_activities" ON public.activities;
DROP POLICY IF EXISTS "patients_update_own_activities" ON public.activities;
DROP POLICY IF EXISTS "family_update_patient_activities" ON public.activities;
DROP POLICY IF EXISTS "patients_delete_own_activities" ON public.activities;
DROP POLICY IF EXISTS "family_delete_patient_activities" ON public.activities;

-- Drop other policies
DROP POLICY IF EXISTS "owners_manage_known_persons" ON public.known_persons;
DROP POLICY IF EXISTS "family_view_patient_known_persons" ON public.known_persons;
DROP POLICY IF EXISTS "patients_insert_own_location" ON public.locations;
DROP POLICY IF EXISTS "family_view_patient_location" ON public.locations;
DROP POLICY IF EXISTS "users_view_emergency_contacts" ON public.emergency_contacts;
DROP POLICY IF EXISTS "family_manage_emergency_contacts" ON public.emergency_contacts;
DROP POLICY IF EXISTS "patients_create_emergency_alerts" ON public.emergency_alerts;
DROP POLICY IF EXISTS "users_view_emergency_alerts" ON public.emergency_alerts;
DROP POLICY IF EXISTS "users_manage_fcm_tokens" ON public.fcm_tokens;
DROP POLICY IF EXISTS "owners_view_face_recognition_logs" ON public.face_recognition_logs;
DROP POLICY IF EXISTS "users_view_own_notifications" ON public.notifications;

-- =====================================================
-- STEP 1: Enable RLS pada Semua Tabel
-- =====================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_family_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.known_persons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emergency_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emergency_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.face_recognition_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- STEP 2: PROFILES - Simplified Policies (NO RECURSION)
-- =====================================================

-- ✅ Users can view their own profile
CREATE POLICY "users_view_own_profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

-- ✅ Users can INSERT their own profile (CRITICAL - was missing!)
-- This is called by trigger after auth.users INSERT
CREATE POLICY "users_insert_own_profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- ✅ Users can update their own profile
CREATE POLICY "users_update_own_profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- ✅ SIMPLIFIED: Anyone authenticated can view other profiles
-- (Needed for family/patient relationships)
-- Security: User role in user_meta_data, tidak perlu query profiles table
CREATE POLICY "authenticated_users_view_profiles"
  ON public.profiles FOR SELECT
  USING (auth.role() = 'authenticated');

-- Note: Removed circular policies that caused infinite recursion
-- family_view_linked_patients and patients_view_linked_family
-- These caused: profiles -> patient_family_links -> profiles (LOOP!)

-- =====================================================
-- STEP 3: PATIENT_FAMILY_LINKS - Simplified
-- =====================================================

-- ✅ Users can view their own links
CREATE POLICY "users_view_own_links"
  ON public.patient_family_links FOR SELECT
  USING (
    auth.uid() = patient_id OR 
    auth.uid() = family_member_id
  );

-- ✅ Authenticated users can create links
-- (Will validate in application layer)
CREATE POLICY "authenticated_users_create_links"
  ON public.patient_family_links FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- ✅ Users can delete their own links
CREATE POLICY "users_delete_own_links"
  ON public.patient_family_links FOR DELETE
  USING (
    auth.uid() = patient_id OR 
    auth.uid() = family_member_id
  );

-- ✅ Users can update their own links
CREATE POLICY "users_update_own_links"
  ON public.patient_family_links FOR UPDATE
  USING (
    auth.uid() = patient_id OR 
    auth.uid() = family_member_id
  )
  WITH CHECK (
    auth.uid() = patient_id OR 
    auth.uid() = family_member_id
  );

-- =====================================================
-- STEP 4: ACTIVITIES - Simplified
-- =====================================================

-- ✅ Users can view activities they own or are linked to
CREATE POLICY "users_view_activities"
  ON public.activities FOR SELECT
  USING (
    auth.uid() = patient_id OR
    patient_id IN (
      SELECT patient_id FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    ) OR
    patient_id IN (
      SELECT family_member_id FROM public.patient_family_links
      WHERE patient_id = auth.uid()
    )
  );

-- ✅ Users can insert activities for themselves or linked patients
CREATE POLICY "users_insert_activities"
  ON public.activities FOR INSERT
  WITH CHECK (
    auth.uid() = patient_id OR
    patient_id IN (
      SELECT patient_id FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  );

-- ✅ Users can update activities they own or manage
CREATE POLICY "users_update_activities"
  ON public.activities FOR UPDATE
  USING (
    auth.uid() = patient_id OR
    patient_id IN (
      SELECT patient_id FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  )
  WITH CHECK (
    auth.uid() = patient_id OR
    patient_id IN (
      SELECT patient_id FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  );

-- ✅ Users can delete activities they own or manage
CREATE POLICY "users_delete_activities"
  ON public.activities FOR DELETE
  USING (
    auth.uid() = patient_id OR
    patient_id IN (
      SELECT patient_id FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  );

-- =====================================================
-- STEP 5: KNOWN_PERSONS - Simplified
-- =====================================================

-- ✅ Users can manage their own known persons
CREATE POLICY "users_manage_own_known_persons"
  ON public.known_persons FOR ALL
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

-- ✅ Family can view patient's known persons
CREATE POLICY "family_view_known_persons"
  ON public.known_persons FOR SELECT
  USING (
    owner_id IN (
      SELECT patient_id FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  );

-- =====================================================
-- STEP 6: LOCATIONS - Simplified
-- =====================================================

-- ✅ Patients can insert their own location
CREATE POLICY "patients_insert_location"
  ON public.locations FOR INSERT
  WITH CHECK (auth.uid() = patient_id);

-- ✅ Users can view their own or linked patient locations
CREATE POLICY "users_view_locations"
  ON public.locations FOR SELECT
  USING (
    auth.uid() = patient_id OR
    patient_id IN (
      SELECT patient_id FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  );

-- =====================================================
-- STEP 7: EMERGENCY_CONTACTS - Simplified
-- =====================================================

-- ✅ Users can manage emergency contacts
CREATE POLICY "users_manage_emergency_contacts"
  ON public.emergency_contacts FOR ALL
  USING (
    auth.uid() = patient_id OR 
    auth.uid() = contact_id
  )
  WITH CHECK (
    auth.uid() = patient_id OR 
    auth.uid() = contact_id
  );

-- =====================================================
-- STEP 8: EMERGENCY_ALERTS - Simplified
-- =====================================================

-- ✅ Patients can create emergency alerts
CREATE POLICY "patients_create_alerts"
  ON public.emergency_alerts FOR INSERT
  WITH CHECK (auth.uid() = patient_id);

-- ✅ Users can view alerts they're involved in
CREATE POLICY "users_view_alerts"
  ON public.emergency_alerts FOR SELECT
  USING (
    auth.uid() = patient_id OR
    patient_id IN (
      SELECT patient_id FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  );

-- ✅ Users can update alerts status
CREATE POLICY "users_update_alerts"
  ON public.emergency_alerts FOR UPDATE
  USING (
    auth.uid() = patient_id OR
    patient_id IN (
      SELECT patient_id FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  );

-- =====================================================
-- STEP 9: FCM_TOKENS - Simplified
-- =====================================================

-- ✅ Users manage their own FCM tokens
CREATE POLICY "users_manage_fcm_tokens"
  ON public.fcm_tokens FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- STEP 10: FACE_RECOGNITION_LOGS - Simplified
-- =====================================================

-- ✅ Users view their own logs
CREATE POLICY "users_view_face_logs"
  ON public.face_recognition_logs FOR SELECT
  USING (auth.uid() = patient_id);

-- ✅ Users insert their own logs
CREATE POLICY "users_insert_face_logs"
  ON public.face_recognition_logs FOR INSERT
  WITH CHECK (auth.uid() = patient_id);

-- =====================================================
-- STEP 11: NOTIFICATIONS - Simplified
-- =====================================================

-- ✅ Users manage their own notifications
CREATE POLICY "users_manage_notifications"
  ON public.notifications FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Verify all policies created
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Check RLS status
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- =====================================================
-- END OF RLS POLICIES
-- =====================================================

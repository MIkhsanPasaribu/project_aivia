-- =====================================================
-- AIVIA Database - Row Level Security (RLS) Policies
-- Version: 1.0.0
-- Date: 8 Oktober 2025
-- Description: RLS policies untuk keamanan data tingkat baris
-- =====================================================

-- =====================================================
-- IMPORTANT: RLS Overview
-- =====================================================
-- Row Level Security (RLS) memastikan bahwa:
-- 1. User hanya bisa akses data mereka sendiri
-- 2. Family hanya bisa akses data pasien yang di-link
-- 3. Anon key aman digunakan di client karena RLS protect data
-- 4. Semua policies menggunakan auth.uid() untuk identifikasi user
-- =====================================================

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
-- STEP 2: RLS Policies untuk Tabel profiles
-- =====================================================

-- Users can view their own profile
CREATE POLICY "users_view_own_profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "users_update_own_profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Family members can view linked patients' profiles
CREATE POLICY "family_view_linked_patients"
  ON public.profiles FOR SELECT
  USING (
    id IN (
      SELECT patient_id 
      FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  );

-- Patients can view their linked family members' profiles
CREATE POLICY "patients_view_linked_family"
  ON public.profiles FOR SELECT
  USING (
    id IN (
      SELECT family_member_id 
      FROM public.patient_family_links
      WHERE patient_id = auth.uid()
    )
  );

-- Admin can view all profiles (jika diperlukan)
CREATE POLICY "admin_view_all_profiles"
  ON public.profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND user_role = 'admin'
    )
  );

-- =====================================================
-- STEP 3: RLS Policies untuk patient_family_links
-- =====================================================

-- Users can view their own links (as patient or family)
CREATE POLICY "users_view_own_links"
  ON public.patient_family_links FOR SELECT
  USING (
    auth.uid() = patient_id OR 
    auth.uid() = family_member_id
  );

-- Family members can create links with patients
CREATE POLICY "family_create_links"
  ON public.patient_family_links FOR INSERT
  WITH CHECK (
    auth.uid() = family_member_id AND
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = patient_id AND user_role = 'patient'
    )
  );

-- Family members can delete their own links
CREATE POLICY "family_delete_own_links"
  ON public.patient_family_links FOR DELETE
  USING (auth.uid() = family_member_id);

-- Patients can delete links (remove family member)
CREATE POLICY "patients_delete_links"
  ON public.patient_family_links FOR DELETE
  USING (auth.uid() = patient_id);

-- Family members can update link permissions
CREATE POLICY "family_update_links"
  ON public.patient_family_links FOR UPDATE
  USING (auth.uid() = family_member_id)
  WITH CHECK (auth.uid() = family_member_id);

-- =====================================================
-- STEP 4: RLS Policies untuk activities
-- =====================================================

-- Patients can view their own activities
CREATE POLICY "patients_view_own_activities"
  ON public.activities FOR SELECT
  USING (auth.uid() = patient_id);

-- Family members can view linked patients' activities
CREATE POLICY "family_view_patient_activities"
  ON public.activities FOR SELECT
  USING (
    patient_id IN (
      SELECT patient_id 
      FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  );

-- Patients can insert their own activities
CREATE POLICY "patients_insert_own_activities"
  ON public.activities FOR INSERT
  WITH CHECK (auth.uid() = patient_id);

-- Family members can insert activities for linked patients
CREATE POLICY "family_insert_patient_activities"
  ON public.activities FOR INSERT
  WITH CHECK (
    patient_id IN (
      SELECT patient_id 
      FROM public.patient_family_links
      WHERE family_member_id = auth.uid() 
        AND can_edit_activities = TRUE
    )
  );

-- Patients can update their own activities
CREATE POLICY "patients_update_own_activities"
  ON public.activities FOR UPDATE
  USING (auth.uid() = patient_id)
  WITH CHECK (auth.uid() = patient_id);

-- Family members can update linked patients' activities (if permission granted)
CREATE POLICY "family_update_patient_activities"
  ON public.activities FOR UPDATE
  USING (
    patient_id IN (
      SELECT patient_id 
      FROM public.patient_family_links
      WHERE family_member_id = auth.uid() 
        AND can_edit_activities = TRUE
    )
  )
  WITH CHECK (
    patient_id IN (
      SELECT patient_id 
      FROM public.patient_family_links
      WHERE family_member_id = auth.uid() 
        AND can_edit_activities = TRUE
    )
  );

-- Patients can delete their own activities
CREATE POLICY "patients_delete_own_activities"
  ON public.activities FOR DELETE
  USING (auth.uid() = patient_id);

-- Family members can delete linked patients' activities (if permission granted)
CREATE POLICY "family_delete_patient_activities"
  ON public.activities FOR DELETE
  USING (
    patient_id IN (
      SELECT patient_id 
      FROM public.patient_family_links
      WHERE family_member_id = auth.uid() 
        AND can_edit_activities = TRUE
    )
  );

-- =====================================================
-- STEP 5: RLS Policies untuk known_persons
-- =====================================================

-- Owners (patients) can view their own known persons
CREATE POLICY "owners_view_own_known_persons"
  ON public.known_persons FOR SELECT
  USING (auth.uid() = owner_id);

-- Family members can view linked patients' known persons
CREATE POLICY "family_view_patient_known_persons"
  ON public.known_persons FOR SELECT
  USING (
    owner_id IN (
      SELECT patient_id 
      FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  );

-- Owners can insert their own known persons
CREATE POLICY "owners_insert_own_known_persons"
  ON public.known_persons FOR INSERT
  WITH CHECK (auth.uid() = owner_id);

-- Family members can insert known persons for linked patients
CREATE POLICY "family_insert_patient_known_persons"
  ON public.known_persons FOR INSERT
  WITH CHECK (
    owner_id IN (
      SELECT patient_id 
      FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  );

-- Owners can update their own known persons
CREATE POLICY "owners_update_own_known_persons"
  ON public.known_persons FOR UPDATE
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

-- Family members can update linked patients' known persons
CREATE POLICY "family_update_patient_known_persons"
  ON public.known_persons FOR UPDATE
  USING (
    owner_id IN (
      SELECT patient_id 
      FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  )
  WITH CHECK (
    owner_id IN (
      SELECT patient_id 
      FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  );

-- Owners can delete their own known persons
CREATE POLICY "owners_delete_own_known_persons"
  ON public.known_persons FOR DELETE
  USING (auth.uid() = owner_id);

-- Family members can delete linked patients' known persons
CREATE POLICY "family_delete_patient_known_persons"
  ON public.known_persons FOR DELETE
  USING (
    owner_id IN (
      SELECT patient_id 
      FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  );

-- =====================================================
-- STEP 6: RLS Policies untuk locations
-- =====================================================

-- Patients can insert their own location
CREATE POLICY "patients_insert_own_location"
  ON public.locations FOR INSERT
  WITH CHECK (auth.uid() = patient_id);

-- Patients can view their own location history
CREATE POLICY "patients_view_own_locations"
  ON public.locations FOR SELECT
  USING (auth.uid() = patient_id);

-- Family members can view linked patients' locations (if permission granted)
CREATE POLICY "family_view_patient_locations"
  ON public.locations FOR SELECT
  USING (
    patient_id IN (
      SELECT patient_id 
      FROM public.patient_family_links
      WHERE family_member_id = auth.uid() 
        AND can_view_location = TRUE
    )
  );

-- =====================================================
-- STEP 7: RLS Policies untuk emergency_contacts
-- =====================================================

-- Patients can view their own emergency contacts
CREATE POLICY "patients_view_own_emergency_contacts"
  ON public.emergency_contacts FOR SELECT
  USING (auth.uid() = patient_id);

-- Family members can view if they are listed as emergency contact
CREATE POLICY "contacts_view_themselves"
  ON public.emergency_contacts FOR SELECT
  USING (auth.uid() = contact_id);

-- Family members can view linked patients' emergency contacts
CREATE POLICY "family_view_patient_emergency_contacts"
  ON public.emergency_contacts FOR SELECT
  USING (
    patient_id IN (
      SELECT patient_id 
      FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  );

-- Patients can manage their own emergency contacts
CREATE POLICY "patients_manage_own_emergency_contacts"
  ON public.emergency_contacts FOR ALL
  USING (auth.uid() = patient_id)
  WITH CHECK (auth.uid() = patient_id);

-- Family members can manage linked patients' emergency contacts
CREATE POLICY "family_manage_patient_emergency_contacts"
  ON public.emergency_contacts FOR ALL
  USING (
    patient_id IN (
      SELECT patient_id 
      FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  )
  WITH CHECK (
    patient_id IN (
      SELECT patient_id 
      FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  );

-- =====================================================
-- STEP 8: RLS Policies untuk emergency_alerts
-- =====================================================

-- Patients can insert their own emergency alerts
CREATE POLICY "patients_insert_own_alerts"
  ON public.emergency_alerts FOR INSERT
  WITH CHECK (auth.uid() = patient_id);

-- Patients can view their own alerts
CREATE POLICY "patients_view_own_alerts"
  ON public.emergency_alerts FOR SELECT
  USING (auth.uid() = patient_id);

-- Family members can view linked patients' alerts
CREATE POLICY "family_view_patient_alerts"
  ON public.emergency_alerts FOR SELECT
  USING (
    patient_id IN (
      SELECT patient_id 
      FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  );

-- Emergency contacts can view alerts
CREATE POLICY "emergency_contacts_view_alerts"
  ON public.emergency_alerts FOR SELECT
  USING (
    patient_id IN (
      SELECT patient_id 
      FROM public.emergency_contacts
      WHERE contact_id = auth.uid()
    )
  );

-- Family members can update alert status (acknowledge, resolve)
CREATE POLICY "family_update_patient_alerts"
  ON public.emergency_alerts FOR UPDATE
  USING (
    patient_id IN (
      SELECT patient_id 
      FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  )
  WITH CHECK (
    patient_id IN (
      SELECT patient_id 
      FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  );

-- =====================================================
-- STEP 9: RLS Policies untuk fcm_tokens
-- =====================================================

-- Users can view their own tokens
CREATE POLICY "users_view_own_tokens"
  ON public.fcm_tokens FOR SELECT
  USING (auth.uid() = user_id);

-- Users can manage their own tokens
CREATE POLICY "users_manage_own_tokens"
  ON public.fcm_tokens FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- STEP 10: RLS Policies untuk face_recognition_logs
-- =====================================================

-- Patients can view their own recognition logs
CREATE POLICY "patients_view_own_recognition_logs"
  ON public.face_recognition_logs FOR SELECT
  USING (auth.uid() = patient_id);

-- Patients can insert their own recognition logs
CREATE POLICY "patients_insert_own_recognition_logs"
  ON public.face_recognition_logs FOR INSERT
  WITH CHECK (auth.uid() = patient_id);

-- Family members can view linked patients' recognition logs
CREATE POLICY "family_view_patient_recognition_logs"
  ON public.face_recognition_logs FOR SELECT
  USING (
    patient_id IN (
      SELECT patient_id 
      FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  );

-- =====================================================
-- STEP 11: RLS Policies untuk notifications
-- =====================================================

-- Users can view their own notifications
CREATE POLICY "users_view_own_notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid() = user_id);

-- Users can update their own notifications (mark as read)
CREATE POLICY "users_update_own_notifications"
  ON public.notifications FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- System/Backend can insert notifications for any user
-- Note: Ini akan di-handle oleh Edge Functions dengan service_role key
CREATE POLICY "system_insert_notifications"
  ON public.notifications FOR INSERT
  WITH CHECK (TRUE); -- Service role akan bypass ini

-- =====================================================
-- STEP 12: Storage Bucket Policies
-- =====================================================

-- Policy untuk avatars bucket (public read, owner write)
CREATE POLICY "avatars_public_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

CREATE POLICY "avatars_user_upload"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "avatars_user_update"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  )
  WITH CHECK (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "avatars_user_delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Policy untuk known_persons_photos bucket (private, owner and family)
CREATE POLICY "known_persons_photos_owner_read"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'known_persons_photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "known_persons_photos_family_read"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'known_persons_photos' AND
    (storage.foldername(name))[1] IN (
      SELECT patient_id::text 
      FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  );

CREATE POLICY "known_persons_photos_owner_upload"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'known_persons_photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "known_persons_photos_family_upload"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'known_persons_photos' AND
    (storage.foldername(name))[1] IN (
      SELECT patient_id::text 
      FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  );

CREATE POLICY "known_persons_photos_owner_delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'known_persons_photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "known_persons_photos_family_delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'known_persons_photos' AND
    (storage.foldername(name))[1] IN (
      SELECT patient_id::text 
      FROM public.patient_family_links
      WHERE family_member_id = auth.uid()
    )
  );

-- Policy untuk face_recognition_captures bucket (private, patient only)
CREATE POLICY "face_recognition_captures_patient_read"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'face_recognition_captures' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "face_recognition_captures_patient_upload"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'face_recognition_captures' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "face_recognition_captures_patient_delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'face_recognition_captures' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '✅ RLS Policies created successfully!';
  RAISE NOTICE '🔒 All tables are now protected with Row Level Security';
  RAISE NOTICE '✅ Storage bucket policies configured';
  RAISE NOTICE '📝 Next: Run 003_triggers_functions.sql for automation';
END $$;
